import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:scanly/Core/DocumentStorage.dart';
import 'package:scanly/Core/Scanly_Items.dart';
import 'package:scanly/Models/DocumentModel.dart';
import 'package:scanly/Models/Note_Model.dart';
import 'package:scanly/Pages/Pdf/PDFPreviewPage.dart';
import 'package:scanly/Pages/QR/QRPreviewPage.dart';
import 'package:scanly/core/ScanlyActivityService.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ScanlyItemOpener {
  static const String _legacyNotesKey =
      'scanly_notes';

  static String? get _notesKey {
    final uid =
        FirebaseAuth.instance.currentUser?.uid;

    if (uid == null || uid.isEmpty) {
      return null;
    }

    return 'scanly_notes_$uid';
  }

  static Future<void> _migrateLegacyNotes(
    SharedPreferences prefs,
    String key,
  ) async {
    if (prefs.containsKey(key)) {
      return;
    }

    if (!prefs.containsKey(_legacyNotesKey)) {
      return;
    }

    final oldNotes =
        prefs.getStringList(_legacyNotesKey);

    if (oldNotes != null &&
        oldNotes.isNotEmpty) {
      await prefs.setStringList(
        key,
        oldNotes,
      );
    }

    await prefs.remove(
      _legacyNotesKey,
    );
  }

  static Future<void> open(
    BuildContext context,
    ScanlyItem item,
  ) async {
    if (item.type == 'note') {
      await _openNote(
        context,
        item,
      );

      return;
    }

    await ScanlyActivityService.addRecent(
      item,
    );

    if (!context.mounted) {
      return;
    }

    if (item.type == 'qr') {
      final value = item.data;

      if (value == null || value.isEmpty) {
        _showMessage(
          context,
          'QR Code data is not available',
        );

        return;
      }

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => QRPreviewPage(
            value: value,
          ),
        ),
      );

      return;
    }

    if (item.type == 'pdf') {
      await _openPdf(
        context,
        item,
      );

      return;
    }

    if (item.route.isNotEmpty) {
      await context.push(
        item.route,
        extra: item.data,
      );
    }
  }

  static Future<void> _openNote(
    BuildContext context,
    ScanlyItem item,
  ) async {
    final note =
        await _findNote(item);

    if (!context.mounted) {
      return;
    }

    if (note == null) {
      _showMessage(
        context,
        'Note not found',
      );

      return;
    }

    final updatedItem = ScanlyItem(
      id: 'note_${note.id}',
      title: note.title.isEmpty
          ? 'Untitled Note'
          : note.title,
      subtitle: _previewText(note),
      type: 'note',
      route: '/view-note',
      data: note.id,
      createdAt:
          note.updatedAt.millisecondsSinceEpoch,
    );

    await ScanlyActivityService.addRecent(
      updatedItem,
    );

    if (!context.mounted) {
      return;
    }

    final result =
        await context.push<NoteModel>(
      '/view-note',
      extra: note,
    );

    if (!context.mounted ||
        result == null) {
      return;
    }

    await _saveUpdatedNote(
      result,
    );
  }

  static Future<NoteModel?> _findNote(
    ScanlyItem item,
  ) async {
    final key = _notesKey;

    if (key == null) {
      return null;
    }

    final prefs =
        await SharedPreferences.getInstance();

    await _migrateLegacyNotes(
      prefs,
      key,
    );

    final savedNotes =
        prefs.getStringList(key) ?? [];

    String? noteId;

    if (item.data != null &&
        item.data!.isNotEmpty) {
      noteId = item.data;
    }

    if (noteId != null) {
      final directId = noteId.startsWith(
        'note_',
      )
          ? noteId.substring(5)
          : noteId;

      for (final noteString in savedNotes) {
        try {
          final decoded =
              jsonDecode(noteString);

          if (decoded is! Map) {
            continue;
          }

          final note =
              NoteModel.fromJson(
            Map<String, dynamic>.from(
              decoded,
            ),
          );

          if (note.id == directId) {
            return note;
          }
        } catch (_) {}
      }
    }

    if (item.data != null &&
        item.data!.isNotEmpty) {
      try {
        final decoded =
            jsonDecode(item.data!);

        if (decoded is Map) {
          final oldNote =
              NoteModel.fromJson(
            Map<String, dynamic>.from(
              decoded,
            ),
          );

          for (final noteString in savedNotes) {
            try {
              final currentDecoded =
                  jsonDecode(noteString);

              if (currentDecoded is! Map) {
                continue;
              }

              final currentNote =
                  NoteModel.fromJson(
                Map<String, dynamic>.from(
                  currentDecoded,
                ),
              );

              if (currentNote.id ==
                  oldNote.id) {
                return currentNote;
              }
            } catch (_) {}
          }

          return oldNote;
        }
      } catch (_) {}
    }

    return null;
  }

  static Future<void> _saveUpdatedNote(
    NoteModel note,
  ) async {
    final key = _notesKey;

    if (key == null) {
      return;
    }

    final prefs =
        await SharedPreferences.getInstance();

    await _migrateLegacyNotes(
      prefs,
      key,
    );

    final savedNotes =
        prefs.getStringList(key) ?? [];

    final updatedNotes = <String>[];

    bool found = false;

    for (final noteString in savedNotes) {
      try {
        final decoded =
            jsonDecode(noteString);

        if (decoded is! Map) {
          continue;
        }

        final currentNote =
            NoteModel.fromJson(
          Map<String, dynamic>.from(
            decoded,
          ),
        );

        if (currentNote.id == note.id) {
          updatedNotes.add(
            jsonEncode(
              note.toJson(),
            ),
          );

          found = true;
        } else {
          updatedNotes.add(
            jsonEncode(
              currentNote.toJson(),
            ),
          );
        }
      } catch (_) {}
    }

    if (!found) {
      updatedNotes.add(
        jsonEncode(
          note.toJson(),
        ),
      );
    }

    await prefs.setStringList(
      key,
      updatedNotes,
    );

    final item = ScanlyItem(
      id: 'note_${note.id}',
      title: note.title.isEmpty
          ? 'Untitled Note'
          : note.title,
      subtitle: _previewText(note),
      type: 'note',
      route: '/view-note',
      data: note.id,
      createdAt:
          note.updatedAt.millisecondsSinceEpoch,
    );

    if (ScanlyActivityService.isFavorite(
      item.id,
    )) {
      await ScanlyActivityService.addFavorite(
        item,
      );
    }

    if (ScanlyActivityService.isRecent(
      item.id,
    )) {
      await ScanlyActivityService.addRecent(
        item,
      );
    }
  }

  static Future<void> _openPdf(
    BuildContext context,
    ScanlyItem item,
  ) async {
    final path = item.data;

    if (path == null || path.isEmpty) {
      _showMessage(
        context,
        'PDF file path is not available',
      );

      return;
    }

    try {
      final file = File(path);

      if (!await file.exists()) {
        _showMessage(
          context,
          'PDF file no longer exists',
        );

        return;
      }

      final bytes =
          await file.readAsBytes();

      if (!context.mounted) {
        return;
      }

      DocumentModel? document;

      final documents =
          DocumentStorage.getDocuments();

      for (final currentDocument in documents) {
        if (currentDocument.filePath ==
            path) {
          document = currentDocument;
          break;
        }
      }

      document ??= DocumentModel(
        id: item.id,
        title: _fileNameFromPath(path),
        date:
            DateTime.now().toIso8601String(),
        type: 'pdf',
        filePath: path,
        isFavorite: false,
        lastOpened:
            DateTime.now().toIso8601String(),
      );

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PDFPreviewPage(
            document: document!,
            pdfBytes: bytes,
            fileName:
                _fileNameFromPath(path),
          ),
        ),
      );
    } catch (e) {
      debugPrint(
        'OPEN PDF ERROR: $e',
      );

      if (!context.mounted) {
        return;
      }

      _showMessage(
        context,
        'Could not open PDF',
      );
    }
  }

  static String _previewText(
    NoteModel note,
  ) {
    if (note.quillData.isEmpty) {
      return 'No content';
    }

    return 'Tap to open this note';
  }

  static String _fileNameFromPath(
    String path,
  ) {
    final normalizedPath =
        path.replaceAll('\\', '/');

    final parts =
        normalizedPath.split('/');

    if (parts.isEmpty) {
      return 'Scanly_Document.pdf';
    }

    final name = parts.last;

    if (name.isEmpty) {
      return 'Scanly_Document.pdf';
    }

    return name;
  }

  static void _showMessage(
    BuildContext context,
    String message,
  ) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior:
              SnackBarBehavior.floating,
        ),
      );
  }
}