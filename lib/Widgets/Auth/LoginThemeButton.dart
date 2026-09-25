import 'package:flutter/material.dart';
import 'package:scanly/core/App_Theme.dart';

class LoginThemeButton extends StatelessWidget {
  final VoidCallback onToggleTheme;

  const LoginThemeButton({
    super.key,
    required this.onToggleTheme,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 12,
      right: 20,
      child: ValueListenableBuilder<ThemeMode>(
        valueListenable: ThemeController.mode,
        builder: (
          context,
          mode,
          _,
        ) {
          final isDarkMode =
              mode == ThemeMode.dark;

          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onToggleTheme,
              borderRadius:
                  BorderRadius.circular(50),
              child: AnimatedContainer(
                duration:
                    const Duration(
                  milliseconds: 250,
                ),
                curve: Curves.easeOut,
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isDarkMode
                      ? Colors.white
                          .withOpacity(0.25)
                      : Colors.white
                          .withOpacity(0.18),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white
                        .withOpacity(0.35),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black
                          .withOpacity(0.10),
                      blurRadius: 12,
                      offset:
                          const Offset(0, 5),
                    ),
                  ],
                ),
                child: AnimatedSwitcher(
                  duration:
                      const Duration(
                    milliseconds: 200,
                  ),
                  transitionBuilder:
                      (
                    child,
                    animation,
                  ) {
                    return RotationTransition(
                      turns: animation,
                      child: FadeTransition(
                        opacity: animation,
                        child: child,
                      ),
                    );
                  },
                  child: Icon(
                    isDarkMode
                        ? Icons
                            .light_mode_rounded
                        : Icons
                            .dark_mode_rounded,
                    key: ValueKey(
                      isDarkMode,
                    ),
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}