import 'package:flutter/material.dart';
import 'package:scanly/Core/DocumentStorage.dart';
import 'package:scanly/Core/Scanly_Items.dart';
import 'package:scanly/Models/DocumentModel.dart';

class FavoritesUtils {
  FavoritesUtils._();

  static List<DocumentModel> favoriteDocuments() {
    final documents = DocumentStorage.getDocuments()
        .where(
          (document) => document.isFavorite,
        )
        .toList();

    sortDocuments(documents);

    return documents;
  }

  static void sortDocuments(
    List<DocumentModel> documents,
  ) {
    documents.sort((a, b) {
      final dateA = DateTime.tryParse(a.date);
      final dateB = DateTime.tryParse(b.date);

      if (dateA == null && dateB == null) {
        return 0;
      }

      if (dateA == null) {
        return 1;
      }

      if (dateB == null) {
        return -1;
      }

      return dateB.compareTo(dateA);
    });
  }

  static IconData iconForType(
    String type,
  ) {
    switch (type.toLowerCase()) {
      case 'qr':
        return Icons.qr_code_rounded;

      case 'note':
        return Icons.edit_note_rounded;

      case 'pdf':
        return Icons.picture_as_pdf_rounded;

      case 'document':
        return Icons.document_scanner_rounded;

      case 'text':
        return Icons.text_snippet_rounded;

      default:
        return Icons.insert_drive_file_rounded;
    }
  }

  static String formatDate(
    String value,
  ) {
    final date = DateTime.tryParse(value);

    if (date == null) {
      return 'Unknown date';
    }

    final day =
        date.day.toString().padLeft(2, '0');

    final month =
        date.month.toString().padLeft(2, '0');

    final year =
        date.year.toString();

    final hour =
        date.hour.toString().padLeft(2, '0');

    final minute =
        date.minute.toString().padLeft(2, '0');

    return '$day/$month/$year • $hour:$minute';
  }
}