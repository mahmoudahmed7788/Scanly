import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:scanly/Auth/Auth_Cubit.dart';
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
  // ============================================================
  // CONTROLLERS
  // ============================================================

  final TextEditingController emailController =
      TextEditingController();

  final TextEditingController passwordController =
      TextEditingController();

  // ============================================================
  // FORM
  // ============================================================

  final GlobalKey<FormState> formKey =
      GlobalKey<FormState>();

  // ============================================================
  // UI STATE
  // ============================================================

  bool obscurePassword = true;

  bool isGoogleLoading = false;

  bool isFacebookLoading = false;

  bool isSocialLogin = false;

  // ============================================================
  // LIFECYCLE
  // ============================================================

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();

    super.dispose();
  }

  // ============================================================
  // GETTERS
  // ============================================================

  bool get isSocialLoading {
    return isGoogleLoading || isFacebookLoading;
  }

  // ============================================================
  // EMAIL LOGIN
  // ============================================================

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

  // ============================================================
  // GOOGLE LOGIN
  // ============================================================

  Future<void> loginWithGoogle() async {
    if (isSocialLoading) {
      return;
    }

    setState(() {
      isGoogleLoading = true;
      isSocialLogin = true;
    });

    try {
      final authCubit = context.read<AuthCubit>();

      await authCubit.signInWithGoogle();

      if (!mounted) {
        return;
      }

      final User? user =
          FirebaseAuth.instance.currentUser;

      debugPrint(
        'LOGIN PAGE GOOGLE USER: ${user?.email}',
      );

      if (user != null) {
        debugPrint(
          'LOGIN PAGE GOOGLE: Going to Home',
        );

        context.go('/home');
      }
    } catch (e) {
      debugPrint(
        'LOGIN PAGE GOOGLE ERROR: $e',
      );

      if (!mounted) {
        return;
      }

      _showSnackBar(
        'Google login failed: $e',
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

  // ============================================================
  // FACEBOOK LOGIN
  // ============================================================

  Future<void> loginWithFacebook() async {
    if (isSocialLoading) {
      return;
    }

    setState(() {
      isFacebookLoading = true;
      isSocialLogin = true;
    });

    try {
      final authCubit = context.read<AuthCubit>();

      await authCubit.signInWithFacebook();

      if (!mounted) {
        return;
      }

      final User? user =
          FirebaseAuth.instance.currentUser;

      debugPrint(
        'LOGIN PAGE FACEBOOK USER: ${user?.email}',
      );

      if (user != null) {
        debugPrint(
          'LOGIN PAGE FACEBOOK: Going to Home',
        );

        context.go('/home');
      }
    } catch (e) {
      debugPrint(
        'LOGIN PAGE FACEBOOK ERROR: $e',
      );

      if (!mounted) {
        return;
      }

      _showSnackBar(
        'Facebook login failed: $e',
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

  // ============================================================
  // FORGOT PASSWORD
  // ============================================================

  Future<void> forgotPassword() async {
    final email = emailController.text.trim();

    if (email.isEmpty) {
      _showSnackBar(
        'Please enter your email first.',
      );

      return;
    }

    if (!_isValidEmail(email)) {
      _showSnackBar(
        'Please enter a valid email address.',
      );

      return;
    }

    await context
        .read<AuthCubit>()
        .sendPasswordResetEmail(email);

    if (!mounted) {
      return;
    }

    final state =
        context.read<AuthCubit>().state;

    if (state.status == AuthStatus.success) {
      context.push(
        '/forgot-password-verification',
        extra: email,
      );
    }
  }

  // ============================================================
  // EMAIL VALIDATION
  // ============================================================

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
    );

    return emailRegex.hasMatch(email);
  }

  // ============================================================
  // PASSWORD VISIBILITY
  // ============================================================

  void togglePasswordVisibility() {
    setState(() {
      obscurePassword = !obscurePassword;
    });
  }

  // ============================================================
  // THEME
  // ============================================================

  Future<void> toggleTheme() async {
    await ThemeController.toggleTheme();
  }

  // ============================================================
  // SNACKBAR
  // ============================================================

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

  // ============================================================
  // AUTH STATE LISTENER
  // ============================================================

  void _handleAuthState(
    BuildContext context,
    AuthState state,
  ) {
    if (state.status == AuthStatus.success &&
        state.user != null) {
      final user = state.user!;

      // --------------------------------------------------------
      // GOOGLE / FACEBOOK
      // --------------------------------------------------------

      if (isSocialLogin) {
        context.go('/home');

        return;
      }

      // --------------------------------------------------------
      // EMAIL LOGIN
      // --------------------------------------------------------

      if (user.emailVerified) {
        context.go('/home');
      } else {
        context.go('/verification');
      }

      return;
    }

    if (state.status == AuthStatus.failure) {
      _showSnackBar(
        state.errorMessage ??
            'Authentication failed.',
        isError: true,
      );
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

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

    return BlocListener<AuthCubit, AuthState>(
      listener: _handleAuthState,
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
                SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 25,
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 55),

                      const LoginHeader(),

                      const SizedBox(height: 30),

                      LoginForm(
                        formKey: formKey,
                        emailController: emailController,
                        passwordController: passwordController,
                        obscurePassword: obscurePassword,
                        isSocialLoading: isSocialLoading,
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                        cardColor: cardColor,
                        onTogglePassword:
                            togglePasswordVisibility,
                        onForgotPassword:
                            forgotPassword,
                        onLogin: login,
                        onRegister: () {
                          context.push('/register');
                        },
                      ),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),

                LoginThemeButton(
                  onToggleTheme: toggleTheme,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}