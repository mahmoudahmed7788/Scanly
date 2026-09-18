import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdfx/pdfx.dart';
import 'package:scanly/PDFEditingPage.dart';
import 'package:scanly/ScanlyActivityService.dart';
import 'package:scanly/Scanly_Items.dart';
import 'package:share_plus/share_plus.dart';

class PDFPreviewPage extends StatefulWidget {
  final Uint8List pdfBytes;
  final String fileName;
  final String? filePath;
  final List<String> imagePaths;

  const PDFPreviewPage({
    super.key,
    required this.pdfBytes,
    required this.fileName,
    this.filePath,
    this.imagePaths = const [],
  });

  @override
  State<PDFPreviewPage> createState() => _PDFPreviewPageState();
}

class _PDFPreviewPageState extends State<PDFPreviewPage> {
  late Uint8List _pdfBytes;
  late String _fileName;
  late List<String> _imagePaths;

  String? _currentFilePath;

  late final PdfControllerPinch _pdfController;

  bool _saving = false;
  bool _sharing = false;
  bool _editing = false;
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();

    _pdfBytes = Uint8List.fromList(widget.pdfBytes);
    _fileName = widget.fileName;
    _currentFilePath = widget.filePath;
    _imagePaths = List<String>.from(widget.imagePaths);

    debugPrint('========== PDF PREVIEW ==========');
    debugPrint('FILE NAME: $_fileName');
    debugPrint('PDF BYTES: ${_pdfBytes.length}');
    debugPrint('IMAGE PATHS COUNT: ${_imagePaths.length}');

    for (final path in _imagePaths) {
      debugPrint('IMAGE PATH: $path');
      debugPrint('IMAGE EXISTS: ${File(path).existsSync()}');
    }

    debugPrint('=================================');

    _pdfController = PdfControllerPinch(
      document: PdfDocument.openData(_pdfBytes),
    );

    _loadFavorite();
  }

  @override
  void dispose() {
    _pdfController.dispose();
    super.dispose();
  }

  String _pdfId(String path) {
    return 'pdf_${path.hashCode}';
  }

  String _cleanName(String value) {
    var name = value.trim();

    if (name.isEmpty) {
      name = 'Scanly Document';
    }

    name = name.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');

    if (name.toLowerCase().endsWith('.pdf')) {
      name = name.substring(0, name.length - 4);
    }

    if (name.trim().isEmpty) {
      name = 'Scanly Document';
    }

    return name.trim();
  }

  Future<void> _loadFavorite() async {
    final path = _currentFilePath;

    if (path == null || path.isEmpty) {
      return;
    }

    final favorite = ScanlyActivityService.isFavorite(_pdfId(path));

    if (!mounted) {
      return;
    }

    setState(() {
      _isFavorite = favorite;
    });
  }

  Future<String> _ensurePdfFile() async {
    if (_currentFilePath != null) {
      final existing = File(_currentFilePath!);

      if (await existing.exists()) {
        return existing.path;
      }
    }

    final appDirectory = await getApplicationDocumentsDirectory();

    final documentsDirectory = Directory(
      '${appDirectory.path}/Scanly/Documents',
    );

    await documentsDirectory.create(recursive: true);

    final cleanName = _cleanName(_fileName);

    var path = '${documentsDirectory.path}/$cleanName.pdf';
    var file = File(path);

    int counter = 1;

    while (await file.exists()) {
      path =
          '${documentsDirectory.path}/'
          '$cleanName ($counter).pdf';

      file = File(path);

      counter++;
    }

    await file.writeAsBytes(_pdfBytes, flush: true);

    _currentFilePath = path;

    return path;
  }

  ScanlyItem _createItem(String path) {
    return ScanlyItem(
      id: _pdfId(path),
      title: 'PDF Document',
      subtitle: _fileName,
      type: 'pdf',
      route: '/pdf-preview',
      data: path,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );
  }

  Future<void> _updateRecent() async {
    final path = await _ensurePdfFile();

    await ScanlyActivityService.addRecent(_createItem(path));
  }

  Future<void> _savePdf() async {
    if (_saving) {
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      final path = await _ensurePdfFile();

      await File(path).writeAsBytes(_pdfBytes, flush: true);

      await _updateRecent();

      if (!mounted) {
        return;
      }

      _showMessage(
        'PDF saved successfully',
        Icons.check_circle_outline_rounded,
      );
    } catch (e, stackTrace) {
      debugPrint('SAVE PDF ERROR: $e');
      debugPrint(stackTrace.toString());

      if (!mounted) {
        return;
      }

      _showMessage('Failed to save PDF', Icons.error_outline_rounded);
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  Future<File> _createShareFile() async {
    final directory = await getTemporaryDirectory();

    final cleanName = _cleanName(_fileName);

    final file = File('${directory.path}/$cleanName.pdf');

    await file.writeAsBytes(_pdfBytes, flush: true);

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
      final file = await _createShareFile();

      await Share.shareXFiles([
        XFile(file.path, mimeType: 'application/pdf'),
      ], text: 'Shared from Scanly');
    } catch (e, stackTrace) {
      debugPrint('SHARE PDF ERROR: $e');
      debugPrint(stackTrace.toString());

      if (!mounted) {
        return;
      }

      _showMessage('Failed to share PDF', Icons.error_outline_rounded);
    } finally {
      if (mounted) {
        setState(() {
          _sharing = false;
        });
      }
    }
  }

  Future<void> _toggleFavorite() async {
    try {
      final path = await _ensurePdfFile();

      final item = _createItem(path);

      await ScanlyActivityService.toggleFavorite(item);

      if (!mounted) {
        return;
      }

      setState(() {
        _isFavorite = ScanlyActivityService.isFavorite(item.id);
      });
    } catch (e) {
      debugPrint('FAVORITE PDF ERROR: $e');

      if (!mounted) {
        return;
      }

      _showMessage('Failed to update favorite', Icons.error_outline_rounded);
    }
  }

  Future<void> _editPdf() async {
    if (_editing) {
      return;
    }

    debugPrint('EDIT BUTTON PRESSED');
    debugPrint('EDIT IMAGE PATHS: ${_imagePaths.length}');

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
      final oldPath = _currentFilePath;

      final wasFavorite =
          oldPath != null && ScanlyActivityService.isFavorite(_pdfId(oldPath));

      debugPrint('OPENING PDF EDIT PAGE');

      final result = await Navigator.push<Map<String, dynamic>>(
        context,
        MaterialPageRoute(
          builder: (_) => PDFEditPage(
            pdfBytes: _pdfBytes,
            fileName: _fileName,
            pageImagePaths: List<String>.from(_imagePaths),
          ),
        ),
      );

      debugPrint('EDIT PAGE RETURNED: $result');

      if (result == null || !mounted) {
        return;
      }

      final newBytes = result['pdfBytes'];
      final newImages = result['imagePaths'];
      final newName = result['fileName'];

      if (newBytes is! Uint8List) {
        _showMessage('Invalid edited PDF', Icons.error_outline_rounded);
        return;
      }

      final updatedImages = <String>[];

      if (newImages is List) {
        for (final path in newImages) {
          if (path is String && path.isNotEmpty && File(path).existsSync()) {
            updatedImages.add(path);
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
        _pdfBytes = Uint8List.fromList(newBytes);

        _imagePaths = updatedImages;

        if (newName is String && newName.isNotEmpty) {
          _fileName = newName;
        }
      });

      await _pdfController.openDocument(PdfDocument.openData(_pdfBytes));

      await _saveEditedPdf(oldPath: oldPath, wasFavorite: wasFavorite);
    } catch (e, stackTrace) {
      debugPrint('EDIT PDF ERROR: $e');
      debugPrint(stackTrace.toString());

      if (!mounted) {
        return;
      }

      _showMessage('Failed to edit PDF', Icons.error_outline_rounded);
    } finally {
      if (mounted) {
        setState(() {
          _editing = false;
        });
      }
    }
  }

  Future<void> _saveEditedPdf({
    required String? oldPath,
    required bool wasFavorite,
  }) async {
    final appDirectory = await getApplicationDocumentsDirectory();

    final documentsDirectory = Directory(
      '${appDirectory.path}/Scanly/Documents',
    );

    await documentsDirectory.create(recursive: true);

    final cleanName = _cleanName(_fileName);

    var path = '${documentsDirectory.path}/$cleanName.pdf';
    var file = File(path);

    int counter = 1;

    while (await file.exists() && path != oldPath) {
      path =
          '${documentsDirectory.path}/'
          '$cleanName ($counter).pdf';

      file = File(path);

      counter++;
    }

    await file.writeAsBytes(_pdfBytes, flush: true);

    _currentFilePath = path;

    await _updateRecent();

    if (oldPath != null && oldPath != path) {
      await ScanlyActivityService.removeFavorite(_pdfId(oldPath));
    }

    if (wasFavorite) {
      await ScanlyActivityService.addFavorite(_createItem(path));
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _isFavorite = wasFavorite;
    });

    _showMessage(
      'PDF updated successfully',
      Icons.check_circle_outline_rounded,
    );
  }

  void _showMessage(String message, IconData icon) {
    if (!mounted) {
      return;
    }

    final colors = Theme.of(context).colorScheme;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: colors.inverseSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: Row(
            children: [
              Icon(icon, color: colors.onInverseSurface),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(
                    color: colors.onInverseSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
  }

  Widget _buildPdfPreview(ColorScheme colors) {
    return Container(
      margin: const EdgeInsets.fromLTRB(10, 0, 10, 10),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      clipBehavior: Clip.antiAlias,
      child: PdfViewPinch(
        controller: _pdfController,
        scrollDirection: Axis.vertical,
        backgroundDecoration: BoxDecoration(
          color: colors.surfaceContainerHighest,
        ),
        onDocumentLoaded: (document) {
          debugPrint('PDF PREVIEW LOADED: ${document.pagesCount} pages');
        },
        onDocumentError: (error) {
          debugPrint('PDF PREVIEW ERROR: $error');
        },
      ),
    );
  }

  Widget _buildActions(ColorScheme colors) {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 4, 14, 14),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.onSurface.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _actionButton(
              colors: colors,
              icon: Icons.edit_rounded,
              label: 'Edit',
              onPressed: _editing ? null : _editPdf,
              outlined: true,
              loading: _editing,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _actionButton(
              colors: colors,
              icon: Icons.share_rounded,
              label: 'Share',
              onPressed: _sharing ? null : _sharePdf,
              outlined: true,
              loading: _sharing,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _actionButton(
              colors: colors,
              icon: Icons.save_rounded,
              label: 'Save',
              onPressed: _saving ? null : _savePdf,
              outlined: false,
              loading: _saving,
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
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 50),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        child: loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 20),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ],
              ),
      );
    }

    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 50),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
      child: loading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 20),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ],
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colors.surfaceContainerLowest,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            context.pop();
          },
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: Text(
          _fileName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            tooltip: 'Favorite',
            onPressed: _toggleFavorite,
            icon: Icon(
              _isFavorite ? Icons.star_rounded : Icons.star_border_rounded,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildActions(colors),
          Expanded(child: _buildPdfPreview(colors)),
        ],
      ),
    );
  }
}

extension on PdfControllerPinch {
  Future<void> openDocument(Future<PdfDocument> openData) async {}
}
