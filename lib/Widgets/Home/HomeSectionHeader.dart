import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomeSectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onViewAll;

  const HomeSectionHeader({
    super.key,
    required this.title,
    required this.icon,
    required this.onViewAll,
  });

  static void openFavorites(
    BuildContext context,
  ) {
    context.push('/favorites');
  }

  static void openRecent(
    BuildContext context,
  ) {
    context.push('/recent');
  }

  @override
  Widget build(BuildContext context) {
    final colors =
        Theme.of(context).colorScheme;

    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: colors.primary.withOpacity(0.10),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(
            icon,
            color: colors.primary,
            size: 19,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              color: colors.onSurface,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        TextButton(
          onPressed: onViewAll,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(
              horizontal: 7,
              vertical: 4,
            ),
            minimumSize: Size.zero,
            tapTargetSize:
                MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            'View All',
            style: TextStyle(
              color: colors.primary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}