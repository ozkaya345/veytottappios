import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../data/services/status_table_service.dart';

class TrashScreen extends StatefulWidget {
  const TrashScreen({super.key});

  @override
  State<TrashScreen> createState() => _TrashScreenState();
}

class _TrashScreenState extends State<TrashScreen> {
  bool _loading = true;
  List<_TrashItem> _items = [];

  @override
  void initState() {
    super.initState();
    _loadTrash();
  }

  Future<void> _loadTrash() async {
    setState(() => _loading = true);
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null || uid.isEmpty) {
        _items = [];
        return;
      }

      // Not: Çöp kutusundaki kayıtlar otomatik olarak KALICI SİLİNMEZ.
      // Kullanıcı yalnızca "Kalıcı Sil" veya "Eski çöpü temizle" ile siler.
      Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> loadCollection(
        String collection,
      ) async {
        final base = FirebaseFirestore.instance
            .collection(collection)
            .where('ownerId', isEqualTo: uid)
            .where('trashed', isEqualTo: true);

        QuerySnapshot<Map<String, dynamic>> snap;
        try {
          snap = await base.orderBy('deletedAt', descending: true).get();
        } on FirebaseException catch (e) {
          if (e.code == 'failed-precondition') {
            snap = await base.get();
          } else {
            rethrow;
          }
        }

        return snap.docs;
      }

      final stKeep = await loadCollection('status_tables');
      final pKeep = await loadCollection('personnel');

      final list = <_TrashItem>[];
      for (final d in stKeep) {
        list.add(
          _TrashItem(collection: 'status_tables', id: d.id, data: d.data()),
        );
      }
      for (final d in pKeep) {
        list.add(_TrashItem(collection: 'personnel', id: d.id, data: d.data()));
      }
      list.sort((a, b) {
        final da = a.data['deletedAt'] as Timestamp?;
        final db = b.data['deletedAt'] as Timestamp?;
        final ta = da?.toDate() ?? DateTime.fromMillisecondsSinceEpoch(0);
        final tb = db?.toDate() ?? DateTime.fromMillisecondsSinceEpoch(0);
        return tb.compareTo(ta);
      });
      _items = list;
    } catch (_) {
      _items = [];
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _purgeOldTrash({int days = 15}) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eski Çöpü Temizle'),
        content: Text(
          '$days günden eski çöp kayıtları kalıcı olarak silinsin mi?\nBu işlem geri alınamaz.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('İptal'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.delete_forever),
            label: const Text('Temizle'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    setState(() => _loading = true);
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null || uid.isEmpty) return;

      final threshold = DateTime.now().subtract(Duration(days: days));

      Future<void> purgeCollection(String collection) async {
        final base = FirebaseFirestore.instance
            .collection(collection)
            .where('ownerId', isEqualTo: uid)
            .where('trashed', isEqualTo: true);

        QuerySnapshot<Map<String, dynamic>> snap;
        try {
          snap = await base.orderBy('deletedAt', descending: true).get();
        } on FirebaseException catch (e) {
          if (e.code == 'failed-precondition') {
            snap = await base.get();
          } else {
            rethrow;
          }
        }

        final toDelete = <QueryDocumentSnapshot<Map<String, dynamic>>>[];
        for (final d in snap.docs) {
          final ts = d.data()['deletedAt'];
          if (ts is Timestamp && ts.toDate().isBefore(threshold)) {
            toDelete.add(d);
          }
        }

        // Firestore batch limiti 500. Güvenli tarafta kalalım.
        const maxOpsPerBatch = 450;
        WriteBatch? batch;
        int ops = 0;
        Future<void> flush() async {
          if (batch == null) return;
          if (ops == 0) return;
          await batch!.commit();
          batch = null;
          ops = 0;
        }

        for (final d in toDelete) {
          batch ??= FirebaseFirestore.instance.batch();
          batch!.delete(d.reference);
          ops++;
          if (ops >= maxOpsPerBatch) {
            await flush();
          }
        }
        await flush();
      }

      await purgeCollection('status_tables');
      await purgeCollection('personnel');
    } catch (_) {
      // Best-effort: UI'da yine de mevcut çöpü göstermeye çalış.
    }

    await _loadTrash();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Eski çöp temizlendi')),
    );
  }

  Future<void> _restore(String id, String collection) async {
    if (collection == 'status_tables') {
      await StatusTableService.restoreTable(id);
    } else {
      await FirebaseFirestore.instance.collection('personnel').doc(id).set({
        'trashed': false,
        'deletedAt': null,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
    await _loadTrash();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Geri yüklendi')),
    );
  }

  Future<void> _deleteForever(String id, {String? title, required String collection}) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Kalıcı Sil'),
        content: Text('"${title ?? id}" kalıcı olarak silinsin mi? Bu işlem geri alınamaz.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('İptal')),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.delete_forever),
            label: const Text('Sil'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await FirebaseFirestore.instance.collection(collection).doc(id).delete();
    await _loadTrash();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Kalıcı olarak silindi')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    final Widget content = _loading
        ? const Center(child: CircularProgressIndicator())
        : (_items.isEmpty
            ? Center(
                child: Text(
                  'Çöp kutusu boş',
                  style: theme.textTheme.bodyLarge?.copyWith(color: Colors.white70),
                ),
              )
            : ListView.separated(
                itemCount: _items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (ctx, idx) {
                  final item = _items[idx];
                  final data = item.data;
                  final id = item.id;
                  final isTable = item.collection == 'status_tables';
                  final title = isTable
                      ? ((data['title'] as String?)?.trim())
                      : ((data['name'] as String?)?.trim());
                  final code = isTable ? ((data['code'] as String?)?.trim() ?? id) : null;
                  final deletedAt = data['deletedAt'];
                  DateTime? deletedDate;
                  if (deletedAt is Timestamp) deletedDate = deletedAt.toDate();
                  return GestureDetector(
                    onLongPress: () => _deleteForever(id, title: title, collection: item.collection),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: primary.withAlpha(115)),
                        color: Colors.black.withAlpha(89),
                      ),

                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(isTable ? Icons.table_chart : Icons.person_off, color: Colors.white70),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  title == null || title.isEmpty ? 'Başlıksız' : title,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              if (isTable && code != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withAlpha(77),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: Colors.white24),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text('Kod: $code', style: const TextStyle(color: Colors.white70)),
                                      const SizedBox(width: 6),
                                      InkWell(
                                        onTap: () {
                                          Clipboard.setData(ClipboardData(text: code));
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Kod kopyalandı')),
                                          );
                                        },
                                        child: const Icon(Icons.copy_all, size: 18, color: Colors.white70),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                          if (deletedDate != null) ...[
                            const SizedBox(height: 6),
                            Text('Silinme: $deletedDate', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                          ],
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              ElevatedButton.icon(
                                onPressed: () => _restore(id, item.collection),
                                icon: const Icon(Icons.restore),
                                label: const Text('Geri Yükle'),
                              ),
                              const SizedBox(width: 12),
                              OutlinedButton.icon(
                                onPressed: () => _deleteForever(id, title: title, collection: item.collection),
                                icon: const Icon(Icons.delete_forever),
                                label: const Text('Kalıcı Sil'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ));

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Çöp Kutusu'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Eski çöpü temizle',
            icon: const Icon(Icons.delete_sweep),
            onPressed: _purgeOldTrash,
          ),
          IconButton(
            tooltip: 'Yenile',
            icon: const Icon(Icons.refresh),
            onPressed: _loadTrash,
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  stops: const [0.0, 0.55, 1.0],
                  colors: [
                    Colors.black,
                    Color.alphaBlend(primary.withAlpha(90), Colors.black),
                    primary.withAlpha(56),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: content,
            ),
          ),
        ],
      ),
    );
  }
}

class _TrashItem {
  _TrashItem({required this.collection, required this.id, required this.data});
  final String collection; // 'status_tables' | 'personnel'
  final String id;
  final Map<String, dynamic> data;
}
