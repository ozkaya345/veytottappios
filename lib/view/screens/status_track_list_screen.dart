import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/navigation/app_routes.dart';
import '../../data/services/status_table_link_service.dart';

class StatusTrackListScreen extends StatefulWidget {
  const StatusTrackListScreen({super.key});

  @override
  State<StatusTrackListScreen> createState() => _StatusTrackListScreenState();
}

class _StatusTrackListScreenState extends State<StatusTrackListScreen> {
  Future<Map<String, Map<String, dynamic>>>? _tablesFuture;
  String _tablesFutureKey = '';

  Future<Map<String, Map<String, dynamic>>> _fetchTablesByIds(
    List<String> tableIds,
  ) async {
    final ids = tableIds
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList(growable: false);

    if (ids.isEmpty) return <String, Map<String, dynamic>>{};

    // Firestore whereIn limiti: 10 öğe.
    const batchSize = 10;
    final out = <String, Map<String, dynamic>>{};
    for (int i = 0; i < ids.length; i += batchSize) {
      final chunk = ids.sublist(
        i,
        (i + batchSize > ids.length) ? ids.length : i + batchSize,
      );
      final snap = await FirebaseFirestore.instance
          .collection('status_tables')
          .where(FieldPath.documentId, whereIn: chunk)
          .get();
      for (final d in snap.docs) {
        out[d.id] = d.data();
      }
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Trans Takip'),
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
                    'Kartlar',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: StatusTableLinkService.watchMyLinks(),
                      builder: (context, snapshot) {
                        final links = snapshot.data?.docs ?? const [];
                        if (links.isEmpty) {
                          return const Center(
                            child: Text(
                              'Henüz kart yok',
                              style: TextStyle(color: Colors.white70),
                            ),
                          );
                        }

                        final idsInOrder = links
                            .map(
                              (d) => (d.data()['tableId'] as String?)?.trim(),
                            )
                            .whereType<String>()
                            .where((e) => e.isNotEmpty)
                            .toList(growable: false);

                        final uniqueIds = idsInOrder.toSet().toList(
                          growable: false,
                        );
                        final sortedIds = [...uniqueIds]..sort();
                        final key = sortedIds.join('|');

                        if (key != _tablesFutureKey) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (!mounted) return;
                            setState(() {
                              _tablesFutureKey = key;
                              _tablesFuture = _fetchTablesByIds(sortedIds);
                            });
                          });
                        }

                        return FutureBuilder<Map<String, Map<String, dynamic>>>(
                          future: _tablesFuture ?? _fetchTablesByIds(sortedIds),
                          builder: (context, tablesSnap) {
                            final tableMap =
                                tablesSnap.data ??
                                const <String, Map<String, dynamic>>{};

                            return ListView.separated(
                              itemCount: links.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 12),
                              itemBuilder: (ctx, idx) {
                                final link = links[idx].data();
                                final tableId = (link['tableId'] as String?)
                                    ?.trim();
                                final code = (link['code'] as String?)?.trim();
                                if (tableId == null || tableId.isEmpty) {
                                  return const SizedBox.shrink();
                                }

                                final table = tableMap[tableId];
                                final title = (table?['title'] as String?)
                                    ?.trim();
                                final shownCode =
                                    (table?['code'] as String?)?.trim() ??
                                    code ??
                                    tableId;

                                final shownTitle =
                                    (title == null || title.isEmpty)
                                    ? 'Başlıksız'
                                    : title;

                                return InkWell(
                                  borderRadius: BorderRadius.circular(16),
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                shownTitle,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: theme
                                                    .textTheme
                                                    .titleMedium
                                                    ?.copyWith(
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.w800,
                                                    ),
                                              ),
                                            ),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                    vertical: 6,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: Colors.black.withValues(
                                                  alpha: 0.30,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                                border: Border.all(
                                                  color: Colors.white24,
                                                ),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text(
                                                    'Kod: $shownCode',
                                                    style: const TextStyle(
                                                      color: Colors.white70,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 6),
                                                  InkWell(
                                                    onTap: () {
                                                      Clipboard.setData(
                                                        ClipboardData(
                                                          text: shownCode,
                                                        ),
                                                      );
                                                      ScaffoldMessenger.of(
                                                        context,
                                                      ).showSnackBar(
                                                        const SnackBar(
                                                          content: Text(
                                                            'Kod kopyalandı',
                                                          ),
                                                        ),
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
                                                  'tableId': tableId,
                                                  'readOnly': true,
                                                },
                                              );
                                            },
                                            icon: const Icon(Icons.visibility),
                                            label: const Text('Görüntüle'),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
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
