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

  static Future<void> init() async {
    await DocumentHiveService.init();

    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      unawaited(
        syncFromCloud(
          expectedUid: user.uid,
        ),
      );
    }
  }

  static Future<void> switchUser(
    String uid,
  ) async {
    await DocumentHiveService.switchUser(
      uid,
    );

    unawaited(
      syncFromCloud(
        expectedUid: uid,
      ),
    );
  }

  static Box? get _box {
    return DocumentHiveService.box;
  }

  static Future<Directory> getDocumentsDirectory() async {
    final user = FirebaseAuth.instance.currentUser;

    return DocumentFileService.getDocumentsDirectory(
      user?.uid,
    );
  }

  static List<DocumentModel> getDocuments() {
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
        DateTime.fromMillisecondsSinceEpoch(
          0,
        );
  }

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
      Map<String, dynamic>.from(
        data,
      ),
    );
  }

  static Future<bool> saveDocumentLocally(
    DocumentModel document,
  ) async {
    final box = _box;

    if (box == null) {
      print(
        'Local document save skipped: no active user.',
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

  static Future<void> saveDocument(
    DocumentModel document,
  ) async {
    final savedLocally = await saveDocumentLocally(
      document,
    );

    if (!savedLocally) {
      return;
    }

    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      return;
    }

    unawaited(
      _syncDocumentToCloud(
        document,
        expectedUid: uid,
      ),
    );
  }

  static Future<void> _syncDocumentToCloud(
    DocumentModel document, {
    required String expectedUid,
  }) async {
    try {
      if (!_isCurrentUser(expectedUid)) {
        return;
      }

      await DocumentCloudService.saveToFirebase(
        document,
      );

      if (!_isCurrentUser(expectedUid)) {
        return;
      }

      await _uploadDocumentIfNeeded(
        document,
        expectedUid: expectedUid,
      );
    } catch (e) {
      print(
        'Background document cloud sync error: $e',
      );
    }
  }

  static Future<bool> updateDocumentLocally(
    DocumentModel document,
  ) async {
    final box = _box;

    if (box == null) {
      print(
        'Local document update skipped: no active user.',
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

    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      return;
    }

    unawaited(
      _syncUpdatedDocumentToCloud(
        document,
        expectedUid: uid,
      ),
    );
  }

  static Future<void> _syncUpdatedDocumentToCloud(
    DocumentModel document, {
    required String expectedUid,
  }) async {
    try {
      if (!_isCurrentUser(expectedUid)) {
        return;
      }

      await DocumentCloudService.updateFirebase(
        document,
      );

      if (!_isCurrentUser(expectedUid)) {
        return;
      }

      if (document.storagePath == null ||
          document.storagePath!.isEmpty) {
        await _uploadDocumentIfNeeded(
          document,
          expectedUid: expectedUid,
        );
      }
    } catch (e) {
      print(
        'Background document update error: $e',
      );
    }
  }

  static Future<void> _uploadDocumentIfNeeded(
    DocumentModel document, {
    required String expectedUid,
  }) async {
    try {
      if (!_isCurrentUser(expectedUid)) {
        return;
      }

      final storagePath =
          await DocumentCloudService.uploadPdfIfNeeded(
        document,
      );

      if (storagePath == null ||
          storagePath.isEmpty) {
        return;
      }

      if (!_isCurrentUser(expectedUid)) {
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
    } catch (e) {
      print(
        'Background PDF upload error: $e',
      );
    }
  }

  static bool _isCurrentUser(
    String expectedUid,
  ) {
    return FirebaseAuth.instance.currentUser?.uid ==
        expectedUid;
  }

  static Future<void> markAsOpened(
    DocumentModel document,
  ) async {
    document.lastOpened =
        DateTime.now().toIso8601String();

    await updateDocument(
      document,
    );
  }

  static Future<void> toggleFavorite(
    DocumentModel document,
  ) async {
    document.isFavorite = !document.isFavorite;

    await updateDocument(
      document,
    );
  }

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

    await TrashService.moveDocumentToTrash(
      document,
      wasFavorite: document.isFavorite,
      wasRecent: document.lastOpened != null,
    );

    await box.delete(id);

    unawaited(
      _deleteDocumentFromCloud(
        id,
      ),
    );

    print(
      'Document moved to Trash: $id',
    );
  }

  static Future<void> _deleteDocumentFromCloud(
    String id,
  ) async {
    try {
      await DocumentCloudService.deleteFromFirebase(
        id,
      );
    } catch (e) {
      print(
        'Background document delete error: $e',
      );
    }
  }

  static Future<void> clearDocuments() async {
    final box = _box;

    if (box == null) {
      return;
    }

    final documents = List<DocumentModel>.from(
      getDocuments(),
    );

    if (documents.isEmpty) {
      return;
    }

    for (final document in documents) {
      await TrashService.moveDocumentToTrash(
        document,
        wasFavorite: document.isFavorite,
        wasRecent: document.lastOpened != null,
      );

      await box.delete(
        document.id,
      );

      unawaited(
        _deleteDocumentFromCloud(
          document.id,
        ),
      );
    }

    print(
      'All documents moved to Trash: ${documents.length}',
    );
  }

  static Future<void> syncFromCloud({
    String? expectedUid,
  }) async {
    final box = _box;

    if (box == null) {
      print(
        'Cloud sync skipped: no active user.',
      );

      return;
    }

    final uid =
        expectedUid ??
        FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      return;
    }

    try {
      final cloudDocuments =
          await DocumentCloudService.getCloudDocuments();

      if (!_isCurrentUser(uid)) {
        return;
      }

      final localDocuments = getDocuments();

      final localById = <String, DocumentModel>{
        for (final document in localDocuments)
          document.id: document,
      };

      for (final cloudDocument in cloudDocuments) {
        if (!_isCurrentUser(uid)) {
          return;
        }

        final localDocument =
            localById[cloudDocument.id];

        if (localDocument == null) {
          await box.put(
            cloudDocument.id,
            cloudDocument.toMap(),
          );

          continue;
        }

        final localDate =
            _parseDate(localDocument.date);

        final cloudDate =
            _parseDate(cloudDocument.date);

        if (cloudDate.isAfter(localDate)) {
          await box.put(
            cloudDocument.id,
            cloudDocument.toMap(),
          );
        }
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

      filesOnDisk.add(
        entity.path,
      );

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

      final fileName =
          entity.path.split(
        Platform.pathSeparator,
      ).last;

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