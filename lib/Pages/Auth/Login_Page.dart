import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:scanly/Auth/Auth_Cubit.dart';
import 'package:scanly/Core/UserProfileCache.dart';
import 'package:scanly/Widgets/Auth/LoginForm.dart';
import 'package:scanly/Widgets/Auth/LoginHeader.dart';
import 'package:scanly/Widgets/Auth/LoginThemeButton.dart';
import 'package:scanly/core/App_Theme.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController =
      TextEditingController();

  final TextEditingController passwordController =
      TextEditingController();

  final GlobalKey<FormState> formKey =
      GlobalKey<FormState>();

  bool obscurePassword = true;
  bool isGoogleLoading = false;
  bool isFacebookLoading = false;
  bool isSocialLogin = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  bool get isSocialLoading {
    return isGoogleLoading || isFacebookLoading;
  }

  Future<void> login() async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      isSocialLogin = false;
    });

    await context.read<AuthCubit>().login(
          email: emailController.text.trim(),
          password: passwordController.text,
        );
  }

  Future<void> loginWithGoogle() async {
    if (isSocialLoading) {
      return;
    }

    setState(() {
      isGoogleLoading = true;
      isSocialLogin = true;
    });

    try {
      await context
          .read<AuthCubit>()
          .signInWithGoogle();
    } catch (e) {
      debugPrint(
        'LOGIN PAGE GOOGLE ERROR: $e',
      );

      if (!mounted) {
        return;
      }

      _showSnackBar(
        'Google login failed. Please try again.',
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

  Future<void> loginWithFacebook() async {
    if (isSocialLoading) {
      return;
    }

    setState(() {
      isFacebookLoading = true;
      isSocialLogin = true;
    });

    try {
      await context
          .read<AuthCubit>()
          .signInWithFacebook();
    } catch (e) {
      debugPrint(
        'LOGIN PAGE FACEBOOK ERROR: $e',
      );

      if (!mounted) {
        return;
      }

      _showSnackBar(
        'Facebook login failed. Please try again.',
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

  void forgotPassword() {
    if (isSocialLoading) {
      return;
    }

    final email =
        emailController.text.trim();

    context.push(
      '/forgot-password',
      extra: email,
    );
  }

  void togglePasswordVisibility() {
    setState(() {
      obscurePassword =
          !obscurePassword;
    });
  }

  Future<void> toggleTheme() async {
    await ThemeController.toggleTheme();
  }

  void _showSnackBar(
    String message, {
    bool isError = false,
  }) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            isError ? Colors.redAccent : null,
      ),
    );
  }

  Future<void> _showWrongPasswordDialog() async {
    if (!mounted) {
      return;
    }

    final email =
        emailController.text.trim();

    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(24),
          ),
          title: const Row(
            children: [
              Icon(
                Icons.lock_outline_rounded,
                color: Colors.redAccent,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Wrong Password',
                ),
              ),
            ],
          ),
          content: const Text(
            'The password you entered is incorrect. Would you like to reset your password?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop();

                context.push(
                  '/forgot-password',
                  extra: email,
                );
              },
              child: const Text(
                'Forgot Password?',
                style: TextStyle(
                  color:
                      Color(0xFF5B5FEF),
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop();
              },
              child:
                  const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleSuccessfulLogin(
    User user,
  ) async {
    if (user.emailVerified == false &&
        user.providerData.any(
          (provider) =>
              provider.providerId ==
              'password',
        )) {
      context.go('/verification');
      return;
    }

    final onboardingCompleted =
        await UserProfileCache
            .isOnboardingCompleted();

    if (!mounted) {
      return;
    }

    if (onboardingCompleted) {
      context.go('/home');
    } else {
      context.go('/onboarding');
    }
  }

  void _handleAuthState(
    BuildContext context,
    AuthState state,
  ) {
    if (state.status ==
        AuthStatus.notRegistered) {
      _showSnackBar(
        'This account is not registered. Please create an account first.',
        isError: true,
      );

      Future.delayed(
        const Duration(
          milliseconds: 700,
        ),
        () {
          if (!mounted) {
            return;
          }

          context.go('/register');
        },
      );

      return;
    }

    if (state.status ==
            AuthStatus.success &&
        state.user != null) {
      _handleSuccessfulLogin(
        state.user!,
      );

      return;
    }

    if (state.status ==
        AuthStatus.failure) {
      final errorCode =
          state.errorCode;

      if (errorCode ==
              'wrong-password' ||
          errorCode ==
              'invalid-credential') {
        _showWrongPasswordDialog();
        return;
      }

      _showSnackBar(
        state.errorMessage ??
            'Authentication failed.',
        isError: true,
      );
    }
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final theme =
        Theme.of(context);

    final isDark =
        theme.brightness ==
            Brightness.dark;

    final textPrimary =
        theme.colorScheme.onSurface;

    final textSecondary = isDark
        ? const Color(0xFFB8B6CC)
        : const Color(0xFF6F6B98);

    final cardColor = isDark
        ? const Color(0xFF1D1D29)
        : Colors.white;

    return BlocListener<
        AuthCubit,
        AuthState>(
      listener:
          _handleAuthState,
      child: Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration:
              const BoxDecoration(
            gradient:
                LinearGradient(
              begin:
                  Alignment.topLeft,
              end: Alignment
                  .bottomRight,
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
                SingleChildScrollView(
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 25,
                  ),
                  child: Column(
                    children: [
                      const SizedBox(
                        height: 55,
                      ),
                      const LoginHeader(),
                      const SizedBox(
                        height: 30,
                      ),
                      LoginForm(
                        formKey: formKey,
                        emailController:
                            emailController,
                        passwordController:
                            passwordController,
                        obscurePassword:
                            obscurePassword,
                        isSocialLoading:
                            isSocialLoading,
                        textPrimary:
                            textPrimary,
                        textSecondary:
                            textSecondary,
                        cardColor:
                            cardColor,
                        onTogglePassword:
                            togglePasswordVisibility,
                        onForgotPassword:
                            forgotPassword,
                        onLogin:
                            login,
                        onRegister: () {
                          context.push(
                            '/register',
                          );
                        },
                        onGoogle:
                            loginWithGoogle,
                        onFacebook:
                            loginWithFacebook,
                      ),
                      const SizedBox(
                        height: 20,
                      ),
                    ],
                  ),
                ),
                LoginThemeButton(
                  onToggleTheme:
                      toggleTheme,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}