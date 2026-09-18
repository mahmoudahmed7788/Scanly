import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:scanly/QRPreviewPage.dart';

class QRFavoritesPage extends StatelessWidget {
  final List<String> favorites;
  final ValueChanged<String> onToggleFavorite;

  const QRFavoritesPage({
    super.key,
    required this.favorites,
    required this.onToggleFavorite,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    if (favorites.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.favorite_border_rounded,
                  size: 45,
                  color: colors.primary,
                ),
              ),

              const SizedBox(height: 20),

              Text(
                'No Favorites Yet',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: colors.onSurface,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                'Your favorite QR Codes will appear here.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
      itemCount: favorites.length,
      separatorBuilder: (_, __) =>
          const SizedBox(height: 10),

      itemBuilder: (context, index) {
        final value = favorites[index];

        return Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(18),

          child: InkWell(
            borderRadius: BorderRadius.circular(18),

            // =========================
            // OPEN QR PREVIEW
            // =========================
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => QRPreviewPage(
                    value: value,
                  ),
                ),
              );
            },

            child: Container(
              padding: const EdgeInsets.all(14),

              decoration: BoxDecoration(
                color: colors.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(18),
              ),

              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,

                    decoration: BoxDecoration(
                      color: colors.primaryContainer,
                      borderRadius: BorderRadius.circular(14),
                    ),

                    child: Icon(
                      Icons.favorite_rounded,
                      color: colors.primary,
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Text(
                      value,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,

                      style: TextStyle(
                        color: colors.onSurface,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                  // =========================
                  // COPY
                  // =========================
                  IconButton(
                    tooltip: 'Copy',

                    onPressed: () {
                      Clipboard.setData(
                        ClipboardData(text: value),
                      );

                      ScaffoldMessenger.of(context)
                        ..hideCurrentSnackBar()
                        ..showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Copied to clipboard',
                            ),
                          ),
                        );
                    },

                    icon: const Icon(
                      Icons.copy_rounded,
                    ),
                  ),

                  // =========================
                  // REMOVE FAVORITE
                  // =========================
                  IconButton(
                    tooltip: 'Remove',

                    onPressed: () {
                      onToggleFavorite(value);
                    },

                    icon: const Icon(
                      Icons.favorite_rounded,
                    ),

                    color: colors.primary,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
