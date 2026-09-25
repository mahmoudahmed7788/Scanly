import 'package:flutter/material.dart';

class SocialButton extends StatelessWidget {
  final VoidCallback? onPressed;

  final Widget icon;

  final String label;

  final bool isLoading;

  final bool facebook;

  final Color foregroundColor;

  const SocialButton({
    super.key,
    required this.onPressed,
    required this.icon,
    required this.label,
    required this.foregroundColor,
    this.isLoading = false,
    this.facebook = false, required Color textPrimary, required bool isSocialLoading, required Null Function() onGoogle, required Null Function() onFacebook,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor =
        Theme.of(context)
            .colorScheme
            .onSurface
            .withOpacity(0.12);

    return SizedBox(
      height: 52,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: foregroundColor,
          side: BorderSide(
            color: borderColor,
          ),
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(16),
          ),
          padding:
              const EdgeInsets.symmetric(
            horizontal: 10,
          ),
        ),
        child: isLoading
            ? _buildLoadingIndicator()
            : _buildButtonContent(),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return SizedBox(
      width: 21,
      height: 21,
      child: CircularProgressIndicator(
        strokeWidth: 2.2,
        color: facebook
            ? const Color(0xFF1877F2)
            : const Color(0xFF5B5FEF),
      ),
    );
  }

  Widget _buildButtonContent() {
    return Row(
      mainAxisAlignment:
          MainAxisAlignment.center,
      children: [
        Container(
          width: 30,
          height: 30,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: facebook
                ? const Color(0xFF1877F2)
                : Colors.transparent,
            shape: BoxShape.circle,
          ),
          child: icon,
        ),

        const SizedBox(width: 7),

        Flexible(
          child: Text(
            label,
            overflow:
                TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}