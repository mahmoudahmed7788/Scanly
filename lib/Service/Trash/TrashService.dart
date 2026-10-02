import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:scanly/Core/DocumentStorage.dart';
import 'package:scanly/Core/Scanly_Items.dart';
import 'package:scanly/Models/DocumentModel.dart';
import 'package:scanly/Models/Note_Model.dart';
import 'package:scanly/Models/TrashItem.dart';

class TrashService {
  TrashService._();

  static const String _trashKey = 'scanly_global_trash';
  static const String _notesKey = 'scanly_notes';

  // ==========================================================
  // GET ITEMS
  // ==========================================================

  static Future<List<TrashItem>> getItems() async {
    final prefs = await SharedPreferences.getInstance();

    final values = prefs.getStringList(_trashKey) ?? <String>[];

    final items = <TrashItem>[];

    for (final value in values) {
      try {
        items.add(
          TrashItem.fromJson(value),
        );
      } catch (_) {
        // Ignore corrupted entries instead of crashing
        // the entire Trash screen.
      }
    }

    items.sort(
      (a, b) => b.deletedAt.compareTo(a.deletedAt),
    );

    return items;
  }

  // ==========================================================
  // SAVE ITEMS
  // ==========================================================

  static Future<void> _saveItems(
    List<TrashItem> items,
  ) async {
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

    items.removeWhere(
      (existing) =>
          existing.id == id && existing.type == type,
    );

    items.add(
      TrashItem(
        id: id,
        type: type,
        title: title,
        data: Map<String, dynamic>.from(data),
        deletedAt: DateTime.now(),
        wasFavorite: wasFavorite ?? false,
        wasRecent: wasRecent ?? false,
      ),
    );

    await _saveItems(items);
  }

  // ==========================================================
  // DOCUMENT
  // ==========================================================

  static Future<void> moveDocumentToTrash(
    DocumentModel document, {
    bool wasFavorite = false,
    bool wasRecent = false,
  }) async {
    await moveToTrash(
      id: document.id,
      type: document.type == 'pdf'
          ? TrashItemType.pdf
          : TrashItemType.document,
      title: document.title,
      data: document.toMap(),
      wasFavorite: wasFavorite,
      wasRecent: wasRecent,
    );
  }

  // ==========================================================
  // NOTE
  // ==========================================================

  static Future<void> moveNoteToTrash(
    NoteModel note, {
    bool wasFavorite = false,
    bool wasRecent = false,
  }) async {
    await moveToTrash(
      id: note.id,
      type: TrashItemType.note,
      title: note.title,
      data: note.toJson(),
      wasFavorite: wasFavorite,
      wasRecent: wasRecent,
    );
  }

  // ==========================================================
  // RESTORE
  // ==========================================================

  static Future<void> restore(
    TrashItem item,
  ) async {
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
        await _restoreGenericItem(item);
        break;
    }

    await _removeFromTrash(item);
  }

  // ==========================================================
  // RESTORE DOCUMENT
  // ==========================================================

  static Future<void> _restoreDocument(
    TrashItem item,
  ) async {
    final document = DocumentModel.fromMap(
      Map<String, dynamic>.from(item.data),
    );

    await DocumentStorage.saveDocument(
      document,
    );
  }

  // ==========================================================
  // RESTORE NOTE
  // ==========================================================

  static Future<void> _restoreNote(
    TrashItem item,
  ) async {
    final prefs = await SharedPreferences.getInstance();

    final values =
        prefs.getStringList(_notesKey) ?? <String>[];

    values.removeWhere(
      (value) {
        try {
          final decoded = jsonDecode(value);

          return decoded is Map &&
              decoded['id']?.toString() == item.id;
        } catch (_) {
          return false;
        }
      },
    );

    values.add(
      jsonEncode(item.data),
    );

    await prefs.setStringList(
      _notesKey,
      values,
    );
  }

  // ==========================================================
  // RESTORE GENERIC ITEM
  // ==========================================================

  static Future<void> _restoreGenericItem(
    TrashItem item,
  ) async {
    /*
     * Image / QR / Other restoration depends on the
     * storage/service responsible for each feature.
     *
     * We intentionally do NOT pretend that restoring
     * these items is implemented when their storage
     * contract has not been provided yet.
     */
    throw UnsupportedError(
      'Restore is not implemented for ${item.type.value} items yet.',
    );
  }

  // ==========================================================
  // PERMANENT DELETE
  // ==========================================================

  static Future<void> permanentlyDelete(
    TrashItem item,
  ) async {
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
        await _permanentlyDeleteGenericItem(item);
        break;
    }

    await _removeFromTrash(item);
  }

  // ==========================================================
  // PERMANENT DELETE DOCUMENT
  // ==========================================================

  static Future<void> _permanentlyDeleteDocument(
    TrashItem item,
  ) async {
    final document = DocumentModel.fromMap(
      Map<String, dynamic>.from(item.data),
    );

    await _deleteLocalDocumentFiles(
      document,
    );
  }

  static Future<void> _deleteLocalDocumentFiles(
    DocumentModel document,
  ) async {
    /*
     * The actual file deletion must use the same storage
     * contract used by DocumentStorage.
     *
     * We do not delete arbitrary paths here because doing
     * so without knowing the DocumentStorage implementation
     * could delete the wrong file.
     */
  }

  // ==========================================================
  // PERMANENT DELETE NOTE
  // ==========================================================

  static Future<void> _permanentlyDeleteNote(
    TrashItem item,
  ) async {
    final prefs = await SharedPreferences.getInstance();

    final values =
        prefs.getStringList(_notesKey) ?? <String>[];

    values.removeWhere(
      (value) {
        try {
          final decoded = jsonDecode(value);

          return decoded is Map &&
              decoded['id']?.toString() == item.id;
        } catch (_) {
          return false;
        }
      },
    );

    await prefs.setStringList(
      _notesKey,
      values,
    );
  }

  // ==========================================================
  // GENERIC PERMANENT DELETE
  // ==========================================================

  static Future<void> _permanentlyDeleteGenericItem(
    TrashItem item,
  ) async {
    /*
     * Feature-specific permanent deletion will be connected
     * once the corresponding storage services are available.
     */
  }

  // ==========================================================
  // REMOVE ONE FROM TRASH
  // ==========================================================

  static Future<void> _removeFromTrash(
    TrashItem item,
  ) async {
    final items = await getItems();

    items.removeWhere(
      (trashItem) =>
          trashItem.id == item.id &&
          trashItem.type == item.type,
    );

    await _saveItems(items);
  }

  // ==========================================================
  // EMPTY TRASH
  // ==========================================================

  static Future<void> emptyTrash() async {
    final items = await getItems();

    if (items.isEmpty) {
      return;
    }

    final failedItems = <TrashItem>[];

    for (final item in items) {
      try {
        await _permanentlyDeleteDataOnly(item);
      } catch (_) {
        failedItems.add(item);
      }
    }

    await _saveItems(failedItems);
  }

  static Future<void> _permanentlyDeleteDataOnly(
    TrashItem item,
  ) async {
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
        await _permanentlyDeleteGenericItem(item);
        break;
    }
  }

  // ==========================================================
  // CLEAN EXPIRED ITEMS
  // ==========================================================

  static Future<void> cleanupExpiredItems() async {
    final items = await getItems();

    if (items.isEmpty) {
      return;
    }

    final activeItems = <TrashItem>[];

    for (final item in items) {
      if (!item.isExpired) {
        activeItems.add(item);
        continue;
      }

      try {
        await _permanentlyDeleteDataOnly(item);
      } catch (_) {
        // Keep failed items so the data is not silently lost.
        activeItems.add(item);
      }
    }

    await _saveItems(activeItems);
  }
}