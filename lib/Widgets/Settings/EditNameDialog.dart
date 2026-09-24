import 'package:flutter/material.dart';

class EditNameDialog
    extends StatefulWidget {
  final String initialName;

  const EditNameDialog({
    super.key,
    required this.initialName,
  });

  @override
  State<EditNameDialog> createState() =>
      _EditNameDialogState();
}

class _EditNameDialogState
    extends State<EditNameDialog> {
  late final TextEditingController
      _controller;

  @override
  void initState() {
    super.initState();

    _controller =
        TextEditingController(
      text: widget.initialName,
    );
  }

  @override
  void dispose() {
    _controller.dispose();

    super.dispose();
  }

  void _save() {
    final value =
        _controller.text.trim();

    if (value.isEmpty) {
      return;
    }

    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title:
          const Text('Edit Name'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        textCapitalization:
            TextCapitalization.words,
        decoration:
            const InputDecoration(
          labelText: 'Name',
          prefixIcon:
              Icon(Icons.person_outline),
        ),
        onSubmitted: (_) => _save(),
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
          onPressed: _save,
          child: const Text('Save'),
        ),
      ],
    );
  }
}