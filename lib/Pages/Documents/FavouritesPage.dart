import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:scanly/Core/DocumentStorage.dart';
import 'package:scanly/Core/Scanly_Items.dart';
import 'package:scanly/Models/DocumentModel.dart';
import 'package:scanly/Widgets/Favourites/favorite_document_card.dart';
import 'package:scanly/Widgets/Favourites/favorite_item_card.dart';
import 'package:scanly/Widgets/Favourites/favorites_empty_state.dart';
import 'package:scanly/Widgets/Favourites/favorites_utils.dart';
import 'package:scanly/core/ScanlyActivityService.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({
    super.key,
  });

  @override
  State<FavoritesPage> createState() =>
      _FavoritesPageState();
}

class _FavoritesPageState
    extends State<FavoritesPage>
    with WidgetsBindingObserver {
  static const String _qrFavoritesKey =
      'qr_favorites';

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance
        .addObserver(this);

    ScanlyActivityService.version
        .addListener(_refresh);

    _loadDocuments();
  }

  @override
  void dispose() {
    WidgetsBinding.instance
        .removeObserver(this);

    ScanlyActivityService.version
        .removeListener(_refresh);

    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(
    AppLifecycleState state,
  ) {
    if (state ==
        AppLifecycleState.resumed) {
      _loadDocuments();
    }
  }

  // ============================================================
  // REFRESH
  // ============================================================

  void _refresh() {
    if (!mounted) {
      return;
    }

    setState(() {});
  }

  Future<void> _loadDocuments() async {
    try {
      await DocumentStorage.syncFromDisk();
    } catch (e) {
      debugPrint(
        'Favorites sync error: $e',
      );
    }

    if (!mounted) {
      return;
    }

    setState(() {});
  }

  // ============================================================
  // FAVORITES
  // ============================================================

  List<DocumentModel> _favoriteDocuments() {
    return FavoritesUtils.favoriteDocuments();
  }

  List<ScanlyItem> get _favorites =>
      ScanlyActivityService.favorites;

  // ============================================================
  // OPEN SCANLY ITEM
  // ============================================================

  Future<void> _openItem(
    ScanlyItem item,
  ) async {
    await ScanlyActivityService.addRecent(
      item,
    );

    if (!mounted) {
      return;
    }

    if (item.route.isNotEmpty) {
      await context.push(
        item.route,
        extra: item.data,
      );
    }

    if (!mounted) {
      return;
    }

    await _loadDocuments();
  }

  // ============================================================
  // OPEN DOCUMENT
  // ============================================================

  Future<void> _openDocument(
    DocumentModel document,
  ) async {
    await DocumentStorage.markAsOpened(
      document,
    );

    if (!mounted) {
      return;
    }

    final path = document.filePath;

    if (path == null || path.isEmpty) {
      _showMessage(
        'PDF file path not found',
      );
      return;
    }

    final file = File(path);

    if (!await file.exists()) {
      _showMessage(
        'PDF file no longer exists',
      );

      await _loadDocuments();

      return;
    }

    final bytes = await file.readAsBytes();

    if (bytes.isEmpty) {
      _showMessage(
        'PDF file is empty',
      );
      return;
    }

    await context.push(
      '/pdf-preview',
      extra: {
        'pdfBytes': bytes,
        'fileName':
            '${document.title}.pdf',
        'filePath': path,
        'imagePaths': <String>[],
      },
    );

    if (!mounted) {
      return;
    }

    await _loadDocuments();
  }

  // ============================================================
  // REMOVE ITEM FAVORITE
  // ============================================================

  Future<void> _removeFavorite(
    ScanlyItem item,
  ) async {
    await ScanlyActivityService
        .removeFavorite(
      item.id,
    );

    if (!mounted) {
      return;
    }

    _showMessage(
      'Removed from favorites',
    );
  }

  // ============================================================
  // REMOVE DOCUMENT FAVORITE
  // ============================================================

  Future<void> _removeDocumentFavorite(
    DocumentModel document,
  ) async {
    await DocumentStorage.toggleFavorite(
      document,
    );

    if (!mounted) {
      return;
    }

    _showMessage(
      'Removed from favorites',
    );

    await _loadDocuments();
  }

  // ============================================================
  // CLEAR FAVORITES
  // ============================================================

  Future<void> _clearFavorites() async {
    final confirmed =
        await _showClearFavoritesDialog();

    if (confirmed != true) {
      return;
    }

    // Clear global Scanly favorites.
    await ScanlyActivityService
        .clearFavorites();

    // Clear QR favorites.
    final prefs =
        await SharedPreferences
            .getInstance();

    await prefs.remove(
      _qrFavoritesKey,
    );

    // Clear PDF favorites.
    final documents =
        _favoriteDocuments();

    for (final document in documents) {
      if (document.isFavorite) {
        await DocumentStorage
            .toggleFavorite(
          document,
        );
      }
    }

    if (!mounted) {
      return;
    }

    setState(() {});

    _showMessage(
      'Favorites cleared',
    );

    await _loadDocuments();
  }

  Future<bool?> _showClearFavoritesDialog() {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        final colors =
            Theme.of(context).colorScheme;

        return AlertDialog(
          backgroundColor:
              colors.surface,
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(20),
          ),
          title: Text(
            'Clear Favorites',
            style: TextStyle(
              color:
                  colors.onSurface,
              fontWeight:
                  FontWeight.w700,
            ),
          ),
          content: Text(
            'Remove all items from your favorites?',
            style: TextStyle(
              color:
                  colors.onSurfaceVariant,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  false,
                );
              },
              child:
                  const Text('Cancel'),
            ),
            FilledButton.icon(
              onPressed: () {
                Navigator.pop(
                  context,
                  true,
                );
              },
              icon: const Icon(
                Icons
                    .delete_sweep_rounded,
              ),
              label:
                  const Text('Clear'),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(
    String message,
  ) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior:
              SnackBarBehavior.floating,
          content: Text(message),
        ),
      );
  }

  // ============================================================
  // SECTION TITLE
  // ============================================================

  Widget _buildSectionTitle(
    BuildContext context,
    String title,
    IconData icon,
  ) {
    final colors =
        Theme.of(context).colorScheme;

    return Row(
      children: [
        Icon(
          icon,
          color: colors.primary,
          size: 22,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            color:
                colors.onSurface,
            fontSize: 18,
            fontWeight:
                FontWeight.w700,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    final theme =
        Theme.of(context);

    final colors =
        theme.colorScheme;

    final favorites =
        _favorites;

    final documentFavorites =
        _favoriteDocuments();

    final hasFavorites =
        favorites.isNotEmpty ||
        documentFavorites.isNotEmpty;

    return Scaffold(
      backgroundColor:
          theme.scaffoldBackgroundColor,

      appBar: AppBar(
        backgroundColor:
            theme.scaffoldBackgroundColor,
        foregroundColor:
            colors.onSurface,
        surfaceTintColor:
            Colors.transparent,
        elevation: 0,
        title: Text(
          'Favorites',
          style: TextStyle(
            color:
                colors.onSurface,
            fontWeight:
                FontWeight.w700,
          ),
        ),
        actions: [
          if (hasFavorites)
            IconButton(
              tooltip:
                  'Clear favorites',
              onPressed:
                  _clearFavorites,
              icon: Icon(
                Icons
                    .delete_sweep_rounded,
                color:
                    colors.onSurface,
              ),
            ),
        ],
      ),

      body: !hasFavorites
          ? const FavoritesEmptyState()
          : RefreshIndicator(
              color:
                  colors.primary,
              onRefresh:
                  _loadDocuments,
              child: ListView(
                padding:
                    const EdgeInsets
                        .fromLTRB(
                  18,
                  12,
                  18,
                  30,
                ),
                children: [
                  // ------------------------------------------------
                  // PDF DOCUMENTS
                  // ------------------------------------------------

                  if (documentFavorites
                      .isNotEmpty) ...[
                    _buildSectionTitle(
                      context,
                      'PDF Documents',
                      Icons
                          .picture_as_pdf_rounded,
                    ),

                    const SizedBox(
                      height: 10,
                    ),

                    ...documentFavorites.map(
                      (document) =>
                          FavoriteDocumentCard(
                        document:
                            document,
                        onOpen: () =>
                            _openDocument(
                          document,
                        ),
                        onRemove: () =>
                            _removeDocumentFavorite(
                          document,
                        ),
                      ),
                    ),
                  ],

                  // ------------------------------------------------
                  // OTHER FAVORITES
                  // ------------------------------------------------

                  if (favorites.isNotEmpty) ...[
                    if (documentFavorites
                        .isNotEmpty)
                      const SizedBox(
                        height: 22,
                      ),

                    _buildSectionTitle(
                      context,
                      'Other Favorites',
                      Icons.favorite_rounded,
                    ),

                    const SizedBox(
                      height: 10,
                    ),

                    ...favorites.map(
                      (item) =>
                          FavoriteItemCard(
                        item: item,
                        onOpen: () =>
                            _openItem(item),
                        onRemove: () =>
                            _removeFavorite(
                          item,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}