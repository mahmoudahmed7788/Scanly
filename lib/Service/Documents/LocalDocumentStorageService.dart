// ============================================================
// LOCAL DOCUMENT STORAGE SERVICE
// ============================================================

import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:scanly/Core/SupabaseStorageService.dart';



// ============================================================
// LOCAL DOCUMENT STORAGE SERVICE
// ============================================================

class LocalDocumentStorageService {
  // ==========================================================
  // DOWNLOAD FILE IF NEEDED
  // ==========================================================

  static Future<String?> downloadFileIfNeeded({
    required String documentId,
    required String storagePath,
    required String firebaseUid,
  }) async {
    // ========================================================
    // APPLICATION DIRECTORY
    // ========================================================

    final Directory applicationDirectory =
        await getApplicationDocumentsDirectory();

    // ========================================================
    // USER-SPECIFIC DIRECTORY
    // ========================================================

    final Directory documentsDirectory = Directory(
      '${applicationDirectory.path}/'
      'Scanly/Documents/$firebaseUid',
    );

    if (!await documentsDirectory.exists()) {
      await documentsDirectory.create(
        recursive: true,
      );
    }

    // ========================================================
    // LOCAL PDF FILE
    // ========================================================

    final File localFile = File(
      '${documentsDirectory.path}/$documentId.pdf',
    );

    // ========================================================
    // FILE ALREADY EXISTS
    // ========================================================

    if (await localFile.exists()) {
      return localFile.path;
    }

    // ========================================================
    // DOWNLOAD FROM SUPABASE
    // ========================================================

    final Uint8List bytes =
        await SupabaseStorageService.downloadPdf(
      storagePath,
    );

    // ========================================================
    // SAVE LOCALLY
    // ========================================================

    await localFile.writeAsBytes(
      bytes,
      flush: true,
    );

    print(
      'PDF downloaded for user '
      '$firebaseUid: ${localFile.path}',
    );

    return localFile.path;
  }
}