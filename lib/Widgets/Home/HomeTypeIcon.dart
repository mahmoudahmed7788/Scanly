import 'package:flutter/material.dart';

class HomeTypeIcon extends StatelessWidget {
  final IconData icon;

  const HomeTypeIcon({
    super.key,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final colors =
        Theme.of(context).colorScheme;

    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.primary.withOpacity(0.14),
            colors.secondary.withOpacity(0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(
        icon,
        color: colors.primary,
        size: 27,
      ),
    );
  }
}