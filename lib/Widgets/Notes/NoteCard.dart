import 'package:flutter/material.dart';
import 'package:scanly/Models/Note_Model.dart';

class NoteCard extends StatelessWidget {
  final NoteModel note;

  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onTogglePin;
  final VoidCallback onDelete;
  final VoidCallback onShare;

  final Future<bool> Function() onSwipeDelete;

  const NoteCard({
    super.key,
    required this.note,
    required this.onTap,
    required this.onEdit,
    required this.onTogglePin,
    required this.onDelete,
    required this.onShare,
    required this.onSwipeDelete, required Future<void> Function(NoteModel note) onPin, required Future<void> Function(NoteModel note) onOpen, required String Function(NoteModel note) previewText,
  });

  String _formatDate(DateTime date) {
    final hour =
        date.hour % 12 == 0
            ? 12
            : date.hour % 12;

    final minute =
        date.minute.toString().padLeft(2, '0');

    final period =
        date.hour >= 12 ? 'PM' : 'AM';

    return '${date.day}/${date.month}/${date.year} • '
        '$hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    final colors =
        Theme.of(context).colorScheme;

    final noteColor =
        Color(note.colorValue);

    final dark =
        ThemeData.estimateBrightnessForColor(
              noteColor,
            ) ==
            Brightness.dark;

    final primaryText =
        dark
            ? Colors.white
            : const Color(0xFF24213D);

    final secondaryText =
        dark
            ? Colors.white70
            : const Color(0xFF69647E);

    return Dismissible(
      key: ValueKey(
        'note_${note.id}',
      ),

      direction:
          DismissDirection.endToStart,

      background: Container(
        margin:
            const EdgeInsets.only(
          bottom: 12,
        ),
        padding:
            const EdgeInsets.only(
          right: 20,
        ),
        alignment:
            Alignment.centerRight,
        decoration:
            BoxDecoration(
          color: colors.error,
          borderRadius:
              BorderRadius.circular(18),
        ),
        child: const Icon(
          Icons.delete_outline_rounded,
          color: Colors.white,
        ),
      ),

      confirmDismiss: (_) async {
        return await onSwipeDelete();
      },

      child: GestureDetector(
        onTap: onTap,

        child: Container(
          margin:
              const EdgeInsets.only(
            bottom: 12,
          ),
          padding:
              const EdgeInsets.all(16),

          decoration:
              BoxDecoration(
            color: noteColor,
            borderRadius:
                BorderRadius.circular(18),
            border: Border.all(
              color:
                  colors.outline.withValues(
                alpha: .08,
              ),
            ),
          ),

          child: Row(
            children: [
              // ==================================================
              // NOTE ICON
              // ==================================================

              Container(
                width: 44,
                height: 44,
                decoration:
                    BoxDecoration(
                  color: primaryText
                      .withValues(
                    alpha: .10,
                  ),
                  borderRadius:
                      BorderRadius.circular(
                    14,
                  ),
                ),
                child: Icon(
                  Icons.note_alt_outlined,
                  color: primaryText,
                  size: 23,
                ),
              ),

              const SizedBox(
                width: 13,
              ),

              // ==================================================
              // NOTE INFO
              // ==================================================

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            note.title.isEmpty
                                ? 'Untitled Note'
                                : note.title,
                            maxLines: 1,
                            overflow:
                                TextOverflow.ellipsis,
                            style:
                                TextStyle(
                              color:
                                  primaryText,
                              fontSize: 16,
                              fontWeight:
                                  FontWeight.w700,
                            ),
                          ),
                        ),

                        if (note.isPinned)
                          Padding(
                            padding:
                                const EdgeInsets
                                    .only(
                              left: 8,
                            ),
                            child: Icon(
                              Icons
                                  .push_pin_rounded,
                              size: 18,
                              color:
                                  primaryText,
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(
                      height: 5,
                    ),

                    Text(
                      'Tap to open this note',
                      maxLines: 2,
                      overflow:
                          TextOverflow.ellipsis,
                      style: TextStyle(
                        color: secondaryText,
                        fontSize: 12,
                      ),
                    ),

                    const SizedBox(
                      height: 9,
                    ),

                    // ==================================================
                    // META
                    // ==================================================

                    Row(
                      children: [
                        Icon(
                          Icons
                              .schedule_rounded,
                          size: 14,
                          color:
                              secondaryText,
                        ),

                        const SizedBox(
                          width: 4,
                        ),

                        Text(
                          _formatDate(
                            note.updatedAt,
                          ),
                          style:
                              TextStyle(
                            fontSize: 11,
                            color:
                                secondaryText,
                            fontWeight:
                                FontWeight.w500,
                          ),
                        ),

                        if (note.imagePaths
                            .isNotEmpty) ...[
                          const SizedBox(
                            width: 10,
                          ),
                          Icon(
                            Icons
                                .image_outlined,
                            size: 16,
                            color:
                                secondaryText,
                          ),
                        ],

                        if (note.pdfs
                            .isNotEmpty) ...[
                          const SizedBox(
                            width: 8,
                          ),
                          Icon(
                            Icons
                                .picture_as_pdf_outlined,
                            size: 16,
                            color:
                                secondaryText,
                          ),
                        ],

                        if (note.pages.length >
                            1) ...[
                          const SizedBox(
                            width: 8,
                          ),
                          Text(
                            '${note.pages.length} pages',
                            style:
                                TextStyle(
                              fontSize: 11,
                              color:
                                  secondaryText,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // ==================================================
              // MENU
              // ==================================================

              PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_vert_rounded,
                  color: primaryText,
                ),

                onSelected: (value) {
                  switch (value) {
                    case 'edit':
                      onEdit();
                      break;

                    case 'pin':
                      onTogglePin();
                      break;

                    case 'share':
                      onShare();
                      break;

                    case 'delete':
                      onDelete();
                      break;
                  }
                },

                itemBuilder: (_) => [
                  // ------------------------------------------------
                  // EDIT
                  // ------------------------------------------------

                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(
                          Icons.edit_outlined,
                          size: 20,
                        ),
                        SizedBox(
                          width: 8,
                        ),
                        Text('Edit'),
                      ],
                    ),
                  ),

                  // ------------------------------------------------
                  // PIN
                  // ------------------------------------------------

                  PopupMenuItem(
                    value: 'pin',
                    child: Row(
                      children: [
                        Icon(
                          note.isPinned
                              ? Icons
                                  .push_pin_outlined
                              : Icons
                                  .push_pin_rounded,
                          size: 20,
                        ),
                        const SizedBox(
                          width: 8,
                        ),
                        Text(
                          note.isPinned
                              ? 'Unpin'
                              : 'Pin',
                        ),
                      ],
                    ),
                  ),

                  // ------------------------------------------------
                  // SHARE
                  // ------------------------------------------------

                  const PopupMenuItem(
                    value: 'share',
                    child: Row(
                      children: [
                        Icon(
                          Icons
                              .ios_share_rounded,
                          size: 20,
                        ),
                        SizedBox(
                          width: 8,
                        ),
                        Text('Share'),
                      ],
                    ),
                  ),

                  // ------------------------------------------------
                  // DELETE
                  // ------------------------------------------------

                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(
                          Icons
                              .delete_outline_rounded,
                          size: 20,
                          color:
                              colors.error,
                        ),
                        const SizedBox(
                          width: 8,
                        ),
                        Text(
                          'Delete',
                          style:
                              TextStyle(
                            color:
                                colors.error,
                          ),
                        ),
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