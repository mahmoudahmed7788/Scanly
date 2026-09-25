import 'package:flutter/material.dart';
import 'package:scanly/Models/Note_Model.dart';
import 'package:scanly/Widgets/Notes/NoteVisualCard.dart';

class PinnedNotesList extends StatelessWidget {
  final List<NoteModel> notes;

  final String Function(NoteModel)
      previewText;

  final ValueChanged<NoteModel> onOpen;
  final ValueChanged<NoteModel> onShare;

  const PinnedNotesList({
    super.key,
    required this.notes,
    required this.previewText,
    required this.onOpen,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 170,
      child: ListView.separated(
        scrollDirection:
            Axis.horizontal,

        itemCount: notes.length,

        separatorBuilder: (_, __) =>
            const SizedBox(width: 12),

        itemBuilder:
            (context, index) {
          final note = notes[index];

          return GestureDetector(
            onTap: () =>
                onOpen(note),

            child: NoteVisualCard(
              note: note,
              width: 235,
              pinned: true,
              previewText:
                  previewText,
              onShare: onShare,
            ),
          );
        },
      ),
    );
  }
}