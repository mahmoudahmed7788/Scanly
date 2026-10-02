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

  // ============================================================
  // PASSWORD CONDITIONS
  // ============================================================

  bool _hasMinimumLength(String password) {
    return password.length >= 8;
  }

  bool _hasUppercase(String password) {
    return RegExp(r'[A-Z]').hasMatch(password);
  }

  bool _hasLowercase(String password) {
    return RegExp(r'[a-z]').hasMatch(password);
  }

  bool _hasNumber(String password) {
    return RegExp(r'[0-9]').hasMatch(password);
  }

  bool _hasSpecialCharacter(String password) {
    return RegExp(
      r'''[!@#$%^&*(),.?":{}|<>_\-\\/\[\]+=]''',
    ).hasMatch(password);
  }

  bool _hasNoSpaces(String password) {
    return !password.contains(RegExp(r'\s'));
  }

  bool _isStrongPassword(String password) {
    return _hasMinimumLength(password) &&
        _hasUppercase(password) &&
        _hasLowercase(password) &&
        _hasNumber(password) &&
        _hasSpecialCharacter(password) &&
        _hasNoSpaces(password);
  }

  // ============================================================
  // PASSWORD REQUIREMENT ITEM
  // ============================================================

  Widget _passwordRequirement({
    required String text,
    required bool valid,
    required bool isDark,
  }) {
    final color = valid
        ? Colors.green
        : (isDark
            ? const Color(0xFFB8B6CC)
            : const Color(0xFF77738F));

    return Padding(
      padding: const EdgeInsets.only(
        bottom: 7,
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.center,
        children: [
          AnimatedSwitcher(
            duration:
                const Duration(milliseconds: 180),
            child: Icon(
              valid
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              key: ValueKey(valid),
              size: 17,
              color: color,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: color,
                fontSize: 12.5,
                fontWeight: valid
                    ? FontWeight.w600
                    : FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PASSWORD REQUIREMENTS
  // ============================================================

  Widget _buildPasswordRequirements(
    BuildContext context,
  ) {
    final theme = Theme.of(context);

    final isDark =
        theme.brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: passwordController,
      builder: (context, child) {
        final password =
            passwordController.text;

        final hasStarted =
            password.isNotEmpty;

        return AnimatedSize(
          duration:
              const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          child: hasStarted
              ? Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(
                    top: 10,
                  ),
                  padding:
                      const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF252533)
                        : const Color(0xFFF7F7FC),
                    borderRadius:
                        BorderRadius.circular(14),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF3A394B)
                          : const Color(0xFFE5E4F0),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Password requirements',
                        style: TextStyle(
                          color: theme
                              .colorScheme
                              .onSurface,
                          fontSize: 13,
                          fontWeight:
                              FontWeight.w700,
                        ),
                      ),
                      const SizedBox(
                        height: 10,
                      ),

                      _passwordRequirement(
                        text:
                            'At least 8 characters',
                        valid:
                            _hasMinimumLength(
                          password,
                        ),
                        isDark: isDark,
                      ),

                      _passwordRequirement(
                        text:
                            'One uppercase letter (A-Z)',
                        valid:
                            _hasUppercase(
                          password,
                        ),
                        isDark: isDark,
                      ),

                      _passwordRequirement(
                        text:
                            'One lowercase letter (a-z)',
                        valid:
                            _hasLowercase(
                          password,
                        ),
                        isDark: isDark,
                      ),

                      _passwordRequirement(
                        text:
                            'One number (0-9)',
                        valid:
                            _hasNumber(
                          password,
                        ),
                        isDark: isDark,
                      ),

                      _passwordRequirement(
                        text:
                            'One special character (!@#\$...)',
                        valid:
                            _hasSpecialCharacter(
                          password,
                        ),
                        isDark: isDark,
                      ),

                      _passwordRequirement(
                        text:
                            'No spaces',
                        valid:
                            _hasNoSpaces(
                          password,
                        ),
                        isDark: isDark,
                      ),
                    ],
                  ),
                )
              : const SizedBox.shrink(),
        );
      },
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ==========================================================
        // FIRST NAME
        // ==========================================================

        TextFormField(
          controller: firstNameController,
          textInputAction:
              TextInputAction.next,
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
          textInputAction:
              TextInputAction.next,
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
              onPressed:
                  onTogglePassword,
              icon: Icon(
                obscurePassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
              ),
            ),
          ),
          onChanged: (_) {
            // The controller listener used by
            // AnimatedBuilder will rebuild
            // the requirements section.
          },
          validator: (value) {
            if (value == null ||
                value.isEmpty) {
              return 'Enter your password';
            }

            if (!_isStrongPassword(value)) {
              return 'Password does not meet all requirements';
            }

            return null;
          },
        ),

        // ==========================================================
        // PASSWORD REQUIREMENTS
        // ==========================================================

        _buildPasswordRequirements(
          context,
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