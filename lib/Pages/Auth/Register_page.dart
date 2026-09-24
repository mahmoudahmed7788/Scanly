import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:scanly/Auth/Auth_Cubit.dart';
import 'package:scanly/core/App_Theme.dart';
import 'package:shared_preferences/shared_preferences.dart';


class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  final formKey = GlobalKey<FormState>();

  bool obscurePassword = true;
  bool obscureConfirmPassword = true;

  bool isGoogleLoading = false;
  bool isFacebookLoading = false;

  // false = Email registration
  // true = Google / Facebook registration
  bool isSocialRegister = false;

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  // ============================================================
  // NORMAL EMAIL REGISTER
  // ============================================================

  Future<void> register() async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    if (passwordController.text != confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Passwords do not match.'),
        ),
      );

      return;
    }

    isSocialRegister = false;

    await context.read<AuthCubit>().register(
          firstName: firstNameController.text.trim(),
          lastName: lastNameController.text.trim(),
          email: emailController.text.trim(),
          password: passwordController.text,
          name: '',
        );
  }

  // ============================================================
  // GOOGLE REGISTER
  // ============================================================

  Future<void> registerWithGoogle() async {
    if (isGoogleLoading || isFacebookLoading) {
      return;
    }

    setState(() {
      isGoogleLoading = true;
      isSocialRegister = true;
    });

    debugPrint('REGISTER PAGE: Google button pressed');

    try {
      final authCubit = context.read<AuthCubit>();

      await authCubit.signInWithGoogle();

      debugPrint(
        'REGISTER PAGE: signInWithGoogle returned',
      );

      if (!mounted) {
        return;
      }

      final User? user = FirebaseAuth.instance.currentUser;

      debugPrint(
        'REGISTER PAGE GOOGLE USER: ${user?.email}',
      );

      if (user != null) {
        debugPrint(
          'REGISTER PAGE GOOGLE: Going to Home',
        );

        await saveSocialUserData(user);

        if (!mounted) {
          return;
        }

        context.go('/home');
      }
    } catch (e) {
      debugPrint(
        'REGISTER PAGE GOOGLE ERROR: $e',
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Google registration failed: $e',
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (!mounted) {
        return;
      }

      setState(() {
        isGoogleLoading = false;
      });
    }
  }

  // ============================================================
  // FACEBOOK REGISTER
  // ============================================================

  Future<void> registerWithFacebook() async {
    if (isGoogleLoading || isFacebookLoading) {
      return;
    }

    setState(() {
      isFacebookLoading = true;
      isSocialRegister = true;
    });

    debugPrint(
      'REGISTER PAGE: Facebook button pressed',
    );

    try {
      final authCubit = context.read<AuthCubit>();

      await authCubit.signInWithFacebook();

      debugPrint(
        'REGISTER PAGE: signInWithFacebook returned',
      );

      if (!mounted) {
        return;
      }

      final User? user = FirebaseAuth.instance.currentUser;

      debugPrint(
        'REGISTER PAGE FACEBOOK USER: ${user?.email}',
      );

      if (user != null) {
        debugPrint(
          'REGISTER PAGE FACEBOOK: Going to Home',
        );

        await saveSocialUserData(user);

        if (!mounted) {
          return;
        }

        context.go('/home');
      }
    } catch (e) {
      debugPrint(
        'REGISTER PAGE FACEBOOK ERROR: $e',
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Facebook registration failed: $e',
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (!mounted) {
        return;
      }

      setState(() {
        isFacebookLoading = false;
      });
    }
  }

  // ============================================================
  // SAVE NORMAL USER DATA
  // ============================================================

  Future<void> saveUserData() async {
    final prefs = await SharedPreferences.getInstance();

    final firstName = firstNameController.text.trim();
    final lastName = lastNameController.text.trim();
    final email = emailController.text.trim();

    final fullName = '$firstName $lastName'.trim();

    if (fullName.isNotEmpty) {
      await prefs.setString(
        'user_name',
        fullName,
      );
    }

    if (firstName.isNotEmpty) {
      await prefs.setString(
        'first_name',
        firstName,
      );
    }

    if (lastName.isNotEmpty) {
      await prefs.setString(
        'last_name',
        lastName,
      );
    }

    if (email.isNotEmpty) {
      await prefs.setString(
        'user_email',
        email,
      );
    }

    await prefs.setBool(
      'is_registered',
      true,
    );
  }

  // ============================================================
  // SAVE GOOGLE / FACEBOOK USER DATA
  // ============================================================

  Future<void> saveSocialUserData(User user) async {
    final prefs = await SharedPreferences.getInstance();

    final displayName = user.displayName?.trim() ?? '';
    final email = user.email?.trim() ?? '';

    if (displayName.isNotEmpty) {
      await prefs.setString(
        'user_name',
        displayName,
      );

      final parts = displayName.split(' ');

      if (parts.isNotEmpty && parts.first.isNotEmpty) {
        await prefs.setString(
          'first_name',
          parts.first,
        );
      }

      if (parts.length > 1) {
        final lastName = parts.sublist(1).join(' ').trim();

        if (lastName.isNotEmpty) {
          await prefs.setString(
            'last_name',
            lastName,
          );
        }
      }
    }

    if (email.isNotEmpty) {
      await prefs.setString(
        'user_email',
        email,
      );
    }

    await prefs.setBool(
      'is_registered',
      true,
    );
  }

  // ============================================================
  // THEME
  // ============================================================

  Future<void> toggleTheme() async {
    await ThemeController.toggleTheme();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final textPrimary = theme.colorScheme.onSurface;

    final textSecondary = isDark
        ? const Color(0xFFB8B6CC)
        : const Color(0xFF6F6B98);

    final cardColor = isDark
        ? const Color(0xFF1D1D29)
        : Colors.white;

    final isSocialLoading =
        isGoogleLoading || isFacebookLoading;

    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) async {
        // ======================================================
        // SUCCESS
        // ======================================================

        if (state.status == AuthStatus.success &&
            state.user != null) {
          final user = state.user!;

          // ====================================================
          // GOOGLE / FACEBOOK
          //
          // Social registration goes directly to Home.
          // ====================================================

          if (isSocialRegister) {
            await saveSocialUserData(user);

            if (!context.mounted) {
              return;
            }

            context.go('/home');
            return;
          }

          // ====================================================
          // NORMAL EMAIL REGISTRATION
          // ====================================================

          if (user.emailVerified) {
            await saveUserData();

            if (!context.mounted) {
              return;
            }

            context.go('/home');
            return;
          }

          // ====================================================
          // EMAIL NOT VERIFIED
          // ====================================================

          await saveUserData();

          if (!context.mounted) {
            return;
          }

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Account created! Check your email for verification.',
              ),
            ),
          );

          context.go('/verification');

          return;
        }

        // ======================================================
        // FAILURE
        // ======================================================

        if (state.status == AuthStatus.failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                state.errorMessage ??
                    'Registration failed.',
              ),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      },

      // ========================================================
      // UI
      // ========================================================

      child: Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF5B5FEF),
                Color(0xFF7C5CFC),
                Color(0xFF00C2FF),
              ],
            ),
          ),
          child: SafeArea(
            child: Stack(
              children: [
                // ==================================================
                // THEME BUTTON
                // ==================================================

                Positioned(
                  top: 12,
                  right: 20,
                  child: ValueListenableBuilder<ThemeMode>(
                    valueListenable: ThemeController.mode,
                    builder: (context, mode, _) {
                      final isDarkMode =
                          mode == ThemeMode.dark;

                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: toggleTheme,
                          borderRadius:
                              BorderRadius.circular(50),
                          child: AnimatedContainer(
                            duration:
                                const Duration(milliseconds: 250),
                            curve: Curves.easeOut,
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: isDarkMode
                                  ? Colors.white.withOpacity(0.25)
                                  : Colors.white.withOpacity(0.18),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color:
                                    Colors.white.withOpacity(0.35),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      Colors.black.withOpacity(0.10),
                                  blurRadius: 12,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: AnimatedSwitcher(
                              duration:
                                  const Duration(milliseconds: 200),
                              transitionBuilder:
                                  (child, animation) {
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
                                    ? Icons.light_mode_rounded
                                    : Icons.dark_mode_rounded,
                                key: ValueKey(isDarkMode),
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // ==================================================
                // PAGE CONTENT
                // ==================================================

                SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 25,
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 55),

                      // ==================================================
                      // ICON
                      // ==================================================

                      Container(
                        width: 82,
                        height: 82,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.18),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withOpacity(0.30),
                          ),
                        ),
                        child: const Icon(
                          Icons.person_add_alt_1_rounded,
                          size: 48,
                          color: Colors.white,
                        ),
                      ),

                      const SizedBox(height: 15),

                      const Text(
                        'Create Account',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 8),

                      const Text(
                        'Create your Scanly account',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 15,
                        ),
                      ),

                      const SizedBox(height: 30),

                      // ==================================================
                      // CARD
                      // ==================================================

                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  Colors.black.withOpacity(0.12),
                              blurRadius: 25,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Form(
                          key: formKey,
                          child: Column(
                            children: [
                              // ==================================================
                              // FIRST NAME
                              // ==================================================

                              TextFormField(
                                controller: firstNameController,
                                textInputAction:
                                    TextInputAction.next,
                                decoration:
                                    const InputDecoration(
                                  hintText: 'First Name',
                                  prefixIcon: Icon(
                                    Icons.person_outline_rounded,
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null ||
                                      value.trim().isEmpty) {
                                    return 'Enter your first name';
                                  }

                                  return null;
                                },
                              ),

                              const SizedBox(height: 15),

                              // ==================================================
                              // LAST NAME
                              // ==================================================

                              TextFormField(
                                controller: lastNameController,
                                textInputAction:
                                    TextInputAction.next,
                                decoration:
                                    const InputDecoration(
                                  hintText: 'Last Name',
                                  prefixIcon: Icon(
                                    Icons.person_outline_rounded,
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null ||
                                      value.trim().isEmpty) {
                                    return 'Enter your last name';
                                  }

                                  return null;
                                },
                              ),

                              const SizedBox(height: 15),

                              // ==================================================
                              // EMAIL
                              // ==================================================

                              TextFormField(
                                controller: emailController,
                                keyboardType:
                                    TextInputType.emailAddress,
                                textInputAction:
                                    TextInputAction.next,
                                decoration:
                                    const InputDecoration(
                                  hintText: 'Email',
                                  prefixIcon: Icon(
                                    Icons.email_outlined,
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null ||
                                      value.trim().isEmpty) {
                                    return 'Enter your email';
                                  }

                                  final emailRegex = RegExp(
                                    r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                                  );

                                  if (!emailRegex.hasMatch(
                                    value.trim(),
                                  )) {
                                    return 'Enter a valid email';
                                  }

                                  return null;
                                },
                              ),

                              const SizedBox(height: 15),

                              // ==================================================
                              // PASSWORD
                              // ==================================================

                              TextFormField(
                                controller: passwordController,
                                obscureText: obscurePassword,
                                textInputAction:
                                    TextInputAction.next,
                                decoration:
                                    InputDecoration(
                                  hintText: 'Password',
                                  prefixIcon:
                                      const Icon(
                                    Icons.lock_outline_rounded,
                                  ),
                                  suffixIcon:
                                      IconButton(
                                    onPressed: () {
                                      setState(() {
                                        obscurePassword =
                                            !obscurePassword;
                                      });
                                    },
                                    icon: Icon(
                                      obscurePassword
                                          ? Icons
                                              .visibility_off_outlined
                                          : Icons
                                              .visibility_outlined,
                                    ),
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null ||
                                      value.isEmpty) {
                                    return 'Enter your password';
                                  }

                                  if (value.length < 6) {
                                    return 'Password must be at least 6 characters';
                                  }

                                  return null;
                                },
                              ),

                              const SizedBox(height: 15),

                              // ==================================================
                              // CONFIRM PASSWORD
                              // ==================================================

                              TextFormField(
                                controller:
                                    confirmPasswordController,
                                obscureText:
                                    obscureConfirmPassword,
                                textInputAction:
                                    TextInputAction.done,
                                decoration:
                                    InputDecoration(
                                  hintText: 'Confirm Password',
                                  prefixIcon:
                                      const Icon(
                                    Icons.lock_outline_rounded,
                                  ),
                                  suffixIcon:
                                      IconButton(
                                    onPressed: () {
                                      setState(() {
                                        obscureConfirmPassword =
                                            !obscureConfirmPassword;
                                      });
                                    },
                                    icon: Icon(
                                      obscureConfirmPassword
                                          ? Icons
                                              .visibility_off_outlined
                                          : Icons
                                              .visibility_outlined,
                                    ),
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null ||
                                      value.isEmpty) {
                                    return 'Confirm your password';
                                  }

                                  if (value !=
                                      passwordController.text) {
                                    return 'Passwords do not match';
                                  }

                                  return null;
                                },
                              ),

                              const SizedBox(height: 25),

                              // ==================================================
                              // CREATE ACCOUNT BUTTON
                              // ==================================================

                              BlocBuilder<AuthCubit, AuthState>(
                                builder: (context, state) {
                                  final isLoading =
                                      state.status ==
                                          AuthStatus.loading;

                                  return SizedBox(
                                    width: double.infinity,
                                    height: 55,
                                    child: ElevatedButton(
                                      onPressed:
                                          isLoading ||
                                                  isSocialLoading
                                              ? null
                                              : register,
                                      style:
                                          ElevatedButton.styleFrom(
                                        backgroundColor:
                                            const Color(0xFF5B5FEF),
                                        foregroundColor:
                                            Colors.white,
                                        disabledBackgroundColor:
                                            const Color(0xFF5B5FEF)
                                                .withOpacity(0.55),
                                        elevation: 0,
                                        shape:
                                            RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(18),
                                        ),
                                      ),
                                      child: isLoading &&
                                              !isSocialLoading
                                          ? const SizedBox(
                                              width: 24,
                                              height: 24,
                                              child:
                                                  CircularProgressIndicator(
                                                strokeWidth: 2.5,
                                                color: Colors.white,
                                              ),
                                            )
                                          : const Text(
                                              'Create Account',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight:
                                                    FontWeight.bold,
                                              ),
                                            ),
                                    ),
                                  );
                                },
                              ),

                              const SizedBox(height: 25),

                              // ==================================================
                              // DIVIDER
                              // ==================================================

                              Row(
                                children: [
                                  Expanded(
                                    child: Divider(
                                      color: textSecondary
                                          .withOpacity(0.25),
                                    ),
                                  ),
                                  Padding(
                                    padding:
                                        const EdgeInsets.symmetric(
                                      horizontal: 14,
                                    ),
                                    child: Text(
                                      'OR CONTINUE WITH',
                                      style: TextStyle(
                                        color: textSecondary,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.7,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Divider(
                                      color: textSecondary
                                          .withOpacity(0.25),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 20),

                              // ==================================================
                              // GOOGLE + FACEBOOK
                              // ==================================================

                              Row(
                                children: [
                                  Expanded(
                                    child: _SocialButton(
                                      onPressed: isSocialLoading
                                          ? null
                                          : registerWithGoogle,
                                      icon: const Text(
                                        'G',
                                        style: TextStyle(
                                          fontSize: 21,
                                          fontWeight:
                                              FontWeight.bold,
                                          color:
                                              Color(0xFF4285F4),
                                        ),
                                      ),
                                      label: 'Google',
                                      isLoading:
                                          isGoogleLoading,
                                      foregroundColor:
                                          textPrimary,
                                    ),
                                  ),

                                  const SizedBox(width: 12),

                                  Expanded(
                                    child: _SocialButton(
                                      onPressed: isSocialLoading
                                          ? null
                                          : registerWithFacebook,
                                      icon: const Text(
                                        'f',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 22,
                                          fontWeight:
                                              FontWeight.bold,
                                        ),
                                      ),
                                      label: 'Facebook',
                                      isLoading:
                                          isFacebookLoading,
                                      facebook: true,
                                      foregroundColor:
                                          textPrimary,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 25),

                              // ==================================================
                              // LOGIN
                              // ==================================================

                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Already have an account? ',
                                    style: TextStyle(
                                      color: textSecondary,
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: isSocialLoading
                                        ? null
                                        : () {
                                            context.push(
                                              '/login',
                                            );
                                          },
                                    child: const Text(
                                      'Login',
                                      style: TextStyle(
                                        fontWeight:
                                            FontWeight.bold,
                                        color:
                                            Color(0xFF5B5FEF),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// SOCIAL BUTTON
// ============================================================

class _SocialButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget icon;
  final String label;
  final bool isLoading;
  final bool facebook;
  final Color foregroundColor;

  const _SocialButton({
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
              ? const Color(0xFF1877F2).withOpacity(0.04)
              : Colors.transparent,
          side: BorderSide(
            color: borderColor,
            width: 1.2,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 10,
          ),
        ),
        child: isLoading
            ? SizedBox(
                width: 21,
                height: 21,
                child: CircularProgressIndicator(
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
                    decoration: BoxDecoration(
                      color: facebook
                          ? const Color(0xFF1877F2)
                          : Colors.white,
                      shape: BoxShape.circle,
                      border: google
                          ? Border.all(
                              color: Colors.black12,
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
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
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
