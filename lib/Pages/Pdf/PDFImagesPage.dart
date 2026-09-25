import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import 'package:scanly/Service/Ads/AdService.dart';
import 'package:scanly/Service/Pdf/PDFGeneratorService.dart';

import 'package:scanly/Widgets/PDF/PDFTopSection.dart';
import 'package:scanly/Widgets/Pdf/PDFEmptyState.dart';
import 'package:scanly/Widgets/Pdf/PDFImageCard.dart';

class PDFImagesPage extends StatefulWidget {
  const PDFImagesPage({
    super.key,
  });

  @override
  State<PDFImagesPage> createState() =>
      _PDFImagesPageState();
}

class _PDFImagesPageState
    extends State<PDFImagesPage> {
  // ============================================================
  // CONTROLLERS
  // ============================================================

  final ImagePicker _picker =
      ImagePicker();

  final List<XFile> _selectedImages = [];

  final TextEditingController
      _nameController =
      TextEditingController(
    text: 'Scanly Document',
  );

  // ============================================================
  // STATE
  // ============================================================

  bool _isCreating = false;

  Uint8List? _scanlyLogoBytes;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _loadScanlyLogo();
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _nameController.dispose();

    super.dispose();
  }

  // ============================================================
  // LOAD LOGO
  // ============================================================

  Future<void> _loadScanlyLogo() async {
    try {
      final data =
          await rootBundle.load(
        'assets/images/Scanly_Splash.png',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _scanlyLogoBytes =
            data.buffer.asUint8List();
      });
    } catch (e) {
      debugPrint(
        'LOAD SCANLY LOGO ERROR: $e',
      );
    }
  }

  // ============================================================
  // PICK IMAGES
  // ============================================================

  Future<void> _pickImages() async {
    if (_isCreating) {
      return;
    }

    try {
      final images =
          await _picker.pickMultiImage();

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
      debugPrint(
        'PICK IMAGES ERROR: $e',
      );

      if (!mounted) {
        return;
      }

      _showMessage(
        'Could not select images',
        Icons.error_outline_rounded,
      );
    }
  }

  // ============================================================
  // REMOVE IMAGE
  // ============================================================

  void _removeImage(
    int index,
  ) {
    if (_isCreating) {
      return;
    }

    if (index < 0 ||
        index >= _selectedImages.length) {
      return;
    }

    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  // ============================================================
  // REORDER IMAGES
  // ============================================================

  void _moveImage(
    int oldIndex,
    int newIndex,
  ) {
    if (_isCreating) {
      return;
    }

    if (oldIndex < 0 ||
        oldIndex >= _selectedImages.length) {
      return;
    }

    if (newIndex < 0 ||
        newIndex > _selectedImages.length) {
      return;
    }

    setState(() {
      if (newIndex > oldIndex) {
        newIndex--;
      }

      final image =
          _selectedImages.removeAt(
        oldIndex,
      );

      _selectedImages.insert(
        newIndex,
        image,
      );
    });
  }

  // ============================================================
  // CLEAN FILE NAME
  // ============================================================

  String _cleanFileName(
    String value,
  ) {
    var name = value.trim();

    if (name.isEmpty) {
      name = 'Scanly Document';
    }

    name = name.replaceAll(
      RegExp(r'[\\/:*?"<>|]'),
      '_',
    );

    if (name.toLowerCase().endsWith('.pdf')) {
      name = name.substring(
        0,
        name.length - 4,
      );
    }

    name = name.trim();

    if (name.isEmpty) {
      name = 'Scanly Document';
    }

    return name;
  }

  // ============================================================
  // CREATE PDF
  // ============================================================

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
      final documentName =
          _cleanFileName(
        _nameController.text,
      );

      final imagePaths =
          _selectedImages
              .map(
                (image) => image.path,
              )
              .toList();

      final scanlyDocument =
          await PDFGeneratorService.createPdf(
        imagePaths: imagePaths,
        documentName: documentName,
        logoBytes: _scanlyLogoBytes,
      );

      // ========================================================
      // ACTIVITY ITEM
      // ========================================================

      final filePath =
          scanlyDocument.filePath!;

      final fileName =
          filePath.split('/').last;

      final item =
          PDFGeneratorService.createItem(
        path: filePath,
        fileName: fileName,
      );

      // ========================================================
      // BACKGROUND SAVE
      // ========================================================

      unawaited(
        PDFGeneratorService
            .finishBackgroundSave(
          document: scanlyDocument,
          item: item,
          fileName: fileName,
        ),
      );

      // ========================================================
      // INTERSTITIAL AD
      // ========================================================

      await AdService.showInterstitial();

      // ========================================================
      // OPEN PREVIEW
      // ========================================================

      if (!mounted) {
        return;
      }

      setState(() {
        _selectedImages.clear();

        _nameController.text =
            'Scanly Document';

        _isCreating = false;
      });

      await context.push(
        '/pdf-preview',
        extra: scanlyDocument,
      );
    } catch (e, stackTrace) {
      debugPrint(
        'CREATE PDF ERROR: $e',
      );

      debugPrint(
        stackTrace.toString(),
      );

      if (!mounted) {
        return;
      }

      _showMessage(
        'Failed to create PDF',
        Icons.error_outline_rounded,
      );
    } finally {
      if (mounted && _isCreating) {
        setState(() {
          _isCreating = false;
        });
      }
    }
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
        Theme.of(context).colorScheme;

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
        title: const Text(
          'Image to PDF',
          style: TextStyle(
            fontWeight:
                FontWeight.w800,
          ),
        ),
      ),

      resizeToAvoidBottomInset:
          true,

      body: Column(
        children: [
          PDFTopSection(
            colors: colors,
            nameController:
                _nameController,
            isCreating:
                _isCreating,
            hasImages:
                _selectedImages.isNotEmpty,
            onAddImages:
                _pickImages,
            onCreatePdf:
                _createPdf,
          ),

          Expanded(
            child:
                _selectedImages.isEmpty
                    ? PDFEmptyState(
                        colors: colors,
                        isCreating:
                            _isCreating,
                        onAddImages:
                            _pickImages,
                      )
                    : ReorderableListView.builder(
                        padding:
                            const EdgeInsets.fromLTRB(
                          14,
                          14,
                          14,
                          30,
                        ),
                        itemCount:
                            _selectedImages.length,
                        onReorder:
                            _moveImage,
                        buildDefaultDragHandles:
                            false,
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior
                                .onDrag,
                        itemBuilder:
                            (
                          context,
                          index,
                        ) {
                          final image =
                              _selectedImages[
                                  index];

                          return PDFImageCard(
                            key: ValueKey(
                              image.path,
                            ),
                            image: image,
                            index: index,
                            isCreating:
                                _isCreating,
                            onRemove: () {
                              _removeImage(
                                index,
                              );
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}