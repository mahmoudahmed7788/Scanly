import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:scanly/Core/Scanly_Items.dart';
import 'package:scanly/Widgets/Qr/QRCodePreview.dart';
import 'package:scanly/Widgets/Qr/QRTypeButton.dart';
import 'package:scanly/core/ScanlyActivityService.dart';
import 'package:share_plus/share_plus.dart';

import 'QRGeneratorUtils.dart';
import 'QR_Share_Sheet.dart';

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

  static const MethodChannel _shareChannel =
      MethodChannel('scanly/share');

  String _qrData = '';

  File? _selectedFile;

  QRType _selectedType = QRType.text;

  bool _isSaving = false;

  bool _isSharing = false;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  String _itemId(String value) {
    return QRGeneratorUtils.itemId(value);
  }

  ScanlyItem _createScanlyItem(String value) {
    final type = switch (_selectedType) {
      QRType.text => 'text',
      QRType.image => 'image',
      QRType.video => 'video',
    };

    return ScanlyItem(
      id: _itemId(value),
      title: 'QR Code',
      subtitle: QRGeneratorUtils.getSubtitle(
        value: value,
        type: type,
      ),
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
          QRGeneratorUtils.buildFileQRValue(
        type: 'image',
        path: image.path,
      );

      setState(() {
        _selectedFile = file;
        _qrData = qrValue;
        _selectedType = QRType.image;
      });

      widget.onGenerated(qrValue);

      await _registerGeneratedQR(qrValue);
    } catch (_) {
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
          QRGeneratorUtils.buildFileQRValue(
        type: 'video',
        path: video.path,
      );

      setState(() {
        _selectedFile = file;
        _qrData = qrValue;
        _selectedType = QRType.video;
      });

      widget.onGenerated(qrValue);

      await _registerGeneratedQR(qrValue);
    } catch (_) {
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
    } catch (_) {
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
    } catch (_) {
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
    } catch (_) {
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
    } catch (_) {
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
      await ScanlyActivityService.removeFavorite(
        item.id,
      );

      widget.onToggleFavorite(_qrData);

      if (mounted) {
        _showMessage(
          'Removed from Favorites.',
        );
      }
    } else {
      await ScanlyActivityService.addFavorite(
        item,
      );

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
          behavior: SnackBarBehavior.floating,
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
          padding: const EdgeInsets.fromLTRB(
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

              Row(
                children: [
                  Expanded(
                    child: QRTypeButton(
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
                          _selectedFile = null;
                          _qrData = '';
                        });
                      },
                    ),
                  ),

                  const SizedBox(width: 10),

                  Expanded(
                    child: QRTypeButton(
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
                    child: QRTypeButton(
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
                      Icons.qr_code_2_rounded,
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

              if (_selectedType ==
                      QRType.image &&
                  _qrData.isEmpty)
                QRFilePickerCard(
                  icon: Icons.image_rounded,
                  title: 'Select an Image',
                  subtitle:
                      'Choose an image from your gallery',
                  onTap: _pickImage,
                ),

              if (_selectedType ==
                      QRType.video &&
                  _qrData.isEmpty)
                QRFilePickerCard(
                  icon:
                      Icons.video_library_rounded,
                  title: 'Select a Video',
                  subtitle:
                      'Choose a video from your gallery',
                  onTap: _pickVideo,
                ),

              const SizedBox(height: 24),

              if (hasQR)
                QRCodePreview(
                  qrData: _qrData,
                  displayValue:
                      QRGeneratorUtils
                          .getDisplayValue(
                    qrData: _qrData,
                    filePath:
                        _selectedFile?.path,
                  ),
                  isSaving: _isSaving,
                  isSharing: _isSharing,
                  isFavorite: favorite,
                  qrKey: _qrKey,
                  onCopy: () {
                    Clipboard.setData(
                      ClipboardData(
                        text: _qrData,
                      ),
                    );

                    _showMessage(
                      'QR value copied.',
                    );
                  },
                  onSave: _saveQR,
                  onShare: _showShareSheet,
                  onToggleFavorite:
                      _toggleFavorite,
                  onCreateAnother:
                      _createAnother,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

extension on _QRGeneratorPageState {
  QRFilePickerCard({required IconData icon, required String title, required String subtitle, required Future<void> Function() onTap}) {}
}

enum QRType {
  text,
  image,
  video,
}