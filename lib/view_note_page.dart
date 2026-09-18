import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:scanly/Note_Model.dart';
import 'package:scanly/create_note_page.dart';

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
    final result = await Navigator.of(context).push<NoteModel>(
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

  String _formatFileSize(int bytes) {
    if (bytes <= 0) {
      return '0 B';
    }

    if (bytes < 1024) {
      return '$bytes B';
    }

    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }

    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }

    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  Widget _buildPagesPreview(NoteModel note) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Pages',
          style: TextStyle(
            color: Color(0xFF292653),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...List.generate(
          note.pages.length,
          (index) {
            final page = note.pages[index];

            String previewText = '';

            try {
              if (page.quillData.isNotEmpty) {
                final document = Document.fromJson(
                  List<dynamic>.from(
                    page.quillData,
                  ),
                );

                previewText = document.toPlainText().trim();
              }
            } catch (_) {
              previewText = '';
            }

            if (previewText.isEmpty) {
              previewText = 'Empty page';
            }

            return Container(
              width: double.infinity,
              margin: const EdgeInsets.only(
                bottom: 10,
              ),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(
                  alpha: .75,
                ),
                borderRadius: BorderRadius.circular(
                  18,
                ),
              ),
              child: Row(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: const Color(
                        0xFF5B5FEF,
                      ).withValues(
                        alpha: .12,
                      ),
                      borderRadius:
                          BorderRadius.circular(12),
                    ),
                    child: Icon(
                      page.isLandscape
                          ? Icons
                              .crop_landscape_rounded
                          : Icons
                              .crop_portrait_rounded,
                      color: const Color(
                        0xFF5B5FEF,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Page ${index + 1}',
                          style: const TextStyle(
                            color: Color(
                              0xFF292653,
                            ),
                            fontWeight:
                                FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          previewText,
                          maxLines: 3,
                          overflow:
                              TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(
                              0xFF6F6B98,
                            ),
                            fontSize: 14,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildImages(NoteModel note) {
    if (note.imagePaths.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Images',
          style: TextStyle(
            color: Color(0xFF292653),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics:
              const NeverScrollableScrollPhysics(),
          itemCount: note.imagePaths.length,
          gridDelegate:
              const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1,
          ),
          itemBuilder: (context, index) {
            final path = note.imagePaths[index];

            return ClipRRect(
              borderRadius:
                  BorderRadius.circular(18),
              child: Image.file(
                File(path),
                fit: BoxFit.cover,
                errorBuilder:
                    (context, error, stackTrace) {
                  return Container(
                    color: Colors.white
                        .withValues(alpha: .7),
                    child: const Icon(
                      Icons.broken_image_outlined,
                      color: Color(0xFF6F6B98),
                      size: 35,
                    ),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildPdfs(NoteModel note) {
    if (note.pdfs.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'PDF Files',
          style: TextStyle(
            color: Color(0xFF292653),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...note.pdfs.map(
          (pdf) {
            return Container(
              width: double.infinity,
              margin: const EdgeInsets.only(
                bottom: 10,
              ),
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.white.withValues(
                  alpha: .75,
                ),
                borderRadius:
                    BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: const Color(
                        0xFF5B5FEF,
                      ).withValues(alpha: .12),
                      borderRadius:
                          BorderRadius.circular(13),
                    ),
                    child: const Icon(
                      Icons.picture_as_pdf_rounded,
                      color: Color(0xFF5B5FEF),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          pdf.name.isEmpty
                              ? 'PDF file'
                              : pdf.name,
                          maxLines: 1,
                          overflow:
                              TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(
                              0xFF292653,
                            ),
                            fontWeight:
                                FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatFileSize(
                            pdf.size,
                          ),
                          style: const TextStyle(
                            color: Color(
                              0xFF6F6B98,
                            ),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
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
                _buildPagesPreview(note),
              ],

              if (note.imagePaths.isNotEmpty) ...[
                const SizedBox(height: 24),
                _buildImages(note),
              ],

              if (note.pdfs.isNotEmpty) ...[
                const SizedBox(height: 24),
                _buildPdfs(note),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
