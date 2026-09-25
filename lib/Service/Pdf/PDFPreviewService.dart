import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import 'package:scanly/Core/DocumentStorage.dart';
import 'package:scanly/Core/SupabaseStorageService.dart';

class PDFPreviewService {
  PDFPreviewService._();

  static const MethodChannel fileChannel =
      MethodChannel('scanly/share');

  // ============================================================
  // PDF HEADER
  // ============================================================

  static bool hasPdfHeader(
    Uint8List bytes,
  ) {
    if (bytes.length < 5) {
      return false;
    }

    return bytes[0] == 0x25 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x44 &&
        bytes[3] == 0x46 &&
        bytes[4] == 0x2D;
  }

  // ============================================================
  // VALIDATE PDF FILE
  // ============================================================

  static bool isValidPdfFile(
    File file,
  ) {
    try {
      if (!file.existsSync()) {
        return false;
      }

      if (file.lengthSync() < 5) {
        return false;
      }

      final raf = file.openSync();

      try {
        final header = raf.readSync(5);

        return header.length >= 5 &&
            header[0] == 0x25 &&
            header[1] == 0x50 &&
            header[2] == 0x44 &&
            header[3] == 0x46 &&
            header[4] == 0x2D;
      } finally {
        raf.closeSync();
      }
    } catch (e) {
      debugPrint(
        'PDF VALIDATION ERROR: $e',
      );

      return false;
    }
  }

  // ============================================================
  // CLEAN NAME
  // ============================================================

  static String cleanName(
    String value,
  ) {
    var name = value.trim();

    if (name.isEmpty) {
      name = 'Scanly Document';
    }

    name = name.replaceAll(
      RegExp(r'[\\/:*?"<>|]'),
      '_',
    );

    if (name.toLowerCase().endsWith('.pdf')) {
      name = name.substring(
        0,
        name.length - 4,
      );
    }

    if (name.trim().isEmpty) {
      name = 'Scanly Document';
    }

    return name.trim();
  }

  // ============================================================
  // WRITE PDF BYTES LOCALLY
  // ============================================================

  static Future<String> writePdfBytesToLocalFile({
    required Uint8List bytes,
    required String fileName,
    String? currentFilePath,
  }) async {
    if (!hasPdfHeader(bytes)) {
      throw Exception(
        'Invalid PDF bytes.',
      );
    }

    final directory =
        await DocumentStorage
            .getDocumentsDirectory();

    final cleanedName =
        cleanName(fileName);

    String path;

    if (currentFilePath != null &&
        currentFilePath.isNotEmpty) {
      final current =
          File(currentFilePath);

      if (current.parent.path ==
          directory.path) {
        path = current.path;
      } else {
        path =
            '${directory.path}/$cleanedName.pdf';
      }
    } else {
      path =
          '${directory.path}/$cleanedName.pdf';
    }

    final file = File(path);

    await file.parent.create(
      recursive: true,
    );

    await file.writeAsBytes(
      bytes,
      flush: true,
    );

    if (!isValidPdfFile(file)) {
      throw Exception(
        'PDF write verification failed.',
      );
    }

    return path;
  }

  // ============================================================
  // DOWNLOAD FROM SUPABASE
  // ============================================================

  static Future<Uint8List> downloadPdfFromCloud(
    String storagePath,
  ) async {
    if (storagePath.isEmpty) {
      throw Exception(
        'No cloud storage path.',
      );
    }

    final bytes =
        await SupabaseStorageService
            .downloadFile(
      storagePath,
    );

    if (bytes.isEmpty ||
        !hasPdfHeader(bytes)) {
      throw Exception(
        'Downloaded file is not a valid PDF.',
      );
    }

    return Uint8List.fromList(
      bytes,
    );
  }

  // ============================================================
  // SAVE TO PHONE FILES
  // ============================================================

  static Future<void> saveToPhoneFiles({
    required String pdfPath,
    required String fileName,
  }) async {
    final file = File(pdfPath);

    if (!await file.exists()) {
      throw Exception(
        'PDF file does not exist.',
      );
    }

    if (!isValidPdfFile(file)) {
      throw Exception(
        'Invalid PDF file.',
      );
    }

    try {
      final result =
          await fileChannel
              .invokeMethod<String>(
        'saveFileToScanly',
        {
          'filePath': pdfPath,
          'fileName': '$fileName.pdf',
          'mimeType': 'application/pdf',
          'folder': 'Documents',
        },
      );

      debugPrint(
        'PUBLIC FILE SAVED: $result',
      );

      if (result == null ||
          result.isEmpty) {
        throw Exception(
          'Android did not return a saved file URI.',
        );
      }
    } on PlatformException catch (e) {
      debugPrint(
        'PUBLIC FILE SAVE ERROR: '
        '${e.code} - ${e.message}',
      );

      throw Exception(
        e.message ??
            'Could not save PDF to phone.',
      );
    }
  }

  // ============================================================
  // CREATE SHARE FILE
  // ============================================================

  static Future<File> createShareFile({
    required String pdfPath,
    required String fileName,
  }) async {
    final source = File(pdfPath);

    if (!await source.exists()) {
      throw Exception(
        'PDF file does not exist.',
      );
    }

    final directory =
        await getTemporaryDirectory();

    final clean =
        cleanName(fileName);

    final file = File(
      '${directory.path}/$clean.pdf',
    );

    await source.copy(
      file.path,
    );

    return file;
  }
}