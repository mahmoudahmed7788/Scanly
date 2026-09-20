import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:scanly/DocumentModel.dart';
import 'package:scanly/ScanlyActivityService.dart';
import 'package:scanly/Scanly_Items.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage>
    with WidgetsBindingObserver {
  static const String _qrFavoritesKey = 'qr_favorites';

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    ScanlyActivityService.version.addListener(_refresh);

    _loadDocuments();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    ScanlyActivityService.version.removeListener(_refresh);

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
    if (!mounted) return;

    setState(() {});
  }

  Future<void> _loadDocuments() async {
    try {
      await DocumentStorage.syncFromDisk();
    } catch (e) {
      debugPrint('Favorites sync error: $e');
    }

    if (!mounted) return;

    setState(() {});
  }

  List<DocumentModel> _favoriteDocuments() {
    final documents = DocumentStorage.getDocuments()
        .where(
          (document) => document.isFavorite,
        )
        .toList();

    documents.sort((a, b) {
      final dateA = DateTime.tryParse(a.date);
      final dateB = DateTime.tryParse(b.date);

      if (dateA == null && dateB == null) {
        return 0;
      }

      if (dateA == null) {
        return 1;
      }

      if (dateB == null) {
        return -1;
      }

      return dateB.compareTo(dateA);
    });

    return documents;
  }

  IconData _iconForType(String type) {
    switch (type.toLowerCase()) {
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
    await ScanlyActivityService.addRecent(item);

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
    await DocumentStorage.markAsOpened(document);

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

    if (!mounted) return;

    _showMessage('Removed from favorites');
  }

  Future<void> _removeDocumentFavorite(
    DocumentModel document,
  ) async {
    await DocumentStorage.toggleFavorite(
      document,
    );

    if (!mounted) return;

    _showMessage('Removed from favorites');

    await _loadDocuments();
  }

  Future<void> _clearFavorites() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        final colors =
            Theme.of(context).colorScheme;

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
            'Remove all items from your favorites?',
            style: TextStyle(
              color: colors.onSurfaceVariant,
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
              child: const Text('Cancel'),
            ),
            FilledButton.icon(
              onPressed: () {
                Navigator.pop(
                  context,
                  true,
                );
              },
              icon: const Icon(
                Icons.delete_sweep_rounded,
              ),
              label: const Text('Clear'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    // =========================================
    // 1. Clear ALL global Scanly favorites
    // =========================================
    await ScanlyActivityService.clearFavorites();

    // =========================================
    // 2. Clear QR Favorites local storage
    // =========================================
    final prefs =
        await SharedPreferences.getInstance();

    await prefs.remove(
      _qrFavoritesKey,
    );

    // =========================================
    // 3. Clear PDF / Document favorites
    // =========================================
    final documents = _favoriteDocuments();

    for (final document in documents) {
      if (document.isFavorite) {
        await DocumentStorage.toggleFavorite(
          document,
        );
      }
    }

    // =========================================
    // 4. Refresh Favorites page
    // =========================================
    if (!mounted) return;

    setState(() {});

    _showMessage(
      'Favorites cleared',
    );

    await _loadDocuments();
  }

  void _showMessage(
    String message,
  ) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(message),
        ),
      );
  }

  String _formatDate(
    String value,
  ) {
    final date =
        DateTime.tryParse(value);

    if (date == null) {
      return 'Unknown date';
    }

    final day =
        date.day.toString().padLeft(2, '0');

    final month =
        date.month.toString().padLeft(2, '0');

    final year =
        date.year.toString();

    final hour =
        date.hour.toString().padLeft(2, '0');

    final minute =
        date.minute.toString().padLeft(2, '0');

    return '$day/$month/$year • $hour:$minute';
  }

  Widget _buildPdfIcon(
    BuildContext context,
  ) {
    final colors =
        Theme.of(context).colorScheme;

    return Container(
      width: 62,
      height: 62,
      decoration: BoxDecoration(
        color: colors.error.withValues(
          alpha: 0.10,
        ),
        borderRadius:
            BorderRadius.circular(16),
        border: Border.all(
          color: colors.error.withValues(
            alpha: 0.18,
          ),
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            Icons.picture_as_pdf_rounded,
            size: 35,
            color: colors.error,
          ),
          Positioned(
            bottom: 5,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 5,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: colors.error,
                borderRadius:
                    BorderRadius.circular(4),
              ),
              child: const Text(
                'PDF',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 7,
                  fontWeight:
                      FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
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
    final theme =
        Theme.of(context);

    final colors =
        theme.colorScheme;

    return Container(
      margin:
          const EdgeInsets.only(
        bottom: 12,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius:
            BorderRadius.circular(20),
        border: Border.all(
          color:
              colors.outlineVariant
                  .withValues(
            alpha: 0.35,
          ),
        ),
        boxShadow: [
          if (theme.brightness ==
              Brightness.light)
            BoxShadow(
              color:
                  colors.onSurface
                      .withValues(
                alpha: 0.05,
              ),
              blurRadius: 12,
              offset:
                  const Offset(0, 5),
            ),
        ],
      ),
      child: InkWell(
        borderRadius:
            BorderRadius.circular(20),
        onTap: () =>
            _openDocument(document),
        child: Padding(
          padding:
              const EdgeInsets.all(14),
          child: Row(
            children: [
              _buildPdfIcon(context),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      document.title,
                      maxLines: 2,
                      overflow:
                          TextOverflow.ellipsis,
                      style: TextStyle(
                        color:
                            colors.onSurface,
                        fontSize: 16,
                        fontWeight:
                            FontWeight.w700,
                      ),
                    ),

                    const SizedBox(
                      height: 7,
                    ),

                    Row(
                      children: [
                        Icon(
                          Icons
                              .schedule_rounded,
                          size: 14,
                          color: colors
                              .onSurfaceVariant,
                        ),
                        const SizedBox(
                          width: 5,
                        ),
                        Flexible(
                          child: Text(
                            _formatDate(
                              document.date,
                            ),
                            overflow:
                                TextOverflow
                                    .ellipsis,
                            style: TextStyle(
                              color: colors
                                  .onSurfaceVariant,
                              fontSize: 12,
                              fontWeight:
                                  FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(
                      height: 7,
                    ),

                    Container(
                      padding:
                          const EdgeInsets
                              .symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration:
                          BoxDecoration(
                        color: colors.error
                            .withValues(
                          alpha: 0.09,
                        ),
                        borderRadius:
                            BorderRadius
                                .circular(7),
                      ),
                      child: Text(
                        'PDF',
                        style: TextStyle(
                          color:
                              colors.error,
                          fontSize: 10,
                          fontWeight:
                              FontWeight.w800,
                          letterSpacing:
                              0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 4),

              IconButton(
                tooltip:
                    'Remove from favorites',
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
    final theme =
        Theme.of(context);

    final colors =
        theme.colorScheme;

    return Dismissible(
      key: ValueKey(
        'favorite_${item.id}',
      ),
      direction:
          DismissDirection.endToStart,
      background: Container(
        margin:
            const EdgeInsets.only(
          bottom: 12,
        ),
        alignment:
            Alignment.centerRight,
        padding:
            const EdgeInsets.only(
          right: 20,
        ),
        decoration:
            BoxDecoration(
          color: colors.error,
          borderRadius:
              BorderRadius.circular(20),
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
        margin:
            const EdgeInsets.only(
          bottom: 12,
        ),
        decoration:
            BoxDecoration(
          color: colors.surface,
          borderRadius:
              BorderRadius.circular(20),
          border: Border.all(
            color:
                colors.outlineVariant
                    .withValues(
              alpha: 0.35,
            ),
          ),
          boxShadow: [
            if (theme.brightness ==
                Brightness.light)
              BoxShadow(
                color:
                    colors.onSurface
                        .withValues(
                  alpha: 0.05,
                ),
                blurRadius: 12,
                offset:
                    const Offset(0, 5),
              ),
          ],
        ),
        child: InkWell(
          borderRadius:
              BorderRadius.circular(20),
          onTap: () =>
              _openItem(item),
          child: Padding(
            padding:
                const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 62,
                  height: 62,
                  decoration:
                      BoxDecoration(
                    color: colors.primary
                        .withValues(
                      alpha: 0.10,
                    ),
                    borderRadius:
                        BorderRadius.circular(
                      16,
                    ),
                  ),
                  child: Icon(
                    _iconForType(
                      item.type,
                    ),
                    color:
                        colors.primary,
                    size: 30,
                  ),
                ),

                const SizedBox(width: 14),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
                    children: [
                      Text(
                        item.title,
                        maxLines: 2,
                        overflow:
                            TextOverflow
                                .ellipsis,
                        style: TextStyle(
                          color:
                              colors.onSurface,
                          fontSize: 16,
                          fontWeight:
                              FontWeight.w700,
                        ),
                      ),

                      const SizedBox(
                        height: 6,
                      ),

                      Text(
                        item.subtitle,
                        maxLines: 2,
                        overflow:
                            TextOverflow
                                .ellipsis,
                        style: TextStyle(
                          color: colors
                              .onSurfaceVariant,
                          fontSize: 13,
                        ),
                      ),

                      const SizedBox(
                        height: 7,
                      ),

                      Container(
                        padding:
                            const EdgeInsets
                                .symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration:
                            BoxDecoration(
                          color: colors
                              .primary
                              .withValues(
                            alpha: 0.09,
                          ),
                          borderRadius:
                              BorderRadius
                                  .circular(
                            7,
                          ),
                        ),
                        child: Text(
                          item.type
                              .toUpperCase(),
                          style: TextStyle(
                            color:
                                colors.primary,
                            fontSize: 10,
                            fontWeight:
                                FontWeight.w800,
                            letterSpacing:
                                0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 4),

                IconButton(
                  tooltip:
                      'Remove from favorites',
                  onPressed: () =>
                      _removeFavorite(item),
                  icon: Icon(
                    Icons.favorite_rounded,
                    color: colors.error,
                  ),
                ),
              ],
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
          mainAxisSize:
              MainAxisSize.min,
          children: [
            Container(
              width: 92,
              height: 92,
              decoration:
                  BoxDecoration(
                color: colors.primary
                    .withValues(
                  alpha: 0.10,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons
                    .favorite_border_rounded,
                size: 48,
                color:
                    colors.primary,
              ),
            ),

            const SizedBox(
              height: 20,
            ),

            Text(
              'No Favorites Yet',
              style: TextStyle(
                color:
                    colors.onSurface,
                fontSize: 21,
                fontWeight:
                    FontWeight.w700,
              ),
            ),

            const SizedBox(
              height: 8,
            ),

            Text(
              'Anything you favorite in Scanly will appear here.',
              textAlign:
                  TextAlign.center,
              style: TextStyle(
                color: colors
                    .onSurfaceVariant,
                fontSize: 14,
                height: 1.4,
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
    final theme =
        Theme.of(context);

    final colors =
        theme.colorScheme;

    final favorites =
        ScanlyActivityService
            .favorites;

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
          ? _buildEmptyState(
              context,
            )
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
                          _buildDocumentCard(
                        context,
                        document,
                      ),
                    ),
                  ],

                  if (favorites
                      .isNotEmpty) ...[
                    if (documentFavorites
                        .isNotEmpty)
                      const SizedBox(
                        height: 22,
                      ),

                    _buildSectionTitle(
                      context,
                      'Other Favorites',
                      Icons
                          .favorite_rounded,
                    ),

                    const SizedBox(
                      height: 10,
                    ),

                    ...favorites.map(
                      (item) =>
                          _buildItemCard(
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
}