import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:scanly/QR_Share_Sheet.dart';
import 'package:scanly/ScanlyActivityService.dart';
import 'package:scanly/Scanly_Items.dart';

class QRGeneratorPage extends StatefulWidget {
  final ValueChanged<String> onGenerated;
  final bool Function(String value) isFavorite;
  final ValueChanged<String> onToggleFavorite;

  const QRGeneratorPage({
    super.key,
    required this.onGenerated,
    required this.isFavorite,
    required this.onToggleFavorite,
  });

  @override
  State<QRGeneratorPage> createState() =>
      _QRGeneratorPageState();
}

class _QRGeneratorPageState
    extends State<QRGeneratorPage> {
  final TextEditingController _textController =
      TextEditingController();

  final ImagePicker _picker = ImagePicker();

  final GlobalKey _qrKey = GlobalKey();

  // Used only for saving QR image to gallery.
  static const MethodChannel _shareChannel =
      MethodChannel('scanly/share');

  String _qrData = '';

  File? _selectedFile;

  QRType _selectedType = QRType.text;

  bool _isSaving = false;

  bool _isSharing = false;

  String _itemId(String value) {
    return 'qr_${base64Url.encode(
      utf8.encode(value),
    )}';
  }

  ScanlyItem _createScanlyItem(String value) {
    String subtitle;

    if (_selectedType == QRType.image) {
      subtitle = 'Image QR Code';
    } else if (_selectedType == QRType.video) {
      subtitle = 'Video QR Code';
    } else {
      subtitle = value.length > 45
          ? value.substring(0, 45)
          : value;
    }

    return ScanlyItem(
      id: _itemId(value),
      title: 'QR Code',
      subtitle: subtitle,
      type: 'qr',
      route: '/qr-tools',
      data: value,
      createdAt:
          DateTime.now().millisecondsSinceEpoch,
    );
  }

  Future<void> _registerGeneratedQR(
    String value,
  ) async {
    final item = _createScanlyItem(value);

    await ScanlyActivityService.addRecent(item);
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _generateTextQR() async {
    final value = _textController.text.trim();

    if (value.isEmpty) {
      _showMessage(
        'Please enter some text first.',
      );
      return;
    }

    setState(() {
      _qrData = value;
      _selectedFile = null;
    });

    widget.onGenerated(value);

    await _registerGeneratedQR(value);
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image =
          await _picker.pickImage(
        source: ImageSource.gallery,
      );

      if (image == null) return;

      final file = File(image.path);

      final qrValue =
          'scanly://file?type=image&path=${image.path}';

      setState(() {
        _selectedFile = file;
        _qrData = qrValue;
      });

      widget.onGenerated(qrValue);

      await _registerGeneratedQR(qrValue);
    } catch (e) {
      _showMessage(
        'Failed to select image.',
      );
    }
  }

  Future<void> _pickVideo() async {
    try {
      final XFile? video =
          await _picker.pickVideo(
        source: ImageSource.gallery,
      );

      if (video == null) return;

      final file = File(video.path);

      final qrValue =
          'scanly://file?type=video&path=${video.path}';

      setState(() {
        _selectedFile = file;
        _qrData = qrValue;
      });

      widget.onGenerated(qrValue);

      await _registerGeneratedQR(qrValue);
    } catch (e) {
      _showMessage(
        'Failed to select video.',
      );
    }
  }

  Future<String?> _createQRImage() async {
    try {
      await WidgetsBinding.instance.endOfFrame;

      final boundary =
          _qrKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;

      if (boundary == null) {
        return null;
      }

      final ui.Image image =
          await boundary.toImage(
        pixelRatio: 3.0,
      );

      final ByteData? byteData =
          await image.toByteData(
        format: ui.ImageByteFormat.png,
      );

      image.dispose();

      if (byteData == null) {
        return null;
      }

      final Uint8List pngBytes =
          byteData.buffer.asUint8List();

      final directory =
          await getApplicationDocumentsDirectory();

      final qrDirectory = Directory(
        '${directory.path}/Scanly/QR',
      );

      if (!await qrDirectory.exists()) {
        await qrDirectory.create(
          recursive: true,
        );
      }

      final file = File(
        '${qrDirectory.path}/scanly_qr_${DateTime.now().millisecondsSinceEpoch}.png',
      );

      await file.writeAsBytes(
        pngBytes,
        flush: true,
      );

      return file.path;
    } catch (e) {
      if (mounted) {
        _showMessage(
          'Failed to create QR image.',
        );
      }

      return null;
    }
  }

  Future<void> _saveQR() async {
    if (_qrData.isEmpty) {
      _showMessage(
        'Generate a QR Code first.',
      );
      return;
    }

    if (_isSaving) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final imagePath =
          await _createQRImage();

      if (imagePath == null) {
        return;
      }

      final file = File(imagePath);

      if (!await file.exists()) {
        _showMessage(
          'QR image file was not created.',
        );
        return;
      }

      final fileName =
          'Scanly_QR_${DateTime.now().millisecondsSinceEpoch}.png';

      final savedUri =
          await _shareChannel.invokeMethod<String>(
        'saveQrToGallery',
        {
          'filePath': imagePath,
          'fileName': fileName,
        },
      );

      if (!mounted) return;

      if (savedUri != null &&
          savedUri.isNotEmpty) {
        _showMessage(
          'QR Code saved to Scanly Images.',
        );
      } else {
        _showMessage(
          'Failed to save QR Code.',
        );
      }
    } on PlatformException catch (e) {
      if (!mounted) return;

      _showMessage(
        e.message ?? 'Failed to save QR Code.',
      );
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        'Failed to save QR Code.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  // ----------------------------------------------------------
  // SHARE QR CODE
  // ----------------------------------------------------------

  Future<void> _shareTo(
    List<String> packageNames,
  ) async {
    if (_qrData.isEmpty) {
      _showMessage(
        'Generate a QR Code first.',
      );
      return;
    }

    if (_isSharing) return;

    setState(() {
      _isSharing = true;
    });

    try {
      final imagePath =
          await _createQRImage();

      if (imagePath == null) {
        return;
      }

      final file = File(imagePath);

      if (!await file.exists()) {
        _showMessage(
          'QR image file was not created.',
        );
        return;
      }

      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile(
              imagePath,
              mimeType: 'image/png',
            ),
          ],
          text: _qrData,
          subject: 'Scanly QR Code',
        ),
      );
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        'Failed to share QR Code.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSharing = false;
        });
      }
    }
  }

  Future<void> _shareMore() async {
    if (_qrData.isEmpty) {
      _showMessage(
        'Generate a QR Code first.',
      );
      return;
    }

    if (_isSharing) return;

    setState(() {
      _isSharing = true;
    });

    try {
      final imagePath =
          await _createQRImage();

      if (imagePath == null) {
        return;
      }

      final file = File(imagePath);

      if (!await file.exists()) {
        _showMessage(
          'QR image file was not created.',
        );
        return;
      }

      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile(
              imagePath,
              mimeType: 'image/png',
            ),
          ],
          text: _qrData,
          subject: 'Scanly QR Code',
        ),
      );
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        'Failed to share QR Code.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSharing = false;
        });
      }
    }
  }

  void _showShareSheet() {
    if (_qrData.isEmpty) {
      _showMessage(
        'Generate a QR Code first.',
      );
      return;
    }

    QRShareSheet.show(
      context: context,
      onShare: _shareTo,
      onShareMore: _shareMore,
    );
  }

  // ----------------------------------------------------------
  // FAVORITES
  // ----------------------------------------------------------

  Future<void> _toggleFavorite() async {
    if (_qrData.isEmpty) {
      _showMessage(
        'Generate a QR Code first.',
      );
      return;
    }

    final item =
        _createScanlyItem(_qrData);

    final currentlyFavorite =
        ScanlyActivityService.isFavorite(
      item.id,
    );

    if (currentlyFavorite) {
      await ScanlyActivityService
          .removeFavorite(item.id);

      widget.onToggleFavorite(_qrData);

      if (mounted) {
        _showMessage(
          'Removed from Favorites.',
        );
      }
    } else {
      await ScanlyActivityService
          .addFavorite(item);

      widget.onToggleFavorite(_qrData);

      if (mounted) {
        _showMessage(
          'Added to Favorites.',
        );
      }
    }

    if (mounted) {
      setState(() {});
    }
  }

  void _createAnother() {
    setState(() {
      _qrData = '';
      _selectedFile = null;
      _selectedType = QRType.text;
      _textController.clear();
    });
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior:
              SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(14),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final colors =
        Theme.of(context).colorScheme;

    final bool hasQR =
        _qrData.isNotEmpty;

    final bool favorite =
        hasQR &&
        ScanlyActivityService.isFavorite(
          _itemId(_qrData),
        );

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'QR Generator',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding:
              const EdgeInsets.fromLTRB(
            20,
            10,
            20,
            30,
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.stretch,
            children: [
              Text(
                'Create your QR Code',
                style: Theme.of(context)
                    .textTheme
                    .headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Generate a QR Code from text, images, or videos.',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium,
              ),
              const SizedBox(height: 24),

              // TYPE BUTTONS
              Row(
                children: [
                  Expanded(
                    child: _TypeButton(
                      icon:
                          Icons.text_fields_rounded,
                      label: 'Text',
                      selected:
                          _selectedType ==
                              QRType.text,
                      onTap: () {
                        setState(() {
                          _selectedType =
                              QRType.text;
                          _selectedFile =
                              null;
                          _qrData = '';
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _TypeButton(
                      icon:
                          Icons.image_rounded,
                      label: 'Image',
                      selected:
                          _selectedType ==
                              QRType.image,
                      onTap: () {
                        setState(() {
                          _selectedType =
                              QRType.image;
                          _qrData = '';
                        });

                        _pickImage();
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _TypeButton(
                      icon: Icons
                          .video_library_rounded,
                      label: 'Video',
                      selected:
                          _selectedType ==
                              QRType.video,
                      onTap: () {
                        setState(() {
                          _selectedType =
                              QRType.video;
                          _qrData = '';
                        });

                        _pickVideo();
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // TEXT INPUT
              if (_selectedType ==
                  QRType.text) ...[
                TextField(
                  controller:
                      _textController,
                  maxLines: 5,
                  minLines: 3,
                  textInputAction:
                      TextInputAction.newline,
                  decoration:
                      const InputDecoration(
                    hintText:
                        'Enter text, URL, phone number...',
                    prefixIcon: Padding(
                      padding:
                          EdgeInsets.only(
                        top: 14,
                      ),
                      child: Icon(
                        Icons.edit_rounded,
                      ),
                    ),
                    alignLabelWithHint:
                        true,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 56,
                  child:
                      ElevatedButton.icon(
                    onPressed:
                        _generateTextQR,
                    icon: const Icon(
                      Icons
                          .qr_code_2_rounded,
                    ),
                    label: const Text(
                      'Generate QR Code',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],

              // IMAGE PICKER
              if (_selectedType ==
                      QRType.image &&
                  _qrData.isEmpty)
                _FilePickerCard(
                  icon:
                      Icons.image_rounded,
                  title:
                      'Select an Image',
                  subtitle:
                      'Choose an image from your gallery',
                  onTap: _pickImage,
                ),

              // VIDEO PICKER
              if (_selectedType ==
                      QRType.video &&
                  _qrData.isEmpty)
                _FilePickerCard(
                  icon: Icons
                      .video_library_rounded,
                  title:
                      'Select a Video',
                  subtitle:
                      'Choose a video from your gallery',
                  onTap: _pickVideo,
                ),

              const SizedBox(height: 24),

              // QR PREVIEW
              if (hasQR)
                Container(
                  padding:
                      const EdgeInsets.all(20),
                  decoration:
                      BoxDecoration(
                    color: colors.surface,
                    borderRadius:
                        BorderRadius.circular(
                      24,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color:
                            Colors.black
                                .withValues(
                          alpha: 0.05,
                        ),
                        blurRadius: 20,
                        offset:
                            const Offset(
                          0,
                          8,
                        ),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Your QR Code',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight:
                              FontWeight.bold,
                          color:
                              colors.onSurface,
                        ),
                      ),
                      const SizedBox(
                        height: 18,
                      ),

                      // THIS ENTIRE AREA IS SHARED
                      RepaintBoundary(
                        key: _qrKey,
                        child: Container(
                          width:
                              double.infinity,
                          padding:
                              const EdgeInsets
                                  .fromLTRB(
                            24,
                            24,
                            24,
                            18,
                          ),
                          decoration:
                              BoxDecoration(
                            color:
                                Colors.white,
                            borderRadius:
                                BorderRadius
                                    .circular(
                              18,
                            ),
                          ),
                          child: Column(
                            mainAxisSize:
                                MainAxisSize
                                    .min,
                            children: [
                              QrImageView(
                                data: _qrData,
                                version:
                                    QrVersions
                                        .auto,
                                size: 240,
                                backgroundColor:
                                    Colors.white,
                                errorCorrectionLevel:
                                    QrErrorCorrectLevel
                                        .M,
                              ),
                              const SizedBox(
                                height: 18,
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment
                                        .center,
                                crossAxisAlignment:
                                    CrossAxisAlignment
                                        .center,
                                children: [
                                  Image.asset(
                                    'assets/images/Scanly_Splash.png',
                                    width: 38,
                                    height: 38,
                                    fit: BoxFit
                                        .contain,
                                  ),
                                  const SizedBox(
                                      width: 9),
                                  const Text(
                                    'Scanly',
                                    style:
                                        TextStyle(
                                      fontSize:
                                          22,
                                      fontWeight:
                                          FontWeight
                                              .w800,
                                      color:
                                          Color(
                                        0xFF5B5FEF,
                                      ),
                                      letterSpacing:
                                          0.2,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(
                        height: 18,
                      ),

                      // QR DATA
                      Container(
                        width:
                            double.infinity,
                        padding:
                            const EdgeInsets
                                .all(14),
                        decoration:
                            BoxDecoration(
                          color: colors
                              .surfaceContainerHighest,
                          borderRadius:
                              BorderRadius
                                  .circular(
                            14,
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                _selectedFile !=
                                        null
                                    ? _selectedFile!
                                        .path
                                    : _qrData,
                                maxLines: 2,
                                overflow:
                                    TextOverflow
                                        .ellipsis,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: colors
                                      .onSurfaceVariant,
                                ),
                              ),
                            ),
                            const SizedBox(
                              width: 8,
                            ),
                            IconButton(
                              tooltip: 'Copy',
                              onPressed: () {
                                Clipboard
                                    .setData(
                                  ClipboardData(
                                    text:
                                        _qrData,
                                  ),
                                );

                                _showMessage(
                                  'QR value copied.',
                                );
                              },
                              icon:
                                  const Icon(
                                Icons
                                    .copy_rounded,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(
                        height: 18,
                      ),

                      // SAVE + SHARE
                      Row(
                        children: [
                          Expanded(
                            child:
                                OutlinedButton
                                    .icon(
                              onPressed:
                                  _isSaving
                                      ? null
                                      : _saveQR,
                              icon: _isSaving
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child:
                                          CircularProgressIndicator(
                                        strokeWidth:
                                            2,
                                      ),
                                    )
                                  : const Icon(
                                      Icons
                                          .download_rounded,
                                    ),
                              label:
                                  const Text(
                                'Save',
                              ),
                            ),
                          ),
                          const SizedBox(
                              width: 12),
                          Expanded(
                            child:
                                ElevatedButton
                                    .icon(
                              onPressed:
                                  _isSharing
                                      ? null
                                      : _showShareSheet,
                              icon: _isSharing
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child:
                                          CircularProgressIndicator(
                                        strokeWidth:
                                            2,
                                        color: Colors
                                            .white,
                                      ),
                                    )
                                  : const Icon(
                                      Icons
                                          .share_rounded,
                                    ),
                              label:
                                  const Text(
                                'Share',
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(
                        height: 12,
                      ),

                      // FAVORITE
                      SizedBox(
                        width:
                            double.infinity,
                        child:
                            OutlinedButton
                                .icon(
                          onPressed:
                              _toggleFavorite,
                          icon: Icon(
                            favorite
                                ? Icons
                                    .favorite_rounded
                                : Icons
                                    .favorite_border_rounded,
                          ),
                          label: Text(
                            favorite
                                ? 'Remove from Favorites'
                                : 'Add to Favorites',
                          ),
                        ),
                      ),

                      const SizedBox(
                          height: 10),

                      // CREATE ANOTHER
                      TextButton.icon(
                        onPressed:
                            _createAnother,
                        icon: const Icon(
                          Icons
                              .refresh_rounded,
                        ),
                        label:
                            const Text(
                          'Create Another',
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

enum QRType {
  text,
  image,
  video,
}

class _TypeButton
    extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TypeButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors =
        Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius:
            BorderRadius.circular(18),
        child: AnimatedContainer(
          duration:
              const Duration(
            milliseconds: 200,
          ),
          padding:
              const EdgeInsets.symmetric(
            vertical: 14,
            horizontal: 8,
          ),
          decoration:
              BoxDecoration(
            color: selected
                ? colors.primary.withValues(
                    alpha: 0.10,
                  )
                : colors.surface,
            borderRadius:
                BorderRadius.circular(18),
            border: Border.all(
              color: selected
                  ? colors.primary
                  : colors
                      .surfaceContainerHighest,
              width:
                  selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: selected
                    ? colors.primary
                    : colors
                        .onSurfaceVariant,
                size: 26,
              ),
              const SizedBox(height: 7),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: selected
                      ? FontWeight.w700
                      : FontWeight.w500,
                  color: selected
                      ? colors.primary
                      : colors
                          .onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilePickerCard
    extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _FilePickerCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors =
        Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius:
            BorderRadius.circular(22),
        child: Container(
          width: double.infinity,
          padding:
              const EdgeInsets.all(24),
          decoration:
              BoxDecoration(
            color: colors.surface,
            borderRadius:
                BorderRadius.circular(22),
            border: Border.all(
              color:
                  colors.surfaceContainerHighest,
            ),
          ),
          child: Column(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration:
                    BoxDecoration(
                  color: colors.primary
                      .withValues(
                    alpha: 0.10,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 30,
                  color: colors.primary,
                ),
              ),
              const SizedBox(
                  height: 14),
              Text(
                title,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight:
                      FontWeight.bold,
                  color:
                      colors.onSurface,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                textAlign:
                    TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: colors
                      .onSurfaceVariant,
                ),
              ),
              const SizedBox(
                  height: 16),
              OutlinedButton(
                onPressed: onTap,
                child:
                    const Text(
                  'Choose File',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}