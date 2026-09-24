import 'package:flutter/material.dart';
import 'package:scanly/Models/DocumentModel.dart';

class DocumentCard extends StatelessWidget {
  final DocumentModel document;
  final VoidCallback onTap;
  final VoidCallback onToggleFavorite;
  final VoidCallback onOpen;
  final VoidCallback onDelete;

  const DocumentCard({
    super.key,
    required this.document,
    required this.onTap,
    required this.onToggleFavorite,
    required this.onOpen,
    required this.onDelete,
  });

  String _formatDate(String value) {
    final date = DateTime.tryParse(value);

    if (date == null) {
      return 'Unknown date';
    }

    final day =
        date.day.toString().padLeft(2, '0');

    final month =
        date.month.toString().padLeft(2, '0');

    final year =
        date.year.toString();

    final hour =
        date.hour.toString().padLeft(2, '0');

    final minute =
        date.minute.toString().padLeft(2, '0');

    return '$day/$month/$year • $hour:$minute';
  }

  String _getDocumentType(
    DocumentModel document,
  ) {
    final type = document.type.trim();

    if (type.isEmpty) {
      return 'PDF';
    }

    return type.toUpperCase();
  }

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
          const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius:
            BorderRadius.circular(20),
        border: Border.all(
          color: colors.outlineVariant
              .withValues(alpha: 0.35),
        ),
        boxShadow: [
          if (theme.brightness ==
              Brightness.light)
            BoxShadow(
              color: colors.onSurface
                  .withValues(alpha: 0.05),
              blurRadius: 12,
              offset:
                  const Offset(0, 5),
            ),
        ],
      ),
      child: InkWell(
        borderRadius:
            BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding:
              const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment:
                CrossAxisAlignment.center,
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
                        fontSize: 16,
                        fontWeight:
                            FontWeight.w700,
                        color:
                            colors.onSurface,
                      ),
                    ),

                    const SizedBox(height: 7),

                    Row(
                      children: [
                        Icon(
                          Icons
                              .schedule_rounded,
                          size: 14,
                          color:
                              colors.onSurfaceVariant,
                        ),
                        const SizedBox(
                          width: 5,
                        ),
                        Flexible(
                          child: Text(
                            _formatDate(
                              document.date,
                            ),
                            overflow:
                                TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: colors
                                  .onSurfaceVariant,
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
                          const EdgeInsets
                              .symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration:
                          BoxDecoration(
                        color: colors.error
                            .withValues(
                          alpha: 0.09,
                        ),
                        borderRadius:
                            BorderRadius
                                .circular(7),
                      ),
                      child: Text(
                        _getDocumentType(
                          document,
                        ),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight:
                              FontWeight.w800,
                          letterSpacing: 0.5,
                          color:
                              colors.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 4),

              IconButton(
                tooltip:
                    document.isFavorite
                        ? 'Remove from favorites'
                        : 'Add to favorites',
                onPressed:
                    onToggleFavorite,
                icon: Icon(
                  document.isFavorite
                      ? Icons.favorite_rounded
                      : Icons
                          .favorite_border_rounded,
                  color:
                      document.isFavorite
                          ? colors.error
                          : colors
                              .onSurfaceVariant,
                ),
              ),

              PopupMenuButton<String>(
                tooltip:
                    'More options',
                icon: Icon(
                  Icons.more_vert_rounded,
                  color:
                      colors.onSurfaceVariant,
                ),
                onSelected: (value) {
                  if (value == 'open') {
                    onOpen();
                  }

                  if (value == 'delete') {
                    onDelete();
                  }
                },
                itemBuilder: (context) {
                  return const [
                    PopupMenuItem(
                      value: 'open',
                      child: Row(
                        children: [
                          Icon(
                            Icons
                                .open_in_new_rounded,
                          ),
                          SizedBox(
                            width: 10,
                          ),
                          Text(
                            'Open PDF',
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(
                            Icons
                                .delete_outline_rounded,
                            color:
                                Colors.red,
                          ),
                          SizedBox(
                            width: 10,
                          ),
                          Text(
                            'Delete',
                          ),
                        ],
                      ),
                    ),
                  ];
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}