import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:scanly/Core/DocumentStorage.dart';
import 'package:scanly/Models/DocumentModel.dart';
import 'package:scanly/Widgets/Documents/DocumentCard.dart';
import 'package:scanly/Widgets/Documents/document_utils.dart';
import 'package:scanly/Widgets/Documents/documents_empty_state.dart';

class DocumentsPage extends StatefulWidget {
  const DocumentsPage({
    super.key,
  });

  @override
  State<DocumentsPage> createState() =>
      _DocumentsPageState();
}

class _DocumentsPageState
    extends State<DocumentsPage>
    with WidgetsBindingObserver {
  // =========================================================
  // STATE
  // =========================================================

  List<DocumentModel> _documents = [];

  List<DocumentModel> _filteredDocuments = [];

  bool _isLoading = true;

  String _searchQuery = '';

  // =========================================================
  // INIT
  // =========================================================

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(
      this,
    );

    _loadDocuments();
  }

  // =========================================================
  // DISPOSE
  // =========================================================

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(
      this,
    );

    super.dispose();
  }

  // =========================================================
  // APP LIFECYCLE
  // =========================================================

  @override
  void didChangeAppLifecycleState(
    AppLifecycleState state,
  ) {
    if (state ==
        AppLifecycleState.resumed) {
      _loadDocuments();
    }
  }

  // =========================================================
  // LOAD DOCUMENTS
  // =========================================================
  //
  // IMPORTANT:
  //
  // We intentionally DO NOT call:
  //
  // DocumentStorage.syncFromDisk()
  //
  // here.
  //
  // Documents created by Scanly are already stored
  // inside DocumentStorage / Hive.
  //
  // Reading Hive directly makes newly-created
  // documents appear immediately.
  //
  // This also prevents a slow disk scan from making
  // the page look empty or removing a document whose
  // cloud upload is still running.
  // =========================================================

  Future<void> _loadDocuments() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final documents =
          DocumentStorage.getDocuments();

      DocumentUtils.sortDocuments(
        documents,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _documents = documents;

        _filteredDocuments =
            DocumentUtils.filterDocuments(
          documents: _documents,
          query: _searchQuery,
        );

        _isLoading = false;
      });
    } catch (e) {
      debugPrint(
        'Documents loading error: $e',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _documents = [];

        _filteredDocuments = [];

        _isLoading = false;
      });
    }
  }

  // =========================================================
  // SEARCH
  // =========================================================

  void _updateSearch(
    String value,
  ) {
    setState(() {
      _searchQuery = value;

      _filteredDocuments =
          DocumentUtils.filterDocuments(
        documents: _documents,
        query: _searchQuery,
      );
    });
  }

  // =========================================================
  // CLEAR SEARCH
  // =========================================================

  void _clearSearch() {
    _updateSearch('');
  }

  // =========================================================
  // OPEN DOCUMENT
  // =========================================================

  Future<void> _openDocument(
    DocumentModel document,
  ) async {
    if (!mounted) {
      return;
    }

    await context.push(
      '/pdf-preview',
      extra: document,
    );

    if (!mounted) {
      return;
    }

    // -------------------------------------------------------
    // Reload after returning from Preview.
    //
    // This catches:
    // - edited PDFs
    // - renamed PDFs
    // - favorite changes
    // - updated document metadata
    // -------------------------------------------------------

    await _loadDocuments();
  }

  // =========================================================
  // TOGGLE FAVORITE
  // =========================================================

  Future<void> _toggleFavorite(
    DocumentModel document,
  ) async {
    await DocumentStorage.toggleFavorite(
      document,
    );

    if (!mounted) {
      return;
    }

    final documents =
        DocumentStorage.getDocuments();

    DocumentUtils.sortDocuments(
      documents,
    );

    setState(() {
      _documents = documents;

      _filteredDocuments =
          DocumentUtils.filterDocuments(
        documents: _documents,
        query: _searchQuery,
      );
    });
  }

  // =========================================================
  // DELETE DOCUMENT
  // =========================================================

  Future<void> _deleteDocument(
    DocumentModel document,
  ) async {
    final confirmed =
        await _showDeleteDialog(
      document,
    );

    if (confirmed != true) {
      return;
    }

    await DocumentStorage.deleteDocument(
      document.id,
    );

    if (!mounted) {
      return;
    }

    _showMessage(
      'Document deleted',
    );

    await _loadDocuments();
  }

  // =========================================================
  // DELETE CONFIRMATION
  // =========================================================

  Future<bool?> _showDeleteDialog(
    DocumentModel document,
  ) {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        final colors =
            Theme.of(context)
                .colorScheme;

        return AlertDialog(
          backgroundColor:
              colors.surface,

          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(
              20,
            ),
          ),

          title: Text(
            'Delete Document',
            style: TextStyle(
              color:
                  colors.onSurface,
              fontWeight:
                  FontWeight.w700,
            ),
          ),

          content: Text(
            'Are you sure you want to delete "${document.title}"?',
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
                  const Text(
                'Cancel',
              ),
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
                    .delete_outline_rounded,
              ),

              label:
                  const Text(
                'Delete',
              ),
            ),
          ],
        );
      },
    );
  }

  // =========================================================
  // MESSAGE
  // =========================================================

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

          content:
              Text(message),
        ),
      );
  }

  // =========================================================
  // SEARCH FIELD
  // =========================================================

  Widget _buildSearchField(
    BuildContext context,
  ) {
    final colors =
        Theme.of(context)
            .colorScheme;

    return Padding(
      padding:
          const EdgeInsets.fromLTRB(
        16,
        8,
        16,
        12,
      ),

      child: TextField(
        onChanged:
            _updateSearch,

        style: TextStyle(
          color:
              colors.onSurface,
        ),

        decoration:
            InputDecoration(
          hintText:
              'Search documents...',

          hintStyle: TextStyle(
            color:
                colors.onSurfaceVariant,
          ),

          prefixIcon: Icon(
            Icons.search_rounded,
            color:
                colors.primary,
          ),

          suffixIcon:
              _searchQuery.isNotEmpty
                  ? IconButton(
                      tooltip:
                          'Clear search',

                      onPressed:
                          _clearSearch,

                      icon: Icon(
                        Icons
                            .close_rounded,
                        color: colors
                            .onSurfaceVariant,
                      ),
                    )
                  : null,

          filled: true,

          fillColor:
              colors.surface,

          border:
              OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(
              16,
            ),

            borderSide:
                BorderSide.none,
          ),

          enabledBorder:
              OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(
              16,
            ),

            borderSide:
                BorderSide.none,
          ),

          focusedBorder:
              OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(
              16,
            ),

            borderSide:
                BorderSide(
              color:
                  colors.primary,
              width: 1.5,
            ),
          ),
        ),
      ),
    );
  }

  // =========================================================
  // DOCUMENT LIST
  // =========================================================

  Widget _buildDocumentList() {
    return ListView.builder(
      physics:
          const AlwaysScrollableScrollPhysics(),

      padding:
          const EdgeInsets.fromLTRB(
        16,
        0,
        16,
        24,
      ),

      itemCount:
          _filteredDocuments.length,

      itemBuilder:
          (context, index) {
        final document =
            _filteredDocuments[index];

        return DocumentCard(
          document: document,

          onOpen: () =>
              _openDocument(
            document,
          ),

          onToggleFavorite: () =>
              _toggleFavorite(
            document,
          ),

          onDelete: () =>
              _deleteDocument(
            document,
          ),

          onTap: () =>
              _openDocument(
            document,
          ),
        );
      },
    );
  }

  // =========================================================
  // BUILD
  // =========================================================

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

      // =====================================================
      // APP BAR
      // =====================================================

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
            tooltip:
                'Refresh',

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

      // =====================================================
      // BODY
      // =====================================================

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
                  _filteredDocuments
                          .isEmpty
                      ? DocumentsEmptyState(
                          hasSearch:
                              _searchQuery
                                  .trim()
                                  .isNotEmpty,
                        )
                      : Column(
                          children: [
                            // ---------------------------------
                            // SEARCH
                            // ---------------------------------

                            _buildSearchField(
                              context,
                            ),

                            // ---------------------------------
                            // DOCUMENTS
                            // ---------------------------------

                            Expanded(
                              child:
                                  _buildDocumentList(),
                            ),
                          ],
                        ),
            ),
    );
  }
}