import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pdfx/pdfx.dart';
import 'package:scanly/Core/DocumentStorage.dart';
import 'package:scanly/Core/Scanly_Items.dart';
import 'package:scanly/Models/DocumentModel.dart';
import 'package:scanly/Pages/Pdf/PDFEditingPage.dart';
import 'package:scanly/Service/Pdf/PDFPreviewService.dart';
import 'package:scanly/Widgets/PDF/PDFPreviewActions.dart';
import 'package:scanly/Widgets/PDF/PDFPreviewViewer.dart';
import 'package:scanly/core/ScanlyActivityService.dart';
import 'package:share_plus/share_plus.dart';

class PDFPreviewPage
    extends StatefulWidget {
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

  // ============================================================
  // INIT
  // ============================================================

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
      'IMAGE PATHS: ${_imagePaths.length}',
    );

    _initializePdf();
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _pdfController?.dispose();

    super.dispose();
  }

  // ============================================================
  // INITIALIZE PDF
  // ============================================================

  Future<void> _initializePdf() async {
    try {
      if (mounted) {
        setState(() {
          _loadingPdf = true;
          _pdfError = null;
        });
      }

      // --------------------------------------------------------
      // 1. LOCAL FILE
      // --------------------------------------------------------

      if (_currentFilePath != null &&
          _currentFilePath!.isNotEmpty) {
        final file =
            File(
              _currentFilePath!,
            );

        if (await file.exists() &&
            PDFPreviewService
                .isValidPdfFile(
              file,
            )) {
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
          'LOCAL PDF NOT FOUND OR INVALID.',
        );
      }

      // --------------------------------------------------------
      // 2. PDF BYTES
      // --------------------------------------------------------

      if (_pdfBytes.isNotEmpty &&
          PDFPreviewService
              .hasPdfHeader(
            _pdfBytes,
          )) {
        debugPrint(
          'VALID PDF BYTES FOUND.',
        );

        final path =
            await PDFPreviewService
                .writePdfBytesToLocalFile(
          bytes: _pdfBytes,
          fileName: _fileName,
          currentFilePath:
              _currentFilePath,
        );

        _currentFilePath = path;

        widget.document.filePath =
            path;

        await DocumentStorage
            .updateDocumentLocally(
          widget.document,
        );

        await _openPdfFromFile(
          path,
        );

        await _loadFavorite();

        return;
      }

      // --------------------------------------------------------
      // 3. SUPABASE
      // --------------------------------------------------------

      if (widget.document.storagePath !=
              null &&
          widget.document.storagePath!
              .isNotEmpty) {
        debugPrint(
          'TRYING TO RESTORE PDF FROM SUPABASE...',
        );

        await _downloadPdfFromCloud();

        if (_currentFilePath != null &&
            _currentFilePath!.isNotEmpty) {
          final file =
              File(
            _currentFilePath!,
          );

          if (await file.exists() &&
              PDFPreviewService
                  .isValidPdfFile(
                file,
              )) {
            await _openPdfFromFile(
              file.path,
            );

            await DocumentStorage
                .updateDocumentLocally(
              widget.document,
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
      'OPENING PDF: $path',
    );

    final file =
        File(path);

    if (!await file.exists()) {
      throw Exception(
        'PDF file does not exist.',
      );
    }

    if (!PDFPreviewService
        .isValidPdfFile(file)) {
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
  // DOWNLOAD FROM CLOUD
  // ============================================================

  Future<void> _downloadPdfFromCloud() async {
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
          await PDFPreviewService
              .downloadPdfFromCloud(
        storagePath,
      );

      _pdfBytes =
          Uint8List.fromList(
        bytes,
      );

      final localPath =
          await PDFPreviewService
              .writePdfBytesToLocalFile(
        bytes: _pdfBytes,
        fileName: _fileName,
        currentFilePath:
            _currentFilePath,
      );

      _currentFilePath =
          localPath;

      widget.document.filePath =
          localPath;

      await DocumentStorage
          .updateDocumentLocally(
        widget.document,
      );

      debugPrint(
        'PDF DOWNLOADED TO: $localPath',
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

  Future<String> _ensurePdfFile() async {
    // --------------------------------------------------------
    // 1. Existing local PDF
    // --------------------------------------------------------

    if (_currentFilePath != null &&
        _currentFilePath!.isNotEmpty) {
      final file =
          File(
        _currentFilePath!,
      );

      if (await file.exists() &&
          PDFPreviewService
              .isValidPdfFile(
            file,
          )) {
        return file.path;
      }
    }

    // --------------------------------------------------------
    // 2. PDF bytes
    // --------------------------------------------------------

    if (_pdfBytes.isNotEmpty &&
        PDFPreviewService
            .hasPdfHeader(
          _pdfBytes,
        )) {
      final path =
          await PDFPreviewService
              .writePdfBytesToLocalFile(
        bytes: _pdfBytes,
        fileName: _fileName,
        currentFilePath:
            _currentFilePath,
      );

      _currentFilePath =
          path;

      widget.document.filePath =
          path;

      await DocumentStorage
          .updateDocumentLocally(
        widget.document,
      );

      return path;
    }

    // --------------------------------------------------------
    // 3. Supabase
    // --------------------------------------------------------

    if (widget.document.storagePath !=
            null &&
        widget.document.storagePath!
            .isNotEmpty) {
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
      id: _pdfId(),
      title:
          widget.document.title.isNotEmpty
              ? widget.document.title
              : 'PDF Document',
      subtitle: _fileName,
      type: 'pdf',
      route: '/pdf-preview',
      data: path,
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

    if (!mounted) {
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

      final cleanName =
          PDFPreviewService
              .cleanName(
        _fileName,
      );

      await PDFPreviewService
          .saveToPhoneFiles(
        pdfPath: path,
        fileName: cleanName,
      );

      if (!mounted) {
        return;
      }

      _showMessage(
        'PDF saved to Documents/Scanly/Documents',
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

  Future<void> _sharePdf() async {
    if (_sharing) {
      return;
    }

    setState(() {
      _sharing = true;
    });

    try {
      final path =
          await _ensurePdfFile();

      final file =
          await PDFPreviewService
              .createShareFile(
        pdfPath: path,
        fileName: _fileName,
      );

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

  Future<void> _toggleFavorite() async {
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

    final validImages =
        <String>[];

    for (final path
        in _imagePaths) {
      if (path.isNotEmpty &&
          await File(path).exists()) {
        validImages.add(path);
      }
    }

    _imagePaths =
        validImages;

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

      if (!PDFPreviewService
          .hasPdfHeader(
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
              await File(path).exists()) {
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

      await _pdfController
          ?.loadDocument(
        PdfDocument.openData(
          _pdfBytes,
        ),
      );

      await _saveEditedPdf(
        oldPath: oldPath,
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
        PDFPreviewService
            .cleanName(
      _fileName,
    );

    String path;

    if (oldPath != null &&
        oldPath.isNotEmpty) {
      path = oldPath;
    } else {
      path =
          '${directory.path}/$cleanName.pdf';
    }

    final file =
        File(path);

    await file.parent.create(
      recursive: true,
    );

    await file.writeAsBytes(
      _pdfBytes,
      flush: true,
    );

    if (!PDFPreviewService
        .isValidPdfFile(
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

    widget.document.storagePath =
        null;

    await DocumentStorage
        .updateDocument(
      widget.document,
    );

    await _updateRecent();

    await PDFPreviewService
        .saveToPhoneFiles(
      pdfPath: path,
      fileName: cleanName,
    );

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
                BorderRadius.circular(16),
          ),
          content: Row(
            children: [
              Icon(
                icon,
                color:
                    colors.onInverseSurface,
              ),
              const SizedBox(
                width: 10,
              ),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(
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

      appBar: AppBar(
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

        title: Text(
          _fileName,
          maxLines: 1,
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
            icon: Icon(
              _isFavorite
                  ? Icons.star_rounded
                  : Icons
                      .star_border_rounded,
            ),
          ),
        ],
      ),

      body: Column(
        children: [
          PDFPreviewActions(
            colors: colors,
            editing: _editing,
            sharing: _sharing,
            saving: _saving,
            onEdit: _editPdf,
            onShare: _sharePdf,
            onSave: _savePdf,
          ),

          Expanded(
            child:
                PDFPreviewViewer(
              colors: colors,
              loading:
                  _loadingPdf,
              error:
                  _pdfError,
              controller:
                  _pdfController,
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
                  'PDF PREVIEW ERROR: '
                  '$error',
                );

                if (mounted) {
                  setState(() {
                    _pdfError =
                        'PDF renderer could not read this file.';
                  });
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}