import 'package:flutter/material.dart';
import 'package:scanly/Widgets/Qr/QRFavoriteItem.dart';
import 'package:scanly/Widgets/Qr/QRFavoritesEmptyState.dart';


import 'QRPreviewPage.dart';


class QRFavoritesPage extends StatelessWidget {
  final List<String> favorites;
  final ValueChanged<String> onToggleFavorite;

  const QRFavoritesPage({
    super.key,
    required this.favorites,
    required this.onToggleFavorite,
  });

  void _openPreview(
    BuildContext context,
    String value,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QRPreviewPage(
          value: value,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (favorites.isEmpty) {
      return const QRFavoritesEmptyState();
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        16,
        10,
        16,
        24,
      ),
      itemCount: favorites.length,
      separatorBuilder: (_, __) =>
          const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final value = favorites[index];

        return GestureDetector(
          onTap: () {
            _openPreview(
              context,
              value,
            );
          },
          child: QRFavoriteItem(
            value: value,
            onRemove: () {
              onToggleFavorite(value);
            },
          ),
        );
      },
    );
  }
}