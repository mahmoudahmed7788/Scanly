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
    this.facebook = false,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = Theme.of(context)
        .colorScheme
        .onSurface
        .withOpacity(0.12);

    final google = !facebook;

    return SizedBox(
      height: 52,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: foregroundColor,
          backgroundColor: facebook
              ? const Color(0xFF1877F2)
                  .withOpacity(0.04)
              : Colors.transparent,
          side: BorderSide(
            color: borderColor,
            width: 1.2,
          ),
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(16),
          ),
          padding:
              const EdgeInsets.symmetric(
            horizontal: 10,
          ),
        ),
        child: isLoading
            ? SizedBox(
                width: 21,
                height: 21,
                child:
                    CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: facebook
                      ? const Color(0xFF1877F2)
                      : const Color(0xFF5B5FEF),
                ),
              )
            : Row(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    alignment: Alignment.center,
                    decoration:
                        BoxDecoration(
                      color: facebook
                          ? const Color(0xFF1877F2)
                          : Colors.white,
                      shape: BoxShape.circle,
                      border: google
                          ? Border.all(
                              color:
                                  Colors.black12,
                              width: 0.7,
                            )
                          : null,
                    ),
                    child: icon,
                  ),

                  const SizedBox(width: 7),

                  Flexible(
                    child: Text(
                      label,
                      overflow:
                          TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight:
                            FontWeight.w600,
                        color: foregroundColor,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}