import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:scanly/Widgets/Qr/QRRecentUtils.dart';


class QRRecentItem extends StatelessWidget {
  final String value;
  final bool isFavorite;

  final VoidCallback onTap;
  final VoidCallback onToggleFavorite;
  final VoidCallback onRemove;

  const QRRecentItem({
    super.key,
    required this.value,
    required this.isFavorite,
    required this.onTap,
    required this.onToggleFavorite,
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
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final previewText =
        QRRecentUtils.getPreviewText(value);

    final typeLabel =
        QRRecentUtils.getTypeLabel(value);

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
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
              // QR PREVIEW
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

              // INFORMATION
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
                              const EdgeInsets.symmetric(
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

              // FAVORITE + MENU
              Column(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                children: [
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
                    onPressed:
                        onToggleFavorite,
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

                  PopupMenuButton<String>(
                    padding: EdgeInsets.zero,
                    iconSize: 22,
                    tooltip: 'More',
                    onSelected: (action) {
                      if (action == 'copy') {
                        _copyToClipboard(context);
                      }

                      if (action == 'delete') {
                        onRemove();
                      }
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem<String>(
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
                      const PopupMenuItem<String>(
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
  }
}