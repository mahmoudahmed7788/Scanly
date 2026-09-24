import 'package:flutter/material.dart';

import 'PDFPageItem.dart';

class PDFPageCard extends StatelessWidget {
  final PDFPageItem page;
  final int index;
  final ColorScheme colors;
  final bool saving;

  final VoidCallback onEdit;
  final VoidCallback onRotate;
  final VoidCallback onDelete;

  const PDFPageCard({
    super.key,
    required this.page,
    required this.index,
    required this.colors,
    required this.saving,
    required this.onEdit,
    required this.onRotate,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      key: page.key,
      margin: const EdgeInsets.only(
        bottom: 16,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colors.onSurface.withValues(
            alpha: 0.08,
          ),
        ),
        boxShadow: [
          BoxShadow(
            blurRadius: 10,
            offset: const Offset(0, 3),
            color: Colors.black.withValues(
              alpha: 0.06,
            ),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Stack(
              children: [
                Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(
                    minHeight: 190,
                    maxHeight: 420,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(
                      14,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: RotatedBox(
                    quarterTurns: page.rotation ~/ 90,
                    child: Image.memory(
                      page.bytes,
                      width: double.infinity,
                      fit: BoxFit.contain,
                      errorBuilder: (
                        context,
                        error,
                        stackTrace,
                      ) {
                        return SizedBox(
                          height: 220,
                          child: Center(
                            child: Icon(
                              Icons.broken_image_outlined,
                              size: 48,
                              color: colors.error,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),

                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 11,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(
                        alpha: 0.65,
                      ),
                      borderRadius: BorderRadius.circular(
                        20,
                      ),
                    ),
                    child: Text(
                      'Page ${index + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            Row(
              children: [
                Text(
                  'Page ${index + 1}',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: colors.onSurface,
                  ),
                ),

                const Spacer(),

                IconButton(
                  tooltip: 'Edit',
                  onPressed: saving ? null : onEdit,
                  icon: const Icon(
                    Icons.edit_rounded,
                  ),
                ),

                IconButton(
                  tooltip: 'Rotate',
                  onPressed: saving ? null : onRotate,
                  icon: const Icon(
                    Icons.rotate_right_rounded,
                  ),
                ),

                IconButton(
                  tooltip: 'Delete',
                  onPressed: saving ? null : onDelete,
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}