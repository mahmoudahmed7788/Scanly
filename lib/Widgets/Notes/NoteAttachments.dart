import 'dart:io';

import 'package:flutter/material.dart';
import 'package:scanly/Models/Note_Model.dart';

class NoteAttachments extends StatelessWidget {
  final List<String> imagePaths;
  final List<PdfAttachment> pdfs;
  final ValueChanged<int> onRemoveImage;
  final ValueChanged<int> onRemovePdf;

  const NoteAttachments({
    super.key,
    required this.imagePaths,
    required this.pdfs,
    required this.onRemoveImage,
    required this.onRemovePdf,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (imagePaths.isEmpty && pdfs.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 22),

        Row(
          children: [
            Icon(
              Icons.attach_file,
              size: 20,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              'Attachments',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        if (imagePaths.isNotEmpty)
          SizedBox(
            height: 105,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: imagePaths.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final path = imagePaths[index];

                return Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.file(
                        File(path),
                        width: 105,
                        height: 105,
                        fit: BoxFit.cover,
                        errorBuilder:
                            (context, error, stackTrace) {
                          return Container(
                            width: 105,
                            height: 105,
                            decoration: BoxDecoration(
                              color: theme.colorScheme
                                  .surfaceContainerHighest,
                              borderRadius:
                                  BorderRadius.circular(16),
                            ),
                            child: Icon(
                              Icons.broken_image_outlined,
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.55),
                            ),
                          );
                        },
                      ),
                    ),

                    Positioned(
                      top: 6,
                      right: 6,
                      child: GestureDetector(
                        onTap: () => onRemoveImage(index),
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color:
                                Colors.black.withValues(alpha: 0.62),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 17,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

        if (pdfs.isNotEmpty)
          const SizedBox(height: 12),

        ...List.generate(
          pdfs.length,
          (index) {
            final pdf = pdfs[index];

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest
                    .withValues(alpha: 0.42),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color:
                      theme.dividerColor.withValues(alpha: 0.22),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary
                          .withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.picture_as_pdf,
                      color: theme.colorScheme.primary,
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Text(
                      pdf.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  IconButton(
                    onPressed: () => onRemovePdf(index),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}