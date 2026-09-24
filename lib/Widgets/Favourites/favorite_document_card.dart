import 'package:flutter/material.dart';
import 'package:scanly/Models/DocumentModel.dart';
import 'package:scanly/Widgets/Favourites/favorites_utils.dart';

class FavoriteDocumentCard extends StatelessWidget {
  final DocumentModel document;
  final VoidCallback onOpen;
  final VoidCallback onRemove;

  const FavoriteDocumentCard({
    super.key,
    required this.document,
    required this.onOpen,
    required this.onRemove,
  });

  Widget _buildPdfIcon(
    BuildContext context,
  ) {
    final colors =
        Theme.of(context).colorScheme;

    return Container(
      width: 62,
      height: 62,
      decoration: BoxDecoration(
        color: colors.error.withValues(
          alpha: 0.10,
        ),
        borderRadius:
            BorderRadius.circular(16),
        border: Border.all(
          color: colors.error.withValues(
            alpha: 0.18,
          ),
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            Icons.picture_as_pdf_rounded,
            size: 35,
            color: colors.error,
          ),
          Positioned(
            bottom: 5,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 5,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: colors.error,
                borderRadius:
                    BorderRadius.circular(4),
              ),
              child: const Text(
                'PDF',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 7,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme =
        Theme.of(context);

    final colors =
        theme.colorScheme;

    return Container(
      margin:
          const EdgeInsets.only(
        bottom: 12,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius:
            BorderRadius.circular(20),
        border: Border.all(
          color:
              colors.outlineVariant.withValues(
            alpha: 0.35,
          ),
        ),
        boxShadow: [
          if (theme.brightness ==
              Brightness.light)
            BoxShadow(
              color:
                  colors.onSurface.withValues(
                alpha: 0.05,
              ),
              blurRadius: 12,
              offset:
                  const Offset(0, 5),
            ),
        ],
      ),
      child: InkWell(
        borderRadius:
            BorderRadius.circular(20),
        onTap: onOpen,
        child: Padding(
          padding:
              const EdgeInsets.all(14),
          child: Row(
            children: [
              _buildPdfIcon(context),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      document.title,
                      maxLines: 2,
                      overflow:
                          TextOverflow.ellipsis,
                      style: TextStyle(
                        color:
                            colors.onSurface,
                        fontSize: 16,
                        fontWeight:
                            FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 7),

                    Row(
                      children: [
                        Icon(
                          Icons.schedule_rounded,
                          size: 14,
                          color:
                              colors.onSurfaceVariant,
                        ),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            FavoritesUtils.formatDate(
                              document.date,
                            ),
                            overflow:
                                TextOverflow.ellipsis,
                            style: TextStyle(
                              color: colors
                                  .onSurfaceVariant,
                              fontSize: 12,
                              fontWeight:
                                  FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 7),

                    Container(
                      padding:
                          const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration:
                          BoxDecoration(
                        color:
                            colors.error.withValues(
                          alpha: 0.09,
                        ),
                        borderRadius:
                            BorderRadius.circular(7),
                      ),
                      child: Text(
                        'PDF',
                        style: TextStyle(
                          color:
                              colors.error,
                          fontSize: 10,
                          fontWeight:
                              FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 4),

              IconButton(
                tooltip:
                    'Remove from favorites',
                onPressed: onRemove,
                icon: Icon(
                  Icons.favorite_rounded,
                  color: colors.error,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}