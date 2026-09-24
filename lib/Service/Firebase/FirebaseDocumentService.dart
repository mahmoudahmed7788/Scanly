// ============================================================
// FIREBASE DOCUMENT SERVICE
// ============================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:scanly/Models/DocumentModel.dart';
import 'package:scanly/Service/Documents/LocalDocumentStorageService.dart';



// ============================================================
// FIREBASE DOCUMENT SERVICE
// ============================================================

class FirebaseDocumentService {
  // ==========================================================
  // FIREBASE
  // ==========================================================

  static final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  static FirebaseAuth get _auth {
    return FirebaseAuth.instance;
  }

  // ==========================================================
  // CURRENT USER
  // ==========================================================

  static User? get _currentUser {
    return _auth.currentUser;
  }

  // ==========================================================
  // USER REFERENCE
  // ==========================================================

  static DocumentReference<Map<String, dynamic>>?
      get _userReference {
    final User? user = _currentUser;

    if (user == null) {
      return null;
    }

    return _firestore
        .collection('users')
        .doc(user.uid);
  }

  // ==========================================================
  // DOCUMENTS REFERENCE
  // ==========================================================

  static CollectionReference<Map<String, dynamic>>?
      get _documentsReference {
    final DocumentReference<Map<String, dynamic>>? userReference =
        _userReference;

    if (userReference == null) {
      return null;
    }

    return userReference.collection('documents');
  }

  // ==========================================================
  // SAVE DOCUMENT
  // ==========================================================

  static Future<void> saveDocument(
    DocumentModel document,
  ) async {
    final CollectionReference<Map<String, dynamic>>? documents =
        _documentsReference;

    if (documents == null) {
      print(
        'Firebase save skipped: no logged-in user.',
      );
      return;
    }

    final Map<String, dynamic> data =
        document.toMap();

    data['updatedAt'] =
        FieldValue.serverTimestamp();

    data['createdAt'] =
        FieldValue.serverTimestamp();

    await documents
        .doc(document.id)
        .set(
      data,
      SetOptions(
        merge: true,
      ),
    );
  }

  // ==========================================================
  // UPDATE DOCUMENT
  // ==========================================================

  static Future<void> updateDocument(
    DocumentModel document,
  ) async {
    final CollectionReference<Map<String, dynamic>>? documents =
        _documentsReference;

    if (documents == null) {
      print(
        'Firebase update skipped: no logged-in user.',
      );
      return;
    }

    final Map<String, dynamic> data =
        document.toMap();

    data['updatedAt'] =
        FieldValue.serverTimestamp();

    await documents
        .doc(document.id)
        .set(
      data,
      SetOptions(
        merge: true,
      ),
    );
  }

  // ==========================================================
  // DELETE DOCUMENT
  // ==========================================================

  static Future<void> deleteDocument(
    String id,
  ) async {
    final CollectionReference<Map<String, dynamic>>? documents =
        _documentsReference;

    if (documents == null) {
      print(
        'Firebase delete skipped: no logged-in user.',
      );
      return;
    }

    await documents
        .doc(id)
        .delete();
  }

  // ==========================================================
  // GET CLOUD DOCUMENTS
  // ==========================================================

  static Future<List<DocumentModel>>
      getCloudDocuments() async {
    final CollectionReference<Map<String, dynamic>>? documents =
        _documentsReference;

    final User? user = _currentUser;

    if (documents == null || user == null) {
      print(
        'Cloud documents skipped: no logged-in user.',
      );

      return [];
    }

    QuerySnapshot<Map<String, dynamic>> snapshot;

    // ========================================================
    // ORDERED QUERY
    // ========================================================

    try {
      snapshot = await documents
          .orderBy(
            'date',
            descending: true,
          )
          .get();
    } catch (e) {
      print(
        'Cloud documents ordered query error: $e',
      );

      // ======================================================
      // FALLBACK QUERY
      // ======================================================

      try {
        snapshot = await documents.get();
      } catch (e) {
        print(
          'Cloud documents query error: $e',
        );

        return [];
      }
    }

    // ========================================================
    // BUILD DOCUMENT LIST
    // ========================================================

    final List<DocumentModel> result = [];

    for (final QueryDocumentSnapshot<Map<String, dynamic>> doc
        in snapshot.docs) {
      final Map<String, dynamic> data =
          Map<String, dynamic>.from(
        doc.data(),
      );

      // ======================================================
      // DOCUMENT ID
      // ======================================================

      data['id'] ??= doc.id;

      // ======================================================
      // STORAGE PATH
      // ======================================================

      final String? storagePath =
          data['storagePath']?.toString();

      String? localPath;

      // ======================================================
      // DOWNLOAD PDF
      // ======================================================

      if (storagePath != null &&
          storagePath.isNotEmpty) {
        try {
          localPath =
              await LocalDocumentStorageService
                  .downloadFileIfNeeded(
            documentId: doc.id,
            storagePath: storagePath,
            firebaseUid: user.uid,
          );
        } catch (e) {
          print(
            'Supabase download error: $e',
          );
        }
      }

      // ======================================================
      // LOCAL PATH
      // ======================================================
      //
      // The local path is intentionally not stored in Firebase
      // because it can be different on every device.
      // ======================================================

      data['filePath'] = localPath;

      // ======================================================
      // CREATE MODEL
      // ======================================================

      result.add(
        DocumentModel.fromMap(
          data,
        ),
      );
    }

    return result;
  }

  // ==========================================================
  // CLEAR CURRENT USER DOCUMENTS
  // ==========================================================

  static Future<void> clearCloudDocuments() async {
    final CollectionReference<Map<String, dynamic>>? documents =
        _documentsReference;

    final User? user = _currentUser;

    if (documents == null || user == null) {
      print(
        'Firebase clear skipped: no logged-in user.',
      );
      return;
    }

    // ========================================================
    // GET DOCUMENTS
    // ========================================================

    final QuerySnapshot<Map<String, dynamic>> snapshot =
        await documents.get();

    // ========================================================
    // DELETE DOCUMENTS
    // ========================================================

    for (final QueryDocumentSnapshot<Map<String, dynamic>> doc
        in snapshot.docs) {
      await documents
          .doc(doc.id)
          .delete();
    }

    print(
      'All cloud documents cleared for user: '
      '${user.uid}',
    );
  }
}