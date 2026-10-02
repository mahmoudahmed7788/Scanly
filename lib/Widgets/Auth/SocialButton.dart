import 'package:flutter/material.dart';

class SocialButton extends StatelessWidget {
  final VoidCallback onGoogle;
  final VoidCallback onFacebook;
  final bool isSocialLoading;
  final Color textPrimary;

  const SocialButton({
    super.key,
    required this.onGoogle,
    required this.onFacebook,
    required this.isSocialLoading,
    required this.textPrimary, required Null Function() onPressed, required Icon icon, required String label, required Color foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor =
        Theme.of(context).colorScheme.onSurface.withOpacity(0.12);

    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 52,
            child: OutlinedButton(
              onPressed: isSocialLoading ? null : onGoogle,
              style: OutlinedButton.styleFrom(
                foregroundColor: textPrimary,
                side: BorderSide(
                  color: borderColor,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/icons/google.png',
                    width: 22,
                    height: 22,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.g_mobiledata_rounded,
                        size: 28,
                      );
                    },
                  ),
                  const SizedBox(width: 7),
                  const Text(
                    'Google',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: SizedBox(
            height: 52,
            child: OutlinedButton(
              onPressed: isSocialLoading ? null : onFacebook,
              style: OutlinedButton.styleFrom(
                foregroundColor: textPrimary,
                side: BorderSide(
                  color: borderColor,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    decoration: const BoxDecoration(
                      color: Color(0xFF1877F2),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Text(
                        'f',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 7),
                  const Text(
                    'Facebook',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
