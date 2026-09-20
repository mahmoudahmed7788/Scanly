import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:path_provider/path_provider.dart';

import 'DocumentModel.dart';
import 'SupabaseStorageService.dart';

class FirebaseDataService {
  // =========================================================
  // FIREBASE
  // =========================================================

  static final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  static FirebaseAuth get _auth =>
      FirebaseAuth.instance;

  static User? get currentUser =>
      _auth.currentUser;

  static String? get uid =>
      _auth.currentUser?.uid;

  // =========================================================
  // USER REFERENCE
  // =========================================================

  static DocumentReference<Map<String, dynamic>>?
      get _userReference {
    final user = _auth.currentUser;

    if (user == null) {
      return null;
    }

    return _firestore
        .collection('users')
        .doc(user.uid);
  }

  // =========================================================
  // DOCUMENTS REFERENCE
  // =========================================================

  static CollectionReference<Map<String, dynamic>>?
      get _documentsReference {
    final userReference = _userReference;

    if (userReference == null) {
      return null;
    }

    return userReference.collection('documents');
  }

  // =========================================================
  // ENSURE USER DOCUMENT
  // =========================================================

  static Future<void> ensureUserDocument() async {
    final user = _auth.currentUser;

    if (user == null) {
      return;
    }

    final ref =
        _firestore
            .collection('users')
            .doc(user.uid);

    final snapshot = await ref.get();

    final data = <String, dynamic>{
      'uid': user.uid,
      'email': user.email,
      'name': user.displayName ?? '',
      'photoUrl': user.photoURL,
      'emailVerified': user.emailVerified,
      'lastLoginAt':
          FieldValue.serverTimestamp(),
      'updatedAt':
          FieldValue.serverTimestamp(),
    };

    if (!snapshot.exists) {
      data['createdAt'] =
          FieldValue.serverTimestamp();
    }

    await ref.set(
      data,
      SetOptions(merge: true),
    );
  }

  // =========================================================
  // SAVE DOCUMENT
  // =========================================================

  static Future<void> saveDocument(
    DocumentModel document,
  ) async {
    final documents =
        _documentsReference;

    if (documents == null) {
      print(
        'Firebase save skipped: no logged-in user.',
      );
      return;
    }

    final data =
        document.toMap();

    data['updatedAt'] =
        FieldValue.serverTimestamp();

    data['createdAt'] =
        FieldValue.serverTimestamp();

    await documents
        .doc(document.id)
        .set(
      data,
      SetOptions(merge: true),
    );
  }

  // =========================================================
  // UPDATE DOCUMENT
  // =========================================================

  static Future<void> updateDocument(
    DocumentModel document,
  ) async {
    final documents =
        _documentsReference;

    if (documents == null) {
      print(
        'Firebase update skipped: no logged-in user.',
      );
      return;
    }

    final data =
        document.toMap();

    data['updatedAt'] =
        FieldValue.serverTimestamp();

    await documents
        .doc(document.id)
        .set(
      data,
      SetOptions(merge: true),
    );
  }

  // =========================================================
  // DELETE DOCUMENT
  // =========================================================

  static Future<void> deleteDocument(
    String id,
  ) async {
    final documents =
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

  // =========================================================
  // GET CLOUD DOCUMENTS
  // =========================================================

  static Future<List<DocumentModel>>
      getCloudDocuments() async {
    final documents =
        _documentsReference;

    final user =
        _auth.currentUser;

    if (documents == null ||
        user == null) {
      print(
        'Cloud documents skipped: no logged-in user.',
      );

      return [];
    }

    QuerySnapshot<
        Map<String, dynamic>> snapshot;

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

      try {
        snapshot =
            await documents.get();
      } catch (e) {
        print(
          'Cloud documents query error: $e',
        );

        return [];
      }
    }

    final result =
        <DocumentModel>[];

    for (final doc
        in snapshot.docs) {
      final data =
          Map<String, dynamic>.from(
        doc.data(),
      );

      // Make sure the document ID exists.
      data['id'] ??= doc.id;

      final storagePath =
          data['storagePath']
              ?.toString();

      String? localPath;

      // =====================================================
      // DOWNLOAD PDF FROM SUPABASE
      // =====================================================

      if (storagePath != null &&
          storagePath.isNotEmpty) {
        try {
          localPath =
              await _downloadFileIfNeeded(
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

      // Local path is not stored in Firebase
      // as the actual local path can differ
      // between devices.
      data['filePath'] =
          localPath;

      result.add(
        DocumentModel.fromMap(
          data,
        ),
      );
    }

    return result;
  }

  // =========================================================
  // DOWNLOAD FILE IF NEEDED
  // =========================================================

  static Future<String?>
      _downloadFileIfNeeded({
    required String documentId,
    required String storagePath,
    required String firebaseUid,
  }) async {
    final directory =
        await getApplicationDocumentsDirectory();

    // =======================================================
    // USER-SPECIFIC LOCAL DIRECTORY
    // =======================================================

    final documentsDirectory =
        Directory(
      '${directory.path}/Scanly/Documents/$firebaseUid',
    );

    if (!await documentsDirectory.exists()) {
      await documentsDirectory.create(
        recursive: true,
      );
    }

    // =======================================================
    // USER-SPECIFIC LOCAL PDF
    // =======================================================

    final localFile =
        File(
      '${documentsDirectory.path}/$documentId.pdf',
    );

    // =======================================================
    // ALREADY EXISTS LOCALLY
    // =======================================================

    if (await localFile.exists()) {
      return localFile.path;
    }

    // =======================================================
    // DOWNLOAD FROM SUPABASE
    // =======================================================

    final Uint8List bytes =
        await SupabaseStorageService
            .downloadPdf(
      storagePath,
    );

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

  // =========================================================
  // CLEAR CURRENT USER CLOUD DOCUMENTS
  // =========================================================

  static Future<void>
      clearCloudDocuments() async {
    final documents =
        _documentsReference;

    final user =
        _auth.currentUser;

    if (documents == null ||
        user == null) {
      print(
        'Firebase clear skipped: no logged-in user.',
      );
      return;
    }

    final snapshot =
        await documents.get();

    for (final doc
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
