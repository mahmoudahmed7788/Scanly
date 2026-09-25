import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

class DocumentFileService {
  DocumentFileService._();

  static const MethodChannel _channel =
      MethodChannel('scanly/share');

  // ============================================================
  // INTERNAL APP DOCUMENTS
  // ============================================================

  static Future<Directory>
      getDocumentsDirectory(
    String? uid,
  ) async {
    final appDirectory =
        await getApplicationDocumentsDirectory();

    final userFolder =
        uid ?? 'guest';

    final documentsDirectory =
        Directory(
      '${appDirectory.path}/Scanly/Documents/$userFolder',
    );

    if (!await documentsDirectory.exists()) {
      await documentsDirectory.create(
        recursive: true,
      );
    }

    return documentsDirectory;
  }

  // ============================================================
  // SAVE TO PUBLIC PHONE STORAGE
  //
  // Documents/Scanly/<folder>/
  // ============================================================

  static Future<String>
      saveToScanlyFolder(
    String filePath, {
    required String fileName,
    required String mimeType,
    String folder = 'Documents',
  }) async {
    final file =
        File(filePath);

    if (!await file.exists()) {
      throw Exception(
        'Source file does not exist.',
      );
    }

    final result =
        await _channel.invokeMethod<String>(
      'saveFileToScanly',
      {
        'filePath': filePath,
        'fileName': fileName,
        'mimeType': mimeType,
        'folder': folder,
      },
    );

    if (result == null ||
        result.isEmpty) {
      throw Exception(
        'File was not saved to Scanly folder.',
      );
    }

    return result;
  }

  // ============================================================
  // PDF
  // ============================================================

  static Future<String>
      savePdfToPhone(
    String filePath,
    String fileName,
  ) async {
    return saveToScanlyFolder(
      filePath,
      fileName:
          fileName.toLowerCase().endsWith('.pdf')
              ? fileName
              : '$fileName.pdf',
      mimeType:
          'application/pdf',
      folder:
          'Documents',
    );
  }

  // ============================================================
  // QR
  // ============================================================

  static Future<String>
      saveQrToPhone(
    String filePath,
    String fileName,
  ) async {
    return saveToScanlyFolder(
      filePath,
      fileName:
          fileName.toLowerCase().endsWith('.png')
              ? fileName
              : '$fileName.png',
      mimeType:
          'image/png',
      folder:
          'QR Codes',
    );
  }

  // ============================================================
  // EXTENSION
  // ============================================================

  static String getExtension(
    String path,
  ) {
    final index =
        path.lastIndexOf('.');

    if (index == -1) {
      return '';
    }

    return path
        .substring(index)
        .toLowerCase();
  }

  // ============================================================
  // REMOVE EXTENSION
  // ============================================================

  static String removeExtension(
    String fileName,
  ) {
    final index =
        fileName.lastIndexOf('.');

    if (index == -1) {
      return fileName;
    }

    return fileName.substring(
      0,
      index,
    );
  }

  // ============================================================
  // SUPPORTED FILE
  // ============================================================

  static bool isSupportedFile(
    String extension,
  ) {
    return extension == '.pdf';
  }

  // ============================================================
  // DELETE LOCAL FILE
  // ============================================================

  static Future<void>
      deleteLocalFile(
    String? path,
  ) async {
    if (path == null ||
        path.isEmpty) {
      return;
    }

    try {
      final file =
          File(path);

      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      print(
        'Local PDF delete error: $e',
      );
    }
  }

  // ============================================================
  // CREATE ID
  // ============================================================

  static String createId(
    File file,
  ) {
    return file.path.hashCode
        .toString();
  }
}