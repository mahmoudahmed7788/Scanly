import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:go_router/go_router.dart';
import 'package:scanly/Models/Note_Model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotesPage extends StatefulWidget {
  const NotesPage({super.key});

  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  final TextEditingController _searchController =
      TextEditingController();

  final List<NoteModel> _notes = [];

  String _searchText = '';
  bool _isLoading = true;

  static const String _notesKey = 'scanly_notes';

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

  Future<void> _loadNotes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedNotes =
          prefs.getStringList(_notesKey) ?? [];

      final loadedNotes = <NoteModel>[];

      for (final noteString in savedNotes) {
        try {
          final decoded = jsonDecode(noteString);

          if (decoded is Map) {
            loadedNotes.add(
              NoteModel.fromJson(
                Map<String, dynamic>.from(decoded),
              ),
            );
          }
        } catch (_) {}
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

  Future<void> _saveNotes() async {
    final prefs =
        await SharedPreferences.getInstance();

    await prefs.setStringList(
      _notesKey,
      _notes
          .map(
            (note) => jsonEncode(note.toJson()),
          )
          .toList(),
    );
  }

  List<NoteModel> get _filteredNotes {
    final query = _searchText.trim().toLowerCase();

    if (query.isEmpty) {
      return _notes;
    }

    return _notes.where((note) {
      final title =
          note.title.toLowerCase();

      final content =
          _previewText(note).toLowerCase();

      return title.contains(query) ||
          content.contains(query);
    }).toList();
  }

  List<NoteModel> get _pinnedNotes {
    return _filteredNotes
        .where((note) => note.isPinned)
        .toList();
  }

  List<NoteModel> get _allNotes {
    return _filteredNotes
        .where((note) => !note.isPinned)
        .toList();
  }

  Future<void> _createNote() async {
    final result =
        await context.push<NoteModel>(
      '/create-note',
    );

    if (!mounted || result == null) {
      return;
    }

    setState(() {
      _notes.removeWhere(
        (note) => note.id == result.id,
      );

      _notes.add(result);
      _sortNotes(_notes);
    });

    await _saveNotes();
  }

  Future<void> _openNote(
    NoteModel note,
  ) async {
    final result =
        await context.push<NoteModel>(
      '/view-note',
      extra: note,
    );

    if (!mounted || result == null) {
      return;
    }

    final index = _notes.indexWhere(
      (item) => item.id == result.id,
    );

    if (index == -1) return;

    setState(() {
      _notes[index] = result;
      _sortNotes(_notes);
    });

    await _saveNotes();
  }

  Future<void> _editNote(
    NoteModel note,
  ) async {
    final result =
        await context.push<NoteModel>(
      '/create-note',
      extra: note,
    );

    if (!mounted || result == null) {
      return;
    }

    final index = _notes.indexWhere(
      (item) => item.id == result.id,
    );

    if (index == -1) return;

    setState(() {
      _notes[index] = result;
      _sortNotes(_notes);
    });

    await _saveNotes();
  }

  Future<void> _deleteNote(
    NoteModel note,
  ) async {
    final colors =
        Theme.of(context).colorScheme;

    final confirmed =
        await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Delete Note',
            style: TextStyle(
              fontWeight: FontWeight.w700,
            ),
          ),
          content: const Text(
            'Are you sure you want to delete this note?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: colors.primary,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              child: Text(
                'Delete',
                style: TextStyle(
                  color: colors.error,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    setState(() {
      _notes.removeWhere(
        (item) => item.id == note.id,
      );
    });

    await _saveNotes();
  }

  Future<void> _togglePin(
    NoteModel note,
  ) async {
    setState(() {
      note.isPinned = !note.isPinned;
      note.updatedAt = DateTime.now();
      _sortNotes(_notes);
    });

    await _saveNotes();
  }

  @override
  Widget build(BuildContext context) {
    final theme =
        Theme.of(context);

    final colors =
        theme.colorScheme;

    final filteredNotes =
        _filteredNotes;

    return Scaffold(
      backgroundColor:
          theme.scaffoldBackgroundColor,

      appBar: AppBar(
        elevation: 0,
        backgroundColor:
            theme.scaffoldBackgroundColor,
        surfaceTintColor:
            Colors.transparent,

        leading: IconButton(
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
          icon: const Icon(
            Icons.arrow_back_rounded,
          ),
        ),

        title: const Text(
          'My Notes',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
        ),

        actions: [
          IconButton(
            onPressed: _createNote,
            icon: Icon(
              Icons.add_rounded,
              color: colors.primary,
              size: 30,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),

      floatingActionButton:
          FloatingActionButton.extended(
        onPressed: _createNote,
        backgroundColor: colors.primary,
        foregroundColor: colors.onPrimary,
        icon: const Icon(
          Icons.add_rounded,
        ),
        label: const Text(
          'New Note',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      body: SafeArea(
        child: _isLoading
            ? Center(
                child:
                    CircularProgressIndicator(
                  color: colors.primary,
                ),
              )
            : filteredNotes.isEmpty
                ? _buildEmptyState()
                : SingleChildScrollView(
                    padding:
                        const EdgeInsets.fromLTRB(
                      20,
                      10,
                      20,
                      100,
                    ),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        _buildSearch(),

                        if (_pinnedNotes
                            .isNotEmpty) ...[
                          const SizedBox(
                            height: 24,
                          ),
                          _buildSectionTitle(
                            'Pinned',
                            Icons
                                .push_pin_rounded,
                          ),
                          const SizedBox(
                            height: 12,
                          ),
                          _buildPinnedNotes(),
                        ],

                        if (_allNotes
                            .isNotEmpty) ...[
                          const SizedBox(
                            height: 28,
                          ),
                          _buildSectionTitle(
                            'All Notes',
                            Icons.notes_rounded,
                          ),
                          const SizedBox(
                            height: 12,
                          ),
                          ..._allNotes.map(
                            _buildNoteCard,
                          ),
                        ],
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildSearch() {
    final theme =
        Theme.of(context);

    final colors =
        theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius:
            BorderRadius.circular(16),
        border: Border.all(
          color: colors.outline.withValues(
            alpha: .10,
          ),
        ),
      ),
      child: TextField(
        controller:
            _searchController,
        onChanged: (value) {
          setState(() {
            _searchText = value;
          });
        },
        decoration: InputDecoration(
          hintText: 'Search notes...',
          prefixIcon: Icon(
            Icons.search_rounded,
            color: colors.primary,
          ),
          suffixIcon:
              _searchText.isNotEmpty
                  ? IconButton(
                      onPressed: () {
                        _searchController
                            .clear();

                        setState(() {
                          _searchText = '';
                        });
                      },
                      icon: const Icon(
                        Icons.close_rounded,
                      ),
                    )
                  : null,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(
    String title,
    IconData icon,
  ) {
    final colors =
        Theme.of(context)
            .colorScheme;

    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: colors.primary,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildPinnedNotes() {
    return SizedBox(
      height: 170,
      child: ListView.separated(
        scrollDirection:
            Axis.horizontal,
        itemCount:
            _pinnedNotes.length,
        separatorBuilder:
            (_, __) =>
                const SizedBox(width: 12),
        itemBuilder:
            (context, index) {
          final note =
              _pinnedNotes[index];

          return GestureDetector(
            onTap: () =>
                _openNote(note),
            child: _buildNoteVisualCard(
              note,
              width: 235,
              pinned: true,
            ),
          );
        },
      ),
    );
  }

  Widget _buildNoteVisualCard(
    NoteModel note, {
    double? width,
    bool pinned = false,
  }) {
    final theme =
        Theme.of(context);

    final colors =
        theme.colorScheme;

    final noteColor =
        Color(note.colorValue);

    final dark =
        ThemeData.estimateBrightnessForColor(
              noteColor,
            ) ==
            Brightness.dark;

    final primaryText =
        dark
            ? Colors.white
            : const Color(0xFF24213D);

    final secondaryText =
        dark
            ? Colors.white70
            : const Color(0xFF69647E);

    return Container(
      width: width,
      padding:
          const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: noteColor,
        borderRadius:
            BorderRadius.circular(20),
        border: Border.all(
          color: colors.outline
              .withValues(alpha: .10),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  note.title.isEmpty
                      ? 'Untitled Note'
                      : note.title,
                  maxLines: 1,
                  overflow:
                      TextOverflow.ellipsis,
                  style: TextStyle(
                    color: primaryText,
                    fontSize: 16,
                    fontWeight:
                        FontWeight.w700,
                  ),
                ),
              ),
              if (pinned)
                Icon(
                  Icons.push_pin_rounded,
                  size: 18,
                  color: primaryText,
                ),
            ],
          ),

          const SizedBox(height: 10),

          Expanded(
            child: Text(
              _previewText(note),
              maxLines: 3,
              overflow:
                  TextOverflow.ellipsis,
              style: TextStyle(
                color: secondaryText,
                height: 1.4,
              ),
            ),
          ),

          const SizedBox(height: 8),

          _buildDate(
            note.updatedAt,
            color: secondaryText,
          ),
        ],
      ),
    );
  }

  Widget _buildNoteCard(
    NoteModel note,
  ) {
    final theme =
        Theme.of(context);

    final colors =
        theme.colorScheme;

    final noteColor =
        Color(note.colorValue);

    final dark =
        ThemeData.estimateBrightnessForColor(
              noteColor,
            ) ==
            Brightness.dark;

    final primaryText =
        dark
            ? Colors.white
            : const Color(0xFF24213D);

    final secondaryText =
        dark
            ? Colors.white70
            : const Color(0xFF69647E);

    return Dismissible(
      key: ValueKey(note.id),
      direction:
          DismissDirection.endToStart,

      background: Container(
        margin:
            const EdgeInsets.only(
          bottom: 12,
        ),
        padding:
            const EdgeInsets.only(
          right: 20,
        ),
        alignment:
            Alignment.centerRight,
        decoration: BoxDecoration(
          color: colors.error,
          borderRadius:
              BorderRadius.circular(18),
        ),
        child: const Icon(
          Icons.delete_outline_rounded,
          color: Colors.white,
        ),
      ),

      onDismissed: (_) async {
        setState(() {
          _notes.removeWhere(
            (item) =>
                item.id == note.id,
          );
        });

        await _saveNotes();
      },

      child: GestureDetector(
        onTap: () =>
            _openNote(note),

        child: Container(
          margin:
              const EdgeInsets.only(
            bottom: 12,
          ),
          padding:
              const EdgeInsets.all(16),

          decoration: BoxDecoration(
            color: noteColor,
            borderRadius:
                BorderRadius.circular(18),
            border: Border.all(
              color: colors.outline
                  .withValues(alpha: .08),
            ),
          ),

          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: primaryText
                      .withValues(alpha: .10),
                  borderRadius:
                      BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.note_alt_outlined,
                  color: primaryText,
                  size: 23,
                ),
              ),

              const SizedBox(width: 13),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            note.title.isEmpty
                                ? 'Untitled Note'
                                : note.title,
                            maxLines: 1,
                            overflow:
                                TextOverflow.ellipsis,
                            style: TextStyle(
                              color:
                                  primaryText,
                              fontSize: 16,
                              fontWeight:
                                  FontWeight.w700,
                            ),
                          ),
                        ),

                        if (note.isPinned)
                          Padding(
                            padding:
                                const EdgeInsets
                                    .only(
                              left: 8,
                            ),
                            child: Icon(
                              Icons
                                  .push_pin_rounded,
                              size: 18,
                              color:
                                  primaryText,
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 5),

                    Text(
                      _previewText(note),
                      maxLines: 2,
                      overflow:
                          TextOverflow.ellipsis,
                      style: TextStyle(
                        color:
                            secondaryText,
                        height: 1.35,
                      ),
                    ),

                    const SizedBox(height: 9),

                    Row(
                      children: [
                        _buildDate(
                          note.updatedAt,
                          color:
                              secondaryText,
                        ),

                        if (note.imagePaths
                            .isNotEmpty) ...[
                          const SizedBox(
                            width: 10,
                          ),
                          Icon(
                            Icons
                                .image_outlined,
                            size: 16,
                            color:
                                secondaryText,
                          ),
                        ],

                        if (note.pdfs
                            .isNotEmpty) ...[
                          const SizedBox(
                            width: 8,
                          ),
                          Icon(
                            Icons
                                .picture_as_pdf_outlined,
                            size: 16,
                            color:
                                secondaryText,
                          ),
                        ],

                        if (note.pages.length >
                            1) ...[
                          const SizedBox(
                            width: 8,
                          ),
                          Text(
                            '${note.pages.length} pages',
                            style: TextStyle(
                              fontSize: 11,
                              color:
                                  secondaryText,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_vert_rounded,
                  color: primaryText,
                ),

                onSelected: (value) {
                  switch (value) {
                    case 'edit':
                      _editNote(note);
                      break;

                    case 'pin':
                      _togglePin(note);
                      break;

                    case 'delete':
                      _deleteNote(note);
                      break;
                  }
                },

                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(
                          Icons
                              .edit_outlined,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text('Edit'),
                      ],
                    ),
                  ),

                  PopupMenuItem(
                    value: 'pin',
                    child: Row(
                      children: [
                        Icon(
                          note.isPinned
                              ? Icons
                                  .push_pin_outlined
                              : Icons
                                  .push_pin_rounded,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          note.isPinned
                              ? 'Unpin'
                              : 'Pin',
                        ),
                      ],
                    ),
                  ),

                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(
                          Icons
                              .delete_outline_rounded,
                          size: 20,
                          color:
                              colors.error,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Delete',
                          style: TextStyle(
                            color:
                                colors.error,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDate(
    DateTime date, {
    Color? color,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.schedule_rounded,
          size: 14,
          color: color,
        ),
        const SizedBox(width: 4),
        Text(
          _formatDate(date),
          style: TextStyle(
            fontSize: 11,
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final hour = date.hour % 12 == 0
        ? 12
        : date.hour % 12;

    final minute =
        date.minute.toString().padLeft(
              2,
              '0',
            );

    final period =
        date.hour >= 12 ? 'PM' : 'AM';

    return '${date.day}/${date.month}/${date.year} • '
        '$hour:$minute $period';
  }

  String _previewText(
    NoteModel note,
  ) {
    List<dynamic> data =
        note.quillData;

    if (data.isEmpty &&
        note.pages.isNotEmpty) {
      data =
          note.pages.first.quillData;
    }

    if (data.isEmpty) {
      return 'No content';
    }

    try {
      final document =
          Document.fromJson(
        List<dynamic>.from(data),
      );

      final text =
          document.toPlainText().trim();

      return text.isEmpty
          ? 'No content'
          : text;
    } catch (_) {
      return 'Tap to open this note';
    }
  }

  Widget _buildEmptyState() {
    final colors =
        Theme.of(context)
            .colorScheme;

    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: colors.primary
                    .withValues(
                  alpha: .08,
                ),
                borderRadius:
                    BorderRadius.circular(
                  28,
                ),
              ),
              child: Icon(
                Icons
                    .note_alt_outlined,
                size: 50,
                color:
                    colors.primary,
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              'No Notes Yet',
              style: TextStyle(
                fontSize: 22,
                fontWeight:
                    FontWeight.w700,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              'Create your first note and keep everything organized.',
              textAlign:
                  TextAlign.center,
              style: TextStyle(
                color: colors.onSurface
                    .withValues(
                  alpha: .60,
                ),
                height: 1.5,
              ),
            ),

            const SizedBox(height: 25),

            ElevatedButton.icon(
              onPressed: _createNote,
              icon: const Icon(
                Icons.add_rounded,
              ),
              label: const Text(
                'Create Note',
              ),
              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    colors.primary,
                foregroundColor:
                    colors.onPrimary,
                padding:
                    const EdgeInsets
                        .symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(
                    14,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}