import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:scanly/Core/Scanly_Items.dart';
import 'package:scanly/Pages/QR/QR_Share_Sheet.dart';
import 'package:scanly/Widgets/Qr/QRPreviewActions.dart';
import 'package:scanly/Widgets/Qr/QRPreviewCard.dart';
import 'package:scanly/core/ScanlyActivityService.dart';

import 'QRPreviewUtils.dart';

class QRPreviewPage extends StatefulWidget {
  final String value;

  const QRPreviewPage({
    super.key,
    required this.value,
  });

  @override
  State<QRPreviewPage> createState() =>
      _QRPreviewPageState();
}

class _QRPreviewPageState extends State<QRPreviewPage> {
  final GlobalKey _qrKey = GlobalKey();

  static const MethodChannel _shareChannel =
      MethodChannel('scanly/share');

  bool _isSaving = false;
  bool _isSharing = false;

  String get _itemId {
    return QRPreviewUtils.itemId(
      widget.value,
    );
  }

  String get _subtitle {
    return QRPreviewUtils.getSubtitle(
      widget.value,
    );
  }

  ScanlyItem get _scanlyItem {
    return ScanlyItem(
      id: _itemId,
      title: 'QR Code',
      subtitle: _subtitle,
      type: 'qr',
      route: '/qr-tools',
      data: widget.value,
      createdAt:
          DateTime.now().millisecondsSinceEpoch,
    );
  }

  bool get _isFavorite {
    return ScanlyActivityService.isFavorite(
      _itemId,
    );
  }

  // =====================================================
  // SYNC FAVORITE STATE
  // =====================================================

  void _onGlobalActivityChanged() {
    if (!mounted) return;

    setState(() {});
  }

  // =====================================================
  // TOGGLE FAVORITE
  // =====================================================

  Future<void> _toggleFavorite() async {
    final currentlyFavorite = _isFavorite;

    if (currentlyFavorite) {
      await ScanlyActivityService.removeFavorite(
        _itemId,
      );

      if (mounted) {
        _showMessage(
          'Removed from Favorites',
        );
      }
    } else {
      await ScanlyActivityService.addFavorite(
        _scanlyItem,
      );

      if (mounted) {
        _showMessage(
          'Added to Favorites',
        );
      }
    }

    if (mounted) {
      setState(() {});
    }
  }

  // =====================================================
  // RECENT
  // =====================================================

  Future<void> _createRecentIfNeeded() async {
    await ScanlyActivityService.addRecent(
      _scanlyItem,
    );
  }

  // =====================================================
  // CREATE QR IMAGE
  // =====================================================

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

      final Uint8List bytes =
          byteData.buffer.asUint8List();

      final directory =
          await getTemporaryDirectory();

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

  // =====================================================
  // SAVE QR
  // =====================================================

  Future<void> _saveQR() async {
    if (_isSaving || _isSharing) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final imagePath =
          await _createQRImage();

      if (imagePath == null) {
        _showMessage(
          'Could not create QR Code',
        );
        return;
      }

      final bytes =
          await File(imagePath).readAsBytes();

      final result =
          await ImageGallerySaverPlus.saveImage(
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

  // =====================================================
  // SHARE TO APP
  // =====================================================

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
      final imagePath =
          await _createQRImage();

      if (imagePath == null ||
          imagePath.isEmpty) {
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
          'text':
              'QR Code generated with Scanly',
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
        e.message ??
            'Could not share QR Code',
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

  // =====================================================
  // SHARE MORE
  // =====================================================

  Future<void> _shareMore() async {
    if (widget.value.isEmpty) {
      _showMessage(
        'QR Code is empty',
      );
      return;
    }

    try {
      final imagePath =
          await _createQRImage();

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
          'text':
              'QR Code generated with Scanly',
        },
      );
    } on PlatformException catch (e) {
      debugPrint(
        'SHARE MORE ERROR: ${e.message}',
      );

      _showMessage(
        e.message ??
            'Could not share QR Code',
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

  // =====================================================
  // SHARE SHEET
  // =====================================================

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

  // =====================================================
  // COPY
  // =====================================================

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

  // =====================================================
  // MESSAGE
  // =====================================================

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior:
              SnackBarBehavior.floating,
        ),
      );
  }

  // =====================================================
  // INIT
  // =====================================================

  @override
  void initState() {
    super.initState();

    ScanlyActivityService.version.addListener(
      _onGlobalActivityChanged,
    );

    WidgetsBinding.instance
        .addPostFrameCallback((_) {
      _createRecentIfNeeded();
    });
  }

  // =====================================================
  // DISPOSE
  // =====================================================

  @override
  void dispose() {
    ScanlyActivityService.version
        .removeListener(
      _onGlobalActivityChanged,
    );

    super.dispose();
  }

  // =====================================================
  // BUILD
  // =====================================================

  @override
  Widget build(BuildContext context) {
    final colors =
        Theme.of(context).colorScheme;

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
                  color:
                      colors.onSurfaceVariant,
                ),
              ),

              const SizedBox(height: 24),

              QRPreviewCard(
                qrKey: _qrKey,
                value: widget.value,
                onCopy: _copyValue,
              ),

              const SizedBox(height: 16),

              QRPreviewActions(
                isFavorite: favorite,
                isSaving: _isSaving,
                isSharing: _isSharing,
                onToggleFavorite:
                    _toggleFavorite,
                onSave: _saveQR,
                onShare: _showShareSheet,
              ),
            ],
          ),
        ),
      ),
    );
  }
}