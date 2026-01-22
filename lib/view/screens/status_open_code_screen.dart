import 'package:flutter/material.dart';

import '../../core/navigation/app_routes.dart';
import '../../data/services/status_table_link_service.dart';
import '../../data/services/status_table_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';

class StatusOpenCodeScreen extends StatefulWidget {
  const StatusOpenCodeScreen({super.key});

  @override
  State<StatusOpenCodeScreen> createState() => _StatusOpenCodeScreenState();
}

class _StatusOpenCodeScreenState extends State<StatusOpenCodeScreen> {
  final _codeCtrl = TextEditingController();
  bool _saving = false;

  Future<void> _confirmAndUnlink({
    required String tableId,
    required String code,
  }) async {
    if (tableId.trim().isEmpty) return;

    final res = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sil'),
        content: Text(
          (code.trim().isEmpty)
              ? 'Bu kartı listenden kaldırmak istiyor musun?'
              : 'Bu kodu listenden silmek istiyor musun?\n\n$code',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('İptal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (res != true) return;
    if (!mounted) return;

    try {
      await StatusTableLinkService.unlinkTableFromCurrentUser(tableId: tableId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Listeden silindi')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Silinemedi: $e')),
      );
    }
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final code = _codeCtrl.text.trim().toUpperCase();
    if (code.isEmpty) return;

    final messenger = ScaffoldMessenger.of(context);
    setState(() => _saving = true);
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null || uid.isEmpty) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Giriş yapmalısın')),
        );
        return;
      }

      final tableId = await StatusTableService.resolveTableIdByCode(code);
      if (tableId == null) {
        if (!mounted) return;
        messenger.showSnackBar(const SnackBar(content: Text('Kod bulunamadı')));
        return;
      }

      await StatusTableLinkService.linkTableToCurrentUser(
        tableId: tableId,
        code: code,
      );

      // Kullanıcı aynı ekranda kalsın; sadece input'u temizle.
      _codeCtrl.clear();

      if (!mounted) return;
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: const Text('Kod eklendi (kartlara kaydedildi)'),
            action: SnackBarAction(
              label: 'Kartlar',
              onPressed: () {
                Navigator.of(context).pushNamed(AppRoutes.statusTrackList);
              },
            ),
          ),
        );
    } catch (e) {
      if (!mounted) return;
      if (e is FirebaseException) {
        final msg = (e.message == null || e.message!.trim().isEmpty)
            ? e.code
            : '${e.code}: ${e.message}';
        messenger.showSnackBar(SnackBar(content: Text('Kaydedilemedi: $msg')));
      } else {
        messenger.showSnackBar(SnackBar(content: Text('Kaydedilemedi: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Kod ile Aç'),
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
                    'Kod Yapıştır',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _codeCtrl,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _save(),
                    decoration: const InputDecoration(
                      filled: true,
                      labelText: 'Kart Kodu (örn: OTT-123456)',
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _save,
                      child: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Kaydet'),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Ekli Kodlarım',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: StreamBuilder(
                      stream: StatusTableLinkService.watchMyLinks(),
                      builder: (context, snapshot) {
                        final links = snapshot.data?.docs ?? const [];
                        if (links.isEmpty) {
                          return const Text(
                            'Henüz kod eklenmedi',
                            style: TextStyle(color: Colors.white70),
                          );
                        }

                        return ListView.separated(
                          itemCount: links.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (ctx, i) {
                            final data = links[i].data();
                            final code = (data['code'] as String?)?.trim() ?? '';
                            final tableId = (data['tableId'] as String?)?.trim() ?? '';
                            final created = data['createdAt'];
                            final ts = created is Timestamp
                                ? created.toDate()
                                : null;
                            final dateStr = ts != null
                                ? '${ts.year}-${ts.month.toString().padLeft(2, '0')}-${ts.day.toString().padLeft(2, '0')}'
                                : '';
                            return InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onLongPress: () => _confirmAndUnlink(
                                tableId: tableId,
                                code: code,
                              ),
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.white24),
                                  color: Colors.black.withValues(alpha: 0.25),
                                ),
                                child: Row(
                                  children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          code.isEmpty ? '(kodsuz)' : code,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        if (tableId.isNotEmpty)
                                          Text(
                                            'Tablo: $tableId',
                                            style: const TextStyle(
                                              color: Colors.white70,
                                              fontSize: 12,
                                            ),
                                          ),
                                        if (dateStr.isNotEmpty)
                                          Text(
                                            dateStr,
                                            style: const TextStyle(
                                              color: Colors.white54,
                                              fontSize: 11,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.copy_all, color: Colors.white70),
                                    onPressed: () {
                                      Clipboard.setData(ClipboardData(text: code));
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Kod kopyalandı')),
                                      );
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.open_in_new, color: Colors.white70),
                                    onPressed: () {
                                      Navigator.of(context).pushNamed(
                                        AppRoutes.statusTrack,
                                        arguments: tableId,
                                      );
                                    },
                                  ),
                                  ],
                                ),
                              ),
                            );
                          },
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
