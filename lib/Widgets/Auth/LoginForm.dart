import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:scanly/Auth/Auth_Cubit.dart';
import 'package:scanly/Widgets/Auth/SocialButton.dart';

class LoginForm extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool obscurePassword;
  final bool isSocialLoading;
  final Color textPrimary;
  final Color textSecondary;
  final Color cardColor;
  final VoidCallback onTogglePassword;
  final VoidCallback onForgotPassword;
  final VoidCallback onLogin;
  final VoidCallback onRegister;
  final VoidCallback onGoogle;
  final VoidCallback onFacebook;

  const LoginForm({
    super.key,
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.obscurePassword,
    required this.isSocialLoading,
    required this.textPrimary,
    required this.textSecondary,
    required this.cardColor,
    required this.onTogglePassword,
    required this.onForgotPassword,
    required this.onLogin,
    required this.onRegister,
    required this.onGoogle,
    required this.onFacebook,
  });

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  bool _emailTouched = false;
  bool _passwordTouched = false;

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
    );

    return emailRegex.hasMatch(email);
  }

  bool get _emailIsValid {
    return _isValidEmail(
      widget.emailController.text.trim(),
    );
  }

  bool get _passwordIsValid {
    return widget.passwordController.text.isNotEmpty;
  }

  InputBorder _border({
    required bool error,
    required Color color,
  }) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(
        color: error ? Colors.redAccent : color,
        width: error ? 1.6 : 1,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final errorColor = Colors.redAccent;
    final normalBorder =
        widget.textSecondary.withOpacity(0.25);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: widget.cardColor,
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
        key: widget.formKey,
        child: Column(
          children: [
            TextFormField(
              controller: widget.emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              onChanged: (_) {
                setState(() {
                  _emailTouched = true;
                });
              },
              decoration: InputDecoration(
                hintText: 'Email',
                prefixIcon: const Icon(
                  Icons.email_outlined,
                ),
                enabledBorder: _border(
                  error:
                      _emailTouched && !_emailIsValid,
                  color: normalBorder,
                ),
                focusedBorder: _border(
                  error:
                      _emailTouched && !_emailIsValid,
                  color: _emailIsValid
                      ? const Color(0xFF5B5FEF)
                      : errorColor,
                ),
                errorBorder: _border(
                  error: true,
                  color: errorColor,
                ),
                focusedErrorBorder: _border(
                  error: true,
                  color: errorColor,
                ),
                errorStyle: const TextStyle(
                  color: Colors.redAccent,
                ),
              ),
              validator: (value) {
                if (value == null ||
                    value.trim().isEmpty) {
                  return 'Enter your email';
                }

                if (!_isValidEmail(
                  value.trim(),
                )) {
                  return 'Enter a valid email';
                }

                return null;
              },
            ),

            const SizedBox(height: 15),

            TextFormField(
              controller: widget.passwordController,
              obscureText: widget.obscurePassword,
              textInputAction: TextInputAction.done,
              onChanged: (_) {
                setState(() {
                  _passwordTouched = true;
                });
              },
              decoration: InputDecoration(
                hintText: 'Password',
                prefixIcon: const Icon(
                  Icons.lock_outline_rounded,
                ),
                suffixIcon: IconButton(
                  onPressed: widget.onTogglePassword,
                  icon: Icon(
                    widget.obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                  ),
                ),
                enabledBorder: _border(
                  error:
                      _passwordTouched &&
                      !_passwordIsValid,
                  color: normalBorder,
                ),
                focusedBorder: _border(
                  error:
                      _passwordTouched &&
                      !_passwordIsValid,
                  color: _passwordIsValid
                      ? const Color(0xFF5B5FEF)
                      : errorColor,
                ),
                errorBorder: _border(
                  error: true,
                  color: errorColor,
                ),
                focusedErrorBorder: _border(
                  error: true,
                  color: errorColor,
                ),
                errorStyle: const TextStyle(
                  color: Colors.redAccent,
                ),
              ),
              validator: (value) {
                if (value == null ||
                    value.isEmpty) {
                  return 'Enter your password';
                }

                return null;
              },
            ),

            const SizedBox(height: 8),

            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: widget.isSocialLoading
                    ? null
                    : widget.onForgotPassword,
                child: const Text(
                  'Forgot Password?',
                  style: TextStyle(
                    color: Color(0xFF5B5FEF),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 10),

            BlocBuilder<AuthCubit, AuthState>(
              builder: (context, state) {
                final isLoading =
                    state.status == AuthStatus.loading;

                return SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed:
                        isLoading ||
                                widget.isSocialLoading
                            ? null
                            : widget.onLogin,
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
                        isLoading &&
                                !widget.isSocialLoading
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
            ),

            const SizedBox(height: 25),

            Row(
              children: [
                Expanded(
                  child: Divider(
                    color: widget.textSecondary
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
                      color: widget.textSecondary,
                      fontSize: 11,
                      fontWeight:
                          FontWeight.w600,
                      letterSpacing: 0.7,
                    ),
                  ),
                ),
                Expanded(
                  child: Divider(
                    color: widget.textSecondary
                        .withOpacity(0.25),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            SocialButton(
              textPrimary: widget.textPrimary,
              isSocialLoading:
                  widget.isSocialLoading,
              onGoogle: widget.onGoogle,
              onFacebook: widget.onFacebook,
              onPressed: () {},
              icon: const Icon(Icons.login),
              label: '',
              foregroundColor:
                  widget.textPrimary,
            ),

            const SizedBox(height: 25),

            Row(
              mainAxisAlignment:
                  MainAxisAlignment.center,
              children: [
                Text(
                  'Don\'t have an account? ',
                  style: TextStyle(
                    color: widget.textSecondary,
                  ),
                ),
                TextButton(
                  onPressed:
                      widget.isSocialLoading
                          ? null
                          : widget.onRegister,
                  child: const Text(
                    'Create Account',
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
    );
  }
}
