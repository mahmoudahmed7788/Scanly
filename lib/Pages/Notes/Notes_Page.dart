import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:go_router/go_router.dart';
import 'package:scanly/Models/Note_Model.dart';
import 'package:scanly/Widgets/Notes/NoteCard.dart';
import 'package:scanly/Widgets/Notes/NoteShareSheet.dart';
import 'package:scanly/Widgets/Notes/NoteVisualCard.dart';
import 'package:scanly/Widgets/Notes/NotesEmptyState.dart';
import 'package:scanly/Widgets/Notes/NotesSearch.dart';
import 'package:scanly/Widgets/Notes/NotesSectionTitle.dart';
import 'package:scanly/Widgets/Notes/PinnedNotesList.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotesPage extends StatefulWidget {
  const NotesPage({super.key});

  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  final TextEditingController _searchController = TextEditingController();

  final List<NoteModel> _notes = [];

  static const String _notesKey = 'scanly_notes';

  String _searchText = '';

  bool _isLoading = true;

  // ============================================================
  // LIFECYCLE
  // ============================================================

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ============================================================
  // LOAD NOTES
  // ============================================================

  Future<void> _loadNotes() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final savedNotes = prefs.getStringList(_notesKey) ?? [];

      final loadedNotes = <NoteModel>[];

      for (final noteString in savedNotes) {
        try {
          final decoded = jsonDecode(noteString);

          if (decoded is Map) {
            loadedNotes.add(
              NoteModel.fromJson(Map<String, dynamic>.from(decoded)),
            );
          }
        } catch (_) {
          // Ignore invalid notes.
        }
      }

      _sortNotes(loadedNotes);

      if (!mounted) return;

      setState(() {
        _notes
          ..clear()
          ..addAll(loadedNotes);

        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });
    }
  }

  // ============================================================
  // SAVE NOTES
  // ============================================================

  Future<void> _saveNotes() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setStringList(
      _notesKey,
      _notes.map((note) => jsonEncode(note.toJson())).toList(),
    );
  }

  // ============================================================
  // SORT
  // ============================================================

  void _sortNotes(List<NoteModel> notes) {
    notes.sort((a, b) {
      if (a.isPinned && !b.isPinned) {
        return -1;
      }

      if (!a.isPinned && b.isPinned) {
        return 1;
      }

      return b.updatedAt.compareTo(a.updatedAt);
    });
  }

  // ============================================================
  // FILTER
  // ============================================================

  List<NoteModel> get _filteredNotes {
    final query = _searchText.trim().toLowerCase();

    if (query.isEmpty) {
      return List<NoteModel>.from(_notes);
    }

    return _notes.where((note) {
      final title = note.title.toLowerCase();

      final content = _previewText(note).toLowerCase();

      return title.contains(query) || content.contains(query);
    }).toList();
  }

  List<NoteModel> get _pinnedNotes {
    return _filteredNotes.where((note) => note.isPinned).toList();
  }

  List<NoteModel> get _allNotes {
    return _filteredNotes.where((note) => !note.isPinned).toList();
  }

  // ============================================================
  // CREATE NOTE
  // ============================================================

  Future<void> _createNote() async {
    final result = await context.push<NoteModel>('/create-note');

    if (!mounted || result == null) {
      return;
    }

    setState(() {
      _notes.removeWhere((note) => note.id == result.id);

      _notes.add(result);

      _sortNotes(_notes);
    });

    await _saveNotes();
  }

  // ============================================================
  // OPEN NOTE
  // ============================================================

  Future<void> _openNote(NoteModel note) async {
    final result = await context.push<NoteModel>('/view-note', extra: note);

    if (!mounted || result == null) {
      return;
    }

    final index = _notes.indexWhere((item) => item.id == result.id);

    if (index == -1) {
      return;
    }

    setState(() {
      _notes[index] = result;

      _sortNotes(_notes);
    });

    await _saveNotes();
  }

  // ============================================================
  // EDIT NOTE
  // ============================================================

  Future<void> _editNote(NoteModel note) async {
    final result = await context.push<NoteModel>('/create-note', extra: note);

    if (!mounted || result == null) {
      return;
    }

    final index = _notes.indexWhere((item) => item.id == result.id);

    if (index == -1) {
      return;
    }

    setState(() {
      _notes[index] = result;

      _sortNotes(_notes);
    });

    await _saveNotes();
  }

  // ============================================================
  // SHARE NOTE
  // ============================================================

  void _shareNote(NoteModel note) {
    NoteShareSheet.show(context, note);
  }

  // ============================================================
  // DELETE NOTE
  // ============================================================

  Future<void> _deleteNote(NoteModel note) async {
    final colors = Theme.of(context).colorScheme;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Delete Note',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          content: const Text('Are you sure you want to delete this note?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: Text('Cancel', style: TextStyle(color: colors.primary)),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: Text('Delete', style: TextStyle(color: colors.error)),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    setState(() {
      _notes.removeWhere((item) => item.id == note.id);
    });

    await _saveNotes();
  }

  // ============================================================
  // PIN
  // ============================================================

  Future<void> _togglePin(NoteModel note) async {
    setState(() {
      note.isPinned = !note.isPinned;

      note.updatedAt = DateTime.now();

      _sortNotes(_notes);
    });

    await _saveNotes();
  }

  // ============================================================
  // SEARCH
  // ============================================================

  void _onSearchChanged(String value) {
    setState(() {
      _searchText = value;
    });
  }

  void _clearSearch() {
    _searchController.clear();

    setState(() {
      _searchText = '';
    });
  }

  // ============================================================
  // PREVIEW TEXT
  // ============================================================

  String _previewText(NoteModel note) {
    List<dynamic> data = note.quillData;

    if (data.isEmpty && note.pages.isNotEmpty) {
      data = note.pages.first.quillData;
    }

    if (data.isEmpty) {
      return 'No content';
    }

    try {
      final document = Document.fromJson(List<dynamic>.from(data));

      final text = document.toPlainText().trim();

      return text.isEmpty ? 'No content' : text;
    } catch (_) {
      return 'Tap to open this note';
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final colors = theme.colorScheme;

    final filteredNotes = _filteredNotes;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,

      appBar: AppBar(
        elevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
        surfaceTintColor: Colors.transparent,

        leading: IconButton(
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
          icon: const Icon(Icons.arrow_back_rounded),
        ),

        title: const Text(
          'My Notes',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
        ),

        actions: [
          IconButton(
            onPressed: _createNote,
            icon: Icon(Icons.add_rounded, color: colors.primary, size: 30),
          ),
          const SizedBox(width: 8),
        ],
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createNote,
        backgroundColor: colors.primary,
        foregroundColor: colors.onPrimary,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'New Note',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),

      body: SafeArea(
        child: _isLoading
            ? Center(child: CircularProgressIndicator(color: colors.primary))
            : filteredNotes.isEmpty
            ? NotesEmptyState(
                searchText: _searchText,
                onClearSearch: _clearSearch,
                onCreateNote: _createNote, onCreate: () {  },
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    NotesSearch(
                      controller: _searchController,
                      searchText: _searchText,
                      onChanged: _onSearchChanged,
                      onClear: _clearSearch,
                    ),

                    if (_pinnedNotes.isNotEmpty) ...[
                      const SizedBox(height: 24),

                      const NotesSectionTitle(
                        title: 'Pinned',
                        icon: Icons.push_pin_rounded,
                      ),

                      const SizedBox(height: 12),

                      PinnedNotesList(
                        notes: _pinnedNotes,
                        previewText: _previewText,
                        onOpen: _openNote,
                        onShare: _shareNote,
                      ),
                    ],

                    if (_allNotes.isNotEmpty) ...[
                      const SizedBox(height: 28),

                      const NotesSectionTitle(
                        title: 'All Notes',
                        icon: Icons.notes_rounded,
                      ),

                      const SizedBox(height: 12),

                      ..._allNotes.map((note) {
                        return NoteCard(
                          note: note,
                          previewText: _previewText,
                          onOpen: _openNote,
                          onEdit: () => _editNote(note),
                          onPin: _togglePin,
                          onShare: () => _shareNote(note),
                          onDelete: () => _deleteNote(note),
                          onTap: () => _openNote(note),
                          onTogglePin: () => _togglePin(note),
                          onSwipeDelete: () async {
                            await _deleteNote(note);
                            return true;
                          },
                        );
                      }),
                    ],
                  ],
                ),
              ),
      ),
    );
  }
}
