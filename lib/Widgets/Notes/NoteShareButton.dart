import 'package:flutter/material.dart';
import 'package:scanly/Models/Note_Model.dart';
import 'package:scanly/Widgets/Notes/NoteShareSheet.dart';

class NoteShareButton extends StatelessWidget {
  final NoteModel note;

  const NoteShareButton({
    super.key,
    required this.note,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return IconButton(
      tooltip: 'Share Note',
      onPressed: () {
        NoteShareSheet.show(context, note);
      },
      icon: Icon(
        Icons.ios_share_rounded,
        color: colors.primary,
      ),
    );
  }
}