import 'package:flutter/material.dart';
import 'package:scanly/Core/ScanlyActivityService.dart';
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

  // ============================================================
  // OPEN PREVIEW
  // ============================================================

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

  // ============================================================
  // REMOVE FAVORITE
  // ============================================================

  Future<void> _removeFavorite(
    String id,
  ) async {
    await ScanlyActivityService.removeFavorite(
      id,
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

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
      separatorBuilder: (_, __) =>
          const SizedBox(height: 10),
      itemBuilder: (
        context,
        index,
      ) {
        final item = favorites[index];

        final value = item.data!;

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
              _removeFavorite(
                item.id,
              );
            },
          ),
        );
      },
    );
  }
}