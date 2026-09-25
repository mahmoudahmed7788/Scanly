import 'dart:async';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:scanly/Models/DocumentModel.dart';
import 'package:scanly/Service/Documents/DocumentCloudService.dart';
import 'package:scanly/Service/Documents/DocumentFileService.dart';
import 'package:scanly/Service/Documents/DocumentHiveService.dart';
import 'package:scanly/Service/Trash/TrashService.dart';

class DocumentStorage {
  DocumentStorage._();

  // =========================================================
  // INITIALIZE
  // =========================================================

  static Future<void> init() async {
    await DocumentHiveService.init();

    final user =
        FirebaseAuth.instance.currentUser;

    if (user != null) {
      // -------------------------------------------------------
      // IMPORTANT:
      //
      // Cloud sync must NOT block app startup.
      //
      // Local Hive documents are already available.
      // Cloud sync happens in the background.
      // -------------------------------------------------------

      unawaited(
        syncFromCloud(),
      );
    }
  }

  // =========================================================
  // SWITCH USER
  // =========================================================

  static Future<void> switchUser(
    String uid,
  ) async {
    await DocumentHiveService.switchUser(
      uid,
    );

    await syncFromCloud();
  }

  // =========================================================
  // CURRENT USER BOX
  // =========================================================

  static Box? get _box {
    return DocumentHiveService.box;
  }

  // =========================================================
  // DOCUMENT DIRECTORY
  // =========================================================

  static Future<Directory>
      getDocumentsDirectory() async {
    final user =
        FirebaseAuth.instance.currentUser;

    return DocumentFileService
        .getDocumentsDirectory(
      user?.uid,
    );
  }

  // =========================================================
  // GET DOCUMENTS
  // =========================================================

  static List<DocumentModel>
      getDocuments() {
    final box = _box;

    if (box == null) {
      return [];
    }

    final documents = box.values
        .whereType<Map>()
        .map(
          (item) => DocumentModel.fromMap(
            Map<String, dynamic>.from(
              item,
            ),
          ),
        )
        .toList();

    documents.sort(
      _sortDocuments,
    );

    return documents;
  }

  // =========================================================
  // SORT
  // =========================================================

  static int _sortDocuments(
    DocumentModel a,
    DocumentModel b,
  ) {
    final aDate =
        _parseDate(a.date);

    final bDate =
        _parseDate(b.date);

    return bDate.compareTo(
      aDate,
    );
  }

  static DateTime _parseDate(
    String value,
  ) {
    final parsed =
        DateTime.tryParse(value);

    return parsed ??
        DateTime.fromMillisecondsSinceEpoch(
          0,
        );
  }

  // =========================================================
  // GET ONE DOCUMENT
  // =========================================================

  static DocumentModel? getDocument(
    String id,
  ) {
    final box = _box;

    if (box == null) {
      return null;
    }

    final data =
        box.get(id);

    if (data == null) {
      return null;
    }

    return DocumentModel.fromMap(
      Map<String, dynamic>.from(
        data,
      ),
    );
  }

  // =========================================================
  // SAVE DOCUMENT LOCALLY
  // =========================================================
  //
  // Saves immediately to Hive.
  //
  // Firebase is NOT touched here.
  //
  // This guarantees that DocumentsPage can see
  // the document immediately after creation.
  // =========================================================

  static Future<bool>
      saveDocumentLocally(
    DocumentModel document,
  ) async {
    final box = _box;

    if (box == null) {
      print(
        'Local document save skipped: '
        'no active user.',
      );

      return false;
    }

    try {
      await box.put(
        document.id,
        document.toMap(),
      );

      return true;
    } catch (e) {
      print(
        'Local document save error: $e',
      );

      return false;
    }
  }

  // =========================================================
  // SAVE DOCUMENT
  // =========================================================
  //
  // 1. Save locally immediately.
  // 2. Return to UI.
  // 3. Firebase + Storage continue in background.
  // =========================================================

  static Future<void> saveDocument(
    DocumentModel document,
  ) async {
    final savedLocally =
        await saveDocumentLocally(
      document,
    );

    if (!savedLocally) {
      return;
    }

    // -------------------------------------------------------
    // Background cloud sync.
    // -------------------------------------------------------

    unawaited(
      _syncDocumentToCloud(
        document,
      ),
    );
  }

  // =========================================================
  // SYNC NEW DOCUMENT TO CLOUD
  // =========================================================

  static Future<void>
      _syncDocumentToCloud(
    DocumentModel document,
  ) async {
    try {
      await DocumentCloudService
          .saveToFirebase(
        document,
      );

      await _uploadDocumentIfNeeded(
        document,
      );
    } catch (e) {
      print(
        'Background document cloud sync error: $e',
      );
    }
  }

  // =========================================================
  // UPDATE DOCUMENT LOCALLY
  // =========================================================

  static Future<bool>
      updateDocumentLocally(
    DocumentModel document,
  ) async {
    final box = _box;

    if (box == null) {
      print(
        'Local document update skipped: '
        'no active user.',
      );

      return false;
    }

    try {
      await box.put(
        document.id,
        document.toMap(),
      );

      return true;
    } catch (e) {
      print(
        'Local document update error: $e',
      );

      return false;
    }
  }

  // =========================================================
  // UPDATE DOCUMENT
  // =========================================================
  //
  // Local update happens immediately.
  //
  // Firebase update happens in background.
  // =========================================================

  static Future<void> updateDocument(
    DocumentModel document,
  ) async {
    final updatedLocally =
        await updateDocumentLocally(
      document,
    );

    if (!updatedLocally) {
      return;
    }

    unawaited(
      _syncUpdatedDocumentToCloud(
        document,
      ),
    );
  }

  // =========================================================
  // SYNC UPDATED DOCUMENT TO CLOUD
  // =========================================================

  static Future<void>
      _syncUpdatedDocumentToCloud(
    DocumentModel document,
  ) async {
    try {
      await DocumentCloudService
          .updateFirebase(
        document,
      );

      // -----------------------------------------------------
      // If the document does not have a Storage path yet,
      // upload its PDF.
      // -----------------------------------------------------

      if (document.storagePath == null ||
          document.storagePath!.isEmpty) {
        await _uploadDocumentIfNeeded(
          document,
        );
      }
    } catch (e) {
      print(
        'Background document update error: $e',
      );
    }
  }

  // =========================================================
  // UPLOAD PDF
  // =========================================================

  static Future<void>
      _uploadDocumentIfNeeded(
    DocumentModel document,
  ) async {
    try {
      final storagePath =
          await DocumentCloudService
              .uploadPdfIfNeeded(
        document,
      );

      if (storagePath == null ||
          storagePath.isEmpty) {
        return;
      }

      // -----------------------------------------------------
      // Update model with Firebase Storage path.
      // -----------------------------------------------------

      document.storagePath =
          storagePath;

      // -----------------------------------------------------
      // Keep local Hive synchronized.
      // -----------------------------------------------------

      final box = _box;

      if (box != null) {
        await box.put(
          document.id,
          document.toMap(),
        );
      }

      // -----------------------------------------------------
      // Update Firebase metadata.
      // -----------------------------------------------------

      await DocumentCloudService
          .updateFirebase(
        document,
      );
    } catch (e) {
      print(
        'Background PDF upload error: $e',
      );
    }
  }

  // =========================================================
  // MARK AS OPENED
  // =========================================================

  static Future<void> markAsOpened(
    DocumentModel document,
  ) async {
    document.lastOpened =
        DateTime.now()
            .toIso8601String();

    await updateDocument(
      document,
    );
  }

  // =========================================================
  // TOGGLE FAVORITE
  // =========================================================

  static Future<void> toggleFavorite(
    DocumentModel document,
  ) async {
    document.isFavorite =
        !document.isFavorite;

    await updateDocument(
      document,
    );
  }

  // =========================================================
  // DELETE DOCUMENT → TRASH
  // =========================================================

  static Future<void> deleteDocument(
    String id,
  ) async {
    final box = _box;

    if (box == null) {
      return;
    }

    final document =
        getDocument(id);

    if (document == null) {
      return;
    }

    // -------------------------------------------------------
    // 1. Move complete document data to Trash.
    // -------------------------------------------------------

    await TrashService
        .moveDocumentToTrash(
      document,
    );

    // -------------------------------------------------------
    // 2. Remove from active local database.
    // -------------------------------------------------------

    await box.delete(
      id,
    );

    // -------------------------------------------------------
    // 3. Remove active Firebase metadata.
    // -------------------------------------------------------

    await DocumentCloudService
        .deleteFromFirebase(
      id,
    );

    // -------------------------------------------------------
    // IMPORTANT:
    //
    // Do NOT delete the actual local PDF here.
    //
    // Do NOT delete the Firebase Storage PDF here.
    //
    // Permanent Delete is responsible for that.
    // -------------------------------------------------------

    print(
      'Document moved to Trash: $id',
    );
  }

  // =========================================================
  // CLEAR CURRENT USER DOCUMENTS → TRASH
  // =========================================================

  static Future<void>
      clearDocuments() async {
    final box = _box;

    if (box == null) {
      return;
    }

    final documents =
        List<DocumentModel>.from(
      getDocuments(),
    );

    if (documents.isEmpty) {
      return;
    }

    for (final document
        in documents) {
      // -----------------------------------------------------
      // Move document to Trash.
      // -----------------------------------------------------

      await TrashService
          .moveDocumentToTrash(
        document,
      );

      // -----------------------------------------------------
      // Remove active local metadata.
      // -----------------------------------------------------

      await box.delete(
        document.id,
      );

      // -----------------------------------------------------
      // Remove active Firebase metadata.
      // -----------------------------------------------------

      await DocumentCloudService
          .deleteFromFirebase(
        document.id,
      );
    }

    // -------------------------------------------------------
    // IMPORTANT:
    //
    // Do NOT:
    //
    // await box.clear();
    //
    // Do NOT:
    //
    // await DocumentCloudService.clearFirebase();
    //
    // Trash must keep the deleted documents.
    // -------------------------------------------------------

    print(
      'All documents moved to Trash: '
      '${documents.length}',
    );
  }

  // =========================================================
  // SYNC FROM CLOUD
  // =========================================================
  //
  // IMPORTANT FIX:
  //
  // NEVER use:
  //
  // await box.clear();
  //
  // here.
  //
  // Why?
  //
  // A newly-created PDF may already exist locally,
  // while Firebase upload is still running.
  //
  // If cloud sync clears Hive before upload finishes,
  // the new PDF disappears from DocumentsPage.
  //
  // Instead:
  //
  // Cloud documents are MERGED into the existing Hive box.
  // =========================================================

  static Future<void>
      syncFromCloud() async {
    final box = _box;

    if (box == null) {
      print(
        'Cloud sync skipped: '
        'no active user.',
      );

      return;
    }

    try {
      final cloudDocuments =
          await DocumentCloudService
              .getCloudDocuments();

      // -----------------------------------------------------
      // IMPORTANT:
      //
      // No box.clear().
      // No deletion of local documents.
      //
      // We only update/add documents received from cloud.
      // -----------------------------------------------------

      for (final document
          in cloudDocuments) {
        await box.put(
          document.id,
          document.toMap(),
        );
      }

      print(
        'Cloud documents merged for '
        '${DocumentHiveService.activeUid}: '
        '${cloudDocuments.length}',
      );
    } catch (e) {
      print(
        'Cloud document sync error: $e',
      );
    }
  }

  // =========================================================
  // SYNC FROM DISK
  // =========================================================
  //
  // This method is kept for explicit disk synchronization.
  //
  // DocumentsPage should NOT call this automatically,
  // because local Hive is already the primary fast source.
  // =========================================================

  static Future<void>
      syncFromDisk() async {
    final box = _box;

    if (box == null) {
      print(
        'Disk sync skipped: '
        'no active user.',
      );

      return;
    }

    final directory =
        await getDocumentsDirectory();

    if (!await directory.exists()) {
      return;
    }

    final entities =
        await directory
            .list(
              recursive: true,
              followLinks: false,
            )
            .toList();

    final existingDocuments =
        getDocuments();

    final existingByPath =
        <String, DocumentModel>{};

    for (final document
        in existingDocuments) {
      if (document.filePath != null &&
          document.filePath!.isNotEmpty) {
        existingByPath[
          document.filePath!
        ] = document;
      }
    }

    final filesOnDisk =
        <String>{};

    for (final entity in entities) {
      if (entity is! File) {
        continue;
      }

      final extension =
          DocumentFileService
              .getExtension(
        entity.path,
      );

      if (!DocumentFileService
          .isSupportedFile(
        extension,
      )) {
        continue;
      }

      filesOnDisk.add(
        entity.path,
      );

      final existing =
          existingByPath[
            entity.path
          ];

      final stat =
          await entity.stat();

      final fileDate =
          stat.modified
              .toIso8601String();

      if (existing != null) {
        if (existing.date.isEmpty) {
          existing.date =
              fileDate;

          await updateDocument(
            existing,
          );
        }

        continue;
      }

      final fileName =
          entity.path.split(
        Platform.pathSeparator,
      ).last;

      final title =
          DocumentFileService
              .removeExtension(
        fileName,
      );

      final document =
          DocumentModel(
        id:
            DocumentFileService
                .createId(
          entity,
        ),
        title:
            title.isEmpty
                ? 'Untitled Document'
                : title,
        date:
            fileDate,
        type:
            'pdf',
        filePath:
            entity.path,
      );

      await saveDocument(
        document,
      );
    }

    // -------------------------------------------------------
    // Remove Hive records whose local files disappeared.
    //
    // This behavior is intentionally kept here because this
    // method is an explicit "sync from disk" operation.
    // -------------------------------------------------------

    final storedDocuments =
        getDocuments();

    for (final document
        in storedDocuments) {
      final path =
          document.filePath;

      if (path == null ||
          path.isEmpty) {
        continue;
      }

      final extension =
          DocumentFileService
              .getExtension(
        path,
      );

      if (!DocumentFileService
              .isSupportedFile(
            extension,
          ) ||
          !filesOnDisk.contains(
            path,
          )) {
        await box.delete(
          document.id,
        );
      }
    }
  }
}