import 'package:flutter/material.dart';

import 'package:scanly/Core/ScanlyActivityService.dart';
import 'package:scanly/Core/Scanly_Items.dart';

import 'package:scanly/Pages/QR/QRFavoritesPage.dart';
import 'package:scanly/Pages/QR/QRGeneratorUtils.dart';
import 'package:scanly/Pages/QR/QR_Generator_Page.dart';
import 'package:scanly/Pages/QR/QR_Recent_Page.dart';
import 'package:scanly/Pages/QR/QR_Scanner_Page.dart';
import 'package:scanly/Service/Ads/AdService.dart';

enum QRSection {
  scan,
  generate,
  recent,
  favorites,
}

class QRToolsPage extends StatefulWidget {
  const QRToolsPage({
    super.key,
  });

  @override
  State<QRToolsPage> createState() => _QRToolsPageState();
}

class _QRToolsPageState extends State<QRToolsPage> {
  QRSection _section = QRSection.scan;

  bool _isLoading = true;

  static const Color purple = Color(0xFF7C3AED);
  static const Color blue = Color(0xFF2563EB);

  @override
  void initState() {
    super.initState();

    ScanlyActivityService.version.addListener(
      _onActivityChanged,
    );

    _loadData();
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

  ScanlyItem _createQRItem(
    String value,
  ) {
    String type = 'text';

    if (value.startsWith(
      'scanly://file?type=image',
    )) {
      type = 'image';
    } else if (value.startsWith(
      'scanly://file?type=video',
    )) {
      type = 'video';
    }

    return ScanlyItem(
      id: QRGeneratorUtils.itemId(
        value,
      ),
      title: 'QR Code',
      subtitle: QRGeneratorUtils.getSubtitle(
        value: value,
        type: type,
      ),
      type: 'qr',
      route: '/qr-tools',
      data: value,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );
  }

  Future<void> _loadData() async {
    try {
      await ScanlyActivityService.init();

      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      debugPrint(
        'QR TOOLS LOAD ERROR: $e',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _addToRecent(
    String value,
  ) async {
    if (value.trim().isEmpty) {
      return;
    }

    final item = _createQRItem(
      value,
    );

    await ScanlyActivityService.addRecent(
      item,
    );

    await AdService.showInterstitial();
  }

  Future<void> _removeRecent(
    String value,
  ) async {
    if (value.trim().isEmpty) {
      return;
    }

    final item = _createQRItem(
      value,
    );

    await ScanlyActivityService.removeRecent(
      item,
    );

    if (mounted) {
      _showMessage(
        'Removed from Recent and moved to Trash.',
      );
    }
  }

  Future<void> _toggleFavorite(
    String value,
  ) async {
    if (value.trim().isEmpty) {
      return;
    }

    final item = _createQRItem(
      value,
    );

    final isFavorite =
        ScanlyActivityService.isFavorite(
      item.id,
    );

    if (isFavorite) {
      await ScanlyActivityService.removeFavorite(
        item,
      );

      if (mounted) {
        _showMessage(
          'Removed from Favorites and moved to Trash.',
        );
      }
    } else {
      await ScanlyActivityService.addFavorite(
        item,
      );
    }
  }

  bool _isFavorite(
    String value,
  ) {
    return ScanlyActivityService.isFavorite(
      _createQRItem(value).id,
    );
  }

  List<ScanlyItem> get _qrFavorites {
    return ScanlyActivityService.favorites
        .where(
          (item) =>
              item.type == 'qr' &&
              item.data != null &&
              item.data!.isNotEmpty,
        )
        .toList();
  }

  Future<void> _clearFavorites() async {
    if (_qrFavorites.isEmpty) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Clear QR Favorites?',
          ),
          content: const Text(
            'QR Favorites will be moved to Trash for 30 days.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  false,
                );
              },
              child: const Text(
                'Cancel',
              ),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  true,
                );
              },
              child: const Text(
                'Move to Trash',
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    await ScanlyActivityService.clearQrFavorites();

    if (mounted) {
      _showMessage(
        'QR Favorites moved to Trash.',
      );
    }
  }

  void _showMessage(
    String message,
  ) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
        .hideCurrentSnackBar();

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  Widget _buildCurrentSection() {
    switch (_section) {
      case QRSection.scan:
        return QRScannerPage(
          onScan: _addToRecent,
          isFavorite: _isFavorite,
          onToggleFavorite: _toggleFavorite,
        );

      case QRSection.generate:
        return QRGeneratorPage(
          onGenerated: _addToRecent,
          isFavorite: _isFavorite,
          onToggleFavorite: _toggleFavorite,
        );

      case QRSection.recent:
        return const QRRecentPage();

      case QRSection.favorites:
        return const QRFavoritesPage();
    }
  }

  Widget _buildTopNavigation() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        16,
        12,
        16,
        8,
      ),
      child: Row(
        children: [
          Expanded(
            child: _topButton(
              title: 'Scan',
              icon: Icons.qr_code_scanner_rounded,
              selected: _section == QRSection.scan,
              onTap: () {
                setState(() {
                  _section = QRSection.scan;
                });
              },
            ),
          ),
          const SizedBox(
            width: 8,
          ),
          Expanded(
            child: _topButton(
              title: 'Generate',
              icon: Icons.qr_code_rounded,
              selected: _section == QRSection.generate,
              onTap: () {
                setState(() {
                  _section = QRSection.generate;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _topButton({
    required String title,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(
        14,
      ),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(
          milliseconds: 180,
        ),
        padding: const EdgeInsets.symmetric(
          vertical: 13,
        ),
        decoration: BoxDecoration(
          color: selected
              ? purple
              : Colors.transparent,
          borderRadius: BorderRadius.circular(
            14,
          ),
          border: Border.all(
            color: selected
                ? purple
                : Theme.of(context).dividerColor,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20,
              color: selected
                  ? Colors.white
                  : Theme.of(context).iconTheme.color,
            ),
            const SizedBox(
              width: 8,
            ),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: selected
                    ? Colors.white
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          16,
          8,
          16,
          12,
        ),
        child: Row(
          children: [
            Expanded(
              child: _bottomButton(
                title: 'Recent',
                icon: Icons.history_rounded,
                selected: _section == QRSection.recent,
                onTap: () {
                  setState(() {
                    _section = QRSection.recent;
                  });
                },
              ),
            ),
            const SizedBox(
              width: 10,
            ),
            Expanded(
              child: _bottomButton(
                title: 'Favorites',
                icon: Icons.favorite_rounded,
                selected:
                    _section == QRSection.favorites,
                onTap: () {
                  setState(() {
                    _section = QRSection.favorites;
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bottomButton({
    required String title,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(
        16,
      ),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: 12,
        ),
        decoration: BoxDecoration(
          color: selected
              ? blue.withOpacity(0.10)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(
            16,
          ),
          border: Border.all(
            color: selected
                ? blue
                : Theme.of(context).dividerColor,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20,
              color: selected
                  ? blue
                  : Theme.of(context).iconTheme.color,
            ),
            const SizedBox(
              width: 8,
            ),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: selected
                    ? blue
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'QR Tools',
        ),
        actions: [
          if (_section == QRSection.favorites &&
              _qrFavorites.isNotEmpty)
            IconButton(
              tooltip: 'Clear QR Favorites',
              onPressed: _clearFavorites,
              icon: const Icon(
                Icons.delete_sweep_rounded,
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : Column(
              children: [
                if (_section == QRSection.scan ||
                    _section == QRSection.generate)
                  _buildTopNavigation(),
                Expanded(
                  child: _buildCurrentSection(),
                ),
              ],
            ),
      bottomNavigationBar:
          _buildBottomNavigation(),
    );
  }
}
