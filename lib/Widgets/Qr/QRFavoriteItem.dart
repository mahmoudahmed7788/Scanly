import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:scanly/Pages/QR/Qr_favorites_utils.dart';


class QRFavoriteItem extends StatelessWidget {
  final String value;
  final VoidCallback onRemove;

  const QRFavoriteItem({
    super.key,
    required this.value,
    required this.onRemove,
  });

  void _copyToClipboard(BuildContext context) {
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

  void _removeFavorite(BuildContext context) {
    onRemove();

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

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final type =
        QRFavoritesUtils.getTypeLabel(value);

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {},
        child: Container(
          height: 100,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colors.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: colors.outlineVariant.withOpacity(
                0.45,
              ),
            ),
          ),
          child: Row(
            children: [
              // ==========================================
              // QR PREVIEW
              // ==========================================

              Container(
                width: 76,
                height: 76,
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color:
                        colors.outlineVariant.withOpacity(
                      0.5,
                    ),
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

              // ==========================================
              // INFO
              // ==========================================

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
                      QRFavoritesUtils
                          .shortenText(value),
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

              // ==========================================
              // ACTIONS
              // ==========================================

              PopupMenuButton<String>(
                tooltip: 'More',
                icon: Icon(
                  Icons.more_vert_rounded,
                  color: colors.onSurfaceVariant,
                ),
                onSelected: (action) {
                  if (action == 'copy') {
                    _copyToClipboard(context);
                  }

                  if (action == 'remove') {
                    _removeFavorite(context);
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
  }
}
