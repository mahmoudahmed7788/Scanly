import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart' as PDF;
import 'package:pdf/widgets.dart' as pw;
import 'package:scanly/Widgets/Pdf/PDFDrawPage.dart';
import 'package:scanly/Widgets/Pdf/PDFEditEmptyState.dart';
import 'package:scanly/Widgets/Pdf/PDFPageCard.dart';
import 'package:scanly/Widgets/Pdf/PDFPageItem.dart';

class PDFEditPage extends StatefulWidget {
  final Uint8List pdfBytes;
  final String fileName;
  final List<String> pageImagePaths;

  const PDFEditPage({
    super.key,
    required this.pdfBytes,
    required this.fileName,
    this.pageImagePaths = const [],
  });

  @override
  State<PDFEditPage> createState() => _PDFEditPageState();
}

class _PDFEditPageState extends State<PDFEditPage> {
  final ImagePicker _picker = ImagePicker();

  final List<PDFPageItem> _pages = [];

  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadPages();
  }

  // =========================================================
  // Load Pages
  // =========================================================

  Future<void> _loadPages() async {
    try {
      final loadedPages = <PDFPageItem>[];

      for (final path in widget.pageImagePaths) {
        final file = File(path);

        if (!await file.exists()) {
          continue;
        }

        final bytes = await file.readAsBytes();

        if (bytes.isEmpty) {
          continue;
        }

        loadedPages.add(
          PDFPageItem(
            bytes: Uint8List.fromList(bytes),
          ),
        );
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _pages
          ..clear()
          ..addAll(loadedPages);

        _loading = false;
      });

      if (_pages.isEmpty) {
        _showMessage(
          'No editable page images were found.',
        );
      }
    } catch (e, stackTrace) {
      debugPrint(
        'LOAD PDF PAGES ERROR: $e',
      );

      debugPrint(
        stackTrace.toString(),
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _loading = false;
      });

      _showMessage(
        'Failed to load PDF pages.',
      );
    }
  }

  // =========================================================
  // Add Images
  // =========================================================

  Future<void> _addImages() async {
    if (_saving) {
      return;
    }

    try {
      final images = await _picker.pickMultiImage(
        imageQuality: 80,
        maxWidth: 1600,
        maxHeight: 1600,
      );

      if (images.isEmpty) {
        return;
      }

      final newPages = <PDFPageItem>[];

      for (final image in images) {
        final bytes = await image.readAsBytes();

        if (bytes.isEmpty) {
          continue;
        }

        newPages.add(
          PDFPageItem(
            bytes: Uint8List.fromList(bytes),
          ),
        );
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _pages.addAll(newPages);
      });
    } catch (e, stackTrace) {
      debugPrint(
        'ADD IMAGES ERROR: $e',
      );

      debugPrint(
        stackTrace.toString(),
      );

      if (!mounted) {
        return;
      }

      _showMessage(
        'Failed to add images.',
      );
    }
  }

  // =========================================================
  // Delete Page
  // =========================================================

  void _deletePage(int index) {
    if (_pages.length <= 1) {
      _showMessage(
        'PDF must contain at least one page.',
      );
      return;
    }

    setState(() {
      _pages.removeAt(index);
    });
  }

  // =========================================================
  // Rotate Page
  // =========================================================

  void _rotatePage(int index) {
    setState(() {
      _pages[index].rotation += 90;

      if (_pages[index].rotation >= 360) {
        _pages[index].rotation = 0;
      }
    });
  }

  // =========================================================
  // Edit Page
  // =========================================================

  Future<void> _editPage(int index) async {
    if (_saving) {
      return;
    }

    try {
      final result = await Navigator.push<Uint8List>(
        context,
        MaterialPageRoute(
          builder: (_) => PDFDrawPage(
            imageBytes: _pages[index].bytes,
          ),
        ),
      );

      if (result == null || !mounted) {
        return;
      }

      setState(() {
        _pages[index].bytes =
            Uint8List.fromList(result);
      });
    } catch (e, stackTrace) {
      debugPrint(
        'DRAW PAGE ERROR: $e',
      );

      debugPrint(
        stackTrace.toString(),
      );

      if (!mounted) {
        return;
      }

      _showMessage(
        'Failed to edit page.',
      );
    }
  }

  // =========================================================
  // Build PDF
  // =========================================================

  Future<Uint8List?> _buildPdf() async {
    if (_pages.isEmpty) {
      return null;
    }

    final document = pw.Document();

    for (final page in _pages) {
      final image = pw.MemoryImage(
        page.bytes,
      );

      final rotation =
          page.rotation * math.pi / 180;

      document.addPage(
        pw.Page(
          pageFormat: PDF.PdfPageFormat.a4,
          margin: pw.EdgeInsets.zero,
          build: (context) {
            return pw.Center(
              child: pw.Transform.rotate(
                angle: rotation,
                child: pw.Image(
                  image,
                  fit: pw.BoxFit.contain,
                ),
              ),
            );
          },
        ),
      );
    }

    return document.save();
  }

  // =========================================================
  // Save Page Images
  // =========================================================

  Future<List<String>> _savePageImages() async {
    final directory =
        await getApplicationDocumentsDirectory();

    final documentsDirectory = Directory(
      '${directory.path}/Scanly/Documents',
    );

    await documentsDirectory.create(
      recursive: true,
    );

    final timestamp =
        DateTime.now().millisecondsSinceEpoch;

    final pagesDirectory = Directory(
      '${documentsDirectory.path}/'
      '${_cleanName(widget.fileName)}_edited_pages_$timestamp',
    );

    await pagesDirectory.create(
      recursive: true,
    );

    final savedPaths = <String>[];

    for (int i = 0; i < _pages.length; i++) {
      final page = _pages[i];

      final decoded = img.decodeImage(
        page.bytes,
      );

      if (decoded == null) {
        continue;
      }

      img.Image finalImage = decoded;

      if (page.rotation != 0) {
        finalImage = img.copyRotate(
          finalImage,
          angle: page.rotation,
        );
      }

      final jpg = img.encodeJpg(
        finalImage,
        quality: 88,
      );

      final path =
          '${pagesDirectory.path}/'
          'page_${(i + 1).toString().padLeft(3, '0')}.jpg';

      final file = File(path);

      await file.writeAsBytes(
        jpg,
        flush: true,
      );

      savedPaths.add(path);
    }

    return savedPaths;
  }

  // =========================================================
  // Clean File Name
  // =========================================================

  String _cleanName(String value) {
    var name = value.trim();

    if (name.isEmpty) {
      name = 'Scanly Document';
    }

    if (name.toLowerCase().endsWith('.pdf')) {
      name = name.substring(
        0,
        name.length - 4,
      );
    }

    name = name.replaceAll(
      RegExp(r'[\\/:*?"<>|]'),
      '_',
    );

    if (name.trim().isEmpty) {
      name = 'Scanly Document';
    }

    return name.trim();
  }

  // =========================================================
  // Clean PDF Name
  // =========================================================

  String _cleanPdfName(String value) {
    var name = _cleanName(value);

    if (!name.toLowerCase().endsWith('.pdf')) {
      name = '$name.pdf';
    }

    return name;
  }

  // =========================================================
  // Save Changes
  // =========================================================

  Future<void> _saveChanges() async {
    if (_saving || _pages.isEmpty) {
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      final pdfBytes = await _buildPdf();

      if (pdfBytes == null) {
        throw Exception(
          'Unable to create PDF',
        );
      }

      final imagePaths =
          await _savePageImages();

      if (imagePaths.isEmpty) {
        throw Exception(
          'Unable to save page images',
        );
      }

      if (!mounted) {
        return;
      }

      final result = <String, dynamic>{
        'pdfBytes': Uint8List.fromList(
          pdfBytes,
        ),
        'imagePaths': imagePaths,
        'fileName': _cleanPdfName(
          widget.fileName,
        ),
      };

      Navigator.pop(
        context,
        result,
      );
    } catch (e, stackTrace) {
      debugPrint(
        'SAVE EDITED PDF ERROR: $e',
      );

      debugPrint(
        stackTrace.toString(),
      );

      if (!mounted) {
        return;
      }

      _showMessage(
        'Failed to update PDF.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  // =========================================================
  // Show Message
  // =========================================================

  void _showMessage(
    String message,
  ) {
    if (!mounted) {
      return;
    }

    final colors =
        Theme.of(context).colorScheme;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                color: colors.onInverseSurface,
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
          behavior:
              SnackBarBehavior.floating,
          backgroundColor:
              colors.inverseSurface,
        ),
      );
  }

  // =========================================================
  // Reorder Pages
  // =========================================================

  void _reorderPages(
    int oldIndex,
    int newIndex,
  ) {
    setState(() {
      if (oldIndex < newIndex) {
        newIndex--;
      }

      final page =
          _pages.removeAt(oldIndex);

      _pages.insert(
        newIndex,
        page,
      );
    });
  }

  // =========================================================
  // Build
  // =========================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    final colors =
        Theme.of(context).colorScheme;

    // =======================================================
    // Loading
    // =======================================================

    if (_loading) {
      return Scaffold(
        backgroundColor: colors.surface,
        appBar: AppBar(
          title: const Text(
            'Edit PDF',
            style: TextStyle(
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // =======================================================
    // Main Page
    // =======================================================

    return Scaffold(
      backgroundColor: colors.surface,

      // =====================================================
      // App Bar
      // =====================================================

      appBar: AppBar(
        title: const Text(
          'Edit PDF',
          style: TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Add Images',
            onPressed:
                _saving ? null : _addImages,
            icon: const Icon(
              Icons.add_photo_alternate_rounded,
            ),
          ),

          IconButton(
            tooltip: 'Save Changes',
            onPressed:
                _saving ? null : _saveChanges,
            icon: _saving
                ? const SizedBox(
                    width: 21,
                    height: 21,
                    child:
                        CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(
                    Icons.check_rounded,
                  ),
          ),
        ],
      ),

      // =====================================================
      // Body
      // =====================================================

      body: _pages.isEmpty
          ? PDFEditEmptyState(
              colors: colors,
              saving: _saving,
              onAddImages: _addImages,
            )
          : ReorderableListView.builder(
              padding:
                  const EdgeInsets.fromLTRB(
                16,
                16,
                16,
                110,
              ),
              itemCount: _pages.length,
              onReorder: _reorderPages,
              itemBuilder:
                  (context, index) {
                final page =
                    _pages[index];

                return PDFPageCard(
                  key: page.key,
                  page: page,
                  index: index,
                  colors: colors,
                  saving: _saving,
                  onEdit: () {
                    _editPage(index);
                  },
                  onRotate: () {
                    _rotatePage(index);
                  },
                  onDelete: () {
                    _deletePage(index);
                  },
                );
              },
            ),

      // =====================================================
      // Bottom Add Images Button
      // =====================================================

      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            16,
            8,
            16,
            16,
          ),
          child: SizedBox(
            height: 52,
            child: FilledButton.icon(
              onPressed:
                  _saving ? null : _addImages,
              icon: const Icon(
                Icons.add_photo_alternate_rounded,
              ),
              label: const Text(
                'Add Images',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}