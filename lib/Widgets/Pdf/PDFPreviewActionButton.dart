import 'package:flutter/material.dart';

class PDFPreviewActionButton
    extends StatelessWidget {
  final ColorScheme colors;
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool outlined;
  final bool loading;

  const PDFPreviewActionButton({
    super.key,
    required this.colors,
    required this.icon,
    required this.label,
    required this.onPressed,
    required this.outlined,
    required this.loading,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    if (outlined) {
      return OutlinedButton(
        onPressed: onPressed,
        style:
            OutlinedButton.styleFrom(
          minimumSize:
              const Size(0, 50),
          padding:
              const EdgeInsets.symmetric(
            horizontal: 8,
          ),
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(15),
          ),
        ),
        child: loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child:
                    CircularProgressIndicator(
                  strokeWidth: 2,
                ),
              )
            : Row(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    size: 20,
                  ),
                  const SizedBox(
                    width: 6,
                  ),
                  Text(
                    label,
                    style:
                        const TextStyle(
                      fontWeight:
                          FontWeight.w800,
                    ),
                  ),
                ],
              ),
      );
    }

    return FilledButton(
      onPressed: onPressed,
      style:
          FilledButton.styleFrom(
        minimumSize:
            const Size(0, 50),
        padding:
            const EdgeInsets.symmetric(
          horizontal: 8,
        ),
        shape:
            RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(15),
        ),
      ),
      child: loading
          ? const SizedBox(
              width: 20,
              height: 20,
              child:
                  CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : Row(
              mainAxisAlignment:
                  MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 20,
                ),
                const SizedBox(
                  width: 6,
                ),
                Text(
                  label,
                  style:
                      const TextStyle(
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),
              ],
            ),
    );
  }
}