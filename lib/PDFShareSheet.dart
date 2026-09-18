import 'package:flutter/material.dart';

class PDFShareSheet extends StatelessWidget {
  final Future<void> Function(List<String> packageNames) onShare;
  final Future<void> Function() onShareMore;

  const PDFShareSheet({
    super.key,
    required this.onShare,
    required this.onShareMore,
  });

  static void show({
    required BuildContext context,
    required Future<void> Function(
      List<String> packageNames,
    ) onShare,
    required Future<void> Function() onShareMore,
  }) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor:
          Theme.of(context).colorScheme.surface,
      builder: (_) {
        return PDFShareSheet(
          onShare: onShare,
          onShareMore: onShareMore,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors =
        Theme.of(context).colorScheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          20,
          8,
          20,
          24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Share PDF',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: colors.onSurface,
              ),
            ),

            const SizedBox(height: 22),

            Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceEvenly,
              children: [
                _ShareButton(
                  icon: Icons.chat_rounded,
                  label: 'WhatsApp',
                  color:
                      const Color(0xFF25D366),
                  onTap: () {
                    Navigator.pop(context);

                    onShare([
                      'com.whatsapp',
                      'com.whatsapp.w4b',
                    ]);
                  },
                ),

                _ShareButton(
                  icon: Icons.facebook_rounded,
                  label: 'Facebook',
                  color:
                      const Color(0xFF1877F2),
                  onTap: () {
                    Navigator.pop(context);

                    onShare([
                      'com.facebook.katana',
                    ]);
                  },
                ),

                _ShareButton(
                  icon: Icons.camera_alt_rounded,
                  label: 'Instagram',
                  color:
                      const Color(0xFFE1306C),
                  onTap: () {
                    Navigator.pop(context);

                    onShare([
                      'com.instagram.android',
                    ]);
                  },
                ),

                _ShareButton(
                  icon: Icons.send_rounded,
                  label: 'Telegram',
                  color:
                      const Color(0xFF229ED9),
                  onTap: () {
                    Navigator.pop(context);

                    onShare([
                      'org.telegram.messenger',
                    ]);
                  },
                ),
              ],
            ),

            const SizedBox(height: 22),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  onShareMore();
                },
                icon: const Icon(
                  Icons.more_horiz_rounded,
                ),
                label: const Text(
                  'More Apps',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShareButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ShareButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color:
                  color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: 27,
            ),
          ),

          const SizedBox(height: 7),

          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}