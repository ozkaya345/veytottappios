import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';

class StatusTableService {
  static final _db = FirebaseFirestore.instance;

  static final _rnd = Random.secure();

  static String _generateTrackingCode() {
    final n = _rnd.nextInt(1000000); // 0..999999
    final digits = n.toString().padLeft(6, '0');
    return 'OTT-$digits';
  }

  static Future<String> _generateUniqueTrackingCode() async {
    for (int i = 0; i < 10; i++) {
      final code = _generateTrackingCode();
      // Collision check must not rely on reading other users' status_tables.
      // Use the public mapping collection instead.
      final exists = await _db.collection('status_table_codes').doc(code).get();
      if (!exists.exists) return code;
    }
    // Son çare: zaman damgasının son 6 hanesi ile fallback
    final n = DateTime.now().millisecondsSinceEpoch % 1000000;
    final digits = n.toString().padLeft(6, '0');
    return 'OTT-$digits';
  }

  static Future<void> saveTable({
    required String id,
    required int rows,
    required int cols,
    required List<List<String>> data,
    String? title,
    List<String>? colHeaders,
  }) async {
    final flat = _encodeGrid(data, rows: rows, cols: cols);
    final col = _db.collection('status_tables').doc(id);
    await col.set({
      'rows': rows,
      'cols': cols,
      // Firestore nested arrays (List<List<...>>) are not supported.
      // Store as row-major flat list; decode on read.
      'data': flat,
      if (title != null) 'title': title,
      if (colHeaders != null) 'colHeaders': colHeaders,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static Future<Map<String, dynamic>?> loadTable(String id) async {
    final doc = await _db.collection('status_tables').doc(id).get();
    if (!doc.exists) return null;
    final raw = doc.data();
    if (raw == null) return null;

    // Backward/forward compatible decode for `data`.
    final rows = (raw['rows'] as num?)?.toInt() ?? 0;
    final cols = (raw['cols'] as num?)?.toInt() ?? 0;
    final decoded = _decodeGrid(raw['data'], rows: rows, cols: cols);
    return {
      ...raw,
      'rows': rows,
      'cols': cols,
      'data': decoded,
    };
  }

  // Yeni: Auto-ID ile tablo oluştur ve kısa kodu alan olarak yaz. Doc id döner.
  static Future<Map<String, String>> createTable({
    required int rows,
    required int cols,
    required List<List<String>> data,
    required String title,
    List<String>? colHeaders,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty) {
      throw FirebaseAuthException(code: 'no-user', message: 'Oturum bulunamadı');
    }
    final code = await _generateUniqueTrackingCode();
    final flat = _encodeGrid(data, rows: rows, cols: cols);
    final ref = await _db.collection('status_tables').add({
      'rows': rows,
      'cols': cols,
      'data': flat,
      'title': title,
      if (colHeaders != null) 'colHeaders': colHeaders,
      'code': code,
      'ownerId': uid,
      'trashed': false,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Public mapping used for "Kod ile Aç" flow.
    await _db.collection('status_table_codes').doc(code).set({
      'tableId': ref.id,
      'ownerId': uid,
      'trashed': false,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    return {'id': ref.id, 'code': code};
  }

  static List<String> _encodeGrid(List<List<String>> data, {required int rows, required int cols}) {
    final flat = <String>[];
    for (int r = 0; r < rows; r++) {
      final row = (r < data.length) ? data[r] : const <String>[];
      for (int c = 0; c < cols; c++) {
        flat.add((c < row.length) ? row[c] : '');
      }
    }
    return flat;
  }

  static List<List<String>> _decodeGrid(dynamic raw, {required int rows, required int cols}) {
    if (rows <= 0 || cols <= 0) {
      return <List<String>>[];
    }

    // Legacy format (nested list) support.
    if (raw is List && raw.isNotEmpty && raw.first is List) {
      return raw
          .map<List<String>>((row) => (row as List).map((e) => e?.toString() ?? '').toList())
          .toList();
    }

    // New format: flat list.
    final flat = (raw is List) ? raw.map((e) => e?.toString() ?? '').toList() : <String>[];
    final out = List.generate(rows, (_) => List.generate(cols, (_) => ''));
    for (int i = 0; i < rows * cols && i < flat.length; i++) {
      final r = i ~/ cols;
      final c = i % cols;
      out[r][c] = flat[i];
    }
    return out;
  }

  // Yeni: Kullanıcıdan alınan kısa koda göre belge id'sini çöz.
  static Future<String?> resolveTableIdByCode(String code) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;
    final input = code.trim().toUpperCase();
    if (input.isEmpty) return null;

    // Primary: public mapping lookup (works before link exists).
    try {
      final mapped = await _db.collection('status_table_codes').doc(input).get();
      if (mapped.exists) {
        final data = mapped.data();
        final trashed = (data?['trashed'] == true);
        final tableId = (data?['tableId'] as String?)?.trim();
        if (!trashed && tableId != null && tableId.isNotEmpty) return tableId;
        return null;
      }
    } catch (_) {
      // If mapping is not readable for any reason, fall back to legacy logic.
    }

    // Kullanıcı docId yapıştırdıysa direkt dene.
    try {
      final byId = await _db.collection('status_tables').doc(input).get();
      if (byId.exists) {
        final data = byId.data();
        final trashed = (data?['trashed'] == true);
        return trashed ? null : byId.id;
      }
    } catch (_) {
      // Non-owner without link can't read status_tables; ignore.
    }

    // Aksi halde kod alanına göre ara (müşteri hesabı da okuyabilsin diye ownerId filtresi yok).
    try {
      final snap = await _db
          .collection('status_tables')
          .where('code', isEqualTo: input)
          .limit(1)
          .get();
      if (snap.docs.isEmpty) return null;
      final data = snap.docs.first.data();
      final trashed = data['trashed'] == true;
      return trashed ? null : snap.docs.first.id;
    } catch (_) {
      return null;
    }
  }

  static Future<void> softDeleteTable(String id) async {
    final tableRef = _db.collection('status_tables').doc(id);
    await tableRef.set({
      'trashed': true,
      'deletedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    try {
      final snap = await tableRef.get();
      final code = (snap.data()?['code'] as String?)?.trim().toUpperCase();
      if (code != null && code.isNotEmpty) {
        await _db.collection('status_table_codes').doc(code).set({
          'trashed': true,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    } catch (_) {
      // Best-effort only.
    }
  }

  static Future<void> restoreTable(String id) async {
    final tableRef = _db.collection('status_tables').doc(id);
    await tableRef.set({
      'trashed': false,
      'deletedAt': null,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    try {
      final snap = await tableRef.get();
      final code = (snap.data()?['code'] as String?)?.trim().toUpperCase();
      if (code != null && code.isNotEmpty) {
        await _db.collection('status_table_codes').doc(code).set({
          'trashed': false,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    } catch (_) {
      // Best-effort only.
    }
  }
}
