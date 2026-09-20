import 'dart:io';
import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseStorageService {
  // =========================================================
  // SUPABASE BUCKET
  // =========================================================

  static const String bucketName = 'Scanly Documents';

  static SupabaseClient get _supabase =>
      Supabase.instance.client;

  static SupabaseStorageClient get _storage =>
      _supabase.storage;

  // =========================================================
  // UPLOAD PDF
  // =========================================================

  static Future<String> uploadPdf({
    required String firebaseUid,
    required String documentId,
    required File file,
  }) async {
    final storagePath =
        'users/$firebaseUid/documents/$documentId.pdf';

    final bytes = await file.readAsBytes();

    await _storage
        .from(bucketName)
        .uploadBinary(
      storagePath,
      bytes,
      fileOptions: const FileOptions(
        contentType: 'application/pdf',
        upsert: true,
      ),
    );

    return storagePath;
  }

  // =========================================================
  // UPLOAD BYTES
  // =========================================================

  static Future<String> uploadPdfBytes({
    required String storagePath,
    required Uint8List bytes,
  }) async {
    await _storage
        .from(bucketName)
        .uploadBinary(
      storagePath,
      bytes,
      fileOptions: const FileOptions(
        contentType: 'application/pdf',
        upsert: true,
      ),
    );

    return storagePath;
  }

  // =========================================================
  // DOWNLOAD PDF
  // =========================================================

  static Future<Uint8List> downloadPdf(
    String storagePath,
  ) async {
    final bytes = await _storage
        .from(bucketName)
        .download(storagePath);

    return Uint8List.fromList(bytes);
  }

  // =========================================================
  // DOWNLOAD FILE
  // =========================================================

  static Future<Uint8List> downloadFile(
    String storagePath,
  ) async {
    return downloadPdf(storagePath);
  }

  // =========================================================
  // DELETE PDF
  // =========================================================

  static Future<void> deletePdf(
    String storagePath,
  ) async {
    await _storage
        .from(bucketName)
        .remove([
      storagePath,
    ]);
  }

  // =========================================================
  // DELETE FILE
  // =========================================================

  static Future<void> deleteFile(
    String storagePath,
  ) async {
    await deletePdf(storagePath);
  }

  // =========================================================
  // CHECK FILE
  // =========================================================

  static Future<bool> fileExists(
    String storagePath,
  ) async {
    try {
      final parts = storagePath.split('/');

      if (parts.isEmpty) {
        return false;
      }

      final fileName = parts.removeLast();

      final folders = parts.join('/');

      final files = await _storage
          .from(bucketName)
          .list(
        path: folders,
      );

      return files.any(
        (file) => file.name == fileName,
      );
    } catch (e) {
      return false;
    }
  }
}