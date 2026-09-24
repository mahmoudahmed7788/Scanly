import 'package:flutter/material.dart';

class QRPreviewActions extends StatelessWidget {
  final bool isFavorite;
  final bool isSaving;
  final bool isSharing;

  final VoidCallback onToggleFavorite;
  final VoidCallback onSave;
  final VoidCallback onShare;

  const QRPreviewActions({
    super.key,
    required this.isFavorite,
    required this.isSaving,
    required this.isSharing,
    required this.onToggleFavorite,
    required this.onSave,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 52,
          child: OutlinedButton.icon(
            onPressed: onToggleFavorite,
            icon: Icon(
              isFavorite
                  ? Icons.favorite_rounded
                  : Icons.favorite_border_rounded,
              color: isFavorite
                  ? Colors.redAccent
                  : null,
            ),
            label: Text(
              isFavorite
                  ? 'Remove from Favorites'
                  : 'Add to Favorites',
            ),
          ),
        ),

        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 54,
                child: OutlinedButton.icon(
                  onPressed: isSaving || isSharing
                      ? null
                      : onSave,
                  icon: isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(
                          Icons.download_rounded,
                        ),
                  label: Text(
                    isSaving
                        ? 'Saving...'
                        : 'Save',
                  ),
                ),
              ),
            ),

            const SizedBox(width: 10),

            Expanded(
              child: SizedBox(
                height: 54,
                child: FilledButton.icon(
                  onPressed: isSaving || isSharing
                      ? null
                      : onShare,
                  icon: isSharing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(
                          Icons.share_rounded,
                        ),
                  label: Text(
                    isSharing
                        ? 'Sharing...'
                        : 'Share',
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        Text(
          'Share your QR Code with your favorite apps',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: colors.onSurfaceVariant,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}