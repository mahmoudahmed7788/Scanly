import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:scanly/Auth/Auth_Cubit.dart';
import 'package:scanly/Widgets/Settings/ChangePasswordDialog.dart';
import 'package:scanly/Widgets/Settings/EditEmailDialog.dart';
import 'package:scanly/Widgets/Settings/EditNameDialog.dart';
import 'package:scanly/Widgets/Settings/LogoutDialog.dart';
import 'package:scanly/Widgets/Settings/ProfileInfoCard.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() =>
      _ProfilePageState();
}

class _ProfilePageState
    extends State<ProfilePage> {
  User? _user;

  Map<String, dynamic>? _userData;

  bool _loading = true;

  @override
  void initState() {
    super.initState();

    _loadUser();
  }

  // =====================================================
  // LOAD USER
  // =====================================================

  Future<void> _loadUser() async {
    try {
      final auth =
          FirebaseAuth.instance;

      final user = auth.currentUser;

      if (user == null) {
        if (!mounted) return;

        setState(() {
          _loading = false;
        });

        return;
      }

      await user.reload();

      final currentUser =
          auth.currentUser;

      if (currentUser == null) {
        if (!mounted) return;

        setState(() {
          _loading = false;
        });

        return;
      }

      await context
          .read<AuthCubit>()
          .getUserData();

      if (!mounted) return;

      setState(() {
        _user = currentUser;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _user =
            FirebaseAuth.instance.currentUser;
        _loading = false;
      });
    }
  }

  // =====================================================
  // DISPLAY NAME
  // =====================================================

  String get _displayName {
    final firestoreName =
        _userData?['name'];

    if (firestoreName is String &&
        firestoreName.trim().isNotEmpty) {
      return firestoreName.trim();
    }

    final authName =
        _user?.displayName;

    if (authName != null &&
        authName.trim().isNotEmpty) {
      return authName.trim();
    }

    final email = _user?.email;

    if (email != null &&
        email.contains('@')) {
      return email.split('@').first;
    }

    return 'User';
  }

  // =====================================================
  // EMAIL
  // =====================================================

  String get _email {
    return _user?.email ?? 'No email';
  }

  // =====================================================
  // PASSWORD AVAILABILITY
  // =====================================================

  bool get _canChangePassword {
    final user = _user;

    if (user == null) {
      return false;
    }

    return user.providerData.any(
      (provider) =>
          provider.providerId == 'password',
    );
  }

  // =====================================================
  // EDIT NAME
  // =====================================================

  Future<void> _editName() async {
    final newName =
        await showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (_) {
        return EditNameDialog(
          initialName: _displayName,
        );
      },
    );

    if (!mounted ||
        newName == null ||
        newName.isEmpty) {
      return;
    }

    await _runUpdate(
      () => context
          .read<AuthCubit>()
          .updateName(newName),
      successMessage:
          'Name updated successfully.',
    );
  }

  // =====================================================
  // EDIT EMAIL
  // =====================================================

  Future<void> _editEmail() async {
    final newEmail =
        await showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (_) {
        return EditEmailDialog(
          initialEmail: _email,
        );
      },
    );

    if (!mounted ||
        newEmail == null ||
        newEmail.isEmpty) {
      return;
    }

    await _runUpdate(
      () => context
          .read<AuthCubit>()
          .updateEmail(newEmail),
      successMessage:
          'Verification email sent to your new email.',
    );
  }

  // =====================================================
  // CHANGE PASSWORD
  // =====================================================

  Future<void> _changePassword() async {
    final newPassword =
        await showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (_) {
        return const ChangePasswordDialog();
      },
    );

    if (!mounted ||
        newPassword == null ||
        newPassword.isEmpty) {
      return;
    }

    await _runUpdate(
      () => context
          .read<AuthCubit>()
          .updatePassword(newPassword),
      successMessage:
          'Password updated successfully.',
    );
  }

  // =====================================================
  // RUN UPDATE
  // =====================================================

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

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content:
              Text(successMessage),
        ),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            _firebaseErrorMessage(
              e.code,
            ),
          ),
          backgroundColor:
              Colors.redAccent,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            e
                .toString()
                .replaceFirst(
                  'Exception: ',
                  '',
                ),
          ),
          backgroundColor:
              Colors.redAccent,
        ),
      );
    }
  }

  // =====================================================
  // FIREBASE ERROR
  // =====================================================

  String _firebaseErrorMessage(
    String code,
  ) {
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

  // =====================================================
  // LOGOUT
  // =====================================================

  Future<void> _logout() async {
    final confirmed =
        await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (_) {
        return const LogoutDialog();
      },
    );

    if (!mounted ||
        confirmed != true) {
      return;
    }

    await context
        .read<AuthCubit>()
        .logout();

    if (!mounted) return;

    context.go('/login');
  }

  // =====================================================
  // BUILD
  // =====================================================

  @override
  Widget build(BuildContext context) {
    final primary =
        Theme.of(context)
            .colorScheme
            .primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Profile',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _loading && _user == null
          ? const Center(
              child:
                  CircularProgressIndicator(),
            )
          : SingleChildScrollView(
              padding:
                  const EdgeInsets.all(20),
              child: Column(
                children: [
                  const SizedBox(height: 15),

                  // PROFILE AVATAR
                  CircleAvatar(
                    radius: 50,
                    backgroundColor:
                        primary.withOpacity(
                      0.12,
                    ),
                    child: Text(
                      _displayName.isNotEmpty
                          ? _displayName[0]
                              .toUpperCase()
                          : 'U',
                      style: TextStyle(
                        fontSize: 38,
                        fontWeight:
                            FontWeight.bold,
                        color: primary,
                      ),
                    ),
                  ),

                  const SizedBox(
                    height: 18,
                  ),

                  // NAME
                  Text(
                    _displayName,
                    style:
                        const TextStyle(
                      fontSize: 24,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  const SizedBox(
                    height: 6,
                  ),

                  // EMAIL
                  Text(
                    _email,
                    style: TextStyle(
                      fontSize: 14,
                      color:
                          Colors.grey.shade600,
                    ),
                  ),

                  const SizedBox(
                    height: 35,
                  ),

                  // NAME CARD
                  ProfileInfoCard(
                    icon:
                        Icons.person_outline,
                    title: 'Name',
                    value: _displayName,
                    onEdit: _editName,
                  ),

                  const SizedBox(
                    height: 12,
                  ),

                  // EMAIL CARD
                  ProfileInfoCard(
                    icon:
                        Icons.email_outlined,
                    title: 'Email',
                    value: _email,
                    onEdit: _editEmail,
                  ),

                  // PASSWORD CARD
                  if (_canChangePassword) ...[
                    const SizedBox(
                      height: 12,
                    ),
                    ProfileInfoCard(
                      icon:
                          Icons.lock_outline,
                      title: 'Password',
                      value: '••••••••',
                      onEdit:
                          _changePassword,
                    ),
                  ],

                  const SizedBox(
                    height: 30,
                  ),

                  // LOGOUT
                  SizedBox(
                    width:
                        double.infinity,
                    child:
                        OutlinedButton.icon(
                      onPressed: _logout,
                      icon: const Icon(
                        Icons.logout,
                      ),
                      label:
                          const Text(
                        'Logout',
                      ),
                      style:
                          OutlinedButton
                              .styleFrom(
                        padding:
                            const EdgeInsets
                                .symmetric(
                          vertical: 15,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}