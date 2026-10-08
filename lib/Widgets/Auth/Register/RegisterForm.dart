import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:scanly/Auth/Auth_Cubit.dart';

class RegisterForm extends StatefulWidget {
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
  State<RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends State<RegisterForm> {
  bool _firstNameTouched = false;
  bool _lastNameTouched = false;
  bool _emailTouched = false;
  bool _passwordTouched = false;
  bool _confirmPasswordTouched = false;

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

  bool _isValidEmail(String email) {
    return RegExp(
      r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
    ).hasMatch(email);
  }

  bool get _firstNameValid {
    return widget.firstNameController.text.trim().isNotEmpty;
  }

  bool get _lastNameValid {
    return widget.lastNameController.text.trim().isNotEmpty;
  }

  bool get _emailValid {
    return _isValidEmail(
      widget.emailController.text.trim(),
    );
  }

  bool get _passwordValid {
    return _isStrongPassword(
      widget.passwordController.text,
    );
  }

  bool get _confirmPasswordValid {
    final password =
        widget.passwordController.text;

    final confirm =
        widget.confirmPasswordController.text;

    return confirm.isNotEmpty &&
        confirm == password;
  }

  bool get _showFirstNameError {
    return _firstNameTouched && !_firstNameValid;
  }

  bool get _showLastNameError {
    return _lastNameTouched && !_lastNameValid;
  }

  bool get _showEmailError {
    return _emailTouched && !_emailValid;
  }

  bool get _showPasswordError {
    return _passwordTouched && !_passwordValid;
  }

  bool get _showConfirmPasswordError {
    return _confirmPasswordTouched &&
        !_confirmPasswordValid;
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

  @override
  void initState() {
    super.initState();

    widget.firstNameController.addListener(
      _onTextChanged,
    );

    widget.lastNameController.addListener(
      _onTextChanged,
    );

    widget.emailController.addListener(
      _onTextChanged,
    );

    widget.passwordController.addListener(
      _onTextChanged,
    );

    widget.confirmPasswordController.addListener(
      _onTextChanged,
    );
  }

  @override
  void dispose() {
    widget.firstNameController.removeListener(
      _onTextChanged,
    );

    widget.lastNameController.removeListener(
      _onTextChanged,
    );

    widget.emailController.removeListener(
      _onTextChanged,
    );

    widget.passwordController.removeListener(
      _onTextChanged,
    );

    widget.confirmPasswordController.removeListener(
      _onTextChanged,
    );

    super.dispose();
  }

  void _onTextChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _markFirstNameTouched() {
    if (!_firstNameTouched) {
      setState(() {
        _firstNameTouched = true;
      });
    }
  }

  void _markLastNameTouched() {
    if (!_lastNameTouched) {
      setState(() {
        _lastNameTouched = true;
      });
    }
  }

  void _markEmailTouched() {
    if (!_emailTouched) {
      setState(() {
        _emailTouched = true;
      });
    }
  }

  void _markPasswordTouched() {
    if (!_passwordTouched) {
      setState(() {
        _passwordTouched = true;
      });
    }
  }

  void _markConfirmPasswordTouched() {
    if (!_confirmPasswordTouched) {
      setState(() {
        _confirmPasswordTouched = true;
      });
    }
  }

  void _validateAndRegister() {
    setState(() {
      _firstNameTouched = true;
      _lastNameTouched = true;
      _emailTouched = true;
      _passwordTouched = true;
      _confirmPasswordTouched = true;
    });

    if (!_firstNameValid ||
        !_lastNameValid ||
        !_emailValid ||
        !_passwordValid ||
        !_confirmPasswordValid) {
      return;
    }

    widget.onRegister();
  }

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
        children: [
          Icon(
            valid
                ? Icons.check_circle_rounded
                : Icons.radio_button_unchecked_rounded,
            size: 17,
            color: color,
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

  Widget _buildPasswordRequirements(
    BuildContext context,
  ) {
    final theme = Theme.of(context);

    final isDark =
        theme.brightness == Brightness.dark;

    final password =
        widget.passwordController.text;

    final hasStarted =
        password.isNotEmpty;

    if (!hasStarted) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(
        top: 10,
      ),
      padding: const EdgeInsets.all(14),
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
              color:
                  theme.colorScheme.onSurface,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          _passwordRequirement(
            text: 'At least 8 characters',
            valid: _hasMinimumLength(password),
            isDark: isDark,
          ),
          _passwordRequirement(
            text: 'One uppercase letter (A-Z)',
            valid: _hasUppercase(password),
            isDark: isDark,
          ),
          _passwordRequirement(
            text: 'One lowercase letter (a-z)',
            valid: _hasLowercase(password),
            isDark: isDark,
          ),
          _passwordRequirement(
            text: 'One number (0-9)',
            valid: _hasNumber(password),
            isDark: isDark,
          ),
          _passwordRequirement(
            text:
                'One special character (!@#\$...)',
            valid:
                _hasSpecialCharacter(password),
            isDark: isDark,
          ),
          _passwordRequirement(
            text: 'No spaces',
            valid: _hasNoSpaces(password),
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final normalBorder =
        theme.colorScheme.onSurface
            .withOpacity(0.18);

    return Column(
      children: [
        TextFormField(
          controller:
              widget.firstNameController,
          textInputAction:
              TextInputAction.next,
          onTap: _markFirstNameTouched,
          decoration: InputDecoration(
            hintText: 'First Name',
            prefixIcon: const Icon(
              Icons.person_outline_rounded,
            ),
            enabledBorder: _border(
              error: _showFirstNameError,
              normalColor: normalBorder,
            ),
            focusedBorder: _border(
              error: _showFirstNameError,
              normalColor:
                  const Color(0xFF5B5FEF),
            ),
            errorBorder: _border(
              error: true,
              normalColor: Colors.redAccent,
            ),
            focusedErrorBorder: _border(
              error: true,
              normalColor: Colors.redAccent,
            ),
            errorText: _showFirstNameError
                ? 'Enter your first name'
                : null,
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
        TextFormField(
          controller:
              widget.lastNameController,
          textInputAction:
              TextInputAction.next,
          onTap: _markLastNameTouched,
          decoration: InputDecoration(
            hintText: 'Last Name',
            prefixIcon: const Icon(
              Icons.person_outline_rounded,
            ),
            enabledBorder: _border(
              error: _showLastNameError,
              normalColor: normalBorder,
            ),
            focusedBorder: _border(
              error: _showLastNameError,
              normalColor:
                  const Color(0xFF5B5FEF),
            ),
            errorBorder: _border(
              error: true,
              normalColor: Colors.redAccent,
            ),
            focusedErrorBorder: _border(
              error: true,
              normalColor: Colors.redAccent,
            ),
            errorText: _showLastNameError
                ? 'Enter your last name'
                : null,
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
        TextFormField(
          controller:
              widget.emailController,
          keyboardType:
              TextInputType.emailAddress,
          textInputAction:
              TextInputAction.next,
          onTap: _markEmailTouched,
          decoration: InputDecoration(
            hintText: 'Email',
            prefixIcon: const Icon(
              Icons.email_outlined,
            ),
            enabledBorder: _border(
              error: _showEmailError,
              normalColor: normalBorder,
            ),
            focusedBorder: _border(
              error: _showEmailError,
              normalColor:
                  const Color(0xFF5B5FEF),
            ),
            errorBorder: _border(
              error: true,
              normalColor: Colors.redAccent,
            ),
            focusedErrorBorder: _border(
              error: true,
              normalColor: Colors.redAccent,
            ),
            errorText: _showEmailError
                ? (widget.emailController.text
                        .trim()
                        .isEmpty
                    ? 'Enter your email'
                    : 'Enter a valid email')
                : null,
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
          controller:
              widget.passwordController,
          obscureText:
              widget.obscurePassword,
          textInputAction:
              TextInputAction.next,
          onTap: _markPasswordTouched,
          decoration: InputDecoration(
            hintText: 'Password',
            prefixIcon: const Icon(
              Icons.lock_outline_rounded,
            ),
            suffixIcon: IconButton(
              onPressed:
                  widget.onTogglePassword,
              icon: Icon(
                widget.obscurePassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
              ),
            ),
            enabledBorder: _border(
              error: _showPasswordError,
              normalColor: normalBorder,
            ),
            focusedBorder: _border(
              error: _showPasswordError,
              normalColor:
                  const Color(0xFF5B5FEF),
            ),
            errorBorder: _border(
              error: true,
              normalColor: Colors.redAccent,
            ),
            focusedErrorBorder: _border(
              error: true,
              normalColor: Colors.redAccent,
            ),
            errorText: _showPasswordError
                ? (widget.passwordController
                        .text
                        .isEmpty
                    ? 'Enter your password'
                    : 'Password does not meet all requirements')
                : null,
          ),
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
        _buildPasswordRequirements(context),
        const SizedBox(height: 15),
        TextFormField(
          controller:
              widget.confirmPasswordController,
          obscureText:
              widget.obscureConfirmPassword,
          textInputAction:
              TextInputAction.done,
          onTap:
              _markConfirmPasswordTouched,
          decoration: InputDecoration(
            hintText: 'Confirm Password',
            prefixIcon: const Icon(
              Icons.lock_outline_rounded,
            ),
            suffixIcon: IconButton(
              onPressed:
                  widget.onToggleConfirmPassword,
              icon: Icon(
                widget.obscureConfirmPassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
              ),
            ),
            enabledBorder: _border(
              error:
                  _showConfirmPasswordError,
              normalColor: normalBorder,
            ),
            focusedBorder: _border(
              error:
                  _showConfirmPasswordError,
              normalColor:
                  const Color(0xFF5B5FEF),
            ),
            errorBorder: _border(
              error: true,
              normalColor: Colors.redAccent,
            ),
            focusedErrorBorder: _border(
              error: true,
              normalColor: Colors.redAccent,
            ),
            errorText:
                _showConfirmPasswordError
                    ? (widget
                            .confirmPasswordController
                            .text
                            .isEmpty
                        ? 'Confirm your password'
                        : 'Passwords do not match')
                    : null,
          ),
          validator: (value) {
            if (value == null ||
                value.isEmpty) {
              return 'Confirm your password';
            }

            if (value !=
                widget.passwordController.text) {
              return 'Passwords do not match';
            }

            return null;
          },
        ),
        const SizedBox(height: 25),
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
                            widget.isSocialLoading
                        ? null
                        : _validateAndRegister,
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