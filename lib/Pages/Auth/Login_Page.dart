// ============================================================
// IMPORTS
// ============================================================

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:scanly/Auth/Auth_Cubit.dart';
import 'package:scanly/core/App_Theme.dart';

// ============================================================
// LOGIN PAGE
// ============================================================

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

// ============================================================
// LOGIN PAGE STATE
// ============================================================

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

      // ----------------------------------------------------------
      // CHECK FIREBASE USER
      // ----------------------------------------------------------

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

      // ----------------------------------------------------------
      // CHECK FIREBASE USER
      // ----------------------------------------------------------

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

    // ----------------------------------------------------------
    // EMPTY EMAIL
    // ----------------------------------------------------------

    if (email.isEmpty) {
      _showSnackBar(
        'Please enter your email first.',
      );

      return;
    }

    // ----------------------------------------------------------
    // INVALID EMAIL
    // ----------------------------------------------------------

    if (!_isValidEmail(email)) {
      _showSnackBar(
        'Please enter a valid email address.',
      );

      return;
    }

    // ----------------------------------------------------------
    // SEND RESET EMAIL
    // ----------------------------------------------------------

    await context
        .read<AuthCubit>()
        .sendPasswordResetEmail(email);

    if (!mounted) {
      return;
    }

    final state =
        context.read<AuthCubit>().state;

    // ----------------------------------------------------------
    // SUCCESS
    // ----------------------------------------------------------

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
    // ----------------------------------------------------------
    // SUCCESS
    // ----------------------------------------------------------

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

    // ----------------------------------------------------------
    // FAILURE
    // ----------------------------------------------------------

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

    // ----------------------------------------------------------
    // THEME COLORS
    // ----------------------------------------------------------

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

          // ==================================================
          // BACKGROUND
          // ==================================================

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
                // MAIN CONTENT
                // ==================================================

                SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 25,
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 55),

                      // ============================================
                      // LOGO
                      // ============================================

                      _buildLogo(),

                      const SizedBox(height: 18),

                      // ============================================
                      // HEADER
                      // ============================================

                      _buildHeader(),

                      const SizedBox(height: 30),

                      // ============================================
                      // LOGIN CARD
                      // ============================================

                      _buildLoginCard(
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                        cardColor: cardColor,
                      ),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),

                // ==================================================
                // THEME BUTTON
                // ==================================================

                _buildThemeButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // LOGO
  // ============================================================

  Widget _buildLogo() {
    return Container(
      width: 90,
      height: 90,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withOpacity(0.30),
          width: 1,
        ),
      ),
      child: Image.asset(
        'assets/images/Scanly_Splash.png',
        fit: BoxFit.contain,
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader() {
    return const Column(
      children: [
        Text(
          'Welcome Back',
          style: TextStyle(
            color: Colors.white,
            fontSize: 30,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Login to continue to Scanly',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 15,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // LOGIN CARD
  // ============================================================

  Widget _buildLoginCard({
    required Color textPrimary,
    required Color textSecondary,
    required Color cardColor,
  }) {
    return Container(
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
            // ================================================
            // EMAIL FIELD
            // ================================================

            _buildEmailField(),

            const SizedBox(height: 15),

            // ================================================
            // PASSWORD FIELD
            // ================================================

            _buildPasswordField(),

            const SizedBox(height: 8),

            // ================================================
            // FORGOT PASSWORD
            // ================================================

            _buildForgotPasswordButton(),

            const SizedBox(height: 10),

            // ================================================
            // LOGIN BUTTON
            // ================================================

            _buildLoginButton(),

            const SizedBox(height: 25),

            // ================================================
            // DIVIDER
            // ================================================

            _buildDivider(textSecondary),

            const SizedBox(height: 20),

            // ================================================
            // SOCIAL LOGIN
            // ================================================

            _buildSocialButtons(textPrimary),

            const SizedBox(height: 25),

            // ================================================
            // REGISTER
            // ================================================

            _buildRegisterButton(textSecondary),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // EMAIL FIELD
  // ============================================================

  Widget _buildEmailField() {
    return TextFormField(
      controller: emailController,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      decoration: const InputDecoration(
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

        if (!_isValidEmail(value.trim())) {
          return 'Enter a valid email';
        }

        return null;
      },
    );
  }

  // ============================================================
  // PASSWORD FIELD
  // ============================================================

  Widget _buildPasswordField() {
    return TextFormField(
      controller: passwordController,
      obscureText: obscurePassword,
      textInputAction: TextInputAction.done,
      decoration: InputDecoration(
        hintText: 'Password',
        prefixIcon: const Icon(
          Icons.lock_outline_rounded,
        ),
        suffixIcon: IconButton(
          onPressed: togglePasswordVisibility,
          icon: Icon(
            obscurePassword
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
          ),
        ),
      ),
      validator: (value) {
        if (value == null ||
            value.isEmpty) {
          return 'Enter your password';
        }

        return null;
      },
    );
  }

  // ============================================================
  // FORGOT PASSWORD BUTTON
  // ============================================================

  Widget _buildForgotPasswordButton() {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed:
            isSocialLoading
                ? null
                : forgotPassword,
        child: const Text(
          'Forgot Password?',
          style: TextStyle(
            color: Color(0xFF5B5FEF),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // LOGIN BUTTON
  // ============================================================

  Widget _buildLoginButton() {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        final isLoading =
            state.status == AuthStatus.loading;

        return SizedBox(
          width: double.infinity,
          height: 55,
          child: ElevatedButton(
            onPressed:
                isLoading || isSocialLoading
                    ? null
                    : login,
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  const Color(0xFF5B5FEF),
              foregroundColor: Colors.white,
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
            child:
                isLoading && !isSocialLoading
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
                        'Login',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
          ),
        );
      },
    );
  }

  // ============================================================
  // DIVIDER
  // ============================================================

  Widget _buildDivider(Color textSecondary) {
    return Row(
      children: [
        Expanded(
          child: Divider(
            color:
                textSecondary.withOpacity(0.25),
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
            color:
                textSecondary.withOpacity(0.25),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // SOCIAL BUTTONS
  // ============================================================

  Widget _buildSocialButtons(
    Color textPrimary,
  ) {
    return Row(
      children: [
        // ------------------------------------------------------
        // GOOGLE
        // ------------------------------------------------------

        Expanded(
          child: _SocialButton(
            onPressed:
                isSocialLoading
                    ? null
                    : loginWithGoogle,
            icon: const Text(
              'G',
              style: TextStyle(
                fontSize: 21,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
            label: 'Google',
            isLoading: isGoogleLoading,
            foregroundColor: textPrimary,
          ),
        ),

        const SizedBox(width: 12),

        // ------------------------------------------------------
        // FACEBOOK
        // ------------------------------------------------------

        Expanded(
          child: _SocialButton(
            onPressed:
                isSocialLoading
                    ? null
                    : loginWithFacebook,
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
            foregroundColor: textPrimary,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // REGISTER BUTTON
  // ============================================================

  Widget _buildRegisterButton(
    Color textSecondary,
  ) {
    return Row(
      mainAxisAlignment:
          MainAxisAlignment.center,
      children: [
        Text(
          'Don\'t have an account? ',
          style: TextStyle(
            color: textSecondary,
          ),
        ),
        TextButton(
          onPressed:
              isSocialLoading
                  ? null
                  : () {
                      context.push(
                        '/register',
                      );
                    },
          child: const Text(
            'Create Account',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF5B5FEF),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // THEME BUTTON
  // ============================================================

  Widget _buildThemeButton() {
    return Positioned(
      top: 12,
      right: 20,
      child:
          ValueListenableBuilder<ThemeMode>(
        valueListenable:
            ThemeController.mode,
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
              onTap: toggleTheme,
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

// ============================================================
// SOCIAL BUTTON
// ============================================================

class _SocialButton extends StatelessWidget {
  // ============================================================
  // PROPERTIES
  // ============================================================

  final VoidCallback? onPressed;

  final Widget icon;

  final String label;

  final bool isLoading;

  final bool facebook;

  final Color foregroundColor;

  // ============================================================
  // CONSTRUCTOR
  // ============================================================

  const _SocialButton({
    required this.onPressed,
    required this.icon,
    required this.label,
    required this.foregroundColor,
    this.isLoading = false,
    this.facebook = false,
  });

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final borderColor =
        Theme.of(context)
            .colorScheme
            .onSurface
            .withOpacity(0.12);

    return SizedBox(
      height: 52,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: foregroundColor,
          side: BorderSide(
            color: borderColor,
          ),
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(16),
          ),
          padding:
              const EdgeInsets.symmetric(
            horizontal: 10,
          ),
        ),
        child: isLoading
            ? _buildLoadingIndicator()
            : _buildButtonContent(),
      ),
    );
  }

  // ============================================================
  // LOADING INDICATOR
  // ============================================================

  Widget _buildLoadingIndicator() {
    return SizedBox(
      width: 21,
      height: 21,
      child: CircularProgressIndicator(
        strokeWidth: 2.2,
        color: facebook
            ? const Color(0xFF1877F2)
            : const Color(0xFF5B5FEF),
      ),
    );
  }

  // ============================================================
  // BUTTON CONTENT
  // ============================================================

  Widget _buildButtonContent() {
    return Row(
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
                : Colors.transparent,
            shape: BoxShape.circle,
          ),
          child: icon,
        ),

        const SizedBox(width: 7),

        Flexible(
          child: Text(
            label,
            overflow:
                TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}