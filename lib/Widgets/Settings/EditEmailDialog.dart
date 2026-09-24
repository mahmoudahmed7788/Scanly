import 'package:flutter/material.dart';

class EditEmailDialog
    extends StatefulWidget {
  final String initialEmail;

  const EditEmailDialog({
    super.key,
    required this.initialEmail,
  });

  @override
  State<EditEmailDialog> createState() =>
      _EditEmailDialogState();
}

class _EditEmailDialogState
    extends State<EditEmailDialog> {
  late final TextEditingController
      _controller;

  @override
  void initState() {
    super.initState();

    _controller =
        TextEditingController(
      text: widget.initialEmail,
    );
  }

  @override
  void dispose() {
    _controller.dispose();

    super.dispose();
  }

  void _continue() {
    final value =
        _controller.text.trim();

    if (value.isEmpty) {
      return;
    }

    final regex = RegExp(
      r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
    );

    if (!regex.hasMatch(value)) {
      return;
    }

    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title:
          const Text('Change Email'),

      content: Column(
        mainAxisSize:
            MainAxisSize.min,
        children: [
          TextField(
            controller: _controller,
            autofocus: true,
            keyboardType:
                TextInputType.emailAddress,
            decoration:
                const InputDecoration(
              labelText: 'New Email',
              prefixIcon:
                  Icon(Icons.email_outlined),
            ),
            onSubmitted:
                (_) => _continue(),
          ),

          const SizedBox(
            height: 12,
          ),

          Text(
            'A verification email will be sent to your new email address.',
            style: TextStyle(
              fontSize: 12,
              color:
                  Colors.grey.shade600,
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
          onPressed: _continue,
          child:
              const Text('Continue'),
        ),
      ],
    );
  }
}