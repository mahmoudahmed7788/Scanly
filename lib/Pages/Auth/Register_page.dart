import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:scanly/Auth/Auth_Cubit.dart';
import 'package:scanly/Widgets/Auth/Register/RegisterForm.dart';
import 'package:scanly/Widgets/Auth/Register/RegisterHeader.dart';
import 'package:scanly/Widgets/Auth/Register/RegisterSocialButtons.dart';
import 'package:scanly/Widgets/Auth/Register/RegisterThemeButton.dart';
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

    if (passwordController.text !=
        confirmPasswordController.text) {
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
    final prefs =
        await SharedPreferences.getInstance();

    final firstName =
        firstNameController.text.trim();

    final lastName =
        lastNameController.text.trim();

    final email =
        emailController.text.trim();

    final fullName =
        '$firstName $lastName'.trim();

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
    final prefs =
        await SharedPreferences.getInstance();

    final displayName =
        user.displayName?.trim() ?? '';

    final email =
        user.email?.trim() ?? '';

    if (displayName.isNotEmpty) {
      await prefs.setString(
        'user_name',
        displayName,
      );

      final parts =
          displayName.split(' ');

      if (parts.isNotEmpty &&
          parts.first.isNotEmpty) {
        await prefs.setString(
          'first_name',
          parts.first,
        );
      }

      if (parts.length > 1) {
        final lastName =
            parts.sublist(1).join(' ').trim();

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

    final isDark =
        theme.brightness == Brightness.dark;

    final textPrimary =
        theme.colorScheme.onSurface;

    final textSecondary = isDark
        ? const Color(0xFFB8B6CC)
        : const Color(0xFF6F6B98);

    final cardColor = isDark
        ? const Color(0xFF1D1D29)
        : Colors.white;

    final isSocialLoading =
        isGoogleLoading ||
        isFacebookLoading;

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

                RegisterThemeButton(
                  onToggleTheme: toggleTheme,
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
                      // HEADER
                      // ==================================================

                      const RegisterHeader(),

                      const SizedBox(height: 30),

                      // ==================================================
                      // CARD
                      // ==================================================

                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius:
                              BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  Colors.black.withOpacity(0.12),
                              blurRadius: 25,
                              offset:
                                  const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Form(
                          key: formKey,
                          child: Column(
                            children: [
                              RegisterForm(
                                firstNameController:
                                    firstNameController,
                                lastNameController:
                                    lastNameController,
                                emailController:
                                    emailController,
                                passwordController:
                                    passwordController,
                                confirmPasswordController:
                                    confirmPasswordController,
                                obscurePassword:
                                    obscurePassword,
                                obscureConfirmPassword:
                                    obscureConfirmPassword,
                                isSocialLoading:
                                    isSocialLoading,
                                onTogglePassword: () {
                                  setState(() {
                                    obscurePassword =
                                        !obscurePassword;
                                  });
                                },
                                onToggleConfirmPassword: () {
                                  setState(() {
                                    obscureConfirmPassword =
                                        !obscureConfirmPassword;
                                  });
                                },
                                onRegister: register,
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
                                        color:
                                            textSecondary,
                                        fontSize: 11,
                                        fontWeight:
                                            FontWeight.w600,
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

                              RegisterSocialButtons(
                                isSocialLoading:
                                    isSocialLoading,
                                isGoogleLoading:
                                    isGoogleLoading,
                                isFacebookLoading:
                                    isFacebookLoading,
                                textPrimary:
                                    textPrimary,
                                onGoogle:
                                    registerWithGoogle,
                                onFacebook:
                                    registerWithFacebook,
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
                                      color:
                                          textSecondary,
                                    ),
                                  ),
                                  TextButton(
                                    onPressed:
                                        isSocialLoading
                                            ? null
                                            : () {
                                                context.push(
                                                  '/login',
                                                );
                                              },
                                    child: const Text(
                                      'Login',
                                      style:
                                          TextStyle(
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