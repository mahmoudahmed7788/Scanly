import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:scanly/QRPreviewPage.dart';

class QRFavoritesPage extends StatelessWidget {
  final List<String> favorites;
  final ValueChanged<String> onToggleFavorite;

  const QRFavoritesPage({
    super.key,
    required this.favorites,
    required this.onToggleFavorite,
  });

  String _getTypeLabel(String value) {
    final lower = value.toLowerCase();

    if (lower.startsWith('image:') ||
        lower.startsWith('image://') ||
        lower.startsWith('image/')) {
      return 'IMAGE';
    }

    if (lower.startsWith('video:') ||
        lower.startsWith('video://') ||
        lower.startsWith('video/')) {
      return 'VIDEO';
    }

    if (lower.startsWith('http://') ||
        lower.startsWith('https://')) {
      return 'URL';
    }

    return 'TEXT';
  }

  String _getPreviewText(String value) {
    final lower = value.toLowerCase();

    if (lower.startsWith('image:') ||
        lower.startsWith('image://') ||
        lower.startsWith('image/')) {
      return 'Image QR Code';
    }

    if (lower.startsWith('video:') ||
        lower.startsWith('video://') ||
        lower.startsWith('video/')) {
      return 'Video QR Code';
    }

    return value;
  }

  String _shortenText(String value) {
    final text = _getPreviewText(value);

    if (text.length <= 55) {
      return text;
    }

    return '${text.substring(0, 55)}...';
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    if (favorites.isEmpty) {
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
                  Icons.favorite_border_rounded,
                  size: 45,
                  color: colors.primary,
                ),
              ),

              const SizedBox(height: 20),

              Text(
                'No Favorites Yet',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: colors.onSurface,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                'Your favorite QR Codes will appear here.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colors.onSurfaceVariant,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        16,
        10,
        16,
        24,
      ),
      itemCount: favorites.length,
      separatorBuilder: (_, __) =>
          const SizedBox(height: 10),

      itemBuilder: (context, index) {
        final value = favorites[index];
        final type = _getTypeLabel(value);

        return Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(18),

          child: InkWell(
            borderRadius: BorderRadius.circular(18),

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
              height: 100,
              padding: const EdgeInsets.all(12),

              decoration: BoxDecoration(
                color: colors.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: colors.outlineVariant.withOpacity(0.45),
                ),
              ),

              child: Row(
                children: [
                  // =========================
                  // QR PREVIEW
                  // =========================
                  Container(
                    width: 76,
                    height: 76,

                    padding: const EdgeInsets.all(7),

                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color:
                            colors.outlineVariant.withOpacity(0.5),
                      ),
                    ),

                    child: ClipRRect(
                      borderRadius:
                          BorderRadius.circular(8),

                      child: QrImageView(
                        data: value,
                        version: QrVersions.auto,
                        size: 62,
                        padding: EdgeInsets.zero,
                        backgroundColor: Colors.white,
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // =========================
                  // INFO
                  // =========================
                  Expanded(
                    child: Column(
                      mainAxisAlignment:
                          MainAxisAlignment.center,
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'QR Code',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight:
                                    FontWeight.w700,
                                color: colors.onSurface,
                              ),
                            ),

                            const SizedBox(width: 8),

                            Container(
                              padding:
                                  const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    colors.primaryContainer,
                                borderRadius:
                                    BorderRadius.circular(6),
                              ),
                              child: Text(
                                type,
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight:
                                      FontWeight.bold,
                                  color: colors.primary,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 6),

                        Text(
                          _shortenText(value),
                          maxLines: 2,
                          overflow:
                              TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.25,
                            color:
                                colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 4),

                  // =========================
                  // ACTIONS
                  // =========================
                  PopupMenuButton<String>(
                    tooltip: 'More',

                    icon: Icon(
                      Icons.more_vert_rounded,
                      color:
                          colors.onSurfaceVariant,
                    ),

                    onSelected: (action) {
                      if (action == 'copy') {
                        Clipboard.setData(
                          ClipboardData(
                            text: value,
                          ),
                        );

                        ScaffoldMessenger.of(context)
                          ..hideCurrentSnackBar()
                          ..showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Copied to clipboard',
                              ),
                            ),
                          );
                      }

                      if (action == 'remove') {
                        onToggleFavorite(value);

                        ScaffoldMessenger.of(context)
                          ..hideCurrentSnackBar()
                          ..showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Removed from favorites',
                              ),
                            ),
                          );
                      }
                    },

                    itemBuilder: (_) => [
                      const PopupMenuItem<String>(
                        value: 'copy',
                        child: Row(
                          children: [
                            Icon(
                              Icons.copy_rounded,
                              size: 20,
                            ),
                            SizedBox(width: 10),
                            Text('Copy'),
                          ],
                        ),
                      ),

                      const PopupMenuItem<String>(
                        value: 'remove',
                        child: Row(
                          children: [
                            Icon(
                              Icons.favorite_rounded,
                              size: 20,
                            ),
                            SizedBox(width: 10),
                            Text('Remove Favorite'),
                          ],
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