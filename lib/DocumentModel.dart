import 'dart:io';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';

class DocumentModel {
  String id;
  String title;
  String date;
  String type;
  String? filePath;
  bool isFavorite;
  String? lastOpened;

  DocumentModel({
    required this.id,
    required this.title,
    required this.date,
    required this.type,
    this.filePath,
    this.isFavorite = false,
    this.lastOpened,
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
    };
  }

  factory DocumentModel.fromMap(Map map) {
    return DocumentModel(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? 'Untitled Document',
      date: map['date']?.toString() ?? '',
      type: map['type']?.toString() ?? 'pdf',
      filePath: map['filePath']?.toString(),
      isFavorite: map['isFavorite'] == true,
      lastOpened: map['lastOpened']?.toString(),
    );
  }
}

class DocumentStorage {
  static const String boxName = 'documents';

  static Future<void> init() async {
    if (!Hive.isBoxOpen(boxName)) {
      await Hive.initFlutter();
      await Hive.openBox(boxName);
    }
  }

  static Box get _box => Hive.box(boxName);

  static Future<Directory> getDocumentsDirectory() async {
    final appDirectory = await getApplicationDocumentsDirectory();

    final documentsDirectory = Directory(
      '${appDirectory.path}/Scanly/Documents',
    );

    if (!await documentsDirectory.exists()) {
      await documentsDirectory.create(recursive: true);
    }

    return documentsDirectory;
  }

  static List<DocumentModel> getDocuments() {
    final documents = _box.values
        .whereType<Map>()
        .map(
          (item) => DocumentModel.fromMap(
            Map<String, dynamic>.from(item),
          ),
        )
        .toList();

    documents.sort(_sortDocuments);

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

  static DateTime _parseDate(String value) {
    final parsed = DateTime.tryParse(value);

    return parsed ??
        DateTime.fromMillisecondsSinceEpoch(0);
  }

  static DocumentModel? getDocument(String id) {
    final data = _box.get(id);

    if (data == null) {
      return null;
    }

    return DocumentModel.fromMap(
      Map<String, dynamic>.from(data),
    );
  }

  static Future<void> saveDocument(
    DocumentModel document,
  ) async {
    await _box.put(
      document.id,
      document.toMap(),
    );
  }

  static Future<void> updateDocument(
    DocumentModel document,
  ) async {
    await _box.put(
      document.id,
      document.toMap(),
    );
  }

  static Future<void> markAsOpened(
    DocumentModel document,
  ) async {
    document.lastOpened =
        DateTime.now().toIso8601String();

    await updateDocument(document);
  }

  static Future<void> toggleFavorite(
    DocumentModel document,
  ) async {
    document.isFavorite = !document.isFavorite;

    await updateDocument(document);
  }

  static Future<void> deleteDocument(
    String id,
  ) async {
    final document = getDocument(id);

    if (document?.filePath != null &&
        document!.filePath!.isNotEmpty) {
      try {
        final file = File(document.filePath!);

        if (await file.exists()) {
          await file.delete();
        }
      } catch (_) {}
    }

    await _box.delete(id);
  }

  static Future<void> clearDocuments() async {
    final documents = getDocuments();

    for (final document in documents) {
      if (document.filePath != null &&
          document.filePath!.isNotEmpty) {
        try {
          final file = File(document.filePath!);

          if (await file.exists()) {
            await file.delete();
          }
        } catch (_) {}
      }
    }

    await _box.clear();
  }

  static String _detectType(String extension) {
    final value = extension.toLowerCase();

    if (value == '.pdf') {
      return 'pdf';
    }

    return 'pdf';
  }

  static String _createId(File file) {
    return file.path.hashCode.toString();
  }

  static Future<void> syncFromDisk() async {
    final directory = await getDocumentsDirectory();

    if (!await directory.exists()) {
      return;
    }

    final entities = await directory
        .list(
          recursive: true,
          followLinks: false,
        )
        .toList();

    final existingDocuments = getDocuments();

    final existingByPath = <String, DocumentModel>{};

    for (final document in existingDocuments) {
      if (document.filePath != null &&
          document.filePath!.isNotEmpty) {
        existingByPath[document.filePath!] =
            document;
      }
    }

    final filesOnDisk = <String>{};

    for (final entity in entities) {
      if (entity is! File) {
        continue;
      }

      final extension = _getExtension(
        entity.path,
      );

      if (!_isSupportedFile(extension)) {
        continue;
      }

      filesOnDisk.add(entity.path);

      final existing =
          existingByPath[entity.path];

      final stat = await entity.stat();

      final fileDate = stat.modified
          .toIso8601String();

      if (existing != null) {
        if (existing.date.isEmpty) {
          existing.date = fileDate;
          await updateDocument(existing);
        }

        continue;
      }

      final fileName =
          entity.path.split(Platform.pathSeparator).last;

      final title = _removeExtension(fileName);

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

    final storedDocuments = getDocuments();

    for (final document in storedDocuments) {
      final path = document.filePath;

      if (path == null || path.isEmpty) {
        continue;
      }

      final extension = _getExtension(path);

      if (!_isSupportedFile(extension) ||
          !filesOnDisk.contains(path)) {
        await _box.delete(document.id);
      }
    }
  }

  static String _getExtension(String path) {
    final index = path.lastIndexOf('.');

    if (index == -1) {
      return '';
    }

    return path.substring(index).toLowerCase();
  }

  static String _removeExtension(String fileName) {
    final index = fileName.lastIndexOf('.');

    if (index == -1) {
      return fileName;
    }

    return fileName.substring(0, index);
  }

  static bool _isSupportedFile(
    String extension,
  ) {
    return extension == '.pdf';
  }
}