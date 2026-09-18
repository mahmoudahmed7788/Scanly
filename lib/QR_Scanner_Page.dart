import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QRScannerPage extends StatefulWidget {
  final ValueChanged<String> onScan;
  final bool Function(String value) isFavorite;
  final ValueChanged<String> onToggleFavorite;

  const QRScannerPage({
    super.key,
    required this.onScan,
    required this.isFavorite,
    required this.onToggleFavorite,
  });

  @override
  State<QRScannerPage> createState() => _QRScannerPageState();
}

class _QRScannerPageState extends State<QRScannerPage> {
  final MobileScannerController _controller = MobileScannerController();
  final ImagePicker _imagePicker = ImagePicker();

  bool _detected = false;
  String? _scannedValue;

  // =========================
  // Check Image URL
  // =========================

  bool _isImageUrl(String value) {
    final uri = Uri.tryParse(value);

    if (uri == null ||
        !(uri.scheme == 'http' || uri.scheme == 'https')) {
      return false;
    }

    final path = uri.path.toLowerCase();

    return path.endsWith('.jpg') ||
        path.endsWith('.jpeg') ||
        path.endsWith('.png') ||
        path.endsWith('.webp') ||
        path.endsWith('.gif');
  }

  // =========================
  // Scan QR from Camera
  // =========================

  void _handleBarcode(BarcodeCapture capture) {
    if (_detected) return;

    for (final barcode in capture.barcodes) {
      final value = barcode.rawValue;

      if (value != null && value.trim().isNotEmpty) {
        setState(() {
          _detected = true;
          _scannedValue = value;
        });

        widget.onScan(value);

        _controller.stop();
        break;
      }
    }
  }

  // =========================
  // Scan QR from Gallery
  // =========================

  Future<void> _scanFromGallery() async {
    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
    );

    if (image == null) return;

    try {
      final BarcodeCapture? result =
          await _controller.analyzeImage(image.path);

      if (result == null || result.barcodes.isEmpty) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No QR Code found in this image'),
          ),
        );

        return;
      }

      for (final barcode in result.barcodes) {
        final value = barcode.rawValue;

        if (value != null && value.trim().isNotEmpty) {
          setState(() {
            _detected = true;
            _scannedValue = value;
          });

          widget.onScan(value);

          await _controller.stop();

          return;
        }
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No valid QR Code found'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not scan this image'),
        ),
      );
    }
  }

  // =========================
  // Scan Again
  // =========================

  Future<void> _scanAgain() async {
    setState(() {
      _detected = false;
      _scannedValue = null;
    });

    await _controller.start();
  }

  // =========================
  // Copy Result
  // =========================

  Future<void> _copyResult() async {
    if (_scannedValue == null) return;

    await Clipboard.setData(
      ClipboardData(
        text: _scannedValue!,
      ),
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Copied to clipboard'),
      ),
    );
  }

  // =========================
  // Toggle Favorite
  // =========================

  void _toggleFavorite() {
    if (_scannedValue == null) return;

    widget.onToggleFavorite(
      _scannedValue!,
    );

    setState(() {});
  }

  // =========================
  // Dispose
  // =========================

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // =========================
  // Result Widget
  // =========================

  Widget _buildResult({
    required ColorScheme colors,
  }) {
    if (_scannedValue == null) {
      return const SizedBox.shrink();
    }

    final value = _scannedValue!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // =========================
          // Result Header
          // =========================

          Row(
            children: [
              Icon(
                Icons.check_circle_rounded,
                color: colors.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Result',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: colors.onPrimaryContainer,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // =========================
          // Image Result
          // =========================

          if (_isImageUrl(value)) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.network(
                value,
                width: double.infinity,
                height: 220,
                fit: BoxFit.cover,

                loadingBuilder:
                    (context, child, loadingProgress) {
                  if (loadingProgress == null) {
                    return child;
                  }

                  return Container(
                    width: double.infinity,
                    height: 220,
                    alignment: Alignment.center,
                    color: colors.surface,
                    child: CircularProgressIndicator(
                      color: colors.primary,
                    ),
                  );
                },

                errorBuilder:
                    (context, error, stackTrace) {
                  return Container(
                    width: double.infinity,
                    height: 120,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      mainAxisAlignment:
                          MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.broken_image_outlined,
                          size: 40,
                          color: colors.onSurfaceVariant,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Unable to load image',
                          style: TextStyle(
                            color:
                                colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 10),

            Text(
              value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: colors.onPrimaryContainer,
                fontSize: 12,
              ),
            ),
          ]

          // =========================
          // Normal Text Result
          // =========================

          else
            Text(
              value,
              maxLines: 5,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: colors.onPrimaryContainer,
              ),
            ),

          const SizedBox(height: 14),

          // =========================
          // Copy + Scan Again
          // =========================

          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _copyResult,
                  icon: const Icon(
                    Icons.copy_rounded,
                  ),
                  label: const Text('Copy'),
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: FilledButton.icon(
                  onPressed: _scanAgain,
                  icon: const Icon(
                    Icons.qr_code_scanner_rounded,
                  ),
                  label: const Text('Scan Again'),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // =========================
          // Favorite
          // =========================

          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: _toggleFavorite,
              icon: Icon(
                widget.isFavorite(value)
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
              ),
              label: Text(
                widget.isFavorite(value)
                    ? 'Remove from Favorites'
                    : 'Add to Favorites',
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================
  // UI
  // =========================

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        16,
        8,
        16,
        16,
      ),
      child: Column(
        children: [
          // =========================
          // Title
          // =========================

          Text(
            _detected
                ? 'QR Code detected'
                : 'Point your camera at a QR Code',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: colors.onSurface,
            ),
          ),

          const SizedBox(height: 6),

          // =========================
          // Subtitle
          // =========================

          Text(
            _detected
                ? 'The result has been added to Recent'
                : 'Keep the QR Code inside the frame',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.onSurfaceVariant,
            ),
          ),

          const SizedBox(height: 20),

          // =========================
          // Camera Scanner
          // =========================

          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  MobileScanner(
                    controller: _controller,
                    onDetect: _handleBarcode,
                  ),

                  // Scanner Frame
                  Center(
                    child: Container(
                      width: 250,
                      height: 250,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.white,
                          width: 3,
                        ),
                        borderRadius:
                            BorderRadius.circular(24),
                      ),
                    ),
                  ),

                  // Scanning Indicator
                  if (!_detected)
                    Positioned(
                      bottom: 24,
                      left: 24,
                      right: 24,
                      child: Container(
                        padding:
                            const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(
                            alpha: 0.65,
                          ),
                          borderRadius:
                              BorderRadius.circular(14),
                        ),
                        child: const Row(
                          mainAxisAlignment:
                              MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.camera_alt_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Scanning...',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight:
                                    FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // =========================
          // Scan From Gallery
          // =========================

          if (!_detected)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _scanFromGallery,
                icon: const Icon(
                  Icons.photo_library_rounded,
                ),
                label: const Text(
                  'Scan from Gallery',
                ),
              ),
            ),

          const SizedBox(height: 16),

          // =========================
          // Result
          // =========================

          if (_detected && _scannedValue != null)
            _buildResult(
              colors: colors,
            ),
        ],
      ),
    );
  }
}