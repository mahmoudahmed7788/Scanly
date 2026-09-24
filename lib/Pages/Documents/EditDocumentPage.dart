import 'package:flutter/material.dart';
import 'package:scanly/Core/DocumentStorage.dart';
import 'package:scanly/Models/DocumentModel.dart';

class EditDocumentPage extends StatefulWidget {
  final DocumentModel document;

  const EditDocumentPage({
    super.key,
    required this.document,
  });

  @override
  State<EditDocumentPage> createState() =>
      _EditDocumentPageState();
}

class _EditDocumentPageState
    extends State<EditDocumentPage> {
  late TextEditingController _titleController;

  late bool _isFavorite;

  final GlobalKey<FormState> _formKey =
      GlobalKey<FormState>();

  bool _isSaving = false;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();

    _titleController =
        TextEditingController(
      text: widget.document.title,
    );

    _isFavorite =
        widget.document.isFavorite;
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  // ============================================================
  // SAVE DOCUMENT
  // ============================================================

  Future<void> _saveDocument() async {
    if (_isSaving || _isDeleting) {
      return;
    }

    final form =
        _formKey.currentState;

    if (form == null) {
      return;
    }

    if (!form.validate()) {
      return;
    }

    FocusScope.of(context).unfocus();

    if (!mounted) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final updatedDocument =
          DocumentModel(
        id: widget.document.id,

        title:
            _titleController.text.trim(),

        date:
            widget.document.date,

        type:
            widget.document.type,

        filePath:
            widget.document.filePath,

        isFavorite:
            _isFavorite,

        // ======================================================
        // IMPORTANT
        // Keep PDF page images.
        // ======================================================

        imagePaths:
            List<String>.from(
          widget.document.imagePaths,
        ),

        // ======================================================
        // IMPORTANT
        // Keep Supabase storage path.
        // ======================================================

        storagePath:
            widget.document.storagePath,

        // ======================================================
        // Keep last opened date.
        // ======================================================

        lastOpened:
            widget.document.lastOpened,
      );

      await DocumentStorage.updateDocument(
        updatedDocument,
      );

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop(
        updatedDocument,
      );
    } catch (e) {
      debugPrint(
        'SAVE DOCUMENT ERROR: $e',
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            behavior:
                SnackBarBehavior.floating,
            content: Text(
              'Failed to save changes: $e',
            ),
          ),
        );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  // ============================================================
  // DELETE DOCUMENT
  // ============================================================

  Future<void> _deleteDocument() async {
    if (_isSaving || _isDeleting) {
      return;
    }

    FocusScope.of(context).unfocus();

    final confirmed =
        await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title:
              const Text(
            'Delete Document',
          ),
          content:
              const Text(
            'Are you sure you want to delete this document?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop(false);
              },
              child:
                  const Text(
                'Cancel',
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop(true);
              },
              child:
                  const Text(
                'Delete',
                style:
                    TextStyle(
                  color:
                      Colors.red,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _isDeleting = true;
    });

    try {
      await DocumentStorage.deleteDocument(
        widget.document.id,
      );

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop(
        'deleted',
      );
    } catch (e) {
      debugPrint(
        'DELETE DOCUMENT ERROR: $e',
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            behavior:
                SnackBarBehavior.floating,
            content: Text(
              'Failed to delete document: $e',
            ),
          ),
        );
    } finally {
      if (mounted) {
        setState(() {
          _isDeleting = false;
        });
      }
    }
  }

  // ============================================================
  // DOCUMENT ICON
  // ============================================================

  IconData _getIcon() {
    switch (
        widget.document.type.toLowerCase()) {
      case 'pdf':
        return Icons
            .picture_as_pdf_outlined;

      case 'image':
        return Icons.image_outlined;

      case 'text':
        return Icons
            .text_snippet_outlined;

      default:
        return Icons
            .description_outlined;
    }
  }

  // ============================================================
  // INFO ROW
  // ============================================================

  Widget _buildInfoRow({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 22,
        ),

        const SizedBox(
          width: 12,
        ),

        Expanded(
          child: Text(
            title,
            style:
                TextStyle(
              color:
                  Colors.grey.shade600,
            ),
          ),
        ),

        const SizedBox(
          width: 12,
        ),

        Flexible(
          child: Text(
            value,
            textAlign:
                TextAlign.end,
            maxLines: 2,
            overflow:
                TextOverflow.ellipsis,
            style:
                const TextStyle(
              fontWeight:
                  FontWeight.w600,
            ),
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
    final colors =
        Theme.of(context)
            .colorScheme;

    final isBusy =
        _isSaving || _isDeleting;

    return Scaffold(
      appBar: AppBar(
        title:
            const Text(
          'Edit Document',
          style:
              TextStyle(
            fontWeight:
                FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed:
                isBusy
                    ? null
                    : _saveDocument,
            tooltip:
                'Save',
            icon:
                _isSaving
                    ? const SizedBox(
                        width: 21,
                        height: 21,
                        child:
                            CircularProgressIndicator(
                          strokeWidth:
                              2,
                        ),
                      )
                    : const Icon(
                        Icons.check,
                      ),
          ),
        ],
      ),

      body:
          Form(
        key:
            _formKey,
        child:
            ListView(
          padding:
              const EdgeInsets.all(
            20,
          ),
          children: [
            // ==================================================
            // PREVIEW
            // ==================================================

            Container(
              height:
                  180,
              width:
                  double.infinity,
              decoration:
                  BoxDecoration(
                borderRadius:
                    BorderRadius.circular(
                  22,
                ),
                border:
                    Border.all(
                  color:
                      colors.outline.withValues(
                    alpha:
                        0.15,
                  ),
                ),
                color:
                    colors.surfaceContainerHighest,
              ),
              child:
                  Column(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                children: [
                  Icon(
                    _getIcon(),
                    size:
                        65,
                    color:
                        colors.primary,
                  ),

                  const SizedBox(
                    height:
                        12,
                  ),

                  Text(
                    widget.document.type
                        .toUpperCase(),
                    style:
                        TextStyle(
                      fontWeight:
                          FontWeight.w600,
                      color:
                          colors.onSurface
                              .withValues(
                        alpha:
                            0.65,
                      ),
                    ),
                  ),

                  if (widget.document
                      .imagePaths
                      .isNotEmpty) ...[
                    const SizedBox(
                      height:
                          8,
                    ),
                    Text(
                      '${widget.document.imagePaths.length} page'
                      '${widget.document.imagePaths.length == 1 ? '' : 's'}',
                      style:
                          TextStyle(
                        fontSize:
                            12,
                        color:
                            colors.onSurface
                                .withValues(
                          alpha:
                              0.55,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(
              height:
                  30,
            ),

            // ==================================================
            // DOCUMENT NAME
            // ==================================================

            const Text(
              'Document Name',
              style:
                  TextStyle(
                fontSize:
                    15,
                fontWeight:
                    FontWeight.w600,
              ),
            ),

            const SizedBox(
              height:
                  10,
            ),

            TextFormField(
              controller:
                  _titleController,
              enabled:
                  !isBusy,
              textInputAction:
                  TextInputAction.done,
              decoration:
                  InputDecoration(
                hintText:
                    'Enter document name',
                prefixIcon:
                    const Icon(
                  Icons
                      .description_outlined,
                ),
                border:
                    OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(
                    16,
                  ),
                ),
              ),
              validator:
                  (value) {
                if (value == null ||
                    value.trim().isEmpty) {
                  return 'Please enter a document name';
                }

                if (value.trim().length <
                    2) {
                  return 'Document name is too short';
                }

                return null;
              },
            ),

            const SizedBox(
              height:
                  25,
            ),

            // ==================================================
            // FAVORITE
            // ==================================================

            Container(
              decoration:
                  BoxDecoration(
                borderRadius:
                    BorderRadius.circular(
                  18,
                ),
                border:
                    Border.all(
                  color:
                      colors.outline.withValues(
                    alpha:
                        0.15,
                  ),
                ),
              ),
              child:
                  SwitchListTile(
                value:
                    _isFavorite,
                onChanged:
                    isBusy
                        ? null
                        : (value) {
                            setState(() {
                              _isFavorite =
                                  value;
                            });
                          },
                title:
                    const Text(
                  'Favorite',
                  style:
                      TextStyle(
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),
                subtitle:
                    const Text(
                  'Add this document to your favorites',
                ),
                secondary:
                    Icon(
                  _isFavorite
                      ? Icons.favorite
                      : Icons
                          .favorite_border,
                ),
              ),
            ),

            const SizedBox(
              height:
                  25,
            ),

            // ==================================================
            // INFORMATION
            // ==================================================

            const Text(
              'Information',
              style:
                  TextStyle(
                fontSize:
                    15,
                fontWeight:
                    FontWeight.w600,
              ),
            ),

            const SizedBox(
              height:
                  10,
            ),

            Container(
              padding:
                  const EdgeInsets.all(
                18,
              ),
              decoration:
                  BoxDecoration(
                borderRadius:
                    BorderRadius.circular(
                  18,
                ),
                border:
                    Border.all(
                  color:
                      colors.outline.withValues(
                    alpha:
                        0.15,
                  ),
                ),
              ),
              child:
                  Column(
                children: [
                  _buildInfoRow(
                    icon:
                        Icons
                            .insert_drive_file_outlined,
                    title:
                        'Type',
                    value:
                        widget.document.type
                            .toUpperCase(),
                  ),

                  const SizedBox(
                    height:
                        16,
                  ),

                  _buildInfoRow(
                    icon:
                        Icons
                            .calendar_today_outlined,
                    title:
                        'Created',
                    value:
                        widget.document.date,
                  ),

                  if (widget.document
                      .imagePaths
                      .isNotEmpty) ...[
                    const SizedBox(
                      height:
                          16,
                    ),

                    _buildInfoRow(
                      icon:
                          Icons
                              .collections_outlined,
                      title:
                          'Pages',
                      value:
                          '${widget.document.imagePaths.length}',
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(
              height:
                  35,
            ),

            // ==================================================
            // SAVE BUTTON
            // ==================================================

            SizedBox(
              height:
                  55,
              child:
                  ElevatedButton(
                onPressed:
                    isBusy
                        ? null
                        : _saveDocument,
                style:
                    ElevatedButton.styleFrom(
                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(
                      16,
                    ),
                  ),
                ),
                child:
                    _isSaving
                        ? const SizedBox(
                            width:
                                22,
                            height:
                                22,
                            child:
                                CircularProgressIndicator(
                              strokeWidth:
                                  2,
                            ),
                          )
                        : const Text(
                            'Save Changes',
                            style:
                                TextStyle(
                              fontSize:
                                  16,
                              fontWeight:
                                  FontWeight.w600,
                            ),
                          ),
              ),
            ),

            const SizedBox(
              height:
                  15,
            ),

            // ==================================================
            // DELETE
            // ==================================================

            SizedBox(
              height:
                  50,
              child:
                  TextButton.icon(
                onPressed:
                    isBusy
                        ? null
                        : _deleteDocument,
                icon:
                    _isDeleting
                        ? const SizedBox(
                            width:
                                18,
                            height:
                                18,
                            child:
                                CircularProgressIndicator(
                              strokeWidth:
                                  2,
                              color:
                                  Colors.red,
                            ),
                          )
                        : const Icon(
                            Icons
                                .delete_outline,
                            color:
                                Colors.red,
                          ),
                label:
                    const Text(
                  'Delete Document',
                  style:
                      TextStyle(
                    color:
                        Colors.red,
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),
              ),
            ),

            const SizedBox(
              height:
                  20,
            ),
          ],
        ),
      ),
    );
  }
}