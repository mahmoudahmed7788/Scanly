import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:scanly/DocumentModel.dart';

class DocumentsPage extends StatefulWidget {
  const DocumentsPage({super.key});

  @override
  State<DocumentsPage> createState() => _DocumentsPageState();
}

class _DocumentsPageState extends State<DocumentsPage>
    with WidgetsBindingObserver {
  List<DocumentModel> _documents = [];
  List<DocumentModel> _filteredDocuments = [];

  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    _loadDocuments();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadDocuments();
    }
  }

  Future<void> _loadDocuments() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      await DocumentStorage.syncFromDisk();

      final documents = DocumentStorage.getDocuments();

      _sortDocuments(documents);

      if (!mounted) return;

      setState(() {
        _documents = documents;
        _applySearch();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Documents loading error: $e');

      if (!mounted) return;

      setState(() {
        _documents = [];
        _filteredDocuments = [];
        _isLoading = false;
      });
    }
  }

  void _sortDocuments(List<DocumentModel> documents) {
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
  }

  void _applySearch() {
    final query = _searchQuery.trim().toLowerCase();

    if (query.isEmpty) {
      _filteredDocuments =
          List<DocumentModel>.from(_documents);

      _sortDocuments(_filteredDocuments);
      return;
    }

    _filteredDocuments = _documents.where((document) {
      final title = document.title.toLowerCase();
      final type = document.type.toLowerCase();

      return title.contains(query) ||
          type.contains(query);
    }).toList();

    _sortDocuments(_filteredDocuments);
  }

  Future<void> _openDocument(
    DocumentModel document,
  ) async {
    /*
     * IMPORTANT:
     * AppRouter expects:
     *
     * extra: DocumentModel
     *
     * NOT a Map.
     *
     * This was the reason for:
     * "Document not found"
     */

    if (!mounted) return;

    await context.push(
      '/pdf-preview',
      extra: document,
    );

    if (!mounted) return;

    await _loadDocuments();
  }

  Future<void> _toggleFavorite(
    DocumentModel document,
  ) async {
    await DocumentStorage.toggleFavorite(document);

    if (!mounted) return;

    final documents = DocumentStorage.getDocuments();

    _sortDocuments(documents);

    setState(() {
      _documents = documents;
      _applySearch();
    });
  }

  Future<void> _deleteDocument(
    DocumentModel document,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        final colors =
            Theme.of(context).colorScheme;

        return AlertDialog(
          backgroundColor: colors.surface,
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(20),
          ),
          title: Text(
            'Delete Document',
            style: TextStyle(
              color: colors.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Text(
            'Are you sure you want to delete "${document.title}"?',
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
                Icons.delete_outline_rounded,
              ),
              label: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    await DocumentStorage.deleteDocument(
      document.id,
    );

    if (!mounted) return;

    _showMessage('Document deleted');

    await _loadDocuments();
  }

  void _showMessage(String message) {
    if (!mounted) return;

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

  String _formatDate(String value) {
    final date = DateTime.tryParse(value);

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

  String _getDocumentType(
    DocumentModel document,
  ) {
    final type = document.type.trim();

    if (type.isEmpty) {
      return 'PDF';
    }

    return type.toUpperCase();
  }

  Widget _buildPdfIcon(
    BuildContext context,
    DocumentModel document,
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
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
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
          const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius:
            BorderRadius.circular(20),
        border: Border.all(
          color: colors.outlineVariant
              .withValues(alpha: 0.35),
        ),
        boxShadow: [
          if (theme.brightness ==
              Brightness.light)
            BoxShadow(
              color: colors.onSurface
                  .withValues(alpha: 0.05),
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
            crossAxisAlignment:
                CrossAxisAlignment.center,
            children: [
              _buildPdfIcon(
                context,
                document,
              ),

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
                        fontSize: 16,
                        fontWeight:
                            FontWeight.w700,
                        color:
                            colors.onSurface,
                      ),
                    ),

                    const SizedBox(height: 7),

                    Row(
                      children: [
                        Icon(
                          Icons
                              .schedule_rounded,
                          size: 14,
                          color:
                              colors.onSurfaceVariant,
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
                                TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: colors
                                  .onSurfaceVariant,
                              fontWeight:
                                  FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 7),

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
                        _getDocumentType(
                          document,
                        ),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight:
                              FontWeight.w800,
                          letterSpacing: 0.5,
                          color:
                              colors.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 4),

              IconButton(
                tooltip:
                    document.isFavorite
                        ? 'Remove from favorites'
                        : 'Add to favorites',
                onPressed: () =>
                    _toggleFavorite(
                  document,
                ),
                icon: Icon(
                  document.isFavorite
                      ? Icons.favorite_rounded
                      : Icons
                          .favorite_border_rounded,
                  color:
                      document.isFavorite
                          ? colors.error
                          : colors
                              .onSurfaceVariant,
                ),
              ),

              PopupMenuButton<String>(
                tooltip:
                    'More options',
                icon: Icon(
                  Icons.more_vert_rounded,
                  color:
                      colors.onSurfaceVariant,
                ),
                onSelected: (value) {
                  if (value == 'open') {
                    _openDocument(
                      document,
                    );
                  }

                  if (value == 'delete') {
                    _deleteDocument(
                      document,
                    );
                  }
                },
                itemBuilder: (context) {
                  return const [
                    PopupMenuItem(
                      value: 'open',
                      child: Row(
                        children: [
                          Icon(
                            Icons
                                .open_in_new_rounded,
                          ),
                          SizedBox(
                            width: 10,
                          ),
                          Text(
                            'Open PDF',
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(
                            Icons
                                .delete_outline_rounded,
                            color:
                                Colors.red,
                          ),
                          SizedBox(
                            width: 10,
                          ),
                          Text(
                            'Delete',
                          ),
                        ],
                      ),
                    ),
                  ];
                },
              ),
            ],
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

    final hasSearch =
        _searchQuery.trim().isNotEmpty;

    return ListView(
      physics:
          const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height:
              MediaQuery.of(context)
                  .size
                  .height *
              0.22,
        ),

        Center(
          child: Container(
            width: 92,
            height: 92,
            decoration:
                BoxDecoration(
              color: colors.error
                  .withValues(
                alpha: 0.10,
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              hasSearch
                  ? Icons.search_off_rounded
                  : Icons
                      .picture_as_pdf_rounded,
              size: 46,
              color: colors.error,
            ),
          ),
        ),

        const SizedBox(height: 20),

        Center(
          child: Text(
            hasSearch
                ? 'No documents found'
                : 'No PDF documents yet',
            style: TextStyle(
              fontSize: 19,
              fontWeight:
                  FontWeight.w700,
              color:
                  colors.onSurface,
            ),
          ),
        ),

        const SizedBox(height: 8),

        Padding(
          padding:
              const EdgeInsets.symmetric(
            horizontal: 30,
          ),
          child: Text(
            hasSearch
                ? 'Try searching with another document name or type.'
                : 'PDF files created by Scanly will appear here.',
            textAlign:
                TextAlign.center,
            style: TextStyle(
              color:
                  colors.onSurfaceVariant,
              height: 1.4,
            ),
          ),
        ),
      ],
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

    return Scaffold(
      backgroundColor:
          theme.scaffoldBackgroundColor,

      appBar: AppBar(
        elevation: 0,
        backgroundColor:
            theme.scaffoldBackgroundColor,
        foregroundColor:
            colors.onSurface,
        surfaceTintColor:
            Colors.transparent,
        title: Text(
          'My Documents',
          style: TextStyle(
            color:
                colors.onSurface,
            fontWeight:
                FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed:
                _loadDocuments,
            icon: Icon(
              Icons.refresh_rounded,
              color:
                  colors.onSurface,
            ),
          ),
        ],
      ),

      body: _isLoading
          ? Center(
              child:
                  CircularProgressIndicator(
                color:
                    colors.primary,
              ),
            )
          : RefreshIndicator(
              color:
                  colors.primary,
              onRefresh:
                  _loadDocuments,
              child:
                  _filteredDocuments.isEmpty
                      ? _buildEmptyState(
                          context,
                        )
                      : Column(
                          children: [
                            Padding(
                              padding:
                                  const EdgeInsets
                                      .fromLTRB(
                                16,
                                8,
                                16,
                                12,
                              ),
                              child:
                                  TextField(
                                onChanged:
                                    (value) {
                                  setState(() {
                                    _searchQuery =
                                        value;
                                    _applySearch();
                                  });
                                },
                                style:
                                    TextStyle(
                                  color:
                                      colors.onSurface,
                                ),
                                decoration:
                                    InputDecoration(
                                  hintText:
                                      'Search documents...',
                                  hintStyle:
                                      TextStyle(
                                    color:
                                        colors.onSurfaceVariant,
                                  ),
                                  prefixIcon:
                                      Icon(
                                    Icons
                                        .search_rounded,
                                    color:
                                        colors.primary,
                                  ),
                                  suffixIcon:
                                      _searchQuery
                                              .isNotEmpty
                                          ? IconButton(
                                              tooltip:
                                                  'Clear search',
                                              onPressed:
                                                  () {
                                                setState(() {
                                                  _searchQuery =
                                                      '';
                                                  _applySearch();
                                                });
                                              },
                                              icon:
                                                  Icon(
                                                Icons
                                                    .close_rounded,
                                                color:
                                                    colors.onSurfaceVariant,
                                              ),
                                            )
                                          : null,
                                  filled: true,
                                  fillColor:
                                      colors.surface,
                                  border:
                                      OutlineInputBorder(
                                    borderRadius:
                                        BorderRadius
                                            .circular(
                                      16,
                                    ),
                                    borderSide:
                                        BorderSide
                                            .none,
                                  ),
                                  enabledBorder:
                                      OutlineInputBorder(
                                    borderRadius:
                                        BorderRadius
                                            .circular(
                                      16,
                                    ),
                                    borderSide:
                                        BorderSide
                                            .none,
                                  ),
                                  focusedBorder:
                                      OutlineInputBorder(
                                    borderRadius:
                                        BorderRadius
                                            .circular(
                                      16,
                                    ),
                                    borderSide:
                                        BorderSide(
                                      color:
                                          colors.primary,
                                      width:
                                          1.5,
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            Expanded(
                              child:
                                  ListView.builder(
                                physics:
                                    const AlwaysScrollableScrollPhysics(),
                                padding:
                                    const EdgeInsets
                                        .fromLTRB(
                                  16,
                                  0,
                                  16,
                                  24,
                                ),
                                itemCount:
                                    _filteredDocuments
                                        .length,
                                itemBuilder:
                                    (
                                  context,
                                  index,
                                ) {
                                  final document =
                                      _filteredDocuments[
                                          index];

                                  return _buildDocumentCard(
                                    context,
                                    document,
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
            ),
    );
  }
}