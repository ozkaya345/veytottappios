import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

final class StatusTableLinkService {
  StatusTableLinkService._();

  static final _db = FirebaseFirestore.instance;

  static String _linkDocId({required String userId, required String tableId}) {
    return '${userId}_$tableId';
  }

  static Future<void> linkTableToCurrentUser({
    required String tableId,
    required String code,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty) {
      throw FirebaseAuthException(code: 'no-user', message: 'Oturum bulunamadı');
    }

    final docId = _linkDocId(userId: uid, tableId: tableId);
    await _db.collection('status_table_links').doc(docId).set({
      'userId': uid,
      'tableId': tableId,
      'code': code.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> watchMyLinks() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty) {
      return const Stream.empty();
    }
    return _db
        .collection('status_table_links')
        .where('userId', isEqualTo: uid)
        .snapshots();
  }

  static Future<void> unlinkTableFromCurrentUser({required String tableId}) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty) {
      throw FirebaseAuthException(code: 'no-user', message: 'Oturum bulunamadı');
    }

    final id = tableId.trim();
    if (id.isEmpty) return;

    final docId = _linkDocId(userId: uid, tableId: id);
    await _db.collection('status_table_links').doc(docId).delete();
  }
}
