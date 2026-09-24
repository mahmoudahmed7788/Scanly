import 'package:scanly/Models/DocumentModel.dart';

class DocumentUtils {
  DocumentUtils._();

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

  static List<DocumentModel> filterDocuments({
    required List<DocumentModel> documents,
    required String query,
  }) {
    final normalizedQuery =
        query.trim().toLowerCase();

    if (normalizedQuery.isEmpty) {
      final result =
          List<DocumentModel>.from(documents);

      sortDocuments(result);

      return result;
    }

    final result = documents.where((document) {
      final title =
          document.title.toLowerCase();

      final type =
          document.type.toLowerCase();

      return title.contains(normalizedQuery) ||
          type.contains(normalizedQuery);
    }).toList();

    sortDocuments(result);

    return result;
  }

  static String formatDate(String value) {
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

  static String getDocumentType(
    DocumentModel document,
  ) {
    final type =
        document.type.trim();

    if (type.isEmpty) {
      return 'PDF';
    }

    return type.toUpperCase();
  }
}