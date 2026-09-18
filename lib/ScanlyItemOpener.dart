import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:scanly/PDFPreviewPage.dart';
import 'package:scanly/QRPreviewPage.dart';
import 'package:scanly/ScanlyActivityService.dart';
import 'package:scanly/Scanly_Items.dart';

class ScanlyItemOpener {
  static Future<void> open(
    BuildContext context,
    ScanlyItem item,
  ) async {
    await ScanlyActivityService.addRecent(item);

    if (!context.mounted) {
      return;
    }

    if (item.type == 'qr') {
      final value = item.data;

      if (value == null || value.isEmpty) {
        _showMessage(
          context,
          'QR Code data is not available',
        );
        return;
      }

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => QRPreviewPage(
            value: value,
          ),
        ),
      );

      return;
    }

    if (item.type == 'pdf') {
      await _openPdf(
        context,
        item,
      );

      return;
    }

    if (item.route.isNotEmpty) {
      await context.push(
        item.route,
        extra: item.data,
      );
    }
  }

  static Future<void> _openPdf(
    BuildContext context,
    ScanlyItem item,
  ) async {
    final path = item.data;

    if (path == null || path.isEmpty) {
      _showMessage(
        context,
        'PDF file path is not available',
      );
      return;
    }

    try {
      final file = File(path);

      if (!await file.exists()) {
        _showMessage(
          context,
          'PDF file no longer exists',
        );
        return;
      }

      final bytes = await file.readAsBytes();

      if (!context.mounted) {
        return;
      }

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PDFPreviewPage(
            pdfBytes: bytes,
            fileName: _fileNameFromPath(path),
          ),
        ),
      );
    } catch (e) {
      debugPrint(
        'OPEN PDF ERROR: $e',
      );

      if (!context.mounted) {
        return;
      }

      _showMessage(
        context,
        'Could not open PDF',
      );
    }
  }

  static String _fileNameFromPath(
    String path,
  ) {
    final normalizedPath =
        path.replaceAll('\\', '/');

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

  static void _showMessage(
    BuildContext context,
    String message,
  ) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }
}