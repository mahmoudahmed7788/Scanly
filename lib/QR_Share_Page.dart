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
          SnackBar(
            content: const Text('App is not installed'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
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
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
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
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      backgroundColor: colors.surface,

      appBar: AppBar(
        elevation: 0,
        backgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,

        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),

        title: const Text(
          'Share QR Code',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),

        centerTitle: true,
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            20,
            12,
            20,
            28,
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.stretch,
            children: [
              // QR preview
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: colors.surfaceContainerHighest
                      .withValues(alpha: 0.45),
                  borderRadius:
                      BorderRadius.circular(24),
                  border: Border.all(
                    color: colors.outline.withValues(
                      alpha: 0.12,
                    ),
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 250,
                      height: 250,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                            BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(
                              alpha: 0.08,
                            ),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Image.file(
                        File(imagePath),
                        fit: BoxFit.contain,
                        errorBuilder:
                            (context, error, stackTrace) {
                          return const Center(
                            child: Icon(
                              Icons.broken_image_outlined,
                              size: 50,
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 18),

                    Text(
                      'Your QR Code is ready',
                      textAlign: TextAlign.center,
                      style: theme
                          .textTheme
                          .titleMedium
                          ?.copyWith(
                            fontWeight:
                                FontWeight.w700,
                          ),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      'Share it with your favorite app',
                      textAlign: TextAlign.center,
                      style: theme
                          .textTheme
                          .bodySmall
                          ?.copyWith(
                            color:
                                colors.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              Text(
                'Share with',
                style: theme
                    .textTheme
                    .titleLarge
                    ?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),

              const SizedBox(height: 16),

              // Apps
              Row(
                children: [
                  Expanded(
                    child: _ShareButton(
                      icon: Icons.chat_rounded,
                      title: 'WhatsApp',
                      color:
                          const Color(0xFF25D366),
                      onTap: () => _share(
                        context,
                        [
                          'com.whatsapp',
                          'com.whatsapp.w4b',
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(width: 10),

                  Expanded(
                    child: _ShareButton(
                      icon: Icons.facebook_rounded,
                      title: 'Facebook',
                      color:
                          const Color(0xFF1877F2),
                      onTap: () => _share(
                        context,
                        ['com.facebook.katana'],
                      ),
                    ),
                  ),

                  const SizedBox(width: 10),

                  Expanded(
                    child: _ShareButton(
                      icon: Icons.camera_alt_rounded,
                      title: 'Instagram',
                      color:
                          const Color(0xFFE1306C),
                      onTap: () => _share(
                        context,
                        ['com.instagram.android'],
                      ),
                    ),
                  ),

                  const SizedBox(width: 10),

                  Expanded(
                    child: _ShareButton(
                      icon: Icons.send_rounded,
                      title: 'Telegram',
                      color:
                          const Color(0xFF229ED9),
                      onTap: () => _share(
                        context,
                        ['org.telegram.messenger'],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 22),

              SizedBox(
                height: 54,
                child: OutlinedButton.icon(
                  onPressed: () =>
                      _shareMore(context),

                  icon: const Icon(
                    Icons.apps_rounded,
                  ),

                  label: const Text(
                    'More Apps',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(16),
                    ),
                    side: BorderSide(
                      color: colors.outline
                          .withValues(alpha: 0.25),
                    ),
                  ),
                ),
              ),
            ],
          ),
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
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),

        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: 8,
          ),
          child: Column(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: color.withValues(
                    alpha: 0.10,
                  ),
                  borderRadius:
                      BorderRadius.circular(17),
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
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: theme
                    .textTheme
                    .labelMedium
                    ?.copyWith(
                      color: colors.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}