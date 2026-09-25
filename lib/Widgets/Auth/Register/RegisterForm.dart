import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:scanly/Auth/Auth_Cubit.dart';

class RegisterForm extends StatelessWidget {
  final TextEditingController firstNameController;
  final TextEditingController lastNameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;

  final bool obscurePassword;
  final bool obscureConfirmPassword;

  final bool isSocialLoading;

  final VoidCallback onTogglePassword;
  final VoidCallback onToggleConfirmPassword;
  final VoidCallback onRegister;

  const RegisterForm({
    super.key,
    required this.firstNameController,
    required this.lastNameController,
    required this.emailController,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.obscurePassword,
    required this.obscureConfirmPassword,
    required this.isSocialLoading,
    required this.onTogglePassword,
    required this.onToggleConfirmPassword,
    required this.onRegister,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ==========================================================
        // FIRST NAME
        // ==========================================================

        TextFormField(
          controller: firstNameController,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
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

        // ==========================================================
        // LAST NAME
        // ==========================================================

        TextFormField(
          controller: lastNameController,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
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

        // ==========================================================
        // EMAIL
        // ==========================================================

        TextFormField(
          controller: emailController,
          keyboardType:
              TextInputType.emailAddress,
          textInputAction:
              TextInputAction.next,
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

        // ==========================================================
        // PASSWORD
        // ==========================================================

        TextFormField(
          controller: passwordController,
          obscureText: obscurePassword,
          textInputAction:
              TextInputAction.next,
          decoration: InputDecoration(
            hintText: 'Password',
            prefixIcon: const Icon(
              Icons.lock_outline_rounded,
            ),
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

        // ==========================================================
        // CONFIRM PASSWORD
        // ==========================================================

        TextFormField(
          controller:
              confirmPasswordController,
          obscureText:
              obscureConfirmPassword,
          textInputAction:
              TextInputAction.done,
          decoration: InputDecoration(
            hintText: 'Confirm Password',
            prefixIcon: const Icon(
              Icons.lock_outline_rounded,
            ),
            suffixIcon: IconButton(
              onPressed:
                  onToggleConfirmPassword,
              icon: Icon(
                obscureConfirmPassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
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

        // ==========================================================
        // CREATE ACCOUNT BUTTON
        // ==========================================================

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
                        : onRegister,
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
                        BorderRadius.circular(
                      18,
                    ),
                  ),
                ),
                child:
                    isLoading &&
                            !isSocialLoading
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
      ],
    );
  }
}