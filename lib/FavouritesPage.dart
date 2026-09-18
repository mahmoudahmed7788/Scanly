import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import 'package:scanly/DocumentModel.dart';
import 'package:scanly/ScanlyActivityService.dart';
import 'package:scanly/Scanly_Items.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() =>
      _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    ScanlyActivityService.version.addListener(
      _refresh,
    );

    _loadDocuments();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    ScanlyActivityService.version.removeListener(
      _refresh,
    );

    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(
    AppLifecycleState state,
  ) {
    if (state == AppLifecycleState.resumed) {
      _loadDocuments();
    }
  }

  void _refresh() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadDocuments() async {
    await DocumentStorage.syncFromDisk();

    if (!mounted) return;

    setState(() {});
  }

  List<DocumentModel> _favoriteDocuments() {
    return DocumentStorage.getDocuments()
        .where(
          (document) =>
              document.isFavorite &&
              document.type.toLowerCase() == 'pdf',
        )
        .toList();
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'qr':
        return Icons.qr_code_rounded;

      case 'note':
        return Icons.edit_note_rounded;

      case 'pdf':
        return Icons.picture_as_pdf_rounded;

      case 'document':
        return Icons.document_scanner_rounded;

      case 'text':
        return Icons.text_snippet_rounded;

      default:
        return Icons.insert_drive_file_rounded;
    }
  }

  Future<void> _openItem(
    ScanlyItem item,
  ) async {
    await ScanlyActivityService.addRecent(
      item,
    );

    if (!mounted) return;

    if (item.route.isNotEmpty) {
      await context.push(
        item.route,
        extra: item.data,
      );
    }

    if (!mounted) return;

    await _loadDocuments();
  }

  Future<void> _openDocument(
    DocumentModel document,
  ) async {
    await DocumentStorage.markAsOpened(
      document,
    );

    if (!mounted) return;

    final path = document.filePath;

    if (path == null || path.isEmpty) {
      _showMessage('PDF file path not found');
      return;
    }

    final file = File(path);

    if (!await file.exists()) {
      _showMessage('PDF file no longer exists');
      await _loadDocuments();
      return;
    }

    final bytes = await file.readAsBytes();

    if (bytes.isEmpty) {
      _showMessage('PDF file is empty');
      return;
    }

    await context.push(
      '/pdf-preview',
      extra: {
        'pdfBytes': bytes,
        'fileName': '${document.title}.pdf',
        'filePath': path,
        'imagePaths': <String>[],
      },
    );

    if (!mounted) return;

    await _loadDocuments();
  }

  Future<void> _removeFavorite(
    ScanlyItem item,
  ) async {
    await ScanlyActivityService.removeFavorite(
      item.id,
    );
  }

  Future<void> _removeDocumentFavorite(
    DocumentModel document,
  ) async {
    await DocumentStorage.toggleFavorite(
      document,
    );

    await _loadDocuments();
  }

  Future<void> _clearFavorites() async {
    final scanlyFavorites =
        ScanlyActivityService.favorites;

    for (final item in scanlyFavorites) {
      await ScanlyActivityService.removeFavorite(
        item.id,
      );
    }

    final documents = _favoriteDocuments();

    for (final document in documents) {
      if (document.isFavorite) {
        await DocumentStorage.toggleFavorite(
          document,
        );
      }
    }

    await _loadDocuments();
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final favorites =
        ScanlyActivityService.favorites;

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
            color: colors.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (hasFavorites)
            IconButton(
              tooltip: 'Clear favorites',
              onPressed: _clearFavorites,
              icon: Icon(
                Icons.delete_sweep_rounded,
                color: colors.onSurface,
              ),
            ),
        ],
      ),
      body: !hasFavorites
          ? _buildEmptyState(context)
          : RefreshIndicator(
              color: colors.primary,
              onRefresh: _loadDocuments,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  18,
                  12,
                  18,
                  30,
                ),
                children: [
                  if (documentFavorites.isNotEmpty) ...[
                    _buildSectionTitle(
                      context,
                      'PDF Documents',
                      Icons.picture_as_pdf_rounded,
                    ),
                    const SizedBox(height: 10),
                    ...documentFavorites.map(
                      (document) =>
                          _buildDocumentCard(
                        context,
                        document,
                      ),
                    ),
                  ],
                  if (favorites.isNotEmpty) ...[
                    if (documentFavorites.isNotEmpty)
                      const SizedBox(height: 22),
                    _buildSectionTitle(
                      context,
                      'Other Favorites',
                      Icons.favorite_rounded,
                    ),
                    const SizedBox(height: 10),
                    ...favorites.map(
                      (item) => _buildItemCard(
                        context,
                        item,
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

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
            color: colors.onSurface,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildDocumentCard(
    BuildContext context,
    DocumentModel document,
  ) {
    final colors =
        Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(
        bottom: 10,
      ),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius:
            BorderRadius.circular(18),
      ),
      child: InkWell(
        borderRadius:
            BorderRadius.circular(18),
        onTap: () =>
            _openDocument(document),
        child: Padding(
          padding:
              const EdgeInsets.all(15),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: colors.primary
                      .withValues(alpha: 0.12),
                  borderRadius:
                      BorderRadius.circular(15),
                ),
                child: Icon(
                  Icons
                      .picture_as_pdf_rounded,
                  color: colors.primary,
                  size: 27,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      document.title,
                      maxLines: 1,
                      overflow:
                          TextOverflow.ellipsis,
                      style: TextStyle(
                        color:
                            colors.onSurface,
                        fontSize: 16,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'PDF Document',
                      style: TextStyle(
                        color: colors
                            .onSurfaceVariant,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () =>
                    _removeDocumentFavorite(
                  document,
                ),
                icon: Icon(
                  Icons.favorite_rounded,
                  color: colors.error,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildItemCard(
    BuildContext context,
    ScanlyItem item,
  ) {
    final colors =
        Theme.of(context).colorScheme;

    return Dismissible(
      key: ValueKey(
        'favorite_${item.id}',
      ),
      direction:
          DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding:
            const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.redAccent,
          borderRadius:
              BorderRadius.circular(18),
        ),
        child: const Icon(
          Icons.delete_outline_rounded,
          color: Colors.white,
        ),
      ),
      onDismissed: (_) {
        _removeFavorite(item);
      },
      child: Container(
        margin: const EdgeInsets.only(
          bottom: 10,
        ),
        child: Material(
          color:
              colors.surfaceContainerHighest,
          borderRadius:
              BorderRadius.circular(18),
          child: InkWell(
            borderRadius:
                BorderRadius.circular(18),
            onTap: () => _openItem(item),
            child: Padding(
              padding:
                  const EdgeInsets.all(15),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: colors.primary
                          .withValues(
                        alpha: 0.12,
                      ),
                      borderRadius:
                          BorderRadius.circular(15),
                    ),
                    child: Icon(
                      _iconForType(item.type),
                      color: colors.primary,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          maxLines: 1,
                          overflow:
                              TextOverflow.ellipsis,
                          style: TextStyle(
                            color:
                                colors.onSurface,
                            fontSize: 16,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.subtitle,
                          maxLines: 1,
                          overflow:
                              TextOverflow.ellipsis,
                          style: TextStyle(
                            color: colors
                                .onSurfaceVariant,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () =>
                        _removeFavorite(item),
                    icon: Icon(
                      Icons.favorite_rounded,
                      color: colors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
  ) {
    final colors =
        Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: colors.primary
                    .withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons
                    .favorite_border_rounded,
                size: 46,
                color: colors.primary,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'No Favorites Yet',
              style: TextStyle(
                color: colors.onSurface,
                fontSize: 21,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Anything you favorite in Scanly will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.onSurfaceVariant,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}