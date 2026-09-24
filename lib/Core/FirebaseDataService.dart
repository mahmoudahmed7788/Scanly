// ============================================================
// FIREBASE DATA SERVICE
// ============================================================
//
// This class is the main entry point for Firebase document/user
// operations.
//
// The actual responsibilities are delegated to:
// - FirebaseUserService
// - FirebaseDocumentService
//
// Existing code can continue using FirebaseDataService exactly
// as before.
// ============================================================

import 'package:firebase_auth/firebase_auth.dart';
import 'package:scanly/Models/DocumentModel.dart';
import 'package:scanly/Service/Firebase/FirebaseDocumentService.dart';
import 'package:scanly/Service/Firebase/FirebaseUserService.dart';

// ============================================================
// FIREBASE DATA SERVICE
// ============================================================

class FirebaseDataService {
  // ==========================================================
  // USER
  // ==========================================================

  static User? get currentUser {
    return FirebaseUserService.currentUser;
  }

  static String? get uid {
    return FirebaseUserService.uid;
  }

  // ==========================================================
  // USER OPERATIONS
  // ==========================================================

  static Future<void> ensureUserDocument() async {
    await FirebaseUserService.ensureUserDocument();
  }

  // ==========================================================
  // DOCUMENT OPERATIONS
  // ==========================================================

  static Future<void> saveDocument(
    DocumentModel document,
  ) async {
    await FirebaseDocumentService.saveDocument(
      document,
    );
  }

  static Future<void> updateDocument(
    DocumentModel document,
  ) async {
    await FirebaseDocumentService.updateDocument(
      document,
    );
  }

  static Future<void> deleteDocument(
    String id,
  ) async {
    await FirebaseDocumentService.deleteDocument(
      id,
    );
  }

  static Future<List<DocumentModel>> getCloudDocuments() async {
    return FirebaseDocumentService.getCloudDocuments();
  }

  static Future<void> clearCloudDocuments() async {
    await FirebaseDocumentService.clearCloudDocuments();
  }
}