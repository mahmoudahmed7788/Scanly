import 'package:flutter/material.dart';

import 'package:scanly/Core/ScanlyActivityService.dart';
import 'package:scanly/Service/Ads/AdService.dart';
import 'package:scanly/Widgets/Qr/QRFavoriteItem.dart';
import 'package:scanly/Widgets/Qr/QRFavoritesEmptyState.dart';
import 'package:scanly/Pages/QR/QRPreviewPage.dart';

class QRFavoritesPage extends StatefulWidget {
  const QRFavoritesPage({
    super.key,
  });

  @override
  State<QRFavoritesPage> createState() =>
      _QRFavoritesPageState();
}

class _QRFavoritesPageState
    extends State<QRFavoritesPage> {
  @override
  void initState() {
    super.initState();

    ScanlyActivityService.version.addListener(
      _onActivityChanged,
    );
  }

  @override
  void dispose() {
    ScanlyActivityService.version.removeListener(
      _onActivityChanged,
    );

    super.dispose();
  }

  void _onActivityChanged() {
    if (!mounted) {
      return;
    }

    setState(() {});
  }

  Future<void> _openPreview(
    BuildContext context,
    String value,
  ) async {
    await AdService.showInterstitialBeforeAction();

    if (!context.mounted) {
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QRPreviewPage(
          value: value,
        ),
      ),
    );
  }

  Future<void> _removeFavorite(
    dynamic item,
  ) async {
    await ScanlyActivityService.removeFavorite(
      item,
    );
  }

  @override
  Widget build(BuildContext context) {
    final favorites =
        ScanlyActivityService.favorites
            .where(
              (item) =>
                  item.type == 'qr' &&
                  item.data != null &&
                  item.data!.isNotEmpty,
            )
            .toList();

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
      separatorBuilder: (_, __) {
        return const SizedBox(height: 10);
      },
      itemBuilder: (
        context,
        index,
      ) {
        final item = favorites[index];
        final value = item.data!;

        return GestureDetector(
          onTap: () async {
            await _openPreview(
              context,
              value,
            );
          },
          child: QRFavoriteItem(
            value: value,
            onRemove: () async {
              await _removeFavorite(
                item,
              );
            },
          ),
        );
      },
    );
  }
}
