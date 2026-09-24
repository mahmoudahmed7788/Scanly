import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdfx/pdfx.dart';
import 'package:scanly/Core/DocumentStorage.dart';
import 'package:scanly/Core/Scanly_Items.dart';
import 'package:scanly/Core/SupabaseStorageService.dart';
import 'package:scanly/Models/DocumentModel.dart';
import 'package:scanly/Pages/Pdf/PDFEditingPage.dart';
import 'package:scanly/core/ScanlyActivityService.dart';



import 'package:share_plus/share_plus.dart';

class PDFPreviewPage extends StatefulWidget {
  final Uint8List pdfBytes;
  final String fileName;
  final String? filePath;
  final List<String> imagePaths;
  final DocumentModel document;

  const PDFPreviewPage({
    super.key,
    required this.pdfBytes,
    required this.fileName,
    this.filePath,
    this.imagePaths = const [],
    required this.document,
  });

  @override
  State<PDFPreviewPage> createState() =>
      _PDFPreviewPageState();
}

class _PDFPreviewPageState
    extends State<PDFPreviewPage> {
  late Uint8List _pdfBytes;
  late String _fileName;
  late List<String> _imagePaths;

  String? _currentFilePath;

  PdfControllerPinch? _pdfController;

  bool _loadingPdf = true;
  bool _saving = false;
  bool _sharing = false;
  bool _editing = false;
  bool _isFavorite = false;

  String? _pdfError;

  @override
  void initState() {
    super.initState();

    _pdfBytes =
        Uint8List.fromList(
      widget.pdfBytes,
    );

    _fileName =
        widget.fileName.isNotEmpty
            ? widget.fileName
            : widget.document.title;

    _currentFilePath =
        widget.filePath ??
        widget.document.filePath;

    // IMPORTANT:
    //
    // If PDFPreviewPage receives imagePaths,
    // use them.
    //
    // Otherwise get them from DocumentModel.
    _imagePaths =
        widget.imagePaths.isNotEmpty
            ? List<String>.from(
                widget.imagePaths,
              )
            : List<String>.from(
                widget.document.imagePaths,
              );

    debugPrint(
      '========== PDF PREVIEW START ==========',
    );

    debugPrint(
      'DOCUMENT ID: ${widget.document.id}',
    );

    debugPrint(
      'FILE NAME: $_fileName',
    );

    debugPrint(
      'PDF BYTES: ${_pdfBytes.length}',
    );

    debugPrint(
      'LOCAL PATH: $_currentFilePath',
    );

    debugPrint(
      'STORAGE PATH: '
      '${widget.document.storagePath}',
    );

    debugPrint(
      'IMAGE PATHS: '
      '${_imagePaths.length}',
    );

    _initializePdf();
  }

  @override
  void dispose() {
    _pdfController?.dispose();
    super.dispose();
  }

  // ============================================================
  // PDF VALIDATION
  // ============================================================

  bool _hasPdfHeader(
    Uint8List bytes,
  ) {
    if (bytes.length < 5) {
      return false;
    }

    return bytes[0] == 0x25 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x44 &&
        bytes[3] == 0x46 &&
        bytes[4] == 0x2D;
  }

  bool _isValidPdfFile(
    File file,
  ) {
    try {
      if (!file.existsSync()) {
        return false;
      }

      if (file.lengthSync() < 5) {
        return false;
      }

      final raf =
          file.openSync();

      try {
        final header =
            raf.readSync(5);

        return header.length >= 5 &&
            header[0] == 0x25 &&
            header[1] == 0x50 &&
            header[2] == 0x44 &&
            header[3] == 0x46 &&
            header[4] == 0x2D;
      } finally {
        raf.closeSync();
      }
    } catch (e) {
      debugPrint(
        'PDF VALIDATION ERROR: $e',
      );

      return false;
    }
  }

  // ============================================================
  // INITIALIZE PDF
  // ============================================================

  Future<void> _initializePdf() async {
    try {
      setState(() {
        _loadingPdf = true;
        _pdfError = null;
      });

      // --------------------------------------------------------
      // LOCAL FILE
      // --------------------------------------------------------

      if (_currentFilePath != null &&
          _currentFilePath!.isNotEmpty) {
        final file =
            File(
          _currentFilePath!,
        );

        if (await file.exists()) {
          if (_isValidPdfFile(file)) {
            debugPrint(
              'VALID LOCAL PDF FOUND.',
            );

            await _openPdfFromFile(
              file.path,
            );

            await _loadFavorite();

            return;
          }

          debugPrint(
            'LOCAL PDF EXISTS BUT IS INVALID.',
          );
        }
      }

      // --------------------------------------------------------
      // PDF BYTES
      // --------------------------------------------------------

      if (_pdfBytes.isNotEmpty &&
          _hasPdfHeader(
            _pdfBytes,
          )) {
        debugPrint(
          'VALID PDF BYTES FOUND.',
        );

        final path =
            await _writePdfBytesToLocalFile(
          _pdfBytes,
        );

        _currentFilePath =
            path;

        widget.document.filePath =
            path;

        await _openPdfFromFile(
          path,
        );

        await _loadFavorite();

        return;
      }

      // --------------------------------------------------------
      // SUPABASE
      // --------------------------------------------------------

      if (widget.document.storagePath != null &&
          widget.document.storagePath!.isNotEmpty) {
        await _downloadPdfFromCloud();

        if (_currentFilePath != null &&
            _currentFilePath!.isNotEmpty) {
          final file =
              File(
            _currentFilePath!,
          );

          if (await file.exists() &&
              _isValidPdfFile(file)) {
            await _openPdfFromFile(
              file.path,
            );

            await _loadFavorite();

            return;
          }
        }
      }

      throw Exception(
        'No valid PDF found.',
      );
    } catch (e, stackTrace) {
      debugPrint(
        'PDF INITIALIZATION ERROR: $e',
      );

      debugPrint(
        stackTrace.toString(),
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _loadingPdf = false;
        _pdfError =
            'The PDF could not be opened.';
      });
    }
  }

  // ============================================================
  // OPEN PDF
  // ============================================================

  Future<void> _openPdfFromFile(
    String path,
  ) async {
    debugPrint(
      'OPENING PDF:',
    );

    debugPrint(
      path,
    );

    final file =
        File(path);

    if (!await file.exists()) {
      throw Exception(
        'PDF file does not exist.',
      );
    }

    if (!_isValidPdfFile(file)) {
      throw Exception(
        'Invalid PDF file.',
      );
    }

    final controller =
        PdfControllerPinch(
      document:
          PdfDocument.openFile(
        path,
      ),
    );

    if (!mounted) {
      controller.dispose();
      return;
    }

    final oldController =
        _pdfController;

    setState(() {
      _pdfController =
          controller;

      _loadingPdf = false;

      _pdfError = null;
    });

    oldController?.dispose();

    debugPrint(
      'PDF CONTROLLER CREATED.',
    );
  }

  // ============================================================
  // WRITE PDF
  // ============================================================

  Future<String>
      _writePdfBytesToLocalFile(
    Uint8List bytes,
  ) async {
    if (!_hasPdfHeader(
      bytes,
    )) {
      throw Exception(
        'Invalid PDF bytes.',
      );
    }

    final directory =
        await DocumentStorage
            .getDocumentsDirectory();

    final cleanName =
        _cleanName(
      _fileName,
    );

    String path;

    if (_currentFilePath != null &&
        _currentFilePath!.isNotEmpty) {
      final current =
          File(
        _currentFilePath!,
      );

      if (current.parent.path ==
          directory.path) {
        path =
            current.path;
      } else {
        path =
            '${directory.path}/'
            '$cleanName.pdf';
      }
    } else {
      path =
          '${directory.path}/'
          '$cleanName.pdf';
    }

    final file =
        File(path);

    await file.writeAsBytes(
      bytes,
      flush: true,
    );

    if (!_isValidPdfFile(
      file,
    )) {
      throw Exception(
        'PDF write verification failed.',
      );
    }

    return path;
  }

  // ============================================================
  // DOWNLOAD FROM SUPABASE
  // ============================================================

  Future<void>
      _downloadPdfFromCloud() async {
    final storagePath =
        widget.document.storagePath;

    if (storagePath == null ||
        storagePath.isEmpty) {
      throw Exception(
        'No cloud storage path.',
      );
    }

    if (mounted) {
      setState(() {
        _loadingPdf = true;
      });
    }

    try {
      final bytes =
          await SupabaseStorageService
              .downloadFile(
        storagePath,
      );

      if (bytes.isEmpty ||
          !_hasPdfHeader(
            bytes,
          )) {
        throw Exception(
          'Downloaded file is not a valid PDF.',
        );
      }

      _pdfBytes =
          Uint8List.fromList(
        bytes,
      );

      final localPath =
          await _writePdfBytesToLocalFile(
        _pdfBytes,
      );

      _currentFilePath =
          localPath;

      widget.document.filePath =
          localPath;

      debugPrint(
        'PDF DOWNLOADED TO:',
      );

      debugPrint(
        localPath,
      );
    } finally {
      if (mounted) {
        setState(() {
          _loadingPdf = false;
        });
      }
    }
  }

  // ============================================================
  // CLEAN NAME
  // ============================================================

  String _cleanName(
    String value,
  ) {
    var name =
        value.trim();

    if (name.isEmpty) {
      name =
          'Scanly Document';
    }

    name =
        name.replaceAll(
      RegExp(
        r'[\\/:*?"<>|]',
      ),
      '_',
    );

    if (name
        .toLowerCase()
        .endsWith('.pdf')) {
      name =
          name.substring(
        0,
        name.length - 4,
      );
    }

    if (name.trim().isEmpty) {
      name =
          'Scanly Document';
    }

    return name.trim();
  }

  // ============================================================
  // FAVORITE
  // ============================================================

  String _pdfId() {
    return 'pdf_${widget.document.id}';
  }

  Future<void> _loadFavorite() async {
    final favorite =
        ScanlyActivityService
            .isFavorite(
      _pdfId(),
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _isFavorite =
          favorite;
    });
  }

  // ============================================================
  // ENSURE PDF
  // ============================================================

  Future<String>
      _ensurePdfFile() async {
    if (_currentFilePath != null &&
        _currentFilePath!.isNotEmpty) {
      final file =
          File(
        _currentFilePath!,
      );

      if (await file.exists() &&
          _isValidPdfFile(
            file,
          )) {
        return file.path;
      }
    }

    if (_pdfBytes.isNotEmpty &&
        _hasPdfHeader(
          _pdfBytes,
        )) {
      final path =
          await _writePdfBytesToLocalFile(
        _pdfBytes,
      );

      _currentFilePath =
          path;

      widget.document.filePath =
          path;

      return path;
    }

    if (widget.document.storagePath != null &&
        widget.document.storagePath!.isNotEmpty) {
      await _downloadPdfFromCloud();

      if (_currentFilePath != null &&
          _currentFilePath!.isNotEmpty) {
        return _currentFilePath!;
      }
    }

    throw Exception(
      'No valid PDF available.',
    );
  }

  // ============================================================
  // ACTIVITY ITEM
  // ============================================================

  ScanlyItem _createItem(
    String path,
  ) {
    return ScanlyItem(
      id:
          _pdfId(),
      title:
          widget.document.title.isNotEmpty
              ? widget.document.title
              : 'PDF Document',
      subtitle:
          _fileName,
      type:
          'pdf',
      route:
          '/pdf-preview',
      data:
          path,
      createdAt:
          DateTime.now()
              .millisecondsSinceEpoch,
    );
  }

  Future<void> _updateRecent() async {
    final path =
        await _ensurePdfFile();

    await ScanlyActivityService
        .addRecent(
      _createItem(path),
    );
  }

  // ============================================================
  // SAVE
  // ============================================================

  Future<void> _savePdf() async {
    if (_saving) {
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      final path =
          await _ensurePdfFile();

      widget.document.filePath =
          path;

      await DocumentStorage
          .updateDocument(
        widget.document,
      );

      await _updateRecent();

      if (!mounted) {
        return;
      }

      _showMessage(
        'PDF saved successfully',
        Icons.check_circle_outline_rounded,
      );
    } catch (e) {
      debugPrint(
        'SAVE PDF ERROR: $e',
      );

      if (!mounted) {
        return;
      }

      _showMessage(
        'Failed to save PDF',
        Icons.error_outline_rounded,
      );
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  // ============================================================
  // SHARE
  // ============================================================

  Future<File>
      _createShareFile() async {
    final path =
        await _ensurePdfFile();

    final source =
        File(path);

    if (!await source.exists()) {
      throw Exception(
        'PDF file does not exist.',
      );
    }

    final directory =
        await getTemporaryDirectory();

    final cleanName =
        _cleanName(
      _fileName,
    );

    final file =
        File(
      '${directory.path}/$cleanName.pdf',
    );

    await source.copy(
      file.path,
    );

    return file;
  }

  Future<void> _sharePdf() async {
    if (_sharing) {
      return;
    }

    setState(() {
      _sharing = true;
    });

    try {
      final file =
          await _createShareFile();

      await Share.shareXFiles(
        [
          XFile(
            file.path,
            mimeType:
                'application/pdf',
          ),
        ],
        text:
            'Shared from Scanly',
      );
    } catch (e) {
      debugPrint(
        'SHARE PDF ERROR: $e',
      );

      if (!mounted) {
        return;
      }

      _showMessage(
        'Failed to share PDF',
        Icons.error_outline_rounded,
      );
    } finally {
      if (mounted) {
        setState(() {
          _sharing = false;
        });
      }
    }
  }

  // ============================================================
  // FAVORITE
  // ============================================================

  Future<void>
      _toggleFavorite() async {
    try {
      final path =
          await _ensurePdfFile();

      final item =
          _createItem(path);

      await ScanlyActivityService
          .toggleFavorite(
        item,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _isFavorite =
            ScanlyActivityService
                .isFavorite(
          item.id,
        );
      });
    } catch (e) {
      debugPrint(
        'FAVORITE ERROR: $e',
      );

      if (!mounted) {
        return;
      }

      _showMessage(
        'Failed to update favorite',
        Icons.error_outline_rounded,
      );
    }
  }

  // ============================================================
  // EDIT
  // ============================================================

  Future<void> _editPdf() async {
    if (_editing) {
      return;
    }

    debugPrint(
      'EDIT BUTTON PRESSED',
    );

    debugPrint(
      'IMAGE PATHS COUNT: '
      '${_imagePaths.length}',
    );

    // ----------------------------------------------------------
    // Verify images.
    // ----------------------------------------------------------

    final validImages =
        <String>[];

    for (final path
        in _imagePaths) {
      if (path.isNotEmpty &&
          await File(path)
              .exists()) {
        validImages.add(
          path,
        );
      }
    }

    _imagePaths =
        validImages;

    debugPrint(
      'VALID IMAGE PATHS: '
      '${_imagePaths.length}',
    );

    if (_imagePaths.isEmpty) {
      _showMessage(
        'No page images are available for editing.',
        Icons.image_not_supported_outlined,
      );

      return;
    }

    setState(() {
      _editing = true;
    });

    try {
      final oldPath =
          _currentFilePath;

      final wasFavorite =
          ScanlyActivityService
              .isFavorite(
        _pdfId(),
      );

      final result =
          await Navigator.push<
              Map<String, dynamic>>(
        context,
        MaterialPageRoute(
          builder: (_) =>
              PDFEditPage(
            pdfBytes:
                _pdfBytes,
            fileName:
                _fileName,
            pageImagePaths:
                List<String>.from(
              _imagePaths,
            ),
          ),
        ),
      );

      if (result == null ||
          !mounted) {
        return;
      }

      final newBytes =
          result['pdfBytes'];

      final newImages =
          result['imagePaths'];

      final newName =
          result['fileName'];

      if (newBytes is! Uint8List) {
        _showMessage(
          'Invalid edited PDF',
          Icons.error_outline_rounded,
        );

        return;
      }

      if (!_hasPdfHeader(
        newBytes,
      )) {
        _showMessage(
          'Edited PDF is invalid',
          Icons.error_outline_rounded,
        );

        return;
      }

      final updatedImages =
          <String>[];

      if (newImages is List) {
        for (final path
            in newImages) {
          if (path is String &&
              path.isNotEmpty &&
              await File(path)
                  .exists()) {
            updatedImages.add(
              path,
            );
          }
        }
      }

      if (updatedImages.isEmpty) {
        _showMessage(
          'Edited page images were not found.',
          Icons.image_not_supported_outlined,
        );

        return;
      }

      setState(() {
        _pdfBytes =
            Uint8List.fromList(
          newBytes,
        );

        _imagePaths =
            updatedImages;

        widget.document.imagePaths =
            List<String>.from(
          updatedImages,
        );

        if (newName is String &&
            newName.isNotEmpty) {
          _fileName =
              newName;
        }
      });

      await _pdfController?.loadDocument(
        PdfDocument.openData(
          _pdfBytes,
        ),
      );

      await _saveEditedPdf(
        oldPath:
            oldPath,
        wasFavorite:
            wasFavorite,
      );
    } catch (e, stackTrace) {
      debugPrint(
        'EDIT PDF ERROR: $e',
      );

      debugPrint(
        stackTrace.toString(),
      );

      if (!mounted) {
        return;
      }

      _showMessage(
        'Failed to edit PDF',
        Icons.error_outline_rounded,
      );
    } finally {
      if (mounted) {
        setState(() {
          _editing = false;
        });
      }
    }
  }

  // ============================================================
  // SAVE EDITED PDF
  // ============================================================

  Future<void> _saveEditedPdf({
    required String? oldPath,
    required bool wasFavorite,
  }) async {
    final directory =
        await DocumentStorage
            .getDocumentsDirectory();

    final cleanName =
        _cleanName(
      _fileName,
    );

    String path;

    if (oldPath != null &&
        oldPath.isNotEmpty) {
      path =
          oldPath;
    } else {
      path =
          '${directory.path}/'
          '$cleanName.pdf';
    }

    final file =
        File(path);

    await file.writeAsBytes(
      _pdfBytes,
      flush: true,
    );

    if (!_isValidPdfFile(
      file,
    )) {
      throw Exception(
        'Edited PDF is invalid.',
      );
    }

    _currentFilePath =
        path;

    widget.document.filePath =
        path;

    widget.document.title =
        cleanName;

    widget.document.imagePaths =
        List<String>.from(
      _imagePaths,
    );

    // The existing storagePath belongs
    // to the old PDF. Clear it so the
    // updated PDF can be uploaded again.
    widget.document.storagePath =
        null;

    await DocumentStorage
        .updateDocument(
      widget.document,
    );

    await _updateRecent();

    if (wasFavorite) {
      await ScanlyActivityService
          .addFavorite(
        _createItem(path),
      );
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _isFavorite =
          wasFavorite;
    });

    _showMessage(
      'PDF updated successfully',
      Icons.check_circle_outline_rounded,
    );
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(
    String message,
    IconData icon,
  ) {
    if (!mounted) {
      return;
    }

    final colors =
        Theme.of(context)
            .colorScheme;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior:
              SnackBarBehavior.floating,
          backgroundColor:
              colors.inverseSurface,
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(
              16,
            ),
          ),
          content:
              Row(
            children: [
              Icon(
                icon,
                color:
                    colors.onInverseSurface,
              ),
              const SizedBox(
                width:
                    10,
              ),
              Expanded(
                child:
                    Text(
                  message,
                  style:
                      TextStyle(
                    color:
                        colors.onInverseSurface,
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
  }

  // ============================================================
  // PREVIEW
  // ============================================================

  Widget _buildPdfPreview(
    ColorScheme colors,
  ) {
    if (_loadingPdf) {
      return Container(
        margin:
            const EdgeInsets.fromLTRB(
          10,
          0,
          10,
          10,
        ),
        decoration:
            BoxDecoration(
          color:
              colors.surfaceContainerHighest,
          borderRadius:
              BorderRadius.circular(
            14,
          ),
        ),
        child:
            const Center(
          child:
              CircularProgressIndicator(),
        ),
      );
    }

    if (_pdfError != null ||
        _pdfController == null) {
      return Container(
        margin:
            const EdgeInsets.fromLTRB(
          10,
          0,
          10,
          10,
        ),
        decoration:
            BoxDecoration(
          color:
              colors.surfaceContainerHighest,
          borderRadius:
              BorderRadius.circular(
            14,
          ),
        ),
        child:
            Center(
          child:
              Padding(
            padding:
                const EdgeInsets.all(
              24,
            ),
            child:
                Column(
              mainAxisAlignment:
                  MainAxisAlignment
                      .center,
              children: [
                Icon(
                  Icons
                      .picture_as_pdf_outlined,
                  size:
                      56,
                  color:
                      colors.error,
                ),
                const SizedBox(
                  height:
                      14,
                ),
                Text(
                  'PDF is not available',
                  style:
                      TextStyle(
                    fontSize:
                        18,
                    fontWeight:
                        FontWeight.w800,
                    color:
                        colors.onSurface,
                  ),
                ),
                const SizedBox(
                  height:
                      8,
                ),
                Text(
                  _pdfError ??
                      'Could not open this PDF.',
                  textAlign:
                      TextAlign.center,
                  style:
                      TextStyle(
                    color:
                        colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      margin:
          const EdgeInsets.fromLTRB(
        10,
        0,
        10,
        10,
      ),
      decoration:
          BoxDecoration(
        color:
            colors.surfaceContainerHighest,
        borderRadius:
            BorderRadius.circular(
          14,
        ),
      ),
      clipBehavior:
          Clip.antiAlias,
      child:
          PdfViewPinch(
        controller:
            _pdfController!,
        scrollDirection:
            Axis.vertical,
        backgroundDecoration:
            BoxDecoration(
          color:
              colors.surfaceContainerHighest,
        ),
        onDocumentLoaded:
            (document) {
          debugPrint(
            'PDF PREVIEW LOADED: '
            '${document.pagesCount} pages',
          );
        },
        onDocumentError:
            (error) {
          debugPrint(
            'PDF PREVIEW ERROR: $error',
          );

          if (mounted) {
            setState(() {
              _pdfError =
                  'PDF renderer could not read this file.';
            });
          }
        },
      ),
    );
  }

  // ============================================================
  // ACTIONS
  // ============================================================

  Widget _buildActions(
    ColorScheme colors,
  ) {
    return Container(
      margin:
          const EdgeInsets.fromLTRB(
        14,
        4,
        14,
        14,
      ),
      padding:
          const EdgeInsets.all(
        10,
      ),
      decoration:
          BoxDecoration(
        color:
            colors.surface,
        borderRadius:
            BorderRadius.circular(
          20,
        ),
        border:
            Border.all(
          color:
              colors.onSurface
                  .withValues(
            alpha:
                0.08,
          ),
        ),
      ),
      child:
          Row(
        children: [
          Expanded(
            child:
                _actionButton(
              colors:
                  colors,
              icon:
                  Icons.edit_rounded,
              label:
                  'Edit',
              onPressed:
                  _editing
                      ? null
                      : _editPdf,
              outlined:
                  true,
              loading:
                  _editing,
            ),
          ),
          const SizedBox(
            width:
                8,
          ),
          Expanded(
            child:
                _actionButton(
              colors:
                  colors,
              icon:
                  Icons.share_rounded,
              label:
                  'Share',
              onPressed:
                  _sharing
                      ? null
                      : _sharePdf,
              outlined:
                  true,
              loading:
                  _sharing,
            ),
          ),
          const SizedBox(
            width:
                8,
          ),
          Expanded(
            child:
                _actionButton(
              colors:
                  colors,
              icon:
                  Icons.save_rounded,
              label:
                  'Save',
              onPressed:
                  _saving
                      ? null
                      : _savePdf,
              outlined:
                  false,
              loading:
                  _saving,
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton({
    required ColorScheme colors,
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
    required bool outlined,
    required bool loading,
  }) {
    if (outlined) {
      return OutlinedButton(
        onPressed:
            onPressed,
        style:
            OutlinedButton.styleFrom(
          minimumSize:
              const Size(
            0,
            50,
          ),
          padding:
              const EdgeInsets
                  .symmetric(
            horizontal:
                8,
          ),
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(
              15,
            ),
          ),
        ),
        child:
            loading
                ? const SizedBox(
                    width:
                        20,
                    height:
                        20,
                    child:
                        CircularProgressIndicator(
                      strokeWidth:
                          2,
                    ),
                  )
                : Row(
                    mainAxisAlignment:
                        MainAxisAlignment
                            .center,
                    children: [
                      Icon(
                        icon,
                        size:
                            20,
                      ),
                      const SizedBox(
                        width:
                            6,
                      ),
                      Text(
                        label,
                        style:
                            const TextStyle(
                          fontWeight:
                              FontWeight
                                  .w800,
                        ),
                      ),
                    ],
                  ),
      );
    }

    return FilledButton(
      onPressed:
          onPressed,
      style:
          FilledButton.styleFrom(
        minimumSize:
            const Size(
          0,
          50,
        ),
        padding:
            const EdgeInsets
                .symmetric(
          horizontal:
              8,
        ),
        shape:
            RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(
            15,
          ),
        ),
      ),
      child:
          loading
              ? const SizedBox(
                  width:
                      20,
                  height:
                      20,
                  child:
                      CircularProgressIndicator(
                    strokeWidth:
                        2,
                    color:
                        Colors.white,
                  ),
                )
              : Row(
                  mainAxisAlignment:
                      MainAxisAlignment
                          .center,
                  children: [
                    Icon(
                      icon,
                      size:
                          20,
                    ),
                    const SizedBox(
                      width:
                          6,
                    ),
                    Text(
                      label,
                      style:
                          const TextStyle(
                        fontWeight:
                            FontWeight
                                .w800,
                      ),
                    ),
                  ],
                ),
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

    return Scaffold(
      backgroundColor:
          colors.surfaceContainerLowest,
      appBar:
          AppBar(
        leading:
            IconButton(
          onPressed: () {
            context.go(
              '/home',
            );
          },
          icon:
              const Icon(
            Icons.arrow_back_rounded,
          ),
        ),
        title:
            Text(
          _fileName,
          maxLines:
              1,
          overflow:
              TextOverflow.ellipsis,
          style:
              const TextStyle(
            fontWeight:
                FontWeight.w800,
          ),
        ),
        actions: [
          IconButton(
            tooltip:
                'Favorite',
            onPressed:
                _toggleFavorite,
            icon:
                Icon(
              _isFavorite
                  ? Icons.star_rounded
                  : Icons
                      .star_border_rounded,
            ),
          ),
        ],
      ),
      body:
          Column(
        children: [
          _buildActions(
            colors,
          ),
          Expanded(
            child:
                _buildPdfPreview(
              colors,
            ),
          ),
        ],
      ),
    );
  }
}