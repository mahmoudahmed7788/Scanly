import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:scanly/Auth/Auth_Cubit.dart';

class ResetPasswordPage extends StatefulWidget {
  final String code;

  const ResetPasswordPage({
    super.key,
    required this.code,
  });

  @override
  State<ResetPasswordPage>
      createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState
    extends State<ResetPasswordPage> {
  final GlobalKey<FormState> _formKey =
      GlobalKey<FormState>();

  final TextEditingController
      _passwordController =
      TextEditingController();

  final TextEditingController
      _confirmController =
      TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _loading = true;
  bool _validCode = false;
  String? _email;

  @override
  void initState() {
    super.initState();

    _verifyCode();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();

    super.dispose();
  }

  // ==========================================================
  // VERIFY RESET CODE
  // ==========================================================

  Future<void> _verifyCode() async {
    final email =
        await context
            .read<AuthCubit>()
            .verifyPasswordResetCode(
              widget.code,
            );

    if (!mounted) {
      return;
    }

    setState(() {
      _email = email;
      _validCode = email != null;
      _loading = false;
    });
  }

  // ==========================================================
  // RESET PASSWORD
  // ==========================================================

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _loading = true;
    });

    final success =
        await context
            .read<AuthCubit>()
            .confirmPasswordReset(
              code: widget.code,
              newPassword:
                  _passwordController.text,
            );

    if (!mounted) {
      return;
    }

    setState(() {
      _loading = false;
    });

    if (!success) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'This reset link is invalid or has expired.',
          ),
          backgroundColor:
              Colors.redAccent,
        ),
      );

      return;
    }

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          icon: const Icon(
            Icons.check_circle_outline_rounded,
            size: 50,
            color: Colors.green,
          ),
          title: const Text(
            'Password Updated',
          ),
          content: const Text(
            'Your password has been changed successfully. '
            'You can now log in with your new password.',
            textAlign: TextAlign.center,
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  Navigator.of(dialogContext)
                      .pop();
                },
                child: const Text(
                  'Back to Login',
                ),
              ),
            ),
          ],
        );
      },
    );

    if (!mounted) {
      return;
    }

    context.go('/login');
  }

  // ==========================================================
  // PASSWORD VALIDATION
  // ==========================================================

  String? _validatePassword(
    String? value,
  ) {
    final password = value ?? '';

    if (password.isEmpty) {
      return 'Please enter a new password.';
    }

    if (password.length < 6) {
      return 'Password must be at least 6 characters.';
    }

    return null;
  }

  String? _validateConfirm(
    String? value,
  ) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password.';
    }

    if (value != _passwordController.text) {
      return 'Passwords do not match.';
    }

    return null;
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark =
        theme.brightness == Brightness.dark;

    if (_loading) {
      return Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration:
              const BoxDecoration(
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
          child: const Center(
            child: CircularProgressIndicator(
              color: Colors.white,
            ),
          ),
        ),
      );
    }

    if (!_validCode) {
      return Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration:
              const BoxDecoration(
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
            child: Center(
              child: Padding(
                padding:
                    const EdgeInsets.all(24),
                child: Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF1D1D29)
                        : Colors.white,
                    borderRadius:
                        BorderRadius.circular(24),
                  ),
                  child: Column(
                    mainAxisSize:
                        MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.link_off_rounded,
                        size: 60,
                        color: Colors.redAccent,
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'Invalid Reset Link',
                        textAlign:
                            TextAlign.center,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'This password reset link is '
                        'invalid or has expired.',
                        textAlign:
                            TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width:
                            double.infinity,
                        child: FilledButton(
                          onPressed: () {
                            context.go(
                              '/login',
                            );
                          },
                          child: const Text(
                            'Back to Login',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration:
            const BoxDecoration(
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
          child: Center(
            child: SingleChildScrollView(
              padding:
                  const EdgeInsets.all(24),
              child: Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1D1D29)
                      : Colors.white,
                  borderRadius:
                      BorderRadius.circular(24),
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      const Center(
                        child: Icon(
                          Icons.lock_reset_rounded,
                          size: 60,
                          color:
                              Color(0xFF5B5FEF),
                        ),
                      ),

                      const SizedBox(height: 20),

                      const Center(
                        child: Text(
                          'Create New Password',
                          textAlign:
                              TextAlign.center,
                          style: TextStyle(
                            fontSize: 27,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      Center(
                        child: Text(
                          _email ?? '',
                          textAlign:
                              TextAlign.center,
                          style: TextStyle(
                            color: theme
                                .colorScheme
                                .onSurface
                                .withOpacity(
                              0.65,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 28),

                      TextFormField(
                        controller:
                            _passwordController,
                        obscureText:
                            _obscurePassword,
                        validator:
                            _validatePassword,
                        decoration:
                            InputDecoration(
                          labelText:
                              'New Password',
                          prefixIcon:
                              const Icon(
                            Icons
                                .lock_outline_rounded,
                          ),
                          suffixIcon:
                              IconButton(
                            onPressed: () {
                              setState(() {
                                _obscurePassword =
                                    !_obscurePassword;
                              });
                            },
                            icon: Icon(
                              _obscurePassword
                                  ? Icons
                                      .visibility_off_outlined
                                  : Icons
                                      .visibility_outlined,
                            ),
                          ),
                          border:
                              OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(
                              16,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      TextFormField(
                        controller:
                            _confirmController,
                        obscureText:
                            _obscureConfirm,
                        validator:
                            _validateConfirm,
                        decoration:
                            InputDecoration(
                          labelText:
                              'Confirm Password',
                          prefixIcon:
                              const Icon(
                            Icons
                                .lock_outline_rounded,
                          ),
                          suffixIcon:
                              IconButton(
                            onPressed: () {
                              setState(() {
                                _obscureConfirm =
                                    !_obscureConfirm;
                              });
                            },
                            icon: Icon(
                              _obscureConfirm
                                  ? Icons
                                      .visibility_off_outlined
                                  : Icons
                                      .visibility_outlined,
                            ),
                          ),
                          border:
                              OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(
                              16,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      SizedBox(
                        width:
                            double.infinity,
                        height: 54,
                        child: FilledButton(
                          onPressed:
                              _loading
                                  ? null
                                  : _resetPassword,
                          child: const Text(
                            'Update Password',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
