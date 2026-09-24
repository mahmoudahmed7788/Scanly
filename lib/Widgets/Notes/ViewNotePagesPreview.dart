import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:scanly/Models/Note_Model.dart';

class ViewNotePagesPreview extends StatelessWidget {
  final NoteModel note;

  const ViewNotePagesPreview({
    super.key,
    required this.note,
  });

  String _getPreviewText(NotePageModel page) {
    String previewText = '';

    try {
      if (page.quillData.isNotEmpty) {
        final document = Document.fromJson(
          List<dynamic>.from(page.quillData),
        );

        previewText = document.toPlainText().trim();
      }
    } catch (_) {
      previewText = '';
    }

    if (previewText.isEmpty) {
      previewText = 'Empty page';
    }

    return previewText;
  }

  @override
  Widget build(BuildContext context) {
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
            final previewText = _getPreviewText(page);

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
                borderRadius: BorderRadius.circular(18),
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
                          ? Icons.crop_landscape_rounded
                          : Icons.crop_portrait_rounded,
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
}