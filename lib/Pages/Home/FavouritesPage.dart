import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:scanly/Core/DocumentStorage.dart';
import 'package:scanly/Core/ScanlyActivityService.dart';
import 'package:scanly/Core/Scanly_Items.dart';
import 'package:scanly/Core/ScanlyItemOpener.dart';
import 'package:scanly/Models/DocumentModel.dart';
import 'package:scanly/Service/Ads/AdService.dart';
import 'package:scanly/Widgets/Favourites/favorite_document_card.dart';
import 'package:scanly/Widgets/Favourites/favorite_item_card.dart';
import 'package:scanly/Widgets/Favourites/favorites_empty_state.dart';
import 'package:scanly/Widgets/Favourites/favorites_utils.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    ScanlyActivityService.version.addListener(_refresh);

    _loadData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    ScanlyActivityService.version.removeListener(_refresh);

    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadData();
    }
  }

  void _refresh() {
    if (!mounted) {
      return;
    }

    setState(() {});
  }

  Future<void> _loadData() async {
    try {
      await ScanlyActivityService.init();
    } catch (e) {
      debugPrint('Favorites activity sync error: $e');
    }

    try {
      await DocumentStorage.syncFromDisk();
    } catch (e) {
      debugPrint('Favorites document sync error: $e');
    }

    if (!mounted) {
      return;
    }

    setState(() {});
  }

  List<DocumentModel> _favoriteDocuments() {
    return FavoritesUtils.favoriteDocuments();
  }

  List<ScanlyItem> get _favorites {
    return ScanlyActivityService.favorites;
  }

  List<ScanlyItem> get _noteFavorites {
    return _favorites.where((item) => item.type == 'note').toList();
  }

  List<ScanlyItem> get _qrFavorites {
    return _favorites.where((item) => item.type == 'qr').toList();
  }

  List<ScanlyItem> get _imageToTextFavorites {
    return _favorites.where((item) => item.type == 'image_to_text').toList();
  }

  List<ScanlyItem> get _otherFavorites {
    return _favorites
        .where(
          (item) =>
              item.type != 'note' &&
              item.type != 'qr' &&
              item.type != 'image_to_text',
        )
        .toList();
  }

  Future<void> _openItem(ScanlyItem item) async {
    await AdService.showInterstitialBeforeAction();

    if (!mounted) {
      return;
    }

    await ScanlyItemOpener.open(context, item);

    if (!mounted) {
      return;
    }

    await _loadData();
  }

  Future<void> _openDocument(DocumentModel document) async {
    await AdService.showInterstitialBeforeAction();

    if (!mounted) {
      return;
    }

    await DocumentStorage.markAsOpened(document);

    if (!mounted) {
      return;
    }

    final path = document.filePath;

    if (path == null || path.isEmpty) {
      _showMessage('PDF file path not found');
      return;
    }

    final file = File(path);

    if (!await file.exists()) {
      _showMessage('PDF file no longer exists');

      await _loadData();
      return;
    }

    final bytes = await file.readAsBytes();

    if (bytes.isEmpty) {
      _showMessage('PDF file is empty');
      return;
    }

    await context.push('/pdf-preview', extra: document);

    if (!mounted) {
      return;
    }

    await _loadData();
  }

  Future<void> _removeFavorite(ScanlyItem item) async {
    await ScanlyActivityService.removeFavorite(item);

    if (!mounted) {
      return;
    }

    _showMessage('Moved to Trash');
  }

  Future<void> _removeDocumentFavorite(DocumentModel document) async {
    await DocumentStorage.toggleFavorite(document);

    if (!mounted) {
      return;
    }

    _showMessage('Removed from favorites');

    await _loadData();
  }

  Future<void> _clearFavorites() async {
    final confirmed = await _showClearFavoritesDialog();

    if (confirmed != true) {
      return;
    }

    await ScanlyActivityService.clearFavorites();

    final documents = _favoriteDocuments();

    for (final document in documents) {
      if (document.isFavorite) {
        await DocumentStorage.toggleFavorite(document);
      }
    }

    if (!mounted) {
      return;
    }

    setState(() {});

    _showMessage('Favorites moved to Trash');

    await _loadData();
  }

  Future<bool?> _showClearFavoritesDialog() {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        final colors = Theme.of(context).colorScheme;

        return AlertDialog(
          backgroundColor: colors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Clear Favorites',
            style: TextStyle(
              color: colors.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Text(
            'Move all items from your favorites to Trash?',
            style: TextStyle(color: colors.onSurfaceVariant),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton.icon(
              onPressed: () {
                Navigator.pop(context, true);
              },
              icon: const Icon(Icons.delete_sweep_rounded),
              label: const Text('Clear'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title, IconData icon) {
    final colors = Theme.of(context).colorScheme;

    return Row(
      children: [
        Icon(icon, color: colors.primary, size: 22),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            color: colors.onSurface,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  List<Widget> _buildScanlyItemList(List<ScanlyItem> items) {
    return items.map((item) {
      return FavoriteItemCard(
        item: item,
        onOpen: () => _openItem(item),
        onRemove: () => _removeFavorite(item),
      );
    }).toList();
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(behavior: SnackBarBehavior.floating, content: Text(message)),
      );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final colors = theme.colorScheme;

    final documentFavorites = _favoriteDocuments();

    final noteFavorites = _noteFavorites;

    final qrFavorites = _qrFavorites;

    final imageToTextFavorites = _imageToTextFavorites;

    final otherFavorites = _otherFavorites;

    final hasFavorites =
        documentFavorites.isNotEmpty ||
        noteFavorites.isNotEmpty ||
        qrFavorites.isNotEmpty ||
        imageToTextFavorites.isNotEmpty ||
        otherFavorites.isNotEmpty;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: colors.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Favorites',
          style: TextStyle(
            color: colors.onSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          if (hasFavorites)
            IconButton(
              tooltip: 'Clear favorites',
              onPressed: _clearFavorites,
              icon: Icon(Icons.delete_sweep_rounded, color: colors.onSurface),
            ),
        ],
      ),
      body: !hasFavorites
          ? const FavoritesEmptyState()
          : RefreshIndicator(
              color: colors.primary,
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 30),
                children: [
                  if (documentFavorites.isNotEmpty) ...[
                    _buildSectionTitle(
                      context,
                      'PDF Documents',
                      Icons.picture_as_pdf_rounded,
                    ),
                    const SizedBox(height: 10),
                    ...documentFavorites.map(
                      (document) => FavoriteDocumentCard(
                        document: document,
                        onOpen: () => _openDocument(document),
                        onRemove: () => _removeDocumentFavorite(document),
                      ),
                    ),
                  ],
                  if (noteFavorites.isNotEmpty) ...[
                    if (documentFavorites.isNotEmpty)
                      const SizedBox(height: 22),
                    _buildSectionTitle(context, 'Notes', Icons.notes_rounded),
                    const SizedBox(height: 10),
                    ..._buildScanlyItemList(noteFavorites),
                  ],
                  if (qrFavorites.isNotEmpty) ...[
                    if (documentFavorites.isNotEmpty ||
                        noteFavorites.isNotEmpty)
                      const SizedBox(height: 22),
                    _buildSectionTitle(
                      context,
                      'QR Codes',
                      Icons.qr_code_rounded,
                    ),
                    const SizedBox(height: 10),
                    ..._buildScanlyItemList(qrFavorites),
                  ],
                  if (imageToTextFavorites.isNotEmpty) ...[
                    if (documentFavorites.isNotEmpty ||
                        noteFavorites.isNotEmpty ||
                        qrFavorites.isNotEmpty)
                      const SizedBox(height: 22),
                    _buildSectionTitle(
                      context,
                      'Image to Text',
                      Icons.text_snippet_outlined,
                    ),
                    const SizedBox(height: 10),
                    ..._buildScanlyItemList(imageToTextFavorites),
                  ],
                  if (otherFavorites.isNotEmpty) ...[
                    if (documentFavorites.isNotEmpty ||
                        noteFavorites.isNotEmpty ||
                        qrFavorites.isNotEmpty ||
                        imageToTextFavorites.isNotEmpty)
                      const SizedBox(height: 22),
                    _buildSectionTitle(
                      context,
                      'Other Favorites',
                      Icons.favorite_rounded,
                    ),
                    const SizedBox(height: 10),
                    ..._buildScanlyItemList(otherFavorites),
                  ],
                ],
              ),
            ),
    );
  }
}
