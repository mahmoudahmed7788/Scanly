import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

class QRPreviewCard extends StatelessWidget {
  final GlobalKey qrKey;
  final String value;
  final VoidCallback onCopy;

  const QRPreviewCard({
    super.key,
    required this.qrKey,
    required this.value,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
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
            key: qrKey,
            child: Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              child: QrImageView(
                data: value,
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
              value,
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
            onPressed: onCopy,
            icon: const Icon(
              Icons.copy_rounded,
            ),
            label: const Text(
              'Copy Value',
            ),
          ),
        ],
      ),
    );
  }
}