import 'package:flutter/material.dart';

class HomeNotificationButton
    extends StatelessWidget {
  final int unreadCount;

  final VoidCallback onPressed;

  const HomeNotificationButton({
    super.key,
    required this.unreadCount,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme =
        Theme.of(context);

    final colors =
        theme.colorScheme;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          decoration:
              BoxDecoration(
            color: colors.surface,
            borderRadius:
                BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: colors.onSurface
                    .withOpacity(
                  theme.brightness ==
                          Brightness.dark
                      ? 0.20
                      : 0.06,
                ),
                blurRadius: 10,
                offset:
                    const Offset(0, 4),
              ),
            ],
          ),
          child: IconButton(
            onPressed: onPressed,
            icon: Icon(
              unreadCount > 0
                  ? Icons.notifications
                  : Icons
                      .notifications_none_rounded,
              color:
                  colors.primary,
            ),
            tooltip:
                'Notifications',
          ),
        ),

        if (unreadCount > 0)
          Positioned(
            right: -3,
            top: -3,
            child: Container(
              constraints:
                  const BoxConstraints(
                minWidth: 20,
                minHeight: 20,
              ),
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 5,
              ),
              decoration:
                  BoxDecoration(
                color: colors.error,
                borderRadius:
                    BorderRadius.circular(
                  10,
                ),
                border: Border.all(
                  color: theme
                      .scaffoldBackgroundColor,
                  width: 2,
                ),
              ),
              child: Text(
                unreadCount > 99
                    ? '99+'
                    : unreadCount
                        .toString(),
                textAlign:
                    TextAlign.center,
                style:
                    const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }
}