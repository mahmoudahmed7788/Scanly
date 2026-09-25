import 'package:flutter/material.dart';

import 'package:scanly/Widgets/PDF/PDFPreviewActionButton.dart';

class PDFPreviewActions
    extends StatelessWidget {
  final ColorScheme colors;

  final bool editing;
  final bool sharing;
  final bool saving;

  final VoidCallback onEdit;
  final VoidCallback onShare;
  final VoidCallback onSave;

  const PDFPreviewActions({
    super.key,
    required this.colors,
    required this.editing,
    required this.sharing,
    required this.saving,
    required this.onEdit,
    required this.onShare,
    required this.onSave,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      margin:
          const EdgeInsets.fromLTRB(
        14,
        4,
        14,
        14,
      ),
      padding:
          const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius:
            BorderRadius.circular(20),
        border: Border.all(
          color:
              colors.onSurface.withValues(
            alpha: 0.08,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child:
                PDFPreviewActionButton(
              colors: colors,
              icon: Icons.edit_rounded,
              label: 'Edit',
              onPressed:
                  editing ? null : onEdit,
              outlined: true,
              loading: editing,
            ),
          ),
          const SizedBox(
            width: 8,
          ),
          Expanded(
            child:
                PDFPreviewActionButton(
              colors: colors,
              icon: Icons.share_rounded,
              label: 'Share',
              onPressed:
                  sharing ? null : onShare,
              outlined: true,
              loading: sharing,
            ),
          ),
          const SizedBox(
            width: 8,
          ),
          Expanded(
            child:
                PDFPreviewActionButton(
              colors: colors,
              icon: Icons.save_rounded,
              label: 'Save',
              onPressed:
                  saving ? null : onSave,
              outlined: false,
              loading: saving,
            ),
          ),
        ],
      ),
    );
  }
}