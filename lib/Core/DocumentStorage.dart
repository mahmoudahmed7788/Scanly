import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:scanly/Models/DocumentModel.dart';
import 'package:scanly/Service/Documents/DocumentCloudService.dart';
import 'package:scanly/Service/Documents/DocumentFileService.dart';
import 'package:scanly/Service/Documents/DocumentHiveService.dart';
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
      await syncFromCloud();
    }
  }

  // =========================================================
  // SWITCH USER
  // =========================================================

  static Future<void> switchUser(
    String uid,
  ) async {
    await DocumentHiveService.switchUser(uid);
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

    return DocumentFileService.getDocumentsDirectory(
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
            Map<String, dynamic>.from(item),
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
    final aDate = _parseDate(a.date);
    final bDate = _parseDate(b.date);

    return bDate.compareTo(aDate);
  }

  static DateTime _parseDate(
    String value,
  ) {
    final parsed = DateTime.tryParse(value);

    return parsed ??
        DateTime.fromMillisecondsSinceEpoch(0);
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

    final data = box.get(id);

    if (data == null) {
      return null;
    }

    return DocumentModel.fromMap(
      Map<String, dynamic>.from(data),
    );
  }

  // =========================================================
  // SAVE DOCUMENT
  // =========================================================

  static Future<void> saveDocument(
    DocumentModel document,
  ) async {
    final box = _box;

    if (box == null) {
      print(
        'Save document skipped: no active user.',
      );
      return;
    }

    // Save locally FIRST.
    await box.put(
      document.id,
      document.toMap(),
    );

    await DocumentCloudService.saveToFirebase(
      document,
    );

    // Upload PDF in background.
    _uploadDocumentIfNeeded(
      document,
    ).then(
      (_) {},
      onError: (error) {
        print(
          'Background PDF upload error: $error',
        );
      },
    );
  }

  // =========================================================
  // UPDATE DOCUMENT
  // =========================================================

  static Future<void> updateDocument(
    DocumentModel document,
  ) async {
    final box = _box;

    if (box == null) {
      print(
        'Update document skipped: no active user.',
      );
      return;
    }

    await box.put(
      document.id,
      document.toMap(),
    );

    await DocumentCloudService.updateFirebase(
      document,
    );

    if (document.storagePath == null ||
        document.storagePath!.isEmpty) {
      _uploadDocumentIfNeeded(
        document,
      ).then(
        (_) {},
        onError: (error) {
          print(
            'Background PDF upload error: $error',
          );
        },
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
    final storagePath =
        await DocumentCloudService.uploadPdfIfNeeded(
      document,
    );

    if (storagePath == null ||
        storagePath.isEmpty) {
      return;
    }

    document.storagePath = storagePath;

    final box = _box;

    if (box != null) {
      await box.put(
        document.id,
        document.toMap(),
      );
    }

    await DocumentCloudService.updateFirebase(
      document,
    );
  }

  // =========================================================
  // MARK AS OPENED
  // =========================================================

  static Future<void> markAsOpened(
    DocumentModel document,
  ) async {
    document.lastOpened =
        DateTime.now().toIso8601String();

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
  // DELETE DOCUMENT
  // =========================================================

  static Future<void> deleteDocument(
    String id,
  ) async {
    final box = _box;

    if (box == null) {
      return;
    }

    final document = getDocument(id);

    if (document == null) {
      return;
    }

    // Delete local PDF.
    await DocumentFileService.deleteLocalFile(
      document.filePath,
    );

    // Delete Supabase PDF.
    await DocumentCloudService.deletePdf(
      document.storagePath,
    );

    // Delete local metadata.
    await box.delete(id);

    // Delete Firebase metadata.
    await DocumentCloudService.deleteFromFirebase(
      id,
    );
  }

  // =========================================================
  // CLEAR CURRENT USER DOCUMENTS
  // =========================================================

  static Future<void> clearDocuments() async {
    final box = _box;

    if (box == null) {
      return;
    }

    final documents = getDocuments();

    for (final document in documents) {
      await DocumentFileService.deleteLocalFile(
        document.filePath,
      );

      await DocumentCloudService.deletePdf(
        document.storagePath,
      );
    }

    // Clear ONLY current user's Hive box.
    await box.clear();

    // Clear ONLY current user's Firebase documents.
    await DocumentCloudService.clearFirebase();
  }

  // =========================================================
  // SYNC FROM CLOUD
  // =========================================================

  static Future<void> syncFromCloud() async {
    final box = _box;

    if (box == null) {
      print(
        'Cloud sync skipped: no active user.',
      );
      return;
    }

    try {
      final cloudDocuments =
          await DocumentCloudService
              .getCloudDocuments();

      // Cloud is the source of truth for
      // the current user's documents.
      await box.clear();

      for (final document in cloudDocuments) {
        await box.put(
          document.id,
          document.toMap(),
        );
      }

      print(
        'Cloud documents synced for '
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

  static Future<void> syncFromDisk() async {
    final box = _box;

    if (box == null) {
      print(
        'Disk sync skipped: no active user.',
      );
      return;
    }

    final directory =
        await getDocumentsDirectory();

    if (!await directory.exists()) {
      return;
    }

    final entities = await directory
        .list(
          recursive: true,
          followLinks: false,
        )
        .toList();

    final existingDocuments =
        getDocuments();

    final existingByPath =
        <String, DocumentModel>{};

    for (final document in existingDocuments) {
      if (document.filePath != null &&
          document.filePath!.isNotEmpty) {
        existingByPath[
          document.filePath!
        ] = document;
      }
    }

    final filesOnDisk = <String>{};

    for (final entity in entities) {
      if (entity is! File) {
        continue;
      }

      final extension =
          DocumentFileService.getExtension(
        entity.path,
      );

      if (!DocumentFileService.isSupportedFile(
        extension,
      )) {
        continue;
      }

      filesOnDisk.add(entity.path);

      final existing =
          existingByPath[entity.path];

      final stat = await entity.stat();

      final fileDate =
          stat.modified.toIso8601String();

      if (existing != null) {
        if (existing.date.isEmpty) {
          existing.date = fileDate;

          await updateDocument(
            existing,
          );
        }

        continue;
      }

      final fileName = entity.path
          .split(
            Platform.pathSeparator,
          )
          .last;

      final title =
          DocumentFileService.removeExtension(
        fileName,
      );

      final document = DocumentModel(
        id: DocumentFileService.createId(
          entity,
        ),
        title: title.isEmpty
            ? 'Untitled Document'
            : title,
        date: fileDate,
        type: 'pdf',
        filePath: entity.path,
      );

      await saveDocument(
        document,
      );
    }

    final storedDocuments =
        getDocuments();

    for (final document in storedDocuments) {
      final path = document.filePath;

      if (path == null ||
          path.isEmpty) {
        continue;
      }

      final extension =
          DocumentFileService.getExtension(
        path,
      );

      if (!DocumentFileService.isSupportedFile(
            extension,
          ) ||
          !filesOnDisk.contains(path)) {
        await box.delete(
          document.id,
        );
      }
    }
  }
}