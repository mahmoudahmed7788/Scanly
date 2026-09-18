
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart' as PDF;
import 'package:pdf/widgets.dart' as pw;

import 'PDFDrawPage.dart';

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

  final List<_PDFPageItem> _pages = [];

  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadPages();
  }

  Future<void> _loadPages() async {
    try {
      final loadedPages = <_PDFPageItem>[];

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
          _PDFPageItem(
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

  Future<void> _addImages() async {
    if (_saving) {
      return;
    }

    try {
      final images =
          await _picker.pickMultiImage(
        imageQuality: 80,
        maxWidth: 1600,
        maxHeight: 1600,
      );

      if (images.isEmpty) {
        return;
      }

      final newPages = <_PDFPageItem>[];

      for (final image in images) {
        final bytes = await image.readAsBytes();

        if (bytes.isEmpty) {
          continue;
        }

        newPages.add(
          _PDFPageItem(
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

  void _rotatePage(int index) {
    setState(() {
      _pages[index].rotation += 90;

      if (_pages[index].rotation >= 360) {
        _pages[index].rotation = 0;
      }
    });
  }

  Future<void> _editPage(int index) async {
    if (_saving) {
      return;
    }

    try {
      final result =
          await Navigator.push<Uint8List>(
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

  Future<Uint8List?> _buildPdf() async {
    if (_pages.isEmpty) {
      return null;
    }

    final document = pw.Document();

    for (final page in _pages) {
      final image =
          pw.MemoryImage(page.bytes);

      final rotation =
          page.rotation * math.pi / 180;

      document.addPage(
        pw.Page(
          pageFormat:
              PDF.PdfPageFormat.a4,
          margin:
              pw.EdgeInsets.zero,
          build: (context) {
            return pw.Center(
              child:
                  pw.Transform.rotate(
                angle: rotation,
                child:
                    pw.Image(
                  image,
                  fit:
                      pw.BoxFit.contain,
                ),
              ),
            );
          },
        ),
      );
    }

    return document.save();
  }

  Future<List<String>> _savePageImages() async {
    final directory =
        await getApplicationDocumentsDirectory();

    final documentsDirectory =
        Directory(
      '${directory.path}/Scanly/Documents',
    );

    await documentsDirectory.create(
      recursive: true,
    );

    final timestamp =
        DateTime.now().millisecondsSinceEpoch;

    final pagesDirectory =
        Directory(
      '${documentsDirectory.path}/'
      '${_cleanName(widget.fileName)}_edited_pages_$timestamp',
    );

    await pagesDirectory.create(
      recursive: true,
    );

    final savedPaths = <String>[];

    for (int i = 0; i < _pages.length; i++) {
      final page = _pages[i];

      final decoded =
          img.decodeImage(page.bytes);

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

      final jpg =
          img.encodeJpg(
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

  String _cleanPdfName(String value) {
    var name = _cleanName(value);

    if (!name.toLowerCase().endsWith('.pdf')) {
      name = '$name.pdf';
    }

    return name;
  }

  Future<void> _saveChanges() async {
    if (_saving || _pages.isEmpty) {
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      final pdfBytes =
          await _buildPdf();

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

      final result =
          <String, dynamic>{
        'pdfBytes':
            Uint8List.fromList(
          pdfBytes,
        ),
        'imagePaths':
            imagePaths,
        'fileName':
            _cleanPdfName(
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
                color:
                    colors.onInverseSurface,
              ),
              const SizedBox(
                width: 10,
              ),
              Expanded(
                child: Text(
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
          behavior:
              SnackBarBehavior.floating,
          backgroundColor:
              colors.inverseSurface,
        ),
      );
  }

  Widget _buildPageCard(
    ColorScheme colors,
    int index,
  ) {
    final page =
        _pages[index];

    return Container(
      key: page.key,
      margin:
          const EdgeInsets.only(
        bottom: 16,
      ),
      decoration:
          BoxDecoration(
        color:
            colors.surface,
        borderRadius:
            BorderRadius.circular(20),
        border:
            Border.all(
          color:
              colors.onSurface.withValues(
            alpha: 0.08,
          ),
        ),
        boxShadow: [
          BoxShadow(
            blurRadius: 10,
            offset:
                const Offset(0, 3),
            color:
                Colors.black.withValues(
              alpha: 0.06,
            ),
          ),
        ],
      ),
      child:
          Padding(
        padding:
            const EdgeInsets.all(12),
        child:
            Column(
          children: [
            Stack(
              children: [
                Container(
                  width:
                      double.infinity,
                  constraints:
                      const BoxConstraints(
                    minHeight: 190,
                    maxHeight: 420,
                  ),
                  decoration:
                      BoxDecoration(
                    color:
                        Colors.white,
                    borderRadius:
                        BorderRadius.circular(
                      14,
                    ),
                  ),
                  clipBehavior:
                      Clip.antiAlias,
                  child:
                      RotatedBox(
                    quarterTurns:
                        page.rotation ~/
                            90,
                    child:
                        Image.memory(
                      page.bytes,
                      width:
                          double.infinity,
                      fit:
                          BoxFit.contain,
                      errorBuilder:
                          (
                        context,
                        error,
                        stackTrace,
                      ) {
                        return SizedBox(
                          height: 220,
                          child:
                              Center(
                            child:
                                Icon(
                              Icons
                                  .broken_image_outlined,
                              size: 48,
                              color:
                                  colors.error,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                Positioned(
                  top: 10,
                  left: 10,
                  child:
                      Container(
                    padding:
                        const EdgeInsets
                            .symmetric(
                      horizontal: 11,
                      vertical: 6,
                    ),
                    decoration:
                        BoxDecoration(
                      color:
                          Colors.black
                              .withValues(
                        alpha: 0.65,
                      ),
                      borderRadius:
                          BorderRadius.circular(
                        20,
                      ),
                    ),
                    child:
                        Text(
                      'Page ${index + 1}',
                      style:
                          const TextStyle(
                        color:
                            Colors.white,
                        fontSize:
                            12,
                        fontWeight:
                            FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(
              height: 10,
            ),
            Row(
              children: [
                Text(
                  'Page ${index + 1}',
                  style:
                      TextStyle(
                    fontWeight:
                        FontWeight.w800,
                    color:
                        colors.onSurface,
                  ),
                ),
                const Spacer(),
                IconButton(
                  tooltip:
                      'Edit',
                  onPressed:
                      _saving
                          ? null
                          : () =>
                              _editPage(
                                index,
                              ),
                  icon:
                      const Icon(
                    Icons.edit_rounded,
                  ),
                ),
                IconButton(
                  tooltip:
                      'Rotate',
                  onPressed:
                      _saving
                          ? null
                          : () =>
                              _rotatePage(
                                index,
                              ),
                  icon:
                      const Icon(
                    Icons.rotate_right_rounded,
                  ),
                ),
                IconButton(
                  tooltip:
                      'Delete',
                  onPressed:
                      _saving
                          ? null
                          : () =>
                              _deletePage(
                                index,
                              ),
                  icon:
                      const Icon(
                    Icons.delete_outline_rounded,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(
    ColorScheme colors,
  ) {
    return Center(
      child:
          Padding(
        padding:
            const EdgeInsets.all(24),
        child:
            Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Icon(
              Icons
                  .picture_as_pdf_outlined,
              size: 64,
              color:
                  colors.primary,
            ),
            const SizedBox(
              height: 16,
            ),
            Text(
              'No pages available',
              style:
                  TextStyle(
                fontSize: 20,
                fontWeight:
                    FontWeight.w800,
                color:
                    colors.onSurface,
              ),
            ),
            const SizedBox(
              height: 8,
            ),
            Text(
              'Add images to start editing this PDF.',
              textAlign:
                  TextAlign.center,
              style:
                  TextStyle(
                color:
                    colors.onSurface
                        .withValues(
                  alpha: 0.60,
                ),
              ),
            ),
            const SizedBox(
              height: 22,
            ),
            FilledButton.icon(
              onPressed:
                  _saving
                      ? null
                      : _addImages,
              icon:
                  const Icon(
                Icons
                    .add_photo_alternate_rounded,
              ),
              label:
                  const Text(
                'Add Images',
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
    final colors =
        Theme.of(context).colorScheme;

    if (_loading) {
      return Scaffold(
        backgroundColor:
            colors.surface,
        appBar:
            AppBar(
          title:
              const Text(
            'Edit PDF',
            style:
                TextStyle(
              fontWeight:
                  FontWeight.w800,
            ),
          ),
        ),
        body:
            const Center(
          child:
              CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor:
          colors.surface,
      appBar:
          AppBar(
        title:
            const Text(
          'Edit PDF',
          style:
              TextStyle(
            fontWeight:
                FontWeight.w800,
          ),
        ),
        actions: [
          IconButton(
            tooltip:
                'Add Images',
            onPressed:
                _saving
                    ? null
                    : _addImages,
            icon:
                const Icon(
              Icons
                  .add_photo_alternate_rounded,
            ),
          ),
          IconButton(
            tooltip:
                'Save Changes',
            onPressed:
                _saving
                    ? null
                    : _saveChanges,
            icon:
                _saving
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
                        Icons.check_rounded,
                      ),
          ),
        ],
      ),
      body:
          _pages.isEmpty
              ? _buildEmptyState(
                  colors,
                )
              : ReorderableListView.builder(
                  padding:
                      const EdgeInsets.fromLTRB(
                    16,
                    16,
                    16,
                    110,
                  ),
                  itemCount:
                      _pages.length,
                  onReorder:
                      (oldIndex, newIndex) {
                    setState(() {
                      if (oldIndex <
                          newIndex) {
                        newIndex--;
                      }

                      final page =
                          _pages.removeAt(
                        oldIndex,
                      );

                      _pages.insert(
                        newIndex,
                        page,
                      );
                    });
                  },
                  itemBuilder:
                      (context, index) {
                    return _buildPageCard(
                      colors,
                      index,
                    );
                  },
                ),
      bottomNavigationBar:
          SafeArea(
        top: false,
        child:
            Padding(
          padding:
              const EdgeInsets.fromLTRB(
            16,
            8,
            16,
            16,
          ),
          child:
              SizedBox(
            height: 52,
            child:
                FilledButton.icon(
              onPressed:
                  _saving
                      ? null
                      : _addImages,
              icon:
                  const Icon(
                Icons
                    .add_photo_alternate_rounded,
              ),
              label:
                  const Text(
                'Add Images',
                style:
                    TextStyle(
                  fontWeight:
                      FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PDFPageItem {
  Uint8List bytes;
  int rotation;
  final Key key;

  _PDFPageItem({
    required this.bytes,
    this.rotation = 0,
  }) : key = UniqueKey();
}
