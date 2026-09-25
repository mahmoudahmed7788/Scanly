import 'package:flutter/material.dart';
import 'package:scanly/Widgets/Auth/Register/SocialButton.dart';

class RegisterSocialButtons extends StatelessWidget {
  final bool isSocialLoading;
  final bool isGoogleLoading;
  final bool isFacebookLoading;

  final Color textPrimary;

  final VoidCallback onGoogle;
  final VoidCallback onFacebook;

  const RegisterSocialButtons({
    super.key,
    required this.isSocialLoading,
    required this.isGoogleLoading,
    required this.isFacebookLoading,
    required this.textPrimary,
    required this.onGoogle,
    required this.onFacebook,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SocialButton(
            onPressed:
                isSocialLoading
                    ? null
                    : onGoogle,
            icon: const Text(
              'G',
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4285F4),
              ),
            ),
            label: 'Google',
            isLoading: isGoogleLoading,
            foregroundColor: textPrimary,
          ),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: SocialButton(
            onPressed:
                isSocialLoading
                    ? null
                    : onFacebook,
            icon: const Text(
              'f',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            label: 'Facebook',
            isLoading: isFacebookLoading,
            facebook: true,
            foregroundColor: textPrimary,
          ),
        ),
      ],
    );
  }
}