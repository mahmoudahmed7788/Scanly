import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:scanly/QRPreviewPage.dart';

class QRRecentPage extends StatelessWidget {
  final List<String> recent;
  final List<String> favorites;
  final ValueChanged<String> onToggleFavorite;
  final ValueChanged<String> onRemove;

  const QRRecentPage({
    super.key,
    required this.recent,
    required this.favorites,
    required this.onToggleFavorite,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    if (recent.isEmpty) {
      return _EmptyState(
        icon: Icons.history_rounded,
        title: 'No Recent QR Codes',
        subtitle:
            'Scanned and generated QR Codes will appear here.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
      itemCount: recent.length,
      separatorBuilder: (_, __) =>
          const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final value = recent[index];
        final isFavorite = favorites.contains(value);

        return Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),

            // =========================
            // OPEN QR PREVIEW
            // =========================
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => QRPreviewPage(
                    value: value,
                  ),
                ),
              );
            },

            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: colors.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  // =========================
                  // QR ICON
                  // =========================
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: colors.primaryContainer,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.qr_code_2_rounded,
                      color: colors.primary,
                    ),
                  ),

                  const SizedBox(width: 12),

                  // =========================
                  // QR VALUE
                  // =========================
                  Expanded(
                    child: Text(
                      value,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.onSurface,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                  // =========================
                  // MENU
                  // =========================
                  PopupMenuButton<String>(
                    onSelected: (action) {
                      if (action == 'copy') {
                        Clipboard.setData(
                          ClipboardData(text: value),
                        );

                        ScaffoldMessenger.of(context)
                          ..hideCurrentSnackBar()
                          ..showSnackBar(
                            const SnackBar(
                              content:
                                  Text('Copied to clipboard'),
                            ),
                          );
                      }

                      if (action == 'favorite') {
                        onToggleFavorite(value);
                      }

                      if (action == 'delete') {
                        onRemove(value);
                      }
                    },

                    itemBuilder: (_) => [
                      // COPY
                      const PopupMenuItem(
                        value: 'copy',
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading:
                              Icon(Icons.copy_rounded),
                          title: Text('Copy'),
                        ),
                      ),

                      // FAVORITE
                      PopupMenuItem(
                        value: 'favorite',
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(
                            isFavorite
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                          ),
                          title: Text(
                            isFavorite
                                ? 'Remove Favorite'
                                : 'Add Favorite',
                          ),
                        ),
                      ),

                      // DELETE
                      const PopupMenuItem(
                        value: 'delete',
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading:
                              Icon(Icons.delete_outline_rounded),
                          title: Text('Remove'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// =====================================================
// EMPTY STATE
// =====================================================

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: colors.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 45,
                color: colors.primary,
              ),
            ),

            const SizedBox(height: 20),

            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: colors.onSurface,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
