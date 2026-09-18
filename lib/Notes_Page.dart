import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:go_router/go_router.dart';
import 'package:scanly/Note_Model.dart';
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
          final json = jsonDecode(noteString);

          if (json is Map) {
            loadedNotes.add(
              NoteModel.fromJson(
                Map<String, dynamic>.from(json),
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

    final notes = _notes
        .map(
          (note) => jsonEncode(note.toJson()),
        )
        .toList();

    await prefs.setStringList(
      _notesKey,
      notes,
    );
  }

  List<NoteModel> get _filteredNotes {
    if (_searchText.trim().isEmpty) {
      return _notes;
    }

    final query = _searchText.toLowerCase();

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

    if (index == -1) {
      return;
    }

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

    if (index == -1) {
      return;
    }

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
          backgroundColor:
              colors.surface,

          title: Text(
            'Delete Note',
            style: TextStyle(
              color: colors.onSurface,
              fontWeight:
                  FontWeight.bold,
            ),
          ),

          content: Text(
            'Are you sure you want to delete this note?',
            style: TextStyle(
              color: colors.onSurface
                  .withOpacity(0.70),
            ),
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop(false);
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
                Navigator.of(
                  dialogContext,
                ).pop(true);
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

    if (confirmed != true ||
        !mounted) {
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
      note.isPinned =
          !note.isPinned;

      note.updatedAt =
          DateTime.now();

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
        backgroundColor:
            theme.scaffoldBackgroundColor,

        foregroundColor:
            colors.onSurface,

        elevation: 0,

        leading: IconButton(
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },

          icon: Icon(
            Icons.arrow_back_rounded,
            color: colors.onSurface,
          ),
        ),

        title: Text(
          'My Notes',
          style: TextStyle(
            fontSize: 24,
            fontWeight:
                FontWeight.bold,
            color:
                colors.onSurface,
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

        backgroundColor:
            colors.primary,

        foregroundColor:
            colors.onPrimary,

        icon: const Icon(
          Icons.add_rounded,
        ),

        label: const Text(
          'New Note',
          style: TextStyle(
            fontWeight:
                FontWeight.bold,
          ),
        ),
      ),

      body: SafeArea(
        child: _isLoading
            ? Center(
                child:
                    CircularProgressIndicator(
                  color:
                      colors.primary,
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
      decoration:
          BoxDecoration(
        color: colors.surface,

        borderRadius:
            BorderRadius.circular(16),

        boxShadow: [
          BoxShadow(
            color: colors.onSurface
                .withOpacity(
              theme.brightness ==
                      Brightness.dark
                  ? 0.18
                  : 0.04,
            ),

            blurRadius: 12,

            offset:
                const Offset(0, 4),
          ),
        ],
      ),

      child: TextField(
        controller:
            _searchController,

        onChanged: (value) {
          setState(() {
            _searchText = value;
          });
        },

        style: TextStyle(
          color: colors.onSurface,
        ),

        decoration:
            InputDecoration(
          hintText:
              'Search notes...',

          hintStyle: TextStyle(
            color: colors.onSurface
                .withOpacity(0.50),
          ),

          prefixIcon: Icon(
            Icons.search_rounded,
            color:
                colors.primary,
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

                      icon: Icon(
                        Icons
                            .close_rounded,
                        color: colors
                            .onSurface
                            .withOpacity(
                          0.60,
                        ),
                      ),
                    )
                  : null,

          border:
              InputBorder.none,

          contentPadding:
              const EdgeInsets
                  .symmetric(
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
          color:
              colors.primary,
        ),

        const SizedBox(
          width: 8,
        ),

        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight:
                FontWeight.bold,
            color:
                colors.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildPinnedNotes() {
    final theme =
        Theme.of(context);

    final colors =
        theme.colorScheme;

    return SizedBox(
      height: 155,

      child: ListView.separated(
        scrollDirection:
            Axis.horizontal,

        itemCount:
            _pinnedNotes.length,

        separatorBuilder:
            (_, __) =>
                const SizedBox(
          width: 12,
        ),

        itemBuilder:
            (context, index) {
          final note =
              _pinnedNotes[index];

          return GestureDetector(
            onTap: () =>
                _openNote(note),

            child: Container(
              width: 230,

              padding:
                  const EdgeInsets.all(
                16,
              ),

              decoration:
                  BoxDecoration(
                color:
                    Color(note.colorValue),

                borderRadius:
                    BorderRadius.circular(
                  20,
                ),

                border: Border.all(
                  color: colors.primary
                      .withOpacity(.25),

                  width: 1.2,
                ),
              ),

              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment
                        .start,

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
                              TextOverflow
                                  .ellipsis,

                          style: TextStyle(
                            fontSize: 16,
                            fontWeight:
                                FontWeight.bold,

                            color:
                                _noteTextColor(
                              note.colorValue,
                              context,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(
                        width: 8,
                      ),

                      Container(
                        padding:
                            const EdgeInsets
                                .all(6),

                        decoration:
                            BoxDecoration(
                          color: colors
                              .primary
                              .withOpacity(
                            .12,
                          ),

                          shape:
                              BoxShape.circle,
                        ),

                        child: Icon(
                          Icons
                              .push_pin_rounded,

                          size: 17,

                          color:
                              colors.primary,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(
                    height: 12,
                  ),

                  Text(
                    _previewText(note),

                    maxLines: 3,

                    overflow:
                        TextOverflow
                            .ellipsis,

                    style: TextStyle(
                      color:
                          _noteSecondaryTextColor(
                        note.colorValue,
                        context,
                      ),

                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
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

    return Dismissible(
      key: ValueKey(note.id),

      direction:
          DismissDirection
              .endToStart,

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

        decoration:
            BoxDecoration(
          color: colors.error,

          borderRadius:
              BorderRadius.circular(
            18,
          ),
        ),

        child: const Icon(
          Icons
              .delete_outline_rounded,

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
              const EdgeInsets.all(
            16,
          ),

          decoration:
              BoxDecoration(
            color:
                Color(note.colorValue),

            borderRadius:
                BorderRadius.circular(
              18,
            ),

            boxShadow: [
              BoxShadow(
                color: colors
                    .onSurface
                    .withOpacity(
                  theme.brightness ==
                          Brightness.dark
                      ? .18
                      : .03,
                ),

                blurRadius: 10,

                offset:
                    const Offset(0, 3),
              ),
            ],
          ),

          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,

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
                                TextOverflow
                                    .ellipsis,

                            style: TextStyle(
                              fontSize: 16,
                              fontWeight:
                                  FontWeight.bold,

                              color:
                                  _noteTextColor(
                                note.colorValue,
                                context,
                              ),
                            ),
                          ),
                        ),

                        if (note
                            .isPinned) ...[
                          const SizedBox(
                            width: 8,
                          ),

                          Icon(
                            Icons
                                .push_pin_rounded,

                            size: 18,

                            color:
                                colors.primary,
                          ),
                        ],
                      ],
                    ),

                    const SizedBox(
                      height: 7,
                    ),

                    Text(
                      _previewText(note),

                      maxLines: 2,

                      overflow:
                          TextOverflow
                              .ellipsis,

                      style: TextStyle(
                        color:
                            _noteSecondaryTextColor(
                          note.colorValue,
                          context,
                        ),

                        height: 1.4,
                      ),
                    ),

                    const SizedBox(
                      height: 10,
                    ),

                    Row(
                      children: [
                        if (note
                            .imagePaths
                            .isNotEmpty)
                          Icon(
                            Icons
                                .image_outlined,

                            size: 17,

                            color:
                                _noteSecondaryTextColor(
                              note.colorValue,
                              context,
                            ),
                          ),

                        if (note.pdfs
                            .isNotEmpty) ...[
                          const SizedBox(
                            width: 8,
                          ),

                          Icon(
                            Icons
                                .picture_as_pdf_outlined,

                            size: 17,

                            color:
                                _noteSecondaryTextColor(
                              note.colorValue,
                              context,
                            ),
                          ),
                        ],

                        if (note.pages
                                .length >
                            1) ...[
                          const SizedBox(
                            width: 8,
                          ),

                          Icon(
                            Icons
                                .auto_stories_outlined,

                            size: 17,

                            color:
                                _noteSecondaryTextColor(
                              note.colorValue,
                              context,
                            ),
                          ),

                          const SizedBox(
                            width: 3,
                          ),

                          Text(
                            '${note.pages.length} pages',

                            style:
                                TextStyle(
                              fontSize: 12,

                              color:
                                  _noteSecondaryTextColor(
                                note.colorValue,
                                context,
                              ),
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
                  Icons.more_vert,
                  color:
                      _noteTextColor(
                    note.colorValue,
                    context,
                  ),
                ),

                onSelected: (value) {
                  if (value ==
                      'edit') {
                    _editNote(note);
                  } else if (value ==
                      'pin') {
                    _togglePin(note);
                  } else if (value ==
                      'delete') {
                    _deleteNote(note);
                  }
                },

                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'edit',

                    child: Row(
                      children: [
                        Icon(
                          Icons
                              .edit_outlined,

                          size: 20,

                          color: colors
                              .onSurface,
                        ),

                        const SizedBox(
                          width: 8,
                        ),

                        Text(
                          'Edit',
                          style: TextStyle(
                            color: colors
                                .onSurface,
                          ),
                        ),
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

                          color: colors
                              .onSurface,
                        ),

                        const SizedBox(
                          width: 8,
                        ),

                        Text(
                          note.isPinned
                              ? 'Unpin'
                              : 'Pin',

                          style: TextStyle(
                            color: colors
                                .onSurface,
                          ),
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

                        const SizedBox(
                          width: 8,
                        ),

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

      if (text.isEmpty) {
        return 'No content';
      }

      return text;
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
              padding:
                  const EdgeInsets.all(
                25,
              ),

              decoration:
                  BoxDecoration(
                color: colors.primary
                    .withOpacity(.1),

                shape:
                    BoxShape.circle,
              ),

              child: Icon(
                Icons
                    .note_alt_outlined,

                size: 55,

                color:
                    colors.primary,
              ),
            ),

            const SizedBox(
              height: 20,
            ),

            Text(
              'No Notes Yet',

              style: TextStyle(
                fontSize: 22,
                fontWeight:
                    FontWeight.bold,
                color:
                    colors.onSurface,
              ),
            ),

            const SizedBox(
              height: 8,
            ),

            Text(
              'Create your first note and keep everything organized.',

              textAlign:
                  TextAlign.center,

              style: TextStyle(
                color: colors.onSurface
                    .withOpacity(.65),

                height: 1.5,
              ),
            ),

            const SizedBox(
              height: 25,
            ),

            ElevatedButton.icon(
              onPressed:
                  _createNote,

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

  Color _noteTextColor(
    int noteColor,
    BuildContext context,
  ) {
    final noteBackground =
        Color(noteColor);

    final brightness =
        ThemeData.estimateBrightnessForColor(
      noteBackground,
    );

    if (brightness ==
        Brightness.dark) {
      return Colors.white;
    }

    return const Color(
      0xFF292653,
    );
  }

  Color _noteSecondaryTextColor(
    int noteColor,
    BuildContext context,
  ) {
    final noteBackground =
        Color(noteColor);

    final brightness =
        ThemeData.estimateBrightnessForColor(
      noteBackground,
    );

    if (brightness ==
        Brightness.dark) {
      return Colors.white
          .withOpacity(.75);
    }

    return const Color(
      0xFF6F6B98,
    );
  }
}
