import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
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

  String _getPreviewText(String value) {
    if (value.startsWith('scanly://file?type=image')) {
      return 'Image QR Code';
    }

    if (value.startsWith('scanly://file?type=video')) {
      return 'Video QR Code';
    }

    return value;
  }

  String _getTypeLabel(String value) {
    if (value.startsWith('scanly://file?type=image')) {
      return 'IMAGE';
    }

    if (value.startsWith('scanly://file?type=video')) {
      return 'VIDEO';
    }

    if (value.startsWith('http://') ||
        value.startsWith('https://')) {
      return 'URL';
    }

    return 'TEXT';
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    if (recent.isEmpty) {
      return const _EmptyState(
        icon: Icons.history_rounded,
        title: 'No Recent QR Codes',
        subtitle:
            'Scanned and generated QR Codes will appear here.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        16,
        10,
        16,
        24,
      ),
      itemCount: recent.length,
      separatorBuilder: (_, __) =>
          const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final value = recent[index];

        final isFavorite = favorites.contains(value);

        final previewText = _getPreviewText(value);

        final typeLabel = _getTypeLabel(value);

        return Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
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
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: colors.surfaceContainerHighest,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(
                      alpha: 0.035,
                    ),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment:
                    CrossAxisAlignment.center,
                children: [
                  // =====================================
                  // QR PREVIEW
                  // =====================================
                  Container(
                    width: 68,
                    height: 68,
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          BorderRadius.circular(16),
                      border: Border.all(
                        color:
                            colors.surfaceContainerHighest,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius:
                          BorderRadius.circular(9),
                      child: QrImageView(
                        data: value,
                        version: QrVersions.auto,
                        size: 54,
                        backgroundColor: Colors.white,
                        errorCorrectionLevel:
                            QrErrorCorrectLevel.M,
                      ),
                    ),
                  ),

                  const SizedBox(width: 13),

                  // =====================================
                  // INFORMATION
                  // =====================================
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                'QR Code',
                                maxLines: 1,
                                overflow:
                                    TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight:
                                      FontWeight.w700,
                                  color:
                                      colors.onSurface,
                                ),
                              ),
                            ),

                            const SizedBox(width: 7),

                            Container(
                              padding:
                                  const EdgeInsets
                                      .symmetric(
                                horizontal: 7,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: colors.primary
                                    .withValues(
                                  alpha: 0.10,
                                ),
                                borderRadius:
                                    BorderRadius.circular(7),
                              ),
                              child: Text(
                                typeLabel,
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight:
                                      FontWeight.w800,
                                  letterSpacing: 0.4,
                                  color:
                                      colors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 6),

                        Text(
                          previewText,
                          maxLines: 2,
                          overflow:
                              TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.25,
                            color:
                                colors.onSurfaceVariant,
                          ),
                        ),

                        const SizedBox(height: 7),

                        Row(
                          children: [
                            Icon(
                              Icons.qr_code_2_rounded,
                              size: 14,
                              color: colors
                                  .onSurfaceVariant
                                  .withValues(
                                alpha: 0.75,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'QR Code',
                              style: TextStyle(
                                fontSize: 11,
                                color: colors
                                    .onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 4),

                  // =====================================
                  // FAVORITE BUTTON + MENU
                  // =====================================
                  Column(
                    mainAxisAlignment:
                        MainAxisAlignment.center,
                    children: [
                      // ===================================
                      // ❤️ FAVORITE BUTTON
                      // ===================================
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints:
                            const BoxConstraints(
                          minWidth: 40,
                          minHeight: 40,
                        ),
                        tooltip: isFavorite
                            ? 'Remove Favorite'
                            : 'Add Favorite',
                        onPressed: () {
                          onToggleFavorite(value);
                        },
                        icon: Icon(
                          isFavorite
                              ? Icons.favorite_rounded
                              : Icons
                                  .favorite_border_rounded,
                          size: 21,
                          color: isFavorite
                              ? Colors.redAccent
                              : colors
                                  .onSurfaceVariant,
                        ),
                      ),

                      const SizedBox(height: 4),

                      // ===================================
                      // MORE MENU
                      // ===================================
                      PopupMenuButton<String>(
                        padding: EdgeInsets.zero,
                        iconSize: 22,
                        tooltip: 'More',
                        onSelected: (action) {
                          if (action == 'copy') {
                            Clipboard.setData(
                              ClipboardData(
                                text: value,
                              ),
                            );

                            ScaffoldMessenger.of(
                              context,
                            ).hideCurrentSnackBar();

                            ScaffoldMessenger.of(
                              context,
                            ).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Copied to clipboard',
                                ),
                                behavior:
                                    SnackBarBehavior
                                        .floating,
                              ),
                            );
                          }

                          if (action == 'delete') {
                            onRemove(value);
                          }
                        },
                        itemBuilder: (_) => [
                          const PopupMenuItem(
                            value: 'copy',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.copy_rounded,
                                ),
                                SizedBox(width: 12),
                                Text('Copy'),
                              ],
                            ),
                          ),

                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(
                                  Icons
                                      .delete_outline_rounded,
                                ),
                                SizedBox(width: 12),
                                Text('Remove'),
                              ],
                            ),
                          ),
                        ],
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
    final colors =
        Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
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