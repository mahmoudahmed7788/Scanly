import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:scanly/Core/Scanly_Items.dart';
import 'package:scanly/core/ScanlyActivityService.dart';


class RecentPage extends StatefulWidget {
  const RecentPage({super.key});

  @override
  State<RecentPage> createState() =>
      _RecentPageState();
}

class _RecentPageState
    extends State<RecentPage> {
  @override
  void initState() {
    super.initState();

    ScanlyActivityService.version.addListener(
      _refresh,
    );
  }

  @override
  void dispose() {
    ScanlyActivityService.version.removeListener(
      _refresh,
    );

    super.dispose();
  }

  void _refresh() {
    if (mounted) {
      setState(() {});
    }
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'qr':
        return Icons.qr_code_rounded;

      case 'note':
        return Icons.edit_note_rounded;

      case 'pdf':
        return Icons.picture_as_pdf_rounded;

      case 'document':
        return Icons.document_scanner_rounded;

      case 'text':
        return Icons.text_snippet_rounded;

      default:
        return Icons.history_rounded;
    }
  }

  Future<void> _openItem(
    ScanlyItem item,
  ) async {
    await ScanlyActivityService.addRecent(
      item,
    );

    if (!mounted) return;

    if (item.route.isNotEmpty) {
      context.push(
        item.route,
        extra: item.data,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors =
        Theme.of(context).colorScheme;

    final recent =
        ScanlyActivityService.recent;

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        backgroundColor: colors.surface,
        foregroundColor: colors.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Recent',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (recent.isNotEmpty)
            IconButton(
              tooltip: 'Clear recent',
              onPressed: () async {
                await ScanlyActivityService
                    .clearRecent();
              },
              icon: const Icon(
                Icons.delete_sweep_rounded,
              ),
            ),
        ],
      ),
      body: recent.isEmpty
          ? _buildEmptyState(context)
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(
                18,
                12,
                18,
                30,
              ),
              itemCount: recent.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final item = recent[index];

                return _buildItemCard(
                  context,
                  item,
                );
              },
            ),
    );
  }

  Widget _buildItemCard(
    BuildContext context,
    ScanlyItem item,
  ) {
    final colors =
        Theme.of(context).colorScheme;

    final isFavorite =
        ScanlyActivityService.isFavorite(
      item.id,
    );

    return Dismissible(
      key: ValueKey(
        'recent_${item.id}',
      ),
      direction:
          DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding:
            const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.redAccent,
          borderRadius:
              BorderRadius.circular(18),
        ),
        child: const Icon(
          Icons.delete_outline_rounded,
          color: Colors.white,
        ),
      ),
      onDismissed: (_) async {
        await ScanlyActivityService
            .removeRecent(item.id);
      },
      child: Material(
        color: colors.surfaceContainerHighest,
        borderRadius:
            BorderRadius.circular(18),
        child: InkWell(
          borderRadius:
              BorderRadius.circular(18),
          onTap: () => _openItem(item),
          child: Padding(
            padding:
                const EdgeInsets.all(15),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: colors.secondary
                        .withValues(alpha: 0.12),
                    borderRadius:
                        BorderRadius.circular(15),
                  ),
                  child: Icon(
                    _iconForType(item.type),
                    color: colors.secondary,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        maxLines: 1,
                        overflow:
                            TextOverflow.ellipsis,
                        style: TextStyle(
                          color:
                              colors.onSurface,
                          fontSize: 16,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.subtitle,
                        maxLines: 1,
                        overflow:
                            TextOverflow.ellipsis,
                        style: TextStyle(
                          color: colors.onSurface
                              .withValues(
                            alpha: 0.55,
                          ),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () async {
                    await ScanlyActivityService
                        .toggleFavorite(item);
                  },
                  icon: Icon(
                    isFavorite
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    color: isFavorite
                        ? colors.primary
                        : colors.onSurface
                            .withValues(
                            alpha: 0.45,
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
  ) {
    final colors =
        Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: colors.secondary
                    .withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.history_rounded,
                size: 46,
                color: colors.secondary,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'No Recent Items',
              style: TextStyle(
                color: colors.onSurface,
                fontSize: 21,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Items you open or create in Scanly will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.onSurface
                    .withValues(alpha: 0.55),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}