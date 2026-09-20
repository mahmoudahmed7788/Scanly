
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';

import 'FirebaseDataService.dart';
import 'SupabaseStorageService.dart';

class DocumentModel {
  String id;
  String title;
  String date;
  String type;
  String? filePath;
  bool isFavorite;
  String? lastOpened;
  String? storagePath;

  // Original page images used to create/edit the PDF.
  List<String> imagePaths;

  DocumentModel({
    required this.id,
    required this.title,
    required this.date,
    required this.type,
    this.filePath,
    this.isFavorite = false,
    this.lastOpened,
    this.storagePath,
    this.imagePaths = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'date': date,
      'type': type,
      'filePath': filePath,
      'isFavorite': isFavorite,
      'lastOpened': lastOpened,
      'storagePath': storagePath,
      'imagePaths': imagePaths,
    };
  }

  factory DocumentModel.fromMap(Map map) {
    final rawImagePaths = map['imagePaths'];

    List<String> parsedImagePaths = [];

    if (rawImagePaths is List) {
      parsedImagePaths = rawImagePaths
          .map((item) => item.toString())
          .where((item) => item.isNotEmpty)
          .toList();
    }

    return DocumentModel(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? 'Untitled Document',
      date: map['date']?.toString() ?? '',
      type: map['type']?.toString() ?? 'pdf',
      filePath: map['filePath']?.toString(),
      isFavorite: map['isFavorite'] == true,
      lastOpened: map['lastOpened']?.toString(),
      storagePath: map['storagePath']?.toString(),
      imagePaths: parsedImagePaths,
    );
  }
}

class DocumentStorage {
  // =========================================================
  // HIVE
  // =========================================================

  static const String _boxPrefix = 'scanly_documents_';

  static bool _initialized = false;

  static String? _activeUid;

  static Box? _activeBox;

  static bool _authListenerStarted = false;

  // =========================================================
  // INITIALIZE
  // =========================================================

  static Future<void> init() async {
    if (!_initialized) {
      await Hive.initFlutter();
      _initialized = true;
    }

    // Start listening to Firebase login/logout.
    if (!_authListenerStarted) {
      _authListenerStarted = true;

      FirebaseAuth.instance.authStateChanges().listen(
        (user) async {
          try {
            if (user == null) {
              // IMPORTANT:
              // Logout does NOT delete any user's data.
              _activeUid = null;
              _activeBox = null;

              print(
                'DocumentStorage: user logged out.',
              );

              return;
            }

            await switchUser(user.uid);
          } catch (e) {
            print(
              'DocumentStorage auth sync error: $e',
            );
          }
        },
      );
    }

    // If a user is already logged in when the app starts.
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      await switchUser(user.uid);
    }
  }

  // =========================================================
  // SWITCH USER
  // =========================================================

  static Future<void> switchUser(
    String uid,
  ) async {
    if (uid.isEmpty) {
      return;
    }

    // Already using this user's box.
    if (_activeUid == uid &&
        _activeBox != null &&
        _activeBox!.isOpen) {
      await syncFromCloud();
      return;
    }

    final boxName = '$_boxPrefix$uid';

    if (!Hive.isBoxOpen(boxName)) {
      await Hive.openBox(boxName);
    }

    _activeUid = uid;
    _activeBox = Hive.box(boxName);

    print(
      'DocumentStorage: switched to user $uid',
    );

    await syncFromCloud();
  }

  // =========================================================
  // CURRENT USER BOX
  // =========================================================

  static Box? get _box {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return null;
    }

    if (_activeUid != user.uid) {
      return null;
    }

    if (_activeBox == null ||
        !_activeBox!.isOpen) {
      return null;
    }

    return _activeBox;
  }

  // =========================================================
  // DOCUMENT DIRECTORY
  // =========================================================

  static Future<Directory>
      getDocumentsDirectory() async {
    final appDirectory =
        await getApplicationDocumentsDirectory();

    final user = FirebaseAuth.instance.currentUser;

    final userFolder =
        user?.uid ?? 'guest';

    final documentsDirectory = Directory(
      '${appDirectory.path}/Scanly/Documents/$userFolder',
    );

    if (!await documentsDirectory.exists()) {
      await documentsDirectory.create(
        recursive: true,
      );
    }

    return documentsDirectory;
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

  static DocumentModel?
      getDocument(
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

  static Future<void>
      saveDocument(
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

    try {
      await FirebaseDataService.saveDocument(
        document,
      );
    } catch (e) {
      print(
        'Firebase save document error: $e',
      );
    }

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

  static Future<void>
      updateDocument(
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

    try {
      await FirebaseDataService.updateDocument(
        document,
      );
    } catch (e) {
      print(
        'Firebase update document error: $e',
      );
    }

    // Upload only if not already uploaded.
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
    final user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      print(
        'Supabase upload skipped: no Firebase user.',
      );
      return;
    }

    if (document.type.toLowerCase() != 'pdf') {
      return;
    }

    if (document.storagePath != null &&
        document.storagePath!.isNotEmpty) {
      return;
    }

    final path = document.filePath;

    if (path == null ||
        path.isEmpty) {
      return;
    }

    final file = File(path);

    if (!await file.exists()) {
      print(
        'Supabase upload skipped: file does not exist.',
      );
      return;
    }

    try {
      final storagePath =
          await SupabaseStorageService.uploadPdf(
        firebaseUid: user.uid,
        documentId: document.id,
        file: file,
      );

      document.storagePath = storagePath;

      final box = _box;

      if (box != null) {
        await box.put(
          document.id,
          document.toMap(),
        );
      }

      try {
        await FirebaseDataService.updateDocument(
          document,
        );
      } catch (e) {
        print(
          'Firebase storagePath update error: $e',
        );
      }

      print(
        'PDF uploaded successfully: $storagePath',
      );
    } catch (e) {
      print(
        'Supabase PDF upload error: $e',
      );
    }
  }

  // =========================================================
  // MARK AS OPENED
  // =========================================================

  static Future<void>
      markAsOpened(
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

  static Future<void>
      toggleFavorite(
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

  static Future<void>
      deleteDocument(
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
    if (document.filePath != null &&
        document.filePath!.isNotEmpty) {
      try {
        final file =
            File(document.filePath!);

        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        print(
          'Local PDF delete error: $e',
        );
      }
    }

    // Delete Supabase PDF.
    if (document.storagePath != null &&
        document.storagePath!.isNotEmpty) {
      try {
        await SupabaseStorageService.deletePdf(
          document.storagePath!,
        );

        print(
          'Supabase PDF deleted: '
          '${document.storagePath}',
        );
      } catch (e) {
        print(
          'Supabase PDF delete error: $e',
        );
      }
    }

    // Delete local metadata.
    await box.delete(id);

    // Delete Firebase metadata.
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
  // CLEAR CURRENT USER DOCUMENTS
  // =========================================================

  static Future<void>
      clearDocuments() async {
    final box = _box;

    if (box == null) {
      return;
    }

    final documents = getDocuments();

    for (final document in documents) {
      // Delete local PDF.
      if (document.filePath != null &&
          document.filePath!.isNotEmpty) {
        try {
          final file =
              File(document.filePath!);

          if (await file.exists()) {
            await file.delete();
          }
        } catch (e) {
          print(
            'Local PDF delete error: $e',
          );
        }
      }

      // Delete Supabase PDF.
      if (document.storagePath != null &&
          document.storagePath!.isNotEmpty) {
        try {
          await SupabaseStorageService.deletePdf(
            document.storagePath!,
          );
        } catch (e) {
          print(
            'Supabase PDF delete error: $e',
          );
        }
      }
    }

    // Clear ONLY current user's Hive box.
    await box.clear();

    // Clear ONLY current user's Firebase documents.
    try {
      await FirebaseDataService.clearCloudDocuments();
    } catch (e) {
      print(
        'Firebase clear documents error: $e',
      );
    }
  }

  // =========================================================
  // CREATE ID
  // =========================================================

  static String _createId(
    File file,
  ) {
    return file.path.hashCode.toString();
  }

  // =========================================================
  // SYNC FROM CLOUD
  // =========================================================

  static Future<void>
      syncFromCloud() async {
    final box = _box;

    if (box == null) {
      print(
        'Cloud sync skipped: no active user.',
      );
      return;
    }

    try {
      final cloudDocuments =
          await FirebaseDataService.getCloudDocuments();

      // IMPORTANT:
      // Cloud is the source of truth for the
      // current user's documents.
      //
      // We clear ONLY this user's Hive box.
      await box.clear();

      for (final document in cloudDocuments) {
        await box.put(
          document.id,
          document.toMap(),
        );
      }

      print(
        'Cloud documents synced for $_activeUid: '
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

  static Future<void>
      syncFromDisk() async {
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

    for (final document
        in existingDocuments) {
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
          _getExtension(entity.path);

      if (!_isSupportedFile(extension)) {
        continue;
      }

      filesOnDisk.add(entity.path);

      final existing =
          existingByPath[entity.path];

      final stat =
          await entity.stat();

      final fileDate =
          stat.modified.toIso8601String();

      if (existing != null) {
        if (existing.date.isEmpty) {
          existing.date = fileDate;

          await updateDocument(existing);
        }

        continue;
      }

      final fileName =
          entity.path
              .split(
                Platform.pathSeparator,
              )
              .last;

      final title =
          _removeExtension(fileName);

      final document = DocumentModel(
        id: _createId(entity),
        title: title.isEmpty
            ? 'Untitled Document'
            : title,
        date: fileDate,
        type: 'pdf',
        filePath: entity.path,
      );

      await saveDocument(document);
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
          _getExtension(path);

      if (!_isSupportedFile(extension) ||
          !filesOnDisk.contains(path)) {
        await box.delete(document.id);
      }
    }
  }

  // =========================================================
  // FILE EXTENSION
  // =========================================================

  static String _getExtension(
    String path,
  ) {
    final index =
        path.lastIndexOf('.');

    if (index == -1) {
      return '';
    }

    return path
        .substring(index)
        .toLowerCase();
  }

  // =========================================================
  // REMOVE EXTENSION
  // =========================================================

  static String _removeExtension(
    String fileName,
  ) {
    final index =
        fileName.lastIndexOf('.');

    if (index == -1) {
      return fileName;
    }

    return fileName.substring(
      0,
      index,
    );
  }

  // =========================================================
  // SUPPORTED FILE
  // =========================================================

  static bool _isSupportedFile(
    String extension,
  ) {
    return extension == '.pdf';
  }
}
