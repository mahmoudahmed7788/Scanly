import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:scanly/Auth/Auth_Cubit.dart';

class ForgotPasswordPage extends StatefulWidget {
  final String? initialEmail;

  const ForgotPasswordPage({
    super.key,
    this.initialEmail, required String email,
  });

  @override
  State<ForgotPasswordPage> createState() =>
      _ForgotPasswordPageState();
}

class _ForgotPasswordPageState
    extends State<ForgotPasswordPage> {
  late final TextEditingController emailController;

  bool isLoading = false;
  bool emailTouched = false;

  @override
  void initState() {
    super.initState();

    emailController = TextEditingController(
      text: widget.initialEmail ?? '',
    );

    emailController.addListener(_onEmailChanged);
  }

  @override
  void dispose() {
    emailController.removeListener(
      _onEmailChanged,
    );

    emailController.dispose();

    super.dispose();
  }

  void _onEmailChanged() {
    if (!mounted) {
      return;
    }

    setState(() {});
  }

  bool get _isValidEmail {
    return RegExp(
      r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
    ).hasMatch(
      emailController.text.trim(),
    );
  }

  bool get _showEmailError {
    return emailTouched && !_isValidEmail;
  }

  InputBorder _border({
    required bool error,
    required Color normalColor,
  }) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(
        color: error
            ? Colors.redAccent
            : normalColor,
        width: error ? 1.6 : 1,
      ),
    );
  }

  Future<void> _sendResetEmail() async {
    setState(() {
      emailTouched = true;
    });

    final email = emailController.text.trim();

    if (!_isValidEmail) {
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final authCubit = context.read<AuthCubit>();

      await authCubit.sendPasswordResetEmail(
        email,
      );

      if (!mounted) {
        return;
      }

      final state = authCubit.state;

      if (state.status == AuthStatus.success) {
        context.push(
          '/forgot-password-verification',
          extra: email,
        );

        return;
      }

      _showError(
        state.errorMessage ??
            'Unable to send password reset email.',
      );
    } catch (e) {
      debugPrint(
        'FORGOT PASSWORD PAGE ERROR: $e',
      );

      if (!mounted) {
        return;
      }

      _showError(
        'Unable to send password reset email.',
      );
    } finally {
      if (!mounted) {
        return;
      }

      setState(() {
        isLoading = false;
      });
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
      ),
    );
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

    final normalBorder =
        textSecondary.withOpacity(0.25);

    return Scaffold(
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    onPressed: isLoading
                        ? null
                        : () {
                            context.pop();
                          },
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.white,
                    ),
                  ),
                ),

                const SizedBox(height: 55),

                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color:
                        Colors.white.withOpacity(0.18),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color:
                          Colors.white.withOpacity(0.3),
                    ),
                  ),
                  child: const Icon(
                    Icons.lock_reset_rounded,
                    size: 52,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: 25),

                const Text(
                  'Forgot Password?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 12),

                const Text(
                  'Enter your email address and we will '
                  'send you a link to reset your password.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 15,
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: 30),

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
                            Colors.black.withOpacity(
                          0.12,
                        ),
                        blurRadius: 25,
                        offset:
                            const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Align(
                        alignment:
                            Alignment.centerLeft,
                        child: Text(
                          'Email Address',
                          style: TextStyle(
                            color: textPrimary,
                            fontSize: 14,
                            fontWeight:
                                FontWeight.w600,
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      TextFormField(
                        controller:
                            emailController,
                        keyboardType:
                            TextInputType.emailAddress,
                        textInputAction:
                            TextInputAction.done,
                        onTap: () {
                          if (!emailTouched) {
                            setState(() {
                              emailTouched = true;
                            });
                          }
                        },
                        onFieldSubmitted: (_) {
                          if (!isLoading) {
                            _sendResetEmail();
                          }
                        },
                        decoration:
                            InputDecoration(
                          hintText:
                              'Enter your email',
                          prefixIcon:
                              const Icon(
                            Icons.email_outlined,
                          ),
                          enabledBorder:
                              _border(
                            error:
                                _showEmailError,
                            normalColor:
                                normalBorder,
                          ),
                          focusedBorder:
                              _border(
                            error:
                                _showEmailError,
                            normalColor:
                                _showEmailError
                                    ? Colors
                                        .redAccent
                                    : const Color(
                                        0xFF5B5FEF,
                                      ),
                          ),
                          errorBorder:
                              _border(
                            error: true,
                            normalColor:
                                Colors.redAccent,
                          ),
                          focusedErrorBorder:
                              _border(
                            error: true,
                            normalColor:
                                Colors.redAccent,
                          ),
                          errorText:
                              _showEmailError
                                  ? 'Enter a valid email'
                                  : null,
                          errorStyle:
                              const TextStyle(
                            color:
                                Colors.redAccent,
                          ),
                        ),
                      ),

                      const SizedBox(height: 22),

                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          onPressed: isLoading
                              ? null
                              : _sendResetEmail,
                          style:
                              ElevatedButton
                                  .styleFrom(
                            backgroundColor:
                                const Color(
                              0xFF5B5FEF,
                            ),
                            foregroundColor:
                                Colors.white,
                            disabledBackgroundColor:
                                const Color(
                              0xFF5B5FEF,
                            ).withOpacity(0.45),
                            elevation: 0,
                            shape:
                                RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius
                                      .circular(
                                18,
                              ),
                            ),
                          ),
                          child: isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child:
                                      CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color:
                                        Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Send Reset Link',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight:
                                        FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),

                      const SizedBox(height: 18),

                      TextButton(
                        onPressed: isLoading
                            ? null
                            : () {
                                context.go(
                                  '/login',
                                );
                              },
                        child: const Text(
                          'Back to Login',
                          style: TextStyle(
                            color:
                                Color(0xFF5B5FEF),
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                Text(
                  'If you do not receive the email, '
                  'check your Spam or Junk folder.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white
                        .withOpacity(0.85),
                    fontSize: 13,
                    height: 1.5,
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