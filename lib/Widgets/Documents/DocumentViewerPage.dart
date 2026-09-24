import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:scanly/Core/DocumentStorage.dart';
import 'package:scanly/Models/DocumentModel.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class DocumentViewerPage extends StatefulWidget {
  final DocumentModel document;

  const DocumentViewerPage({super.key, required this.document});

  @override
  State<DocumentViewerPage> createState() => _DocumentViewerPageState();
}

class _DocumentViewerPageState extends State<DocumentViewerPage> {
  String _textContent = '';
  bool _loadingText = false;

  DocumentModel get document => widget.document;

  @override
  void initState() {
    super.initState();

    _loadText();
  }

  Future<void> _loadText() async {
    final type = document.type.toLowerCase();

    if (type != 'text' && type != 'txt') {
      return;
    }

    final path = document.filePath;

    if (path == null || path.isEmpty) {
      return;
    }

    setState(() {
      _loadingText = true;
    });

    try {
      final file = File(path);

      if (await file.exists()) {
        final text = await file.readAsString();

        if (!mounted) return;

        setState(() {
          _textContent = text;
        });
      }
    } catch (_) {}

    if (!mounted) return;

    setState(() {
      _loadingText = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          onPressed: () {
            context.pop();
          },
          icon: const Icon(Icons.arrow_back),
        ),
        title: Text(
          document.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            tooltip: 'Favorite',
            onPressed: _toggleFavorite,
            icon: Icon(
              document.isFavorite ? Icons.favorite : Icons.favorite_border,
              color: document.isFavorite ? Colors.redAccent : null,
            ),
          ),
          IconButton(
            tooltip: 'Share',
            onPressed: () {
              _shareDocument(context);
            },
            icon: const Icon(Icons.share_outlined),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'edit') {
                _editDocument(context);
              } else if (value == 'delete') {
                _deleteDocument(context);
              }
            },
            itemBuilder: (context) {
              return const [
                PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit_outlined),
                      SizedBox(width: 12),
                      Text('Edit'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline, color: Colors.red),
                      SizedBox(width: 12),
                      Text('Delete', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ];
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(child: _buildDocumentPreview(context)),
          _buildBottomBar(context),
        ],
      ),
    );
  }

  Widget _buildDocumentPreview(BuildContext context) {
    final type = document.type.toLowerCase();

    final path = document.filePath;

    if (path == null || path.isEmpty) {
      return _buildEmptyPreview();
    }

    final file = File(path);

    if (!file.existsSync()) {
      return _buildEmptyPreview(
        icon: Icons.insert_drive_file,
        message: 'This document is no longer available.',
      );
    }

    if (type == 'image' ||
        type == 'jpg' ||
        type == 'jpeg' ||
        type == 'png' ||
        type == 'webp') {
      return _buildImagePreview(file);
    }

    if (type == 'text' || type == 'txt') {
      return _buildTextPreview();
    }

    if (type == 'pdf') {
      return _buildPdfPreview(context);
    }

    return _buildEmptyPreview();
  }

  Widget _buildImagePreview(File file) {
    return InteractiveViewer(
      minScale: 0.5,
      maxScale: 4,
      child: Center(
        child: Image.file(
          file,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) {
            return _buildEmptyPreview(
              icon: Icons.broken_image_outlined,
              message: 'Unable to load image',
            );
          },
        ),
      ),
    );
  }

  Widget _buildTextPreview() {
    if (_loadingText) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_textContent.isEmpty) {
      return _buildEmptyPreview(
        icon: Icons.text_snippet_outlined,
        message: 'No text found in this document.',
      );
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: SingleChildScrollView(
        child: SelectableText(
          _textContent,
          style: const TextStyle(fontSize: 16, height: 1.6),
        ),
      ),
    );
  }

  Widget _buildPdfPreview(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.picture_as_pdf_outlined,
                size: 60,
                color: Colors.redAccent,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'PDF Document',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              document.title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () {
                  _openPdf(context);
                },
                icon: const Icon(Icons.open_in_new),
                label: const Text('Open PDF'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyPreview({
    IconData icon = Icons.description_outlined,
    String message = 'No preview available',
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 60, color: Colors.grey.shade500),
            ),
            const SizedBox(height: 24),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          border: Border(top: BorderSide(color: Colors.grey.shade200)),
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  _editDocument(context);
                },
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Edit'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  _shareDocument(context);
                },
                icon: const Icon(Icons.share_outlined),
                label: const Text('Share'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleFavorite() async {
    await DocumentStorage.toggleFavorite(document);

    if (!mounted) return;

    setState(() {});

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          document.isFavorite ? 'Added to favorites' : 'Removed from favorites',
        ),
      ),
    );
  }

  Future<void> _openPdf(BuildContext context) async {
    final path = document.filePath;

    if (path == null || path.isEmpty) {
      return;
    }

    final file = File(path);

    if (!await file.exists()) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('PDF file not found')));

      return;
    }

    try {
      final uri = Uri.file(path);

      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);

      if (!opened && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No PDF application is available.')),
        );
      }
    } catch (_) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Unable to open PDF')));
    }
  }

  Future<void> _shareDocument(BuildContext context) async {
    final path = document.filePath;

    if (path == null || path.isEmpty) {
      return;
    }

    final file = File(path);

    if (!await file.exists()) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Document file not found')));

      return;
    }

    try {
      await Share.shareXFiles([XFile(path)], text: document.title);
    } catch (_) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Unable to share document')));
    }
  }

  void _editDocument(BuildContext context) {
    context.push('/edit-document', extra: document);
  }

  void _deleteDocument(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Document'),
          content: const Text(
            'Are you sure you want to delete this document? '
            'This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                await DocumentStorage.deleteDocument(document.id);

                if (!dialogContext.mounted) {
                  return;
                }

                Navigator.pop(dialogContext);

                if (!context.mounted) {
                  return;
                }

                context.pop(true);
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
}
