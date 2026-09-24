import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:scanly/Core/DocumentStorage.dart';
import 'package:scanly/Core/Scanly_Items.dart';
import 'package:scanly/Models/DocumentModel.dart';
import 'package:scanly/Pages/Pdf/PDFPreviewPage.dart';
import 'package:scanly/Pages/QR/QRPreviewPage.dart';
import 'package:scanly/core/ScanlyActivityService.dart';


class ScanlyItemOpener {
  static Future<void> open(BuildContext context, ScanlyItem item) async {
    // ==========================================================
    // ADD TO RECENT
    // ==========================================================

    await ScanlyActivityService.addRecent(item);

    if (!context.mounted) {
      return;
    }

    // ==========================================================
    // QR
    // ==========================================================

    if (item.type == 'qr') {
      final value = item.data;

      if (value == null || value.isEmpty) {
        _showMessage(context, 'QR Code data is not available');

        return;
      }

      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => QRPreviewPage(value: value)),
      );

      return;
    }

    // ==========================================================
    // PDF
    // ==========================================================

    if (item.type == 'pdf') {
      await _openPdf(context, item);

      return;
    }

    // ==========================================================
    // OTHER ITEMS
    // ==========================================================

    if (item.route.isNotEmpty) {
      await context.push(item.route, extra: item.data);
    }
  }

  // ============================================================
  // OPEN PDF
  // ============================================================

  static Future<void> _openPdf(BuildContext context, ScanlyItem item) async {
    final path = item.data;

    if (path == null || path.isEmpty) {
      _showMessage(context, 'PDF file path is not available');

      return;
    }

    try {
      final file = File(path);

      // --------------------------------------------------------
      // CHECK FILE
      // --------------------------------------------------------

      if (!await file.exists()) {
        _showMessage(context, 'PDF file no longer exists');

        return;
      }

      // --------------------------------------------------------
      // READ PDF
      // --------------------------------------------------------

      final bytes = await file.readAsBytes();

      if (!context.mounted) {
        return;
      }

      // --------------------------------------------------------
      // FIND DOCUMENT MODEL
      // --------------------------------------------------------

      DocumentModel? document;

      final documents = DocumentStorage.getDocuments();

      for (final currentDocument in documents) {
        if (currentDocument.filePath == path) {
          document = currentDocument;
          break;
        }
      }

      // --------------------------------------------------------
      // IF DOCUMENT WAS NOT FOUND LOCALLY
      // --------------------------------------------------------

      document ??= DocumentModel(
        id: item.id,
        title: _fileNameFromPath(path),
        date: DateTime.now().toIso8601String(),
        type: 'pdf',
        filePath: path,
        isFavorite: false,
        lastOpened: DateTime.now().toIso8601String(),
      );

      // --------------------------------------------------------
      // OPEN PDF PREVIEW
      // --------------------------------------------------------

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PDFPreviewPage(
            document: document!,
            pdfBytes: bytes,
            fileName: _fileNameFromPath(path),
          ),
        ),
      );
    } catch (e) {
      debugPrint('OPEN PDF ERROR: $e');

      if (!context.mounted) {
        return;
      }

      _showMessage(context, 'Could not open PDF');
    }
  }

  // ============================================================
  // FILE NAME
  // ============================================================

  static String _fileNameFromPath(String path) {
    final normalizedPath = path.replaceAll('\\', '/');

    final parts = normalizedPath.split('/');

    if (parts.isEmpty) {
      return 'Scanly_Document.pdf';
    }

    final name = parts.last;

    if (name.isEmpty) {
      return 'Scanly_Document.pdf';
    }

    return name;
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  static void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }
}
