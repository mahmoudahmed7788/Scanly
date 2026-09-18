import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:scanly/QR_Share_Sheet.dart';
import 'package:scanly/ScanlyActivityService.dart';
import 'package:scanly/Scanly_Items.dart';

class QRPreviewPage extends StatefulWidget {
  final String value;

  const QRPreviewPage({
    super.key,
    required this.value,
  });

  @override
  State<QRPreviewPage> createState() => _QRPreviewPageState();
}

class _QRPreviewPageState extends State<QRPreviewPage> {
  final GlobalKey _qrKey = GlobalKey();

  static const MethodChannel _shareChannel =
      MethodChannel('scanly/share');

  bool _isSaving = false;
  bool _isSharing = false;

  String get _itemId {
    return 'qr_${base64Url.encode(
      utf8.encode(widget.value),
    )}';
  }

  ScanlyItem get _scanlyItem {
    String subtitle;

    if (widget.value.startsWith('scanly://file?type=image')) {
      subtitle = 'QR Image';
    } else if (widget.value.startsWith('scanly://file?type=video')) {
      subtitle = 'QR Video';
    } else {
      subtitle = widget.value;
    }

    return ScanlyItem(
      id: _itemId,
      title: 'QR Code',
      subtitle: subtitle,
      type: 'qr',
      route: '/qr-tools',
      data: widget.value,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );
  }

  bool get _isFavorite {
    return ScanlyActivityService.isFavorite(_itemId);
  }

  Future<void> _toggleFavorite() async {
    if (_isFavorite) {
      await ScanlyActivityService.removeFavorite(_itemId);

      if (mounted) {
        _showMessage('Removed from Favorites');
      }
    } else {
      await ScanlyActivityService.addFavorite(_scanlyItem);

      if (mounted) {
        _showMessage('Added to Favorites');
      }
    }

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _createRecentIfNeeded() async {
    await ScanlyActivityService.addRecent(_scanlyItem);
  }

  Future<String?> _createQRImage() async {
    try {
      final boundary =
          _qrKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;

      if (boundary == null) {
        return null;
      }

      final image = await boundary.toImage(
        pixelRatio: 3.0,
      );

      final byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );

      if (byteData == null) {
        return null;
      }

      final Uint8List bytes = byteData.buffer.asUint8List();

      final directory = await getTemporaryDirectory();

      final file = File(
        '${directory.path}/scanly_qr_${DateTime.now().millisecondsSinceEpoch}.png',
      );

      await file.writeAsBytes(bytes);

      return file.path;
    } catch (e) {
      debugPrint(
        'CREATE QR IMAGE ERROR: $e',
      );

      return null;
    }
  }

  Future<void> _saveQR() async {
    if (_isSaving || _isSharing) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final imagePath = await _createQRImage();

      if (imagePath == null) {
        _showMessage(
          'Could not create QR Code',
        );
        return;
      }

      final bytes = await File(imagePath).readAsBytes();

      final result = await ImageGallerySaverPlus.saveImage(
        bytes,
        quality: 100,
        name:
            'Scanly_QR_${DateTime.now().millisecondsSinceEpoch}',
      );

      debugPrint(
        'SAVE RESULT: $result',
      );

      _showMessage(
        'QR Code saved to Gallery successfully',
      );
    } catch (e) {
      debugPrint(
        'SAVE QR ERROR: $e',
      );

      _showMessage(
        'Could not save QR Code',
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
    if (widget.value.isEmpty) {
      _showMessage(
        'QR Code is empty',
      );
      return;
    }

    setState(() {
      _isSharing = true;
    });

    try {
      final imagePath = await _createQRImage();

      if (imagePath == null || imagePath.isEmpty) {
        _showMessage(
          'QR Code is not ready yet',
        );
        return;
      }

      final result =
          await _shareChannel.invokeMethod<bool>(
        'shareToApp',
        {
          'filePath': imagePath,
          'packageNames': packageNames,
          'text': 'QR Code generated with Scanly',
        },
      );

      if (result != true) {
        _showMessage(
          'App is not installed',
        );
      }
    } on PlatformException catch (e) {
      debugPrint(
        'SHARE ERROR CODE: ${e.code}',
      );

      debugPrint(
        'SHARE ERROR MESSAGE: ${e.message}',
      );

      _showMessage(
        e.message ?? 'Could not share QR Code',
      );
    } catch (e) {
      debugPrint(
        'SHARE ERROR: $e',
      );

      _showMessage(
        'Could not share QR Code',
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
    if (widget.value.isEmpty) {
      _showMessage(
        'QR Code is empty',
      );
      return;
    }

    try {
      final imagePath = await _createQRImage();

      if (imagePath == null) {
        _showMessage(
          'QR Code is not ready yet',
        );
        return;
      }

      await _shareChannel.invokeMethod(
        'shareMore',
        {
          'filePath': imagePath,
          'text': 'QR Code generated with Scanly',
        },
      );
    } on PlatformException catch (e) {
      debugPrint(
        'SHARE MORE ERROR: ${e.message}',
      );

      _showMessage(
        e.message ?? 'Could not share QR Code',
      );
    } catch (e) {
      debugPrint(
        'SHARE MORE ERROR: $e',
      );

      _showMessage(
        'Could not share QR Code',
      );
    }
  }

  void _showShareSheet() {
    if (_isSaving || _isSharing) {
      return;
    }

    QRShareSheet.show(
      context: context,
      onShare: _shareTo,
      onShareMore: _shareMore,
    );
  }

  Future<void> _copyValue() async {
    await Clipboard.setData(
      ClipboardData(
        text: widget.value,
      ),
    );

    _showMessage(
      'Copied to clipboard',
    );
  }

  void _showMessage(
    String message,
  ) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _createRecentIfNeeded();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final favorite = _isFavorite;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'QR Preview',
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: favorite
                ? 'Remove from Favorites'
                : 'Add to Favorites',
            onPressed: _toggleFavorite,
            icon: Icon(
              favorite
                  ? Icons.favorite_rounded
                  : Icons.favorite_border_rounded,
              color: favorite
                  ? Colors.redAccent
                  : null,
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            20,
            12,
            20,
            30,
          ),
          child: Column(
            children: [
              Text(
                'Your QR Code',
                style: Theme.of(context)
                    .textTheme
                    .headlineMedium,
              ),
              const SizedBox(height: 6),
              Text(
                'Preview, save or share your QR Code',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: colors.outlineVariant.withValues(
                      alpha: 0.5,
                    ),
                  ),
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                      color: Colors.black.withValues(
                        alpha: 0.06,
                      ),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    RepaintBoundary(
                      key: _qrKey,
                      child: Container(
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: QrImageView(
                          data: widget.value,
                          size: 270,
                          backgroundColor: Colors.white,
                          errorCorrectionLevel:
                              QrErrorCorrectLevel.H,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: colors.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        widget.value,
                        textAlign: TextAlign.center,
                        maxLines: 5,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: colors.onSurface,
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextButton.icon(
                      onPressed: _copyValue,
                      icon: const Icon(
                        Icons.copy_rounded,
                      ),
                      label: const Text(
                        'Copy Value',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // FAVORITE BUTTON
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: _toggleFavorite,
                  icon: Icon(
                    favorite
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    color: favorite
                        ? Colors.redAccent
                        : null,
                  ),
                  label: Text(
                    favorite
                        ? 'Remove from Favorites'
                        : 'Add to Favorites',
                  ),
                ),
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 54,
                      child: OutlinedButton.icon(
                        onPressed:
                            _isSaving || _isSharing
                                ? null
                                : _saveQR,
                        icon: _isSaving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child:
                                    CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(
                                Icons.download_rounded,
                              ),
                        label: Text(
                          _isSaving
                              ? 'Saving...'
                              : 'Save',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SizedBox(
                      height: 54,
                      child: FilledButton.icon(
                        onPressed:
                            _isSaving || _isSharing
                                ? null
                                : _showShareSheet,
                        icon: _isSharing
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child:
                                    CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(
                                Icons.share_rounded,
                              ),
                        label: Text(
                          _isSharing
                              ? 'Sharing...'
                              : 'Share',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Share your QR Code with your favorite apps',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colors.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}