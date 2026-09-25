import 'dart:convert';

import 'package:scanly/Core/Scanly_Items.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:scanly/Models/TrashItem.dart';
import 'package:scanly/Models/DocumentModel.dart';
import 'package:scanly/Models/Note_Model.dart';
import 'package:scanly/Core/DocumentStorage.dart';

class TrashService {
  TrashService._();

  static const String _trashKey = 'scanly_global_trash';

  static Future<List<TrashItem>> getItems() async {
    final prefs = await SharedPreferences.getInstance();

    final values = prefs.getStringList(_trashKey) ?? [];

    final items = <TrashItem>[];

    for (final value in values) {
      try {
        items.add(TrashItem.fromJson(value));
      } catch (_) {}
    }

    items.sort((a, b) => b.deletedAt.compareTo(a.deletedAt));

    return items;
  }

  static Future<void> _saveItems(List<TrashItem> items) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setStringList(
      _trashKey,
      items.map((item) => item.toJson()).toList(),
    );
  }

  // ==========================================================
  // MOVE TO TRASH
  // ==========================================================

  static Future<void> moveToTrash({
    required String id,
    required TrashItemType type,
    required String title,
    required Map<String, dynamic> data,
    ScanlyItem? item,
    bool? wasFavorite,
    bool? wasRecent,
  }) async {
    final items = await getItems();

    items.removeWhere((item) => item.id == id && item.type == type);

    items.add(
      TrashItem(
        id: id,
        type: type,
        title: title,
        data: data,
        deletedAt: DateTime.now(),
      ),
    );

    await _saveItems(items);
  }

  // ==========================================================
  // DOCUMENT
  // ==========================================================

  static Future<void> moveDocumentToTrash(DocumentModel document) async {
    await moveToTrash(
      id: document.id,
      type: document.type == 'pdf' ? TrashItemType.pdf : TrashItemType.document,
      title: document.title,
      data: document.toMap(),
    );
  }

  // ==========================================================
  // NOTE
  // ==========================================================

  static Future<void> moveNoteToTrash(NoteModel note) async {
    await moveToTrash(
      id: note.id,
      type: TrashItemType.note,
      title: note.title,
      data: note.toJson(),
      item: null,
      wasFavorite: null,
      wasRecent: null,
    );
  }

  // ==========================================================
  // RESTORE
  // ==========================================================

  static Future<void> restore(TrashItem item) async {
    switch (item.type) {
      case TrashItemType.document:
      case TrashItemType.pdf:
        await _restoreDocument(item);
        break;

      case TrashItemType.note:
        await _restoreNote(item);
        break;

      case TrashItemType.image:
      case TrashItemType.qr:
      case TrashItemType.other:
        // These are restored back to their
        // original stored data by their
        // feature service when connected.
        break;
    }

    await _removeFromTrash(item);
  }

  static Future<void> _restoreDocument(TrashItem item) async {
    final document = DocumentModel.fromMap(item.data);

    await DocumentStorage.saveDocument(document);
  }

  static Future<void> _restoreNote(TrashItem item) async {
    final prefs = await SharedPreferences.getInstance();

    const key = 'scanly_notes';

    final values = prefs.getStringList(key) ?? [];

    values.removeWhere((value) {
      try {
        final decoded = jsonDecode(value);

        return decoded['id']?.toString() == item.id;
      } catch (_) {
        return false;
      }
    });

    values.add(jsonEncode(item.data));

    await prefs.setStringList(key, values);
  }

  // ==========================================================
  // PERMANENT DELETE
  // ==========================================================

  static Future<void> permanentlyDelete(TrashItem item) async {
    switch (item.type) {
      case TrashItemType.document:
      case TrashItemType.pdf:
        await _permanentlyDeleteDocument(item);
        break;

      case TrashItemType.note:
        await _permanentlyDeleteNote(item);
        break;

      case TrashItemType.image:
      case TrashItemType.qr:
      case TrashItemType.other:
        break;
    }

    await _removeFromTrash(item);
  }

  static Future<void> _permanentlyDeleteDocument(TrashItem item) async {
    final document = DocumentModel.fromMap(item.data);

    // DocumentStorage.deleteDocument()
    // is intentionally NOT called here because
    // the document has already been removed
    // from active storage when moved to Trash.

    await _deleteLocalDocumentFiles(document);
  }

  static Future<void> _deleteLocalDocumentFiles(DocumentModel document) async {
    // The actual permanent file/cloud deletion
    // will be connected to DocumentFileService
    // and DocumentCloudService in the next step.
  }

  static Future<void> _permanentlyDeleteNote(TrashItem item) async {
    final prefs = await SharedPreferences.getInstance();

    const key = 'scanly_notes';

    final values = prefs.getStringList(key) ?? [];

    values.removeWhere((value) {
      try {
        final decoded = jsonDecode(value);

        return decoded['id']?.toString() == item.id;
      } catch (_) {
        return false;
      }
    });

    await prefs.setStringList(key, values);
  }

  // ==========================================================
  // REMOVE ONE FROM TRASH
  // ==========================================================

  static Future<void> _removeFromTrash(TrashItem item) async {
    final items = await getItems();

    items.removeWhere(
      (trashItem) => trashItem.id == item.id && trashItem.type == item.type,
    );

    await _saveItems(items);
  }

  // ==========================================================
  // EMPTY TRASH
  // ==========================================================

  static Future<void> emptyTrash() async {
    final items = await getItems();

    for (final item in items) {
      await permanentlyDelete(item);
    }
  }

  // ==========================================================
  // CLEAN EXPIRED ITEMS
  // ==========================================================

  static Future<void> cleanupExpiredItems() async {
    final items = await getItems();

    final expired = items.where((item) => item.isExpired);

    for (final item in expired) {
      await permanentlyDelete(item);
    }
  }
}
