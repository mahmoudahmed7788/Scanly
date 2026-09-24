import 'package:flutter/material.dart';

class QRShareSheet extends StatelessWidget {
  final Future<void> Function(List<String> packageNames) onShare;
  final Future<void> Function() onShareMore;

  const QRShareSheet({
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
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return QRShareSheet(
          onShare: onShare,
          onShareMore: onShareMore,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(28),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            20,
            4,
            20,
            24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: colors.primary.withValues(
                        alpha: 0.10,
                      ),
                      borderRadius:
                          BorderRadius.circular(15),
                    ),
                    child: Icon(
                      Icons.qr_code_2_rounded,
                      color: colors.primary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Share QR Code',
                          style: theme
                              .textTheme
                              .titleLarge
                              ?.copyWith(
                                fontWeight:
                                    FontWeight.w700,
                              ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Choose where you want to share it',
                          style: theme
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                color: colors
                                    .onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              Row(
                children: [
                  Expanded(
                    child: _ShareButton(
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
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _ShareButton(
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
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _ShareButton(
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
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _ShareButton(
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
                  ),
                ],
              ),

              const SizedBox(height: 18),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    onShareMore();
                  },
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
                          .withValues(alpha: 0.35),
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
                      BorderRadius.circular(18),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 28,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: theme.textTheme.labelMedium
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