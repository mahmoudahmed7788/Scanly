import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:scanly/Core/FirebaseDataService.dart';
import 'package:scanly/Core/SupabaseStorageService.dart';
import 'package:scanly/Models/DocumentModel.dart';

class DocumentCloudService {
  DocumentCloudService._();

  // =========================================================
  // SAVE FIREBASE
  // =========================================================

  static Future<void> saveToFirebase(
    DocumentModel document,
  ) async {
    try {
      await FirebaseDataService.saveDocument(
        document,
      );
    } catch (e) {
      print(
        'Firebase save document error: $e',
      );
    }
  }

  // =========================================================
  // UPDATE FIREBASE
  // =========================================================

  static Future<void> updateFirebase(
    DocumentModel document,
  ) async {
    try {
      await FirebaseDataService.updateDocument(
        document,
      );
    } catch (e) {
      print(
        'Firebase update document error: $e',
      );
    }
  }

  // =========================================================
  // DELETE FIREBASE
  // =========================================================

  static Future<void> deleteFromFirebase(
    String id,
  ) async {
    try {
      await FirebaseDataService.deleteDocument(
        id,
      );
    } catch (e) {
      print(
        'Firebase delete document error: $e',
      );
    }
  }

  // =========================================================
  // CLEAR FIREBASE
  // =========================================================

  static Future<void> clearFirebase() async {
    try {
      await FirebaseDataService.clearCloudDocuments();
    } catch (e) {
      print(
        'Firebase clear documents error: $e',
      );
    }
  }

  // =========================================================
  // GET CLOUD DOCUMENTS
  // =========================================================

  static Future<List<DocumentModel>>
      getCloudDocuments() async {
    try {
      return await FirebaseDataService
          .getCloudDocuments();
    } catch (e) {
      print(
        'Cloud document fetch error: $e',
      );

      return [];
    }
  }

  // =========================================================
  // UPLOAD PDF
  // =========================================================

  static Future<String?>
      uploadPdfIfNeeded(
    DocumentModel document,
  ) async {
    final user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      print(
        'Supabase upload skipped: no Firebase user.',
      );
      return null;
    }

    if (document.type.toLowerCase() != 'pdf') {
      return null;
    }

    if (document.storagePath != null &&
        document.storagePath!.isNotEmpty) {
      return null;
    }

    final path = document.filePath;

    if (path == null || path.isEmpty) {
      return null;
    }

    final file = File(path);

    if (!await file.exists()) {
      print(
        'Supabase upload skipped: file does not exist.',
      );
      return null;
    }

    try {
      final storagePath =
          await SupabaseStorageService.uploadPdf(
        firebaseUid: user.uid,
        documentId: document.id,
        file: file,
      );

      print(
        'PDF uploaded successfully: $storagePath',
      );

      return storagePath;
    } catch (e) {
      print(
        'Supabase PDF upload error: $e',
      );

      return null;
    }
  }

  // =========================================================
  // DELETE PDF
  // =========================================================

  static Future<void> deletePdf(
    String? storagePath,
  ) async {
    if (storagePath == null ||
        storagePath.isEmpty) {
      return;
    }

    try {
      await SupabaseStorageService.deletePdf(
        storagePath,
      );

      print(
        'Supabase PDF deleted: $storagePath',
      );
    } catch (e) {
      print(
        'Supabase PDF delete error: $e',
      );
    }
  }
}