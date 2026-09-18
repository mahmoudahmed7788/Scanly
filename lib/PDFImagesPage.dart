import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart' as pdf;
import 'package:pdf/widgets.dart' as pw;
import 'package:scanly/ScanlyActivityService.dart';
import 'package:scanly/Scanly_Items.dart';

class PDFImagesPage extends StatefulWidget {
  const PDFImagesPage({super.key});

  @override
  State<PDFImagesPage> createState() => _PDFImagesPageState();
}

class _PDFImagesPageState extends State<PDFImagesPage> {
  final ImagePicker _picker = ImagePicker();

  final List<XFile> _selectedImages = [];

  final TextEditingController _nameController =
      TextEditingController(text: 'Scanly Document');

  bool _isCreating = false;

  Uint8List? _scanlyLogoBytes;

  @override
  void initState() {
    super.initState();
    _loadScanlyLogo();
  }

  Future<void> _loadScanlyLogo() async {
    try {
      final data = await rootBundle.load(
        'assets/images/Scanly_Splash.png',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _scanlyLogoBytes = data.buffer.asUint8List();
      });
    } catch (e) {
      debugPrint('LOAD SCANLY LOGO ERROR: $e');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    try {
      final images = await _picker.pickMultiImage();

      if (images.isEmpty) {
        return;
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _selectedImages.addAll(images);
      });
    } catch (e) {
      debugPrint('PICK IMAGES ERROR: $e');

      if (!mounted) {
        return;
      }

      _showMessage(
        'Could not select images',
        Icons.error_outline_rounded,
      );
    }
  }

  void _removeImage(int index) {
    if (index < 0 || index >= _selectedImages.length) {
      return;
    }

    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  void _moveImage(int oldIndex, int newIndex) {
    if (oldIndex < 0 ||
        oldIndex >= _selectedImages.length ||
        newIndex < 0 ||
        newIndex > _selectedImages.length) {
      return;
    }

    setState(() {
      if (newIndex > oldIndex) {
        newIndex--;
      }

      final image = _selectedImages.removeAt(oldIndex);
      _selectedImages.insert(newIndex, image);
    });
  }

  String _cleanFileName(String value) {
    var name = value.trim();

    if (name.isEmpty) {
      name = 'Scanly Document';
    }

    name = name.replaceAll(
      RegExp(r'[\\/:*?"<>|]'),
      '_',
    );

    if (name.toLowerCase().endsWith('.pdf')) {
      name = name.substring(0, name.length - 4);
    }

    if (name.trim().isEmpty) {
      name = 'Scanly Document';
    }

    return name.trim();
  }

  Future<Uint8List?> _prepareImage(String path) async {
    try {
      final file = File(path);

      if (!await file.exists()) {
        debugPrint('IMAGE FILE DOES NOT EXIST: $path');
        return null;
      }

      final bytes = await file.readAsBytes();

      if (bytes.isEmpty) {
        debugPrint('IMAGE FILE IS EMPTY: $path');
        return null;
      }

      final decoded = img.decodeImage(bytes);

      if (decoded == null) {
        return Uint8List.fromList(bytes);
      }

      img.Image image = decoded;

      if (image.width > 1400) {
        image = img.copyResize(
          image,
          width: 1400,
        );
      }

      final jpg = img.encodeJpg(
        image,
        quality: 75,
      );

      return Uint8List.fromList(jpg);
    } catch (e) {
      debugPrint('PREPARE IMAGE ERROR: $e');
      return null;
    }
  }

  pdf.PdfPageFormat _pageFormatForImage(
    int width,
    int height,
  ) {
    if (width >= height) {
      return pdf.PdfPageFormat(
        841.89,
        595.28,
      );
    }

    return pdf.PdfPageFormat(
      595.28,
      841.89,
    );
  }

  String _itemId(String path) {
    return 'pdf_${path.hashCode}';
  }

  ScanlyItem _createItem(
    String path,
    String fileName,
  ) {
    return ScanlyItem(
      id: _itemId(path),
      title: 'PDF Document',
      subtitle: fileName,
      type: 'pdf',
      route: '/pdf-preview',
      data: path,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );
  }

  pw.Widget _buildScanlyBranding() {
    final logo = _scanlyLogoBytes == null
        ? null
        : pw.MemoryImage(_scanlyLogoBytes!);

    return pw.Container(
      height: 42,
      padding: const pw.EdgeInsets.only(
        top: 6,
        bottom: 4,
      ),
      decoration: pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(
            color: pdf.PdfColors.grey400,
            width: 0.6,
          ),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.center,
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          if (logo != null)
            pw.Container(
              width: 28,
              height: 28,
              child: pw.Image(
                logo,
                fit: pw.BoxFit.contain,
              ),
            )
          else
            pw.Container(
              width: 28,
              height: 28,
              alignment: pw.Alignment.center,
              decoration: pw.BoxDecoration(
                color: pdf.PdfColors.indigo,
                borderRadius: pw.BorderRadius.circular(7),
              ),
              child: pw.Text(
                'S',
                style: pw.TextStyle(
                  color: pdf.PdfColors.white,
                  fontSize: 15,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
          pw.SizedBox(width: 8),
          pw.Text(
            'Scanly',
            style: pw.TextStyle(
              color: pdf.PdfColors.indigo,
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _createPdf() async {
    if (_isCreating) {
      return;
    }

    if (_selectedImages.isEmpty) {
      _showMessage(
        'Select at least one image first',
        Icons.image_outlined,
      );
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _isCreating = true;
    });

    try {
      debugPrint('========== CREATE PDF START =========');

      final documentName = _cleanFileName(
        _nameController.text,
      );

      final document = pw.Document();

      final appDirectory =
          await getApplicationDocumentsDirectory();

      final documentsDirectory = Directory(
        '${appDirectory.path}/Scanly/Documents',
      );

      await documentsDirectory.create(
        recursive: true,
      );

      final timestamp =
          DateTime.now().millisecondsSinceEpoch;

      final pagesDirectory = Directory(
        '${documentsDirectory.path}/'
        '${documentName}_pages_$timestamp',
      );

      await pagesDirectory.create(
        recursive: true,
      );

      final savedPageImagePaths = <String>[];

      debugPrint(
        'IMAGES COUNT: ${_selectedImages.length}',
      );

      for (
        int i = 0;
        i < _selectedImages.length;
        i++
      ) {
        final selected = _selectedImages[i];

        debugPrint(
          'PROCESSING IMAGE ${i + 1}: ${selected.path}',
        );

        final imageBytes = await _prepareImage(
          selected.path,
        );

        if (imageBytes == null) {
          debugPrint(
            'IMAGE ${i + 1} FAILED',
          );
          continue;
        }

        final decoded = img.decodeImage(
          imageBytes,
        );

        if (decoded == null) {
          debugPrint(
            'IMAGE ${i + 1} DECODE FAILED',
          );
          continue;
        }

        final pagePath =
            '${pagesDirectory.path}/'
            'page_${(i + 1).toString().padLeft(3, '0')}.jpg';

        final pageFile = File(pagePath);

        await pageFile.writeAsBytes(
          imageBytes,
          flush: true,
        );

        savedPageImagePaths.add(pagePath);

        final pdfImage = pw.MemoryImage(
          imageBytes,
        );

        final pageFormat = _pageFormatForImage(
          decoded.width,
          decoded.height,
        );

        const brandingHeight = 42.0;

        final imageAreaHeight =
            pageFormat.height - brandingHeight;

        document.addPage(
          pw.Page(
            pageFormat: pageFormat,
            margin: pw.EdgeInsets.zero,
            build: (context) {
              return pw.Column(
                children: [
                  pw.SizedBox(
                    height: imageAreaHeight,
                    width: double.infinity,
                    child: pw.Center(
                      child: pw.Padding(
                        padding:
                            const pw.EdgeInsets.all(8),
                        child: pw.Image(
                          pdfImage,
                          fit: pw.BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                  _buildScanlyBranding(),
                ],
              );
            },
          ),
        );

        debugPrint(
          'IMAGE ${i + 1} DONE',
        );
      }

      if (savedPageImagePaths.isEmpty) {
        throw Exception(
          'No valid images were processed',
        );
      }

      debugPrint('SAVING PDF...');

      final pdfBytes = await document.save();

      debugPrint(
        'PDF SAVED: ${pdfBytes.length} bytes',
      );

      var fileName = '$documentName.pdf';

      var pdfPath =
          '${documentsDirectory.path}/$fileName';

      var pdfFile = File(pdfPath);

      int counter = 1;

      while (await pdfFile.exists()) {
        fileName =
            '$documentName ($counter).pdf';

        pdfPath =
            '${documentsDirectory.path}/$fileName';

        pdfFile = File(pdfPath);

        counter++;
      }

      debugPrint('WRITING PDF FILE...');

      await pdfFile.writeAsBytes(
        pdfBytes,
        flush: true,
      );

      debugPrint(
        'PDF FILE WRITTEN: ${pdfFile.path}',
      );

      final item = _createItem(
        pdfFile.path,
        fileName,
      );

      await ScanlyActivityService.addRecent(item);

      if (!mounted) {
        return;
      }

      debugPrint('OPENING PREVIEW...');

      context.push(
        '/pdf-preview',
        extra: {
          'pdfBytes': Uint8List.fromList(pdfBytes),
          'fileName': fileName,
          'filePath': pdfFile.path,
          'imagePaths': savedPageImagePaths,
        },
      );
    } catch (e, stackTrace) {
      debugPrint(
        '========== CREATE PDF ERROR =========',
      );
      debugPrint('$e');
      debugPrint(stackTrace.toString());

      if (!mounted) {
        return;
      }

      _showMessage(
        'Failed to create PDF',
        Icons.error_outline_rounded,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isCreating = false;
        });
      }

      debugPrint(
        '========== CREATE PDF END =========',
      );
    }
  }

  void _showMessage(
    String message,
    IconData icon,
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
          behavior: SnackBarBehavior.floating,
          backgroundColor:
              colors.inverseSurface,
          shape: RoundedRectangleBorder(
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
              const SizedBox(width: 10),
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

  Widget _buildTopSection(
    ColorScheme colors,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        16,
        12,
        16,
        12,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(
          bottom: BorderSide(
            color: colors.onSurface.withValues(
              alpha: 0.08,
            ),
          ),
        ),
      ),
      child: Column(
        children: [
          TextField(
            controller: _nameController,
            textInputAction:
                TextInputAction.done,
            decoration: InputDecoration(
              labelText: 'PDF File Name',
              hintText: 'Enter PDF name',
              prefixIcon: const Icon(
                Icons
                    .drive_file_rename_outline_rounded,
              ),
              suffixText: '.pdf',
              filled: true,
              fillColor:
                  colors.surfaceContainerHighest,
              border: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(16),
                borderSide:
                    BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed:
                      _isCreating
                          ? null
                          : _pickImages,
                  style:
                      OutlinedButton.styleFrom(
                    minimumSize:
                        const Size(
                      double.infinity,
                      52,
                    ),
                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(
                        16,
                      ),
                    ),
                  ),
                  icon: const Icon(
                    Icons
                        .add_photo_alternate_rounded,
                  ),
                  label: const Text(
                    'Add Images',
                    style: TextStyle(
                      fontWeight:
                          FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed:
                      _isCreating ||
                              _selectedImages.isEmpty
                          ? null
                          : _createPdf,
                  style:
                      FilledButton.styleFrom(
                    minimumSize:
                        const Size(
                      double.infinity,
                      52,
                    ),
                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(
                        16,
                      ),
                    ),
                  ),
                  icon: _isCreating
                      ? const SizedBox(
                          width: 19,
                          height: 19,
                          child:
                              CircularProgressIndicator(
                            strokeWidth: 2,
                            color:
                                Colors.white,
                          ),
                        )
                      : const Icon(
                          Icons
                              .picture_as_pdf_rounded,
                        ),
                  label: Text(
                    _isCreating
                        ? 'Creating...'
                        : 'Create PDF',
                    style:
                        const TextStyle(
                      fontWeight:
                          FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyPreview(
    ColorScheme colors,
  ) {
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                color:
                    colors.primary.withValues(
                  alpha: 0.10,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons
                    .photo_library_outlined,
                size: 54,
                color:
                    colors.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No Images Added',
              style: TextStyle(
                fontSize: 21,
                fontWeight:
                    FontWeight.w800,
                color:
                    colors.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add images and they will appear here as PDF pages.',
              textAlign:
                  TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color:
                    colors.onSurface
                        .withValues(
                  alpha: 0.60,
                ),
              ),
            ),
            const SizedBox(height: 22),
            FilledButton.icon(
              onPressed: _pickImages,
              icon: const Icon(
                Icons
                    .add_photo_alternate_rounded,
              ),
              label: const Text(
                'Add Images',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageCard(
    ColorScheme colors,
    int index,
  ) {
    final image =
        _selectedImages[index];

    final file = File(image.path);

    return Container(
      margin:
          const EdgeInsets.only(
        bottom: 16,
      ),
      decoration: BoxDecoration(
        color:
            colors.surfaceContainerHighest,
        borderRadius:
            BorderRadius.circular(20),
        border: Border.all(
          color:
              colors.onSurface.withValues(
            alpha: 0.08,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withValues(
              alpha: 0.05,
            ),
            blurRadius: 12,
            offset:
                const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior:
          Clip.antiAlias,
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                width:
                    double.infinity,
                constraints:
                    const BoxConstraints(
                  minHeight: 220,
                  maxHeight: 500,
                ),
                color:
                    colors.surface,
                child:
                    file.existsSync()
                        ? Image.file(
                            file,
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
                              return _buildImageError(
                                colors,
                              );
                            },
                          )
                        : _buildImageError(
                            colors,
                          ),
              ),
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration:
                      BoxDecoration(
                    color:
                        Colors.black.withValues(
                      alpha: 0.70,
                    ),
                    borderRadius:
                        BorderRadius.circular(
                      20,
                    ),
                  ),
                  child: Text(
                    'Page ${index + 1}',
                    style:
                        const TextStyle(
                      color:
                          Colors.white,
                      fontSize: 12,
                      fontWeight:
                          FontWeight.w800,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 10,
                right: 10,
                child: Material(
                  color:
                      Colors.black.withValues(
                    alpha: 0.70,
                  ),
                  shape:
                      const CircleBorder(),
                  child: InkWell(
                    customBorder:
                        const CircleBorder(),
                    onTap: _isCreating
                        ? null
                        : () {
                            _removeImage(
                              index,
                            );
                          },
                    child:
                        const Padding(
                      padding:
                          EdgeInsets.all(
                        9,
                      ),
                      child: Icon(
                        Icons
                            .close_rounded,
                        color:
                            Colors.white,
                        size: 21,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding:
                const EdgeInsets.fromLTRB(
              14,
              11,
              10,
              11,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    image.name,
                    maxLines: 1,
                    overflow:
                        TextOverflow.ellipsis,
                    style:
                        TextStyle(
                      fontSize: 13,
                      fontWeight:
                          FontWeight.w600,
                      color:
                          colors.onSurface,
                    ),
                  ),
                ),
                const SizedBox(
                  width: 8,
                ),
                ReorderableDelayedDragStartListener(
                  index: index,
                  enabled:
                      !_isCreating,
                  child: Container(
                    padding:
                        const EdgeInsets.all(
                      8,
                    ),
                    decoration:
                        BoxDecoration(
                      color: colors
                          .primary
                          .withValues(
                        alpha: 0.10,
                      ),
                      borderRadius:
                          BorderRadius.circular(
                        10,
                      ),
                    ),
                    child: Icon(
                      Icons
                          .drag_indicator_rounded,
                      color:
                          colors.primary,
                      size: 22,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageError(
    ColorScheme colors,
  ) {
    return SizedBox(
      height: 260,
      child: Column(
        mainAxisAlignment:
            MainAxisAlignment.center,
        children: [
          Icon(
            Icons
                .broken_image_outlined,
            size: 52,
            color:
                colors.error,
          ),
          const SizedBox(height: 10),
          Text(
            'Unable to preview image',
            style:
                TextStyle(
              color:
                  colors.onSurface,
              fontWeight:
                  FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

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
        title: const Text(
          'Image to PDF',
          style: TextStyle(
            fontWeight:
                FontWeight.w800,
          ),
        ),
      ),
      body: Column(
        children: [
          _buildTopSection(
            colors,
          ),
          Expanded(
            child:
                _selectedImages.isEmpty
                    ? _buildEmptyPreview(
                        colors,
                      )
                    : ReorderableListView
                        .builder(
                        padding:
                            const EdgeInsets
                                .fromLTRB(
                          14,
                          14,
                          14,
                          30,
                        ),
                        itemCount:
                            _selectedImages
                                .length,
                        onReorder:
                            _moveImage,
                        buildDefaultDragHandles:
                            false,
                        itemBuilder:
                            (
                          context,
                          index,
                        ) {
                          return KeyedSubtree(
                            key: ValueKey(
                              _selectedImages[
                                      index]
                                  .path,
                            ),
                            child:
                                _buildImageCard(
                              colors,
                              index,
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
