import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:scanly/QR_Favourite_Page.dart';
import 'package:scanly/ScanlyActivityService.dart';
import 'package:scanly/Scanly_Items.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'QR_Scanner_Page.dart';
import 'QR_Generator_Page.dart';
import 'QR_Recent_Page.dart';

enum QRSection {
  scan,
  generate,
  recent,
  favorites,
}

class QRToolsPage extends StatefulWidget {
  const QRToolsPage({super.key});

  @override
  State<QRToolsPage> createState() => _QRToolsPageState();
}

class _QRToolsPageState extends State<QRToolsPage> {
  QRSection _section = QRSection.scan;

  List<String> _recent = [];
  List<String> _favorites = [];

  bool _isLoading = true;

  static const String _recentKey = 'qr_recent';
  static const String _favoritesKey = 'qr_favorites';

  static const Color purple = Color(0xFF7C3AED);
  static const Color blue = Color(0xFF2563EB);

  @override
  void initState() {
    super.initState();

    ScanlyActivityService.version.addListener(
      _syncWithGlobalFavorites,
    );

    _loadData();
  }

  @override
  void dispose() {
    ScanlyActivityService.version.removeListener(
      _syncWithGlobalFavorites,
    );

    super.dispose();
  }

  // =====================================================
  // CREATE GLOBAL QR ITEM
  // =====================================================

  ScanlyItem _createQRItem(String value) {
    String subtitle = value;

    if (value.length > 45) {
      subtitle = '${value.substring(0, 45)}...';
    }

    if (value.startsWith(
      'scanly://file?type=image',
    )) {
      subtitle = 'Image QR Code';
    } else if (value.startsWith(
      'scanly://file?type=video',
    )) {
      subtitle = 'Video QR Code';
    }

    return ScanlyItem(
      id: 'qr_${base64Url.encode(
        utf8.encode(value),
      )}',
      title: 'QR Code',
      subtitle: subtitle,
      type: 'qr',
      route: '/qr-tools',
      data: value,
      createdAt:
          DateTime.now().millisecondsSinceEpoch,
    );
  }

  // =====================================================
  // LOAD DATA
  // =====================================================

  Future<void> _loadData() async {
    final prefs =
        await SharedPreferences.getInstance();

    final recentData =
        prefs.getString(_recentKey);

    final favoritesData =
        prefs.getString(_favoritesKey);

    List<String> localRecent = [];
    List<String> localFavorites = [];

    if (recentData != null) {
      try {
        final decoded = jsonDecode(recentData);

        if (decoded is List) {
          localRecent =
              List<String>.from(decoded);
        }
      } catch (_) {}
    }

    if (favoritesData != null) {
      try {
        final decoded = jsonDecode(
          favoritesData,
        );

        if (decoded is List) {
          localFavorites =
              List<String>.from(decoded);
        }
      } catch (_) {}
    }

    // ===================================================
    // MIGRATE OLD QR FAVORITES
    // ===================================================

    for (final value in localFavorites) {
      final item = _createQRItem(value);

      if (!ScanlyActivityService.isFavorite(
        item.id,
      )) {
        await ScanlyActivityService.addFavorite(
          item,
        );
      }
    }

    // ===================================================
    // MIGRATE OLD QR RECENT
    // ===================================================

    for (final value in localRecent) {
      final item = _createQRItem(value);

      final alreadyExists =
          ScanlyActivityService.recent.any(
        (oldItem) => oldItem.id == item.id,
      );

      if (!alreadyExists) {
        await ScanlyActivityService.addRecent(
          item,
        );
      }
    }

    if (!mounted) return;

    setState(() {
      _recent = localRecent;
      _isLoading = false;
    });

    _syncWithGlobalFavorites();
  }

  // =====================================================
  // SYNC GLOBAL FAVORITES
  // =====================================================

  void _syncWithGlobalFavorites() {
    if (!mounted) return;

    final globalFavorites =
        ScanlyActivityService.favorites
            .where(
              (item) => item.type == 'qr',
            )
            .map(
              (item) => item.data,
            )
            .whereType<String>()
            .toList();

    setState(() {
      _favorites =
          List<String>.from(globalFavorites);
    });

    // Keep old QR storage synchronized
    _saveFavorites();
  }

  // =====================================================
  // SAVE RECENT
  // =====================================================

  Future<void> _saveRecent() async {
    final prefs =
        await SharedPreferences.getInstance();

    await prefs.setString(
      _recentKey,
      jsonEncode(_recent),
    );
  }

  // =====================================================
  // SAVE FAVORITES
  // =====================================================

  Future<void> _saveFavorites() async {
    final prefs =
        await SharedPreferences.getInstance();

    await prefs.setString(
      _favoritesKey,
      jsonEncode(_favorites),
    );
  }

  // =====================================================
  // ADD RECENT
  // =====================================================

  Future<void> _addToRecent(
    String value,
  ) async {
    if (value.trim().isEmpty) return;

    final item = _createQRItem(value);

    if (!mounted) return;

    setState(() {
      _recent.remove(value);
      _recent.insert(0, value);

      if (_recent.length > 20) {
        _recent.removeLast();
      }
    });

    await ScanlyActivityService.addRecent(
      item,
    );

    await _saveRecent();
  }

  // =====================================================
  // REMOVE RECENT
  // =====================================================

  Future<void> _removeRecent(
    String value,
  ) async {
    if (!mounted) return;

    setState(() {
      _recent.remove(value);
    });

    final item = _createQRItem(value);

    await ScanlyActivityService.removeRecent(
      item.id,
    );

    await _saveRecent();
  }

  // =====================================================
  // TOGGLE FAVORITE
  // =====================================================

  Future<void> _toggleFavorite(
    String value,
  ) async {
    if (value.trim().isEmpty) return;

    final item = _createQRItem(value);

    final currentlyFavorite =
        ScanlyActivityService.isFavorite(
      item.id,
    );

    if (currentlyFavorite) {
      // REMOVE FROM GLOBAL
      await ScanlyActivityService
          .removeFavorite(
        item.id,
      );
    } else {
      // ADD TO GLOBAL
      await ScanlyActivityService
          .addFavorite(
        item,
      );
    }

    if (!mounted) return;

    // ALWAYS READ FROM GLOBAL
    // This guarantees Home + QR stay synchronized.
    final globalFavorites =
        ScanlyActivityService.favorites
            .where(
              (item) => item.type == 'qr',
            )
            .map(
              (item) => item.data,
            )
            .whereType<String>()
            .toList();

    setState(() {
      _favorites =
          List<String>.from(
        globalFavorites,
      );
    });

    await _saveFavorites();
  }

  // =====================================================
  // IS FAVORITE
  // =====================================================

  bool _isFavorite(
    String value,
  ) {
    final item = _createQRItem(value);

    return ScanlyActivityService.isFavorite(
      item.id,
    );
  }

  // =====================================================
  // CLEAR ALL FAVORITES
  // =====================================================

  Future<void> _clearFavorites() async {
    // IMPORTANT:
    // Clear GLOBAL favorites first.
    await ScanlyActivityService
        .clearFavorites();

    // Then clear QR local storage.
    final prefs =
        await SharedPreferences.getInstance();

    await prefs.remove(_favoritesKey);

    if (!mounted) return;

    setState(() {
      _favorites.clear();
    });

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text(
            'Favorites cleared',
          ),
          behavior:
              SnackBarBehavior.floating,
        ),
      );
  }

  // =====================================================
  // TOP TAB
  // =====================================================

  Widget _buildTopTabs() {
    final isScan =
        _section == QRSection.scan;

    final isGenerate =
        _section == QRSection.generate;

    return Container(
      margin:
          const EdgeInsets.fromLTRB(
        20,
        10,
        20,
        16,
      ),
      padding:
          const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withOpacity(0.6),
        borderRadius:
            BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTopButton(
              title: 'Scan',
              icon:
                  Icons.qr_code_scanner_rounded,
              selected: isScan,
              onTap: () {
                setState(() {
                  _section =
                      QRSection.scan;
                });
              },
            ),
          ),
          Expanded(
            child: _buildTopButton(
              title: 'Generate',
              icon:
                  Icons.qr_code_2_rounded,
              selected: isGenerate,
              onTap: () {
                setState(() {
                  _section =
                      QRSection.generate;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopButton({
    required String title,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration:
            const Duration(milliseconds: 250),
        padding:
            const EdgeInsets.symmetric(
          vertical: 13,
        ),
        decoration: BoxDecoration(
          gradient: selected
              ? const LinearGradient(
                  colors: [
                    purple,
                    blue,
                  ],
                )
              : null,
          borderRadius:
              BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20,
              color: selected
                  ? Colors.white
                  : Theme.of(context)
                      .colorScheme
                      .onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight:
                    FontWeight.w700,
                color: selected
                    ? Colors.white
                    : Theme.of(context)
                        .colorScheme
                        .onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =====================================================
  // CONTENT
  // =====================================================

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child:
            CircularProgressIndicator(),
      );
    }

    switch (_section) {
      case QRSection.scan:
        return QRScannerPage(
          onScan: _addToRecent,
          isFavorite: _isFavorite,
          onToggleFavorite:
              _toggleFavorite,
        );

      case QRSection.generate:
        return QRGeneratorPage(
          onGenerated: _addToRecent,
          isFavorite: _isFavorite,
          onToggleFavorite:
              _toggleFavorite,
        );

      case QRSection.recent:
        return QRRecentPage(
          recent: _recent,
          favorites: _favorites,
          onToggleFavorite:
              _toggleFavorite,
          onRemove: _removeRecent,
        );

      case QRSection.favorites:
        return QRFavoritesPage(
          favorites: _favorites,
          onToggleFavorite:
              _toggleFavorite,
        );
    }
  }

  // =====================================================
  // BOTTOM NAVIGATION
  // =====================================================

  Widget _buildBottomNavigation() {
    final isRecent =
        _section == QRSection.recent;

    final isFavorites =
        _section ==
            QRSection.favorites;

    return Container(
      margin:
          const EdgeInsets.fromLTRB(
        20,
        10,
        20,
        20,
      ),
      padding:
          const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surface,
        borderRadius:
            BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset:
                const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildBottomButton(
              title: 'Recent',
              icon:
                  Icons.history_rounded,
              selected: isRecent,
              onTap: () {
                setState(() {
                  _section =
                      QRSection.recent;
                });
              },
            ),
          ),
          Expanded(
            child: _buildBottomButton(
              title: 'Favorites',
              icon:
                  Icons.favorite_rounded,
              selected: isFavorites,
              onTap: () {
                // Sync before opening
                _syncWithGlobalFavorites();

                setState(() {
                  _section =
                      QRSection.favorites;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButton({
    required String title,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration:
            const Duration(milliseconds: 250),
        padding:
            const EdgeInsets.symmetric(
          vertical: 12,
        ),
        decoration: BoxDecoration(
          gradient: selected
              ? const LinearGradient(
                  colors: [
                    purple,
                    blue,
                  ],
                )
              : null,
          borderRadius:
              BorderRadius.circular(17),
        ),
        child: Row(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20,
              color: selected
                  ? Colors.white
                  : Theme.of(context)
                      .colorScheme
                      .onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight:
                    FontWeight.w700,
                color: selected
                    ? Colors.white
                    : Theme.of(context)
                        .colorScheme
                        .onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =====================================================
  // PAGE
  // =====================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'QR Tools',
          style: TextStyle(
            fontWeight:
                FontWeight.w800,
          ),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_rounded,
          ),
          onPressed: () {
            context.go('/home');
          },
        ),

        // ===============================================
        // CLEAR FAVORITES
        // ===============================================
        actions: [
          if (_section ==
                  QRSection.favorites &&
              _favorites.isNotEmpty)
            IconButton(
              tooltip:
                  'Clear Favorites',
              icon: const Icon(
                Icons.delete_sweep_outlined,
              ),
              onPressed:
                  _clearFavorites,
            ),
        ],
      ),

      body: Column(
        children: [
          _buildTopTabs(),

          Expanded(
            child: AnimatedSwitcher(
              duration:
                  const Duration(
                milliseconds: 300,
              ),
              switchInCurve:
                  Curves.easeOut,
              switchOutCurve:
                  Curves.easeIn,
              child: KeyedSubtree(
                key: ValueKey(
                  _section,
                ),
                child:
                    _buildContent(),
              ),
            ),
          ),

          _buildBottomNavigation(),
        ],
      ),
    );
  }
}