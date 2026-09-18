import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class QRSharePage extends StatelessWidget {
  final String imagePath;

  const QRSharePage({
    super.key,
    required this.imagePath,
  });

  static const MethodChannel _channel =
      MethodChannel('scanly/share');

  Future<void> _share(
    BuildContext context,
    List<String> packages,
  ) async {
    try {
      final result = await _channel.invokeMethod<bool>(
        'shareToApp',
        {
          'filePath': imagePath,
          'packageNames': packages,
          'text': 'QR Code generated with Scanly',
        },
      );

      if (result != true && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('App is not installed'),
          ),
        );
      }
    } on PlatformException catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.message ?? 'Could not share QR Code',
          ),
        ),
      );
    }
  }

  Future<void> _shareMore(BuildContext context) async {
    try {
      await _channel.invokeMethod<bool>(
        'shareMore',
        {
          'filePath': imagePath,
          'text': 'QR Code generated with Scanly',
        },
      );
    } on PlatformException catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.message ?? 'Could not share QR Code',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        title: const Text('Share QR Code'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colors.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Image.file(
                File(imagePath),
                height: 220,
              ),
            ),

            const SizedBox(height: 30),

            Text(
              'Share with',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),

            const SizedBox(height: 20),

            Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceAround,
              children: [
                _ShareButton(
                  icon: Icons.chat_rounded,
                  title: 'WhatsApp',
                  color: const Color(0xFF25D366),
                  onTap: () => _share(
                    context,
                    [
                      'com.whatsapp',
                      'com.whatsapp.w4b',
                    ],
                  ),
                ),
                _ShareButton(
                  icon: Icons.facebook_rounded,
                  title: 'Facebook',
                  color: const Color(0xFF1877F2),
                  onTap: () => _share(
                    context,
                    ['com.facebook.katana'],
                  ),
                ),
                _ShareButton(
                  icon: Icons.camera_alt_rounded,
                  title: 'Instagram',
                  color: const Color(0xFFE1306C),
                  onTap: () => _share(
                    context,
                    ['com.instagram.android'],
                  ),
                ),
                _ShareButton(
                  icon: Icons.send_rounded,
                  title: 'Telegram',
                  color: const Color(0xFF229ED9),
                  onTap: () => _share(
                    context,
                    ['org.telegram.messenger'],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 28),

            OutlinedButton.icon(
              onPressed: () => _shareMore(context),
              icon: const Icon(Icons.more_horiz_rounded),
              label: const Text('More Apps'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShareButton extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  const _ShareButton({
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        width: 70,
        child: Column(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                icon,
                color: color,
                size: 28,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}