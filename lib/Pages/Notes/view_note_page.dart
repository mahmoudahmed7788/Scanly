import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:scanly/Models/Note_Model.dart';
import 'package:scanly/Pages/Notes/ViewNotePdfs.dart';
import 'package:scanly/Pages/Notes/create_note_page.dart';
import 'package:scanly/Widgets/Notes/ViewNoteImages.dart';
import 'package:scanly/Widgets/Notes/ViewNotePagesPreview.dart';

class ViewNotePage extends StatefulWidget {
  final NoteModel note;

  const ViewNotePage({
    super.key,
    required this.note,
  });

  @override
  State<ViewNotePage> createState() => _ViewNotePageState();
}

class _ViewNotePageState extends State<ViewNotePage> {
  late NoteModel _note;
  QuillController? _controller;

  @override
  void initState() {
    super.initState();

    _note = widget.note;
    _createController();
  }

  void _createController() {
    final data = _note.pages.isNotEmpty
        ? _note.pages.first.quillData
        : _note.quillData;

    Document document;

    try {
      if (data.isEmpty) {
        document = Document();
      } else {
        document = Document.fromJson(
          List<dynamic>.from(data),
        );
      }
    } catch (_) {
      document = Document();
    }

    _controller = QuillController(
      document: document,
      selection: const TextSelection.collapsed(
        offset: 0,
      ),
    );

    _controller!.readOnly = true;
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _editNote() async {
    final result = await Navigator.of(context)
        .push<NoteModel>(
      MaterialPageRoute(
        builder: (context) {
          return CreateNotePage(
            note: _note,
          );
        },
      ),
    );

    if (!mounted || result == null) {
      return;
    }

    setState(() {
      _controller?.dispose();
      _note = result;
      _createController();
    });
  }

  void _closeView() {
    Navigator.of(context).pop(_note);
  }

  @override
  Widget build(BuildContext context) {
    final note = _note;
    final noteColor = Color(note.colorValue);

    return PopScope<NoteModel>(
      canPop: false,
      onPopInvokedWithResult:
          (didPop, result) {
        if (didPop) {
          return;
        }

        Navigator.of(context).pop(_note);
      },
      child: Scaffold(
        backgroundColor: noteColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            onPressed: _closeView,
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: Color(0xFF292653),
            ),
          ),
          title: Text(
            note.title.isEmpty
                ? 'Note'
                : note.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF292653),
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          actions: [
            IconButton(
              onPressed: _editNote,
              tooltip: 'Edit',
              icon: const Icon(
                Icons.edit_outlined,
                color: Color(0xFF5B5FEF),
              ),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            20,
            10,
            20,
            30,
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              if (note.isPinned)
                Container(
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(
                      0xFF5B5FEF,
                    ).withValues(alpha: .12),
                    borderRadius:
                        BorderRadius.circular(14),
                  ),
                  child: const Row(
                    mainAxisSize:
                        MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.push_pin_rounded,
                        size: 18,
                        color: Color(
                          0xFF5B5FEF,
                        ),
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Pinned',
                        style: TextStyle(
                          color: Color(
                            0xFF5B5FEF,
                          ),
                          fontWeight:
                              FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 20),

              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(
                    alpha: .75,
                  ),
                  borderRadius:
                      BorderRadius.circular(20),
                ),
                child: _controller == null
                    ? const SizedBox(
                        height: 100,
                      )
                    : QuillEditor.basic(
                        controller:
                            _controller!,
                        config:
                            const QuillEditorConfig(
                          padding:
                              EdgeInsets.zero,
                          enableInteractiveSelection:
                              false,
                          scrollable: false,
                          expands: false,
                        ),
                      ),
              ),

              if (note.pages.length > 1) ...[
                const SizedBox(height: 20),
                ViewNotePagesPreview(
                  note: note,
                ),
              ],

              if (note.imagePaths.isNotEmpty) ...[
                const SizedBox(height: 24),
                ViewNoteImages(
                  note: note,
                ),
              ],

              if (note.pdfs.isNotEmpty) ...[
                const SizedBox(height: 24),
                ViewNotePdfs(
                  note: note,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}