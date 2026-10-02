import 'package:flutter/material.dart';

import 'package:scanly/Core/ScanlyActivityService.dart';
import 'package:scanly/Core/Scanly_Items.dart';
import 'package:scanly/Pages/QR/QRPreviewPage.dart';
import 'package:scanly/Service/Ads/AdService.dart';
import 'package:scanly/Widgets/Qr/QRRecentEmptyState.dart';
import 'package:scanly/Widgets/Qr/QRRecentItem.dart';

class QRRecentPage extends StatefulWidget {
  const QRRecentPage({
    super.key,
  });

  @override
  State<QRRecentPage> createState() => _QRRecentPageState();
}

class _QRRecentPageState extends State<QRRecentPage> {
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

  Future<void> _toggleFavorite(
    ScanlyItem item,
  ) async {
    final isFavorite = ScanlyActivityService.isFavorite(
      item.id,
    );

    if (isFavorite) {
      await ScanlyActivityService.removeFavorite(
        item,
      );
    } else {
      await ScanlyActivityService.addFavorite(
        item,
      );
    }
  }

  Future<void> _removeRecent(
    ScanlyItem item,
  ) async {
    await ScanlyActivityService.removeRecent(
      item,
    );
  }

  @override
  Widget build(BuildContext context) {
    final recent = ScanlyActivityService.recent
        .where(
          (item) =>
              item.type == 'qr' &&
              item.data != null &&
              item.data!.isNotEmpty,
        )
        .toList();

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
      separatorBuilder: (_, __) {
        return const SizedBox(height: 12);
      },
      itemBuilder: (
        context,
        index,
      ) {
        final item = recent[index];
        final value = item.data!;

        final isFavorite =
            ScanlyActivityService.isFavorite(
          item.id,
        );

        return QRRecentItem(
          value: value,
          isFavorite: isFavorite,
          onTap: () async {
            await _openPreview(
              context,
              value,
            );
          },
          onToggleFavorite: () async {
            await _toggleFavorite(
              item,
            );
          },
          onRemove: () async {
            await _removeRecent(
              item,
            );
          },
        );
      },
    );
  }
}
