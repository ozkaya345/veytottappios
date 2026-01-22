import 'package:flutter/material.dart';
// Kod artık oluşturma sonrası atanacağı için ek hizmetlere gerek yok
import '../../core/navigation/app_routes.dart';
import '../../data/services/status_table_service.dart';
import '../../data/services/admin_auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StatusAddScreen extends StatefulWidget {
  const StatusAddScreen({super.key, this.useAdminAuth = false});

  final bool useAdminAuth;

  @override
  State<StatusAddScreen> createState() => _StatusAddScreenState();
}

class _StatusAddScreenState extends State<StatusAddScreen> {
  final _titleCtrl = TextEditingController();
  final List<_PendingStatusTable> _pendingTables = [];
  bool _useUnorderedFallback = false;

  String? _adminUid;

  @override
  void initState() {
    super.initState();

    if (widget.useAdminAuth) {
      () async {
        try {
          final adminAuth = await AdminAuthService.adminAuth();
          final uid = adminAuth.currentUser?.uid;
          if (!mounted) return;
          setState(() {
            _adminUid = uid;
          });
        } catch (_) {
          // ignore
        }
      }();
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _watchTables() {
    // Admin panelinde admin oturumunun uid'si ile filtrele.
    // Normal kullanımda default oturum uid'si.
    final uid = widget.useAdminAuth ? _adminUid : FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty) {
      return const Stream.empty();
    }

    final baseQuery = FirebaseFirestore.instance
        .collection('status_tables')
        .where('ownerId', isEqualTo: uid)
        .where('trashed', isEqualTo: false);

    if (_useUnorderedFallback) {
      return baseQuery.limit(200).snapshots();
    }

    return baseQuery
        .orderBy('updatedAt', descending: true)
        .limit(200)
        .snapshots();
  }

  void _syncPendingWithLoaded(Set<String> loadedIds) {
    if (_pendingTables.isEmpty) return;
    final before = _pendingTables.length;
    _pendingTables.removeWhere((p) => loadedIds.contains(p.id));
    if (before != _pendingTables.length && mounted) {
      setState(() {});
    }
  }

  Future<void> _promptAndCreate() async {
    _titleCtrl.clear();
    final title = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Yeni Sayfa Başlığı'),
        content: TextField(
          controller: _titleCtrl,
          decoration: const InputDecoration(labelText: 'Başlık'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, _titleCtrl.text.trim()),
            child: const Text('Oluştur'),
          ),
        ],
      ),
    );
    if (title == null || title.isEmpty) return;
    if (!mounted) return;
    // Başlık girildiğinde tabloyu hemen oluştur, listeye düşsün.
    try {
      const rows = 12;
      const cols = 8;
      final data = List.generate(rows, (_) => List.generate(cols, (_) => ''));
      final colHeaders = List<String>.generate(cols, (_) => '');

      String? ownerIdOverride;
      if (widget.useAdminAuth) {
        final adminAuth = await AdminAuthService.adminAuth();
        ownerIdOverride = adminAuth.currentUser?.uid;
      }

      final res = await StatusTableService.createTable(
        rows: rows,
        cols: cols,
        data: data,
        title: title,
        colHeaders: colHeaders,
        ownerIdOverride: ownerIdOverride,
      );

      final id = res['id'] ?? '';
      final code = res['code'] ?? id;

      if (id.isNotEmpty) {
        // UI'da hemen görünsün (Firestore query'nin dönmesini bekleme).
        setState(() {
          _pendingTables.insert(
            0,
            _PendingStatusTable(id: id, title: title, code: code),
          );
        });
      }

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Sayfa oluşturuldu')));

      if (!mounted) return;

      // Düzenlemeye geçmeden listede kal (kullanıcı isteği: B seçeneği)
      if (id.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Oluşturma başarılı ancak kimlik alınamadı'),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Oluşturulamadı: $e')));
    }
  }

  Future<void> _confirmAndDelete(
    String id, {
    String? title,
    String? code,
  }) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sayfayı Sil'),
        content: Text(
          [
            if (title != null && title.isNotEmpty) 'Başlık: $title',
            if (code != null && code.isNotEmpty) 'Kod: $code',
            'Bu sayfa silinecek. Devam edilsin mi?',
          ].join('\n'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('İptal'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.delete_forever),
            label: const Text('Sil'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await StatusTableService.softDeleteTable(id);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Çöp kutusuna taşındı')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silme sırasında hata oluştu')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Durum Ekle'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
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
                    Color.alphaBlend(
                      primary.withValues(alpha: 0.35),
                      Colors.black,
                    ),
                    primary.withValues(alpha: 0.22),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Çalışma Sayfaları',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: _promptAndCreate,
                    borderRadius: BorderRadius.circular(18),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 18,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: primary.withValues(alpha: 0.45),
                        ),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.black.withValues(alpha: 0.55),
                            Color.alphaBlend(
                              primary.withValues(alpha: 0.22),
                              Colors.black,
                            ),
                          ],
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.white24),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.description_rounded,
                                color: Colors.white,
                                size: 32,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Yeni Sayfa Oluştur',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Başlık girerek yeni çalışma sayfası ekle',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Icon(
                            Icons.chevron_right,
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: _watchTables(),
                      builder: (context, snapshot) {
                        final error = snapshot.error;
                        if (error is FirebaseException &&
                            error.code == 'failed-precondition' &&
                            !_useUnorderedFallback) {
                          // Index yoksa sıralamasız fallback'e otomatik geç.
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (!mounted) return;
                            setState(() => _useUnorderedFallback = true);
                          });
                        }

                        final docs = snapshot.data?.docs ?? const [];

                        final loadedIds = docs.map((e) => e.id).toSet();
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (!mounted) return;
                          _syncPendingWithLoaded(loadedIds);
                        });

                        final showSpinner =
                            snapshot.connectionState == ConnectionState.waiting &&
                            docs.isEmpty &&
                            _pendingTables.isEmpty;

                        if (showSpinner) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        if (docs.isEmpty && _pendingTables.isEmpty) {
                          return Center(
                            child: Text(
                              'Henüz çalışma sayfası yok',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: Colors.white70,
                              ),
                            ),
                          );
                        }

                        final loadErrorText = (snapshot.error != null)
                            ? (snapshot.error is FirebaseException
                                ? (snapshot.error as FirebaseException).message
                                : snapshot.error.toString())
                            : null;

                        return Column(
                          children: [
                            if (loadErrorText != null) ...[
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Text(
                                  'Yüklenemedi: $loadErrorText',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.error,
                                  ),
                                ),
                              ),
                            ],
                            Expanded(
                              child: ListView.separated(
                                itemCount:
                                    _pendingTables.length + docs.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 12),
                                itemBuilder: (ctx, idx) {
                                  final isPending = idx < _pendingTables.length;

                                  final String id;
                                  final String? title;
                                  final String code;

                                  if (isPending) {
                                    final p = _pendingTables[idx];
                                    id = p.id;
                                    title = p.title;
                                    code = p.code;
                                  } else {
                                    final d = docs[idx - _pendingTables.length];
                                    final data = d.data();
                                    id = d.id;
                                    title = (data['title'] as String?)?.trim();
                                    code = (data['code'] as String?)?.trim() ?? id;
                                  }

                                  return GestureDetector(
                                    onLongPress: () => _confirmAndDelete(
                                      id,
                                      title: title,
                                      code: code,
                                    ),
                                    child: Container(
                                      padding: const EdgeInsets.all(14),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: primary.withValues(alpha: 0.45),
                                        ),
                                        gradient: LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            Colors.black.withValues(alpha: 0.55),
                                            Color.alphaBlend(
                                              primary.withValues(alpha: 0.22),
                                              Colors.black,
                                            ),
                                          ],
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Expanded(
                                                child: Row(
                                                  children: [
                                                    Container(
                                                      width: 40,
                                                      height: 40,
                                                      decoration: const BoxDecoration(
                                                        shape: BoxShape.circle,
                                                        gradient: LinearGradient(
                                                          colors: [
                                                            Color(0xFF2E7D32),
                                                            Color(0xFF66BB6A),
                                                          ],
                                                        ),
                                                      ),
                                                      child: const Center(
                                                        child: Icon(
                                                          Icons.eco,
                                                          color: Colors.white,
                                                          size: 22,
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 10),
                                                    Flexible(
                                                      child: Text(
                                                        title == null || title.isEmpty
                                                            ? 'Başlıksız'
                                                            : title,
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                        style: theme.textTheme.titleMedium?.copyWith(
                                                          color: Colors.white,
                                                          fontWeight: FontWeight.w800,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 10,
                                                  vertical: 6,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Colors.black.withValues(alpha: 0.30),
                                                  borderRadius: BorderRadius.circular(20),
                                                  border: Border.all(color: Colors.white24),
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Text(
                                                      'Kod: $code',
                                                      style: const TextStyle(color: Colors.white70),
                                                    ),
                                                    const SizedBox(width: 6),
                                                    InkWell(
                                                      onTap: () {
                                                        Clipboard.setData(ClipboardData(text: code));
                                                        ScaffoldMessenger.of(context).showSnackBar(
                                                          const SnackBar(content: Text('Kod kopyalandı')),
                                                        );
                                                      },
                                                      child: const Icon(
                                                        Icons.copy_all,
                                                        size: 18,
                                                        color: Colors.white70,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 12),
                                          Align(
                                            alignment: Alignment.centerLeft,
                                            child: ElevatedButton.icon(
                                              onPressed: () {
                                                Navigator.of(context).pushNamed(
                                                  AppRoutes.statusTrack,
                                                    arguments: {
                                                      'tableId': id,
                                                      'readOnly': false,
                                                    },
                                                );
                                              },
                                              icon: const Icon(Icons.login),
                                              label: const Text('Giriş'),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

final class _PendingStatusTable {
  _PendingStatusTable({required this.id, required this.title, required this.code});

  final String id;
  final String title;
  final String code;
}
