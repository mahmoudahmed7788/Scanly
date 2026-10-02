import 'package:flutter/material.dart';
import 'package:scanly/Models/Note_Model.dart';
import 'package:scanly/Widgets/Notes/NoteVisualCard.dart';

class PinnedNotesList extends StatelessWidget {
  final List<NoteModel> notes;

  final String Function(NoteModel) previewText;

  final ValueChanged<NoteModel> onOpen;
  final ValueChanged<NoteModel> onShare;
  final ValueChanged<NoteModel> onToggleFavorite;

  final bool Function(NoteModel) isFavorite;

  const PinnedNotesList({
    super.key,
    required this.notes,
    required this.previewText,
    required this.onOpen,
    required this.onShare,
    required this.onToggleFavorite,
    required this.isFavorite,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return SizedBox(
      height: 170,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: notes.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final note = notes[index];

          return GestureDetector(
            onTap: () => onOpen(note),
            child: Stack(
              children: [
                NoteVisualCard(
                  note: note,
                  width: 235,
                  pinned: true,
                  previewText: previewText,
                  onShare: onShare,
                  isFavorite: isFavorite(note),
                  onToggleFavorite: (NoteModel value) {},
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => onToggleFavorite(note),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.18),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isFavorite(note)
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          color: isFavorite(note)
                              ? Colors.redAccent
                              : colors.onSurface,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
