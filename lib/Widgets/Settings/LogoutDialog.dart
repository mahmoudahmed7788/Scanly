import 'package:flutter/material.dart';

class LogoutDialog
    extends StatelessWidget {
  const LogoutDialog({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title:
          const Text('Logout'),

      content: const Text(
        'Are you sure you want to logout?',
      ),

      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context)
                .pop(false);
          },
          child:
              const Text('Cancel'),
        ),

        FilledButton(
          onPressed: () {
            Navigator.of(context)
                .pop(true);
          },
          child:
              const Text('Logout'),
        ),
      ],
    );
  }
}