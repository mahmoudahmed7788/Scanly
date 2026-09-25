import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:scanly/Auth/Auth_Cubit.dart';

import 'package:scanly/Widgets/Auth/SocialButton.dart';

class LoginForm extends StatelessWidget {
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
  });

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

    return emailRegex.hasMatch(email);
  }

  @override
  Widget build(BuildContext context) {
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
            // ====================================================
            // EMAIL
            // ====================================================
            TextFormField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                hintText: 'Email',
                prefixIcon: Icon(Icons.email_outlined),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Enter your email';
                }

                if (!_isValidEmail(value.trim())) {
                  return 'Enter a valid email';
                }

                return null;
              },
            ),

            const SizedBox(height: 15),

            // ====================================================
            // PASSWORD
            // ====================================================
            TextFormField(
              controller: passwordController,
              obscureText: obscurePassword,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                hintText: 'Password',
                prefixIcon: const Icon(Icons.lock_outline_rounded),
                suffixIcon: IconButton(
                  onPressed: onTogglePassword,
                  icon: Icon(
                    obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                  ),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Enter your password';
                }

                return null;
              },
            ),

            const SizedBox(height: 8),

            // ====================================================
            // FORGOT PASSWORD
            // ====================================================
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: isSocialLoading ? null : onForgotPassword,
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

            // ====================================================
            // LOGIN
            // ====================================================
            BlocBuilder<AuthCubit, AuthState>(
              builder: (context, state) {
                final isLoading = state.status == AuthStatus.loading;

                return SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: isLoading || isSocialLoading ? null : onLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5B5FEF),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: const Color(
                        0xFF5B5FEF,
                      ).withOpacity(0.55),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: isLoading && !isSocialLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Login',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                );
              },
            ),

            const SizedBox(height: 25),

            // ====================================================
            // DIVIDER
            // ====================================================
            Row(
              children: [
                Expanded(
                  child: Divider(color: textSecondary.withOpacity(0.25)),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
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
                  child: Divider(color: textSecondary.withOpacity(0.25)),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // ====================================================
            // SOCIAL BUTTONS
            // ====================================================
            SocialButton(
              textPrimary: textPrimary,
              isSocialLoading: isSocialLoading,
              onGoogle: () {},
              onFacebook: () {},
              onPressed: () {},
              icon: const Icon(Icons.login),
              label: '',
              foregroundColor: textPrimary,
            ),

            const SizedBox(height: 25),

            // ====================================================
            // REGISTER
            // ====================================================
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Don\'t have an account? ',
                  style: TextStyle(color: textSecondary),
                ),
                TextButton(
                  onPressed: isSocialLoading ? null : onRegister,
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
