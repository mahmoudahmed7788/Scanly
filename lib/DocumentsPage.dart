import 'dart:io';
import 'dart:typed_data';

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
  void didChangeAppLifecycleState(
    AppLifecycleState state,
  ) {
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

      if (!mounted) return;

      setState(() {
        _documents = documents;
        _applySearch();
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _documents = [];
        _filteredDocuments = [];
        _isLoading = false;
      });
    }
  }

  void _applySearch() {
    final query = _searchQuery.trim().toLowerCase();

    if (query.isEmpty) {
      _filteredDocuments =
          List<DocumentModel>.from(_documents);
      return;
    }

    _filteredDocuments = _documents.where((document) {
      return document.title.toLowerCase().contains(query);
    }).toList();
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

    final Uint8List pdfBytes = await file.readAsBytes();

    if (pdfBytes.isEmpty) {
      _showMessage('PDF file is empty');
      return;
    }

    await context.push(
      '/pdf-preview',
      extra: {
        'pdfBytes': pdfBytes,
        'fileName': '${document.title}.pdf',
        'filePath': path,
        'imagePaths': <String>[],
      },
    );

    if (!mounted) return;

    await _loadDocuments();
  }

  Future<void> _toggleFavorite(
    DocumentModel document,
  ) async {
    await DocumentStorage.toggleFavorite(document);

    if (!mounted) return;

    setState(() {
      _documents = DocumentStorage.getDocuments();
      _applySearch();
    });
  }

  Future<void> _deleteDocument(
    DocumentModel document,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        final colors = Theme.of(context).colorScheme;

        return AlertDialog(
          backgroundColor: colors.surface,
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
                Navigator.pop(context, false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    await DocumentStorage.deleteDocument(document.id);

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

  String _formatDate(String value) {
    final date = DateTime.tryParse(value);

    if (date == null) {
      return '';
    }

    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();

    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');

    return '$day/$month/$year • $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: colors.onSurface,
        surfaceTintColor: Colors.transparent,
        title: Text(
          'My Documents',
          style: TextStyle(
            color: colors.onSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _loadDocuments,
            icon: Icon(
              Icons.refresh_rounded,
              color: colors.onSurface,
            ),
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: colors.primary,
              ),
            )
          : RefreshIndicator(
              color: colors.primary,
              onRefresh: _loadDocuments,
              child: _filteredDocuments.isEmpty
                  ? ListView(
                      physics:
                          const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(
                          height:
                              MediaQuery.of(context).size.height *
                                  0.25,
                        ),
                        Icon(
                          Icons.folder_open_rounded,
                          size: 72,
                          color: colors.primary,
                        ),
                        const SizedBox(height: 16),
                        Center(
                          child: Text(
                            'No PDF documents yet',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: colors.onSurface,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 30,
                          ),
                          child: Text(
                            'PDF files created by Scanly will appear here.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    )
                  : Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                            16,
                            8,
                            16,
                            12,
                          ),
                          child: TextField(
                            onChanged: (value) {
                              setState(() {
                                _searchQuery = value;
                                _applySearch();
                              });
                            },
                            style: TextStyle(
                              color: colors.onSurface,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Search documents...',
                              hintStyle: TextStyle(
                                color:
                                    colors.onSurfaceVariant,
                              ),
                              prefixIcon: Icon(
                                Icons.search_rounded,
                                color: colors.primary,
                              ),
                              filled: true,
                              fillColor: colors.surface,
                              border: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: ListView.builder(
                            physics:
                                const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(
                              16,
                              0,
                              16,
                              24,
                            ),
                            itemCount:
                                _filteredDocuments.length,
                            itemBuilder: (context, index) {
                              final document =
                                  _filteredDocuments[index];

                              return Container(
                                margin: const EdgeInsets.only(
                                  bottom: 12,
                                ),
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
                                        Container(
                                          width: 56,
                                          height: 56,
                                          decoration:
                                              BoxDecoration(
                                            borderRadius:
                                                BorderRadius
                                                    .circular(16),
                                            color: colors
                                                .primaryContainer,
                                          ),
                                          child: Icon(
                                            Icons
                                                .picture_as_pdf_rounded,
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
                                                document.title,
                                                maxLines: 2,
                                                overflow:
                                                    TextOverflow
                                                        .ellipsis,
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight:
                                                      FontWeight
                                                          .w700,
                                                  color:
                                                      colors.onSurface,
                                                ),
                                              ),
                                              const SizedBox(
                                                height: 6,
                                              ),
                                              Text(
                                                _formatDate(
                                                  document.date,
                                                ),
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: colors
                                                      .onSurfaceVariant,
                                                ),
                                              ),
                                              const SizedBox(
                                                height: 4,
                                              ),
                                              Text(
                                                'PDF',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight:
                                                      FontWeight
                                                          .w700,
                                                  color:
                                                      colors.primary,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        IconButton(
                                          onPressed: () =>
                                              _toggleFavorite(
                                            document,
                                          ),
                                          icon: Icon(
                                            document.isFavorite
                                                ? Icons
                                                    .favorite_rounded
                                                : Icons
                                                    .favorite_border_rounded,
                                            color:
                                                document.isFavorite
                                                    ? colors.error
                                                    : colors.primary,
                                          ),
                                        ),
                                        PopupMenuButton<String>(
                                          icon: Icon(
                                            Icons
                                                .more_vert_rounded,
                                            color:
                                                colors.onSurface,
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
                                                      color: Colors.red,
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
                            },
                          ),
                        ),
                      ],
                    ),
            ),
    );
  }
}