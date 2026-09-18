import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:scanly/Auth_Cubit.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  User? _user;
  Map<String, dynamic>? _userData;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    try {
      final auth = FirebaseAuth.instance;
      final user = auth.currentUser;

      if (user == null) {
        if (!mounted) return;

        setState(() {
          _loading = false;
        });

        return;
      }

      await user.reload();

      final currentUser = auth.currentUser;

      if (currentUser == null) {
        if (!mounted) return;

        setState(() {
          _loading = false;
        });

        return;
      }

      await context.read<AuthCubit>().getUserData();

      if (!mounted) return;

      setState(() {
        _user = currentUser;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _user = FirebaseAuth.instance.currentUser;
        _loading = false;
      });
    }
  }

  String get _displayName {
    final firestoreName = _userData?['name'];

    if (firestoreName is String && firestoreName.trim().isNotEmpty) {
      return firestoreName.trim();
    }

    final authName = _user?.displayName;

    if (authName != null && authName.trim().isNotEmpty) {
      return authName.trim();
    }

    final email = _user?.email;

    if (email != null && email.contains('@')) {
      return email.split('@').first;
    }

    return 'User';
  }

  String get _email {
    return _user?.email ?? 'No email';
  }

  bool get _canChangePassword {
    final user = _user;

    if (user == null) return false;

    return user.providerData.any(
      (provider) => provider.providerId == 'password',
    );
  }

  Future<void> _editName() async {
    final newName = await showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (_) {
        return _EditNameDialog(initialName: _displayName);
      },
    );

    if (!mounted || newName == null || newName.isEmpty) {
      return;
    }

    await _runUpdate(
      () => context.read<AuthCubit>().updateName(newName),
      successMessage: 'Name updated successfully.',
    );
  }

  Future<void> _editEmail() async {
    final newEmail = await showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (_) {
        return _EditEmailDialog(initialEmail: _email);
      },
    );

    if (!mounted || newEmail == null || newEmail.isEmpty) {
      return;
    }

    await _runUpdate(
      () => context.read<AuthCubit>().updateEmail(newEmail),
      successMessage: 'Verification email sent to your new email.',
    );
  }

  Future<void> _changePassword() async {
    final newPassword = await showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (_) {
        return const _ChangePasswordDialog();
      },
    );

    if (!mounted || newPassword == null || newPassword.isEmpty) {
      return;
    }

    await _runUpdate(
      () => context.read<AuthCubit>().updatePassword(newPassword),
      successMessage: 'Password updated successfully.',
    );
  }

  Future<void> _runUpdate(
    Future<void> Function() action, {
    required String successMessage,
  }) async {
    try {
      if (!mounted) return;

      setState(() {
        _loading = true;
      });

      await action();

      if (!mounted) return;

      await _loadUser();

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(successMessage)));
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_firebaseErrorMessage(e.code)),
          backgroundColor: Colors.redAccent,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  String _firebaseErrorMessage(String code) {
    switch (code) {
      case 'requires-recent-login':
        return 'Please log in again before changing this information.';

      case 'email-already-in-use':
        return 'This email is already registered.';

      case 'invalid-email':
        return 'Please enter a valid email address.';

      case 'weak-password':
        return 'The password is too weak.';

      case 'network-request-failed':
        return 'Please check your internet connection.';

      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';

      default:
        return 'Something went wrong. Please try again.';
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (_) {
        return const _LogoutDialog();
      },
    );

    if (!mounted || confirmed != true) {
      return;
    }

    await context.read<AuthCubit>().logout();

    if (!mounted) return;

    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Profile',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: _loading && _user == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const SizedBox(height: 15),
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: primary.withOpacity(0.12),
                    child: Text(
                      _displayName.isNotEmpty
                          ? _displayName[0].toUpperCase()
                          : 'U',
                      style: TextStyle(
                        fontSize: 38,
                        fontWeight: FontWeight.bold,
                        color: primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    _displayName,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _email,
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 35),
                  _InfoCard(
                    icon: Icons.person_outline,
                    title: 'Name',
                    value: _displayName,
                    onEdit: _editName,
                  ),
                  const SizedBox(height: 12),
                  _InfoCard(
                    icon: Icons.email_outlined,
                    title: 'Email',
                    value: _email,
                    onEdit: _editEmail,
                  ),
                  if (_canChangePassword) ...[
                    const SizedBox(height: 12),
                    _InfoCard(
                      icon: Icons.lock_outline,
                      title: 'Password',
                      value: '••••••••',
                      onEdit: _changePassword,
                    ),
                  ],
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _logout,
                      icon: const Icon(Icons.logout),
                      label: const Text('Logout'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _EditNameDialog extends StatefulWidget {
  final String initialName;

  const _EditNameDialog({required this.initialName});

  @override
  State<_EditNameDialog> createState() => _EditNameDialogState();
}

class _EditNameDialogState extends State<_EditNameDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    final value = _controller.text.trim();

    if (value.isEmpty) {
      return;
    }

    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Name'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        textCapitalization: TextCapitalization.words,
        decoration: const InputDecoration(
          labelText: 'Name',
          prefixIcon: Icon(Icons.person_outline),
        ),
        onSubmitted: (_) => _save(),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}

class _EditEmailDialog extends StatefulWidget {
  final String initialEmail;

  const _EditEmailDialog({required this.initialEmail});

  @override
  State<_EditEmailDialog> createState() => _EditEmailDialogState();
}

class _EditEmailDialogState extends State<_EditEmailDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialEmail);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _continue() {
    final value = _controller.text.trim();

    if (value.isEmpty) {
      return;
    }

    final regex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

    if (!regex.hasMatch(value)) {
      return;
    }

    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Change Email'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _controller,
            autofocus: true,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'New Email',
              prefixIcon: Icon(Icons.email_outlined),
            ),
            onSubmitted: (_) => _continue(),
          ),
          const SizedBox(height: 12),
          Text(
            'A verification email will be sent to your new email address.',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _continue, child: const Text('Continue')),
      ],
    );
  }
}

class _ChangePasswordDialog extends StatefulWidget {
  const _ChangePasswordDialog();

  @override
  State<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<_ChangePasswordDialog> {
  late final TextEditingController _newPasswordController;
  late final TextEditingController _confirmPasswordController;

  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void initState() {
    super.initState();

    _newPasswordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
  }

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _update() {
    final password = _newPasswordController.text;
    final confirm = _confirmPasswordController.text;

    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password must be at least 6 characters.'),
        ),
      );

      return;
    }

    if (password != confirm) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Passwords do not match.')));

      return;
    }

    Navigator.of(context).pop(password);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Change Password'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _newPasswordController,
            obscureText: _obscureNew,
            decoration: InputDecoration(
              labelText: 'New Password',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                onPressed: () {
                  setState(() {
                    _obscureNew = !_obscureNew;
                  });
                },
                icon: Icon(
                  _obscureNew
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _confirmPasswordController,
            obscureText: _obscureConfirm,
            decoration: InputDecoration(
              labelText: 'Confirm Password',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                onPressed: () {
                  setState(() {
                    _obscureConfirm = !_obscureConfirm;
                  });
                },
                icon: Icon(
                  _obscureConfirm
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _update, child: const Text('Update')),
      ],
    );
  }
}

class _LogoutDialog extends StatelessWidget {
  const _LogoutDialog();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Logout'),
      content: const Text('Are you sure you want to logout?'),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(false);
          },
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.of(context).pop(true);
          },
          child: const Text('Logout'),
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final VoidCallback onEdit;

  const _InfoCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: primary.withOpacity(0.1),
              ),
              child: Icon(icon, color: primary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: onEdit,
              tooltip: 'Edit',
              icon: Icon(Icons.edit_outlined, color: primary),
            ),
          ],
        ),
      ),
    );
  }
}
