import 'dart:io';

import 'package:path_provider/path_provider.dart';

class DocumentFileService {
  DocumentFileService._();

  // =========================================================
  // DOCUMENT DIRECTORY
  // =========================================================

  static Future<Directory> getDocumentsDirectory(
    String? uid,
  ) async {
    final appDirectory =
        await getApplicationDocumentsDirectory();

    final userFolder = uid ?? 'guest';

    final documentsDirectory = Directory(
      '${appDirectory.path}/Scanly/Documents/$userFolder',
    );

    if (!await documentsDirectory.exists()) {
      await documentsDirectory.create(
        recursive: true,
      );
    }

    return documentsDirectory;
  }

  // =========================================================
  // FILE EXTENSION
  // =========================================================

  static String getExtension(String path) {
    final index = path.lastIndexOf('.');

    if (index == -1) {
      return '';
    }

    return path
        .substring(index)
        .toLowerCase();
  }

  // =========================================================
  // REMOVE EXTENSION
  // =========================================================

  static String removeExtension(String fileName) {
    final index = fileName.lastIndexOf('.');

    if (index == -1) {
      return fileName;
    }

    return fileName.substring(
      0,
      index,
    );
  }

  // =========================================================
  // SUPPORTED FILE
  // =========================================================

  static bool isSupportedFile(String extension) {
    return extension == '.pdf';
  }

  // =========================================================
  // DELETE LOCAL FILE
  // =========================================================

  static Future<void> deleteLocalFile(
    String? path,
  ) async {
    if (path == null || path.isEmpty) {
      return;
    }

    try {
      final file = File(path);

      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      print(
        'Local PDF delete error: $e',
      );
    }
  }

  // =========================================================
  // CREATE ID
  // =========================================================

  static String createId(File file) {
    return file.path.hashCode.toString();
  }
}