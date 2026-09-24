import 'package:flutter/material.dart';

class ChangePasswordDialog
    extends StatefulWidget {
  const ChangePasswordDialog({
    super.key,
  });

  @override
  State<ChangePasswordDialog>
      createState() =>
          _ChangePasswordDialogState();
}

class _ChangePasswordDialogState
    extends State<ChangePasswordDialog> {
  late final TextEditingController
      _newPasswordController;

  late final TextEditingController
      _confirmPasswordController;

  bool _obscureNew = true;

  bool _obscureConfirm = true;

  @override
  void initState() {
    super.initState();

    _newPasswordController =
        TextEditingController();

    _confirmPasswordController =
        TextEditingController();
  }

  @override
  void dispose() {
    _newPasswordController.dispose();

    _confirmPasswordController
        .dispose();

    super.dispose();
  }

  void _update() {
    final password =
        _newPasswordController.text;

    final confirm =
        _confirmPasswordController
            .text;

    if (password.length < 6) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Password must be at least 6 characters.',
          ),
        ),
      );

      return;
    }

    if (password != confirm) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Passwords do not match.',
          ),
        ),
      );

      return;
    }

    Navigator.of(context).pop(password);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title:
          const Text('Change Password'),

      content: Column(
        mainAxisSize:
            MainAxisSize.min,
        children: [
          TextField(
            controller:
                _newPasswordController,
            obscureText:
                _obscureNew,
            decoration:
                InputDecoration(
              labelText:
                  'New Password',
              prefixIcon:
                  const Icon(
                Icons.lock_outline,
              ),
              suffixIcon:
                  IconButton(
                onPressed: () {
                  setState(() {
                    _obscureNew =
                        !_obscureNew;
                  });
                },
                icon: Icon(
                  _obscureNew
                      ? Icons
                          .visibility_off_outlined
                      : Icons
                          .visibility_outlined,
                ),
              ),
            ),
          ),

          const SizedBox(
            height: 14,
          ),

          TextField(
            controller:
                _confirmPasswordController,
            obscureText:
                _obscureConfirm,
            decoration:
                InputDecoration(
              labelText:
                  'Confirm Password',
              prefixIcon:
                  const Icon(
                Icons.lock_outline,
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
            ),
          ),
        ],
      ),

      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context)
                .pop();
          },
          child:
              const Text('Cancel'),
        ),

        FilledButton(
          onPressed: _update,
          child:
              const Text('Update'),
        ),
      ],
    );
  }
}