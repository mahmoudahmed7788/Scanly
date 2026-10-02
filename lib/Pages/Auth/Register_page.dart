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

  bool _isStrongPassword(String password) {
    if (password.length < 8) {
      return false;
    }

    if (password.contains(RegExp(r'\s'))) {
      return false;
    }

    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      return false;
    }

    if (!RegExp(r'[a-z]').hasMatch(password)) {
      return false;
    }

    if (!RegExp(r'[0-9]').hasMatch(password)) {
      return false;
    }

    if (!RegExp(r'''[!@#$%^&*(),.?":{}|<>_\-\\/\[\]+=]''').hasMatch(password)) {
      return false;
    }

    return true;
  }

  Future<void> register() async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    final password = passwordController.text;
    final confirmPassword = confirmPasswordController.text;

    if (!_isStrongPassword(password)) {
      _showSnackBar(
        'Password must be at least 8 characters and include an uppercase letter, lowercase letter, number, and special character.',
        isError: true,
      );

      return;
    }

    if (password != confirmPassword) {
      _showSnackBar('Passwords do not match.', isError: true);

      return;
    }

    setState(() {
      isSocialRegister = false;
    });

    await context.read<AuthCubit>().register(
      firstName: firstNameController.text.trim(),
      lastName: lastNameController.text.trim(),
      email: emailController.text.trim(),
      password: password,
      name: '',
    );
  }

  Future<void> registerWithGoogle() async {
    if (isGoogleLoading || isFacebookLoading) {
      return;
    }

    setState(() {
      isGoogleLoading = true;
      isSocialRegister = true;
    });

    debugPrint('REGISTER PAGE: Google registration started.');

    try {
      await context.read<AuthCubit>().registerWithGoogle();
    } catch (e) {
      debugPrint('REGISTER PAGE GOOGLE ERROR: $e');

      if (!mounted) {
        return;
      }

      _showSnackBar(
        'Google registration failed. Please try again.',
        isError: true,
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

  Future<void> registerWithFacebook() async {
    if (isGoogleLoading || isFacebookLoading) {
      return;
    }

    setState(() {
      isFacebookLoading = true;
      isSocialRegister = true;
    });

    debugPrint('REGISTER PAGE: Facebook registration started.');

    try {
      await context.read<AuthCubit>().registerWithFacebook();
    } catch (e) {
      debugPrint('REGISTER PAGE FACEBOOK ERROR: $e');

      if (!mounted) {
        return;
      }

      _showSnackBar(
        'Facebook registration failed. Please try again.',
        isError: true,
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

  Future<void> saveUserData() async {
    final prefs = await SharedPreferences.getInstance();

    final firstName = firstNameController.text.trim();
    final lastName = lastNameController.text.trim();
    final email = emailController.text.trim();

    final fullName = '$firstName $lastName'.trim();

    if (fullName.isNotEmpty) {
      await prefs.setString('user_name', fullName);
    }

    if (firstName.isNotEmpty) {
      await prefs.setString('first_name', firstName);
    }

    if (lastName.isNotEmpty) {
      await prefs.setString('last_name', lastName);
    }

    if (email.isNotEmpty) {
      await prefs.setString('user_email', email);
    }

    await prefs.setBool('is_registered', true);
  }

  Future<void> saveSocialUserData(User user) async {
    final prefs = await SharedPreferences.getInstance();

    final displayName = user.displayName?.trim() ?? '';
    final email = user.email?.trim() ?? '';

    if (displayName.isNotEmpty) {
      await prefs.setString('user_name', displayName);

      final parts = displayName
          .split(' ')
          .where((part) => part.trim().isNotEmpty)
          .toList();

      if (parts.isNotEmpty) {
        await prefs.setString('first_name', parts.first);
      }

      if (parts.length > 1) {
        final lastName = parts.sublist(1).join(' ').trim();

        if (lastName.isNotEmpty) {
          await prefs.setString('last_name', lastName);
        }
      }
    }

    if (email.isNotEmpty) {
      await prefs.setString('user_email', email);
    }

    await prefs.setBool('is_registered', true);
  }

  Future<void> toggleTheme() async {
    await ThemeController.toggleTheme();
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final isDark = theme.brightness == Brightness.dark;

    final textPrimary = theme.colorScheme.onSurface;

    final textSecondary = isDark
        ? const Color(0xFFB8B6CC)
        : const Color(0xFF6F6B98);

    final cardColor = isDark ? const Color(0xFF1D1D29) : Colors.white;

    final isSocialLoading = isGoogleLoading || isFacebookLoading;

    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) async {
        if (state.status == AuthStatus.success && state.user != null) {
          final user = state.user!;

          if (isSocialRegister) {
            await saveSocialUserData(user);

            if (!context.mounted) {
              return;
            }

            context.go('/onboarding');

            return;
          }

          if (user.emailVerified) {
            await saveUserData();

            if (!context.mounted) {
              return;
            }

            context.go('/onboarding');

            return;
          }

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

        if (state.status == AuthStatus.alreadyRegistered) {
          _showSnackBar(
            'This account is already registered. Please login instead.',
            isError: true,
          );

          Future.delayed(const Duration(milliseconds: 900), () {
            if (!mounted) {
              return;
            }

            context.go('/login');
          });

          return;
        }

        if (state.status == AuthStatus.failure) {
          _showSnackBar(
            state.errorMessage ?? 'Registration failed. Please try again.',
            isError: true,
          );
        }
      },
      child: Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF5B5FEF), Color(0xFF7C5CFC), Color(0xFF00C2FF)],
            ),
          ),
          child: SafeArea(
            child: Stack(
              children: [
                RegisterThemeButton(onToggleTheme: toggleTheme),
                SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 25,
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 55),
                      const RegisterHeader(),
                      const SizedBox(height: 30),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.12),
                              blurRadius: 25,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Form(
                          key: formKey,
                          child: Column(
                            children: [
                              RegisterForm(
                                firstNameController: firstNameController,
                                lastNameController: lastNameController,
                                emailController: emailController,
                                passwordController: passwordController,
                                confirmPasswordController:
                                    confirmPasswordController,
                                obscurePassword: obscurePassword,
                                obscureConfirmPassword: obscureConfirmPassword,
                                isSocialLoading: isSocialLoading,
                                onTogglePassword: () {
                                  setState(() {
                                    obscurePassword = !obscurePassword;
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
                              Row(
                                children: [
                                  Expanded(
                                    child: Divider(
                                      color: textSecondary.withOpacity(0.25),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
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
                                      color: textSecondary.withOpacity(0.25),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              RegisterSocialButtons(
                                isSocialLoading: isSocialLoading,
                                isGoogleLoading: isGoogleLoading,
                                isFacebookLoading: isFacebookLoading,
                                textPrimary: textPrimary,
                                onGoogle: registerWithGoogle,
                                onFacebook: registerWithFacebook,
                              ),
                              const SizedBox(height: 25),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Already have an account? ',
                                    style: TextStyle(color: textSecondary),
                                  ),
                                  TextButton(
                                    onPressed: isSocialLoading
                                        ? null
                                        : () {
                                            context.push('/login');
                                          },
                                    child: const Text(
                                      'Login',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF5B5FEF),
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
