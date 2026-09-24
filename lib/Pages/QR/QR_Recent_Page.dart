import 'package:flutter/material.dart';
import 'package:scanly/Pages/QR/QRPreviewPage.dart';
import 'package:scanly/Widgets/Qr/QRRecentEmptyState.dart';
import 'package:scanly/Widgets/Qr/QRRecentItem.dart';

class QRRecentPage extends StatelessWidget {
  final List<String> recent;
  final List<String> favorites;
  final ValueChanged<String> onToggleFavorite;
  final ValueChanged<String> onRemove;

  const QRRecentPage({
    super.key,
    required this.recent,
    required this.favorites,
    required this.onToggleFavorite,
    required this.onRemove,
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
    if (recent.isEmpty) {
      return const QRRecentEmptyState(
        icon: Icons.history_rounded,
        title: 'No Recent QR Codes',
        subtitle:
            'Scanned and generated QR Codes will appear here.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        16,
        10,
        16,
        24,
      ),
      itemCount: recent.length,
      separatorBuilder: (_, __) =>
          const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final value = recent[index];

        final isFavorite =
            favorites.contains(value);

        return QRRecentItem(
          value: value,
          isFavorite: isFavorite,
          onTap: () {
            _openPreview(
              context,
              value,
            );
          },
          onToggleFavorite: () {
            onToggleFavorite(value);
          },
          onRemove: () {
            onRemove(value);
          },
        );
      },
    );
  }
}