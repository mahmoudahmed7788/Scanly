import 'package:flutter/material.dart';

class PDFEditEmptyState extends StatelessWidget {
  final ColorScheme colors;
  final bool saving;
  final VoidCallback onAddImages;

  const PDFEditEmptyState({
    super.key,
    required this.colors,
    required this.saving,
    required this.onAddImages,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.picture_as_pdf_outlined,
              size: 64,
              color: colors.primary,
            ),

            const SizedBox(height: 16),

            Text(
              'No pages available',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: colors.onSurface,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              'Add images to start editing this PDF.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.onSurface.withValues(
                  alpha: 0.60,
                ),
              ),
            ),

            const SizedBox(height: 22),

            FilledButton.icon(
              onPressed: saving ? null : onAddImages,
              icon: const Icon(
                Icons.add_photo_alternate_rounded,
              ),
              label: const Text(
                'Add Images',
              ),
            ),
          ],
        ),
      ),
    );
  }
}