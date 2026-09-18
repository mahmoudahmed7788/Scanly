import 'package:flutter/material.dart';
import 'package:scanly/DocumentModel.dart';

class EditDocumentPage extends StatefulWidget {
  final DocumentModel document;

  const EditDocumentPage({
    super.key,
    required this.document,
  });

  @override
  State<EditDocumentPage> createState() => _EditDocumentPageState();
}

class _EditDocumentPageState extends State<EditDocumentPage> {
  late TextEditingController _titleController;
  late bool _isFavorite;

  final _formKey = GlobalKey<FormState>();

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    _titleController = TextEditingController(
      text: widget.document.title,
    );

    _isFavorite = widget.document.isFavorite;
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _saveDocument() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final updatedDocument = DocumentModel(
      id: widget.document.id,
      title: _titleController.text.trim(),
      date: widget.document.date,
      type: widget.document.type,
      filePath: widget.document.filePath,
      isFavorite: _isFavorite,
    );

    await DocumentStorage.updateDocument(
      updatedDocument,
    );

    if (!mounted) return;

    Navigator.pop(
      context,
      updatedDocument,
    );
  }

  Future<void> _deleteDocument() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Document'),
          content: const Text(
            'Are you sure you want to delete this document?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text(
                'Delete',
                style: TextStyle(
                  color: Colors.red,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    await DocumentStorage.deleteDocument(
      widget.document.id,
    );

    if (!mounted) return;

    Navigator.pop(
      context,
      'deleted',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Edit Document',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _isSaving ? null : _saveDocument,
            icon: const Icon(Icons.check),
          ),
        ],
      ),

      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Preview
            Container(
              height: 180,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: Colors.grey.shade200,
                ),
                color: Colors.grey.shade100,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _getIcon(),
                    size: 65,
                    color: Colors.grey.shade500,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.document.type.toUpperCase(),
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            const Text(
              'Document Name',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 10),

            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                hintText: 'Enter document name',
                prefixIcon: const Icon(
                  Icons.description_outlined,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              validator: (value) {
                if (value == null ||
                    value.trim().isEmpty) {
                  return 'Please enter a document name';
                }

                if (value.trim().length < 2) {
                  return 'Document name is too short';
                }

                return null;
              },
            ),

            const SizedBox(height: 25),

            // Favorite
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: Colors.grey.shade200,
                ),
              ),
              child: SwitchListTile(
                value: _isFavorite,
                onChanged: (value) {
                  setState(() {
                    _isFavorite = value;
                  });
                },
                title: const Text(
                  'Favorite',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: const Text(
                  'Add this document to your favorites',
                ),
                secondary: Icon(
                  _isFavorite
                      ? Icons.favorite
                      : Icons.favorite_border,
                ),
              ),
            ),

            const SizedBox(height: 25),

            const Text(
              'Information',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 10),

            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: Colors.grey.shade200,
                ),
              ),
              child: Column(
                children: [
                  _InfoRow(
                    icon: Icons.insert_drive_file_outlined,
                    title: 'Type',
                    value: widget.document.type
                        .toUpperCase(),
                  ),
                  const SizedBox(height: 16),
                  _InfoRow(
                    icon: Icons.calendar_today_outlined,
                    title: 'Created',
                    value: widget.document.date,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 35),

            SizedBox(
              height: 55,
              child: ElevatedButton(
                onPressed:
                    _isSaving ? null : _saveDocument,
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(16),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Save Changes',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 15),

            SizedBox(
              height: 50,
              child: TextButton.icon(
                onPressed: _deleteDocument,
                icon: const Icon(
                  Icons.delete_outline,
                  color: Colors.red,
                ),
                label: const Text(
                  'Delete Document',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIcon() {
    switch (widget.document.type.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf_outlined;

      case 'image':
        return Icons.image_outlined;

      case 'text':
        return Icons.text_snippet_outlined;

      default:
        return Icons.description_outlined;
    }
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              color: Colors.grey.shade600,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
