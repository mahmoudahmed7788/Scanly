import 'package:flutter/material.dart';
import 'package:scanly/Models/Note_Model.dart';

class NoteVisualCard extends StatelessWidget {
  final NoteModel note;
  final double? width;
  final bool pinned;

  final ValueChanged<NoteModel> onShare;
  final String Function(NoteModel) previewText;

  final bool isFavorite;
  final ValueChanged<NoteModel> onToggleFavorite;

  const NoteVisualCard({
    super.key,
    required this.note,
    this.width,
    this.pinned = false,
    required this.onShare,
    required this.previewText,
    required this.isFavorite,
    required this.onToggleFavorite,
  });

  String _formatDate(DateTime date) {
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;

    final minute = date.minute.toString().padLeft(2, '0');

    final period = date.hour >= 12 ? 'PM' : 'AM';

    return '${date.day}/${date.month}/${date.year} • '
        '$hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final noteColor = Color(note.colorValue);

    final dark =
        ThemeData.estimateBrightnessForColor(noteColor) == Brightness.dark;

    final primaryText = dark ? Colors.white : const Color(0xFF24213D);

    final secondaryText = dark ? Colors.white70 : const Color(0xFF69647E);

    return Container(
      width: width,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: noteColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colors.outline.withValues(alpha: .10),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  note.title.isEmpty ? 'Untitled Note' : note.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: primaryText,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (pinned) ...[
                const SizedBox(width: 6),
                Icon(
                  Icons.push_pin_rounded,
                  size: 18,
                  color: primaryText,
                ),
              ],
              const SizedBox(width: 4),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => onToggleFavorite(note),
                  child: Padding(
                    padding: const EdgeInsets.all(5),
                    child: Icon(
                      isFavorite
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      size: 21,
                      color: isFavorite
                          ? Colors.redAccent
                          : primaryText,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Text(
              previewText(note),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: secondaryText,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.schedule_rounded,
                size: 14,
                color: secondaryText,
              ),
              const SizedBox(width: 4),
              Text(
                _formatDate(note.updatedAt),
                style: TextStyle(
                  fontSize: 11,
                  color: secondaryText,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
