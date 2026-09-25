import 'package:flutter/material.dart';

import 'package:scanly/Core/ScanlyActivityService.dart';
import 'package:scanly/Core/Scanly_Items.dart';
import 'package:scanly/Pages/QR/QRPreviewPage.dart';
import 'package:scanly/Widgets/Qr/QRRecentEmptyState.dart';
import 'package:scanly/Widgets/Qr/QRRecentItem.dart';

class QRRecentPage extends StatefulWidget {
  const QRRecentPage({
    super.key,
  });

  @override
  State<QRRecentPage> createState() =>
      _QRRecentPageState();
}

class _QRRecentPageState
    extends State<QRRecentPage> {

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    ScanlyActivityService.version.addListener(
      _onActivityChanged,
    );
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    ScanlyActivityService.version.removeListener(
      _onActivityChanged,
    );

    super.dispose();
  }

  // ============================================================
  // ACTIVITY CHANGE
  // ============================================================

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
  // TOGGLE FAVORITE
  // ============================================================

  Future<void> _toggleFavorite(
    String id,
  ) async {
    final recentItems =
        ScanlyActivityService.recent;

    ScanlyItem? targetItem;

    for (final item in recentItems) {
      if (item.id == id) {
        targetItem = item;
        break;
      }
    }

    if (targetItem == null) {
      return;
    }

    /*
     * IMPORTANT:
     *
     * We use ScanlyActivityService here.
     *
     * This means the favorite is NOT stored separately
     * inside QRRecentPage.
     *
     * The same favorite will therefore be available in:
     *
     * - Main Favorites
     * - QR Favorites
     * - Home Favorites
     * - Any other page using ScanlyActivityService
     */
    await ScanlyActivityService.toggleFavorite(
      targetItem,
    );
  }

  // ============================================================
  // REMOVE FROM RECENT
  // ============================================================

  Future<void> _removeRecent(
    String id,
  ) async {
    await ScanlyActivityService.removeRecent(
      id,
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final recent =
        ScanlyActivityService.recent
            .where(
              (item) =>
                  item.type == 'qr' &&
                  item.data != null &&
                  item.data!.isNotEmpty,
            )
            .toList();

    // ============================================================
    // EMPTY STATE
    // ============================================================

    if (recent.isEmpty) {
      return const QRRecentEmptyState(
        icon: Icons.history_rounded,
        title: 'No Recent QR Codes',
        subtitle:
            'Scanned and generated QR Codes will appear here.',
      );
    }

    // ============================================================
    // RECENT LIST
    // ============================================================

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
      itemBuilder: (
        context,
        index,
      ) {
        final item = recent[index];

        final value = item.data!;

        /*
         * IMPORTANT:
         *
         * This is read from the SAME global favorites list
         * used by the rest of Scanly.
         *
         * So the heart always reflects the real global state.
         */
        final isFavorite =
            ScanlyActivityService.isFavorite(
          item.id,
        );

        return QRRecentItem(
          value: value,
          isFavorite: isFavorite,

          // ======================================================
          // OPEN
          // ======================================================

          onTap: () {
            _openPreview(
              context,
              value,
            );
          },

          // ======================================================
          // FAVORITE
          // ======================================================

          onToggleFavorite: () async {
            await _toggleFavorite(
              item.id,
            );
          },

          // ======================================================
          // REMOVE RECENT
          // ======================================================

          onRemove: () async {
            await _removeRecent(
              item.id,
            );
          },
        );
      },
    );
  }
}