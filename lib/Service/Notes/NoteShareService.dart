import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_quill/flutter_quill.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:scanly/Models/Note_Model.dart';
import 'package:share_plus/share_plus.dart';

class NoteShareService {
  NoteShareService._();

  // ============================================================
  // SHARE AS TEXT
  // ============================================================

  static Future<void> shareAsText(
    NoteModel note,
  ) async {
    final title = note.title.trim().isEmpty
        ? 'Untitled Note'
        : note.title.trim();

    final content = _extractText(note);

    final text = '''
$title

$content

Shared from Scanly
'''.trim();

    await SharePlus.instance.share(
      ShareParams(
        text: text,
        subject: title,
      ),
    );
  }

  // ============================================================
  // SHARE AS PDF
  // ============================================================

  static Future<void> shareAsPdf(
    NoteModel note,
  ) async {
    final pdfBytes = await _buildPdf(note);

    final directory =
        await getTemporaryDirectory();

    final safeTitle =
        _safeFileName(
      note.title.trim().isEmpty
          ? 'Scanly_Note'
          : note.title.trim(),
    );

    final file = File(
      '${directory.path}/$safeTitle.pdf',
    );

    await file.writeAsBytes(
      pdfBytes,
      flush: true,
    );

    await SharePlus.instance.share(
      ShareParams(
        title: note.title.isEmpty
            ? 'Scanly Note'
            : note.title,
        subject: note.title.isEmpty
            ? 'Scanly Note'
            : note.title,
        text: 'Shared from Scanly',
        files: [
          XFile(
            file.path,
            mimeType: 'application/pdf',
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BUILD PDF
  // ============================================================

  static Future<Uint8List> _buildPdf(
    NoteModel note,
  ) async {
    final pdf = pw.Document(
      title: note.title.isEmpty
          ? 'Scanly Note'
          : note.title,
      author: 'Scanly',
      subject: 'Scanly Note',
    );

    final title = note.title.trim().isEmpty
        ? 'Untitled Note'
        : note.title.trim();

    final pages =
        _extractPages(note);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(
          42,
          45,
          42,
          45,
        ),

        header: (context) {
          return pw.Container(
            margin: const pw.EdgeInsets.only(
              bottom: 20,
            ),
            child: pw.Row(
              mainAxisAlignment:
                  pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'SCANLY',
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight:
                        pw.FontWeight.bold,
                    color:
                        PdfColors.indigo,
                    letterSpacing: 1.5,
                  ),
                ),
                pw.Text(
                  'NOTE',
                  style: pw.TextStyle(
                    fontSize: 9,
                    color:
                        PdfColors.grey600,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          );
        },

        footer: (context) {
          return pw.Container(
            margin: const pw.EdgeInsets.only(
              top: 15,
            ),
            padding:
                const pw.EdgeInsets.only(
              top: 8,
            ),
            decoration:
                const pw.BoxDecoration(
              border: pw.Border(
                top: pw.BorderSide(
                  color: PdfColors.grey300,
                  width: .5,
                ),
              ),
            ),
            child: pw.Row(
              mainAxisAlignment:
                  pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Shared from Scanly',
                  style: const pw.TextStyle(
                    fontSize: 8,
                    color:
                        PdfColors.grey600,
                  ),
                ),
                pw.Text(
                  'Page ${context.pageNumber} / ${context.pagesCount}',
                  style: const pw.TextStyle(
                    fontSize: 8,
                    color:
                        PdfColors.grey600,
                  ),
                ),
              ],
            ),
          );
        },

        build: (context) {
          final widgets =
              <pw.Widget>[
            pw.Text(
              title,
              style: pw.TextStyle(
                fontSize: 26,
                fontWeight:
                    pw.FontWeight.bold,
                color:
                    PdfColors.grey900,
              ),
            ),

            pw.SizedBox(height: 8),

            pw.Text(
              _formatDate(note.updatedAt),
              style: const pw.TextStyle(
                fontSize: 9,
                color:
                    PdfColors.grey600,
              ),
            ),

            pw.SizedBox(height: 25),

            pw.Container(
              height: 3,
              width: 55,
              decoration:
                  const pw.BoxDecoration(
                color: PdfColors.indigo,
              ),
            ),

            pw.SizedBox(height: 25),
          ];

          for (int i = 0;
              i < pages.length;
              i++) {
            final pageText =
                pages[i].trim();

            if (pageText.isEmpty) {
              continue;
            }

            if (pages.length > 1) {
              widgets.add(
                pw.Padding(
                  padding:
                      const pw.EdgeInsets.only(
                    bottom: 10,
                  ),
                  child: pw.Text(
                    'Page ${i + 1}',
                    style: pw.TextStyle(
                      fontSize: 11,
                      fontWeight:
                          pw.FontWeight.bold,
                      color:
                          PdfColors.indigo,
                    ),
                  ),
                ),
              );
            }

            widgets.add(
              pw.Text(
                pageText,
                style: const pw.TextStyle(
                  fontSize: 11,
                  lineSpacing: 4,
                  color:
                      PdfColors.grey900,
                ),
              ),
            );

            widgets.add(
              pw.SizedBox(height: 22),
            );
          }

          if (widgets.length <= 5) {
            widgets.add(
              pw.Text(
                'No content',
                style:
                    const pw.TextStyle(
                  fontSize: 11,
                  color:
                      PdfColors.grey600,
                ),
              ),
            );
          }

          return widgets;
        },
      ),
    );

    return pdf.save();
  }

  // ============================================================
  // EXTRACT NOTE PAGES
  // ============================================================

  static List<String> _extractPages(
    NoteModel note,
  ) {
    if (note.pages.isNotEmpty) {
      return note.pages
          .map(
            (page) => _quillToText(
              page.quillData,
            ),
          )
          .toList();
    }

    return [
      _quillToText(
        note.quillData,
      ),
    ];
  }

  // ============================================================
  // EXTRACT ALL TEXT
  // ============================================================

  static String _extractText(
    NoteModel note,
  ) {
    return _extractPages(note)
        .where(
          (text) => text.trim().isNotEmpty,
        )
        .join('\n\n');
  }

  // ============================================================
  // QUILL -> PLAIN TEXT
  // ============================================================

  static String _quillToText(
    List<dynamic> data,
  ) {
    if (data.isEmpty) {
      return '';
    }

    try {
      final document =
          Document.fromJson(
        List<dynamic>.from(data),
      );

      return document
          .toPlainText()
          .trim();
    } catch (_) {
      return '';
    }
  }

  // ============================================================
  // DATE
  // ============================================================

  static String _formatDate(
    DateTime date,
  ) {
    final day =
        date.day.toString().padLeft(2, '0');

    final month =
        date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }

  // ============================================================
  // SAFE FILE NAME
  // ============================================================

  static String _safeFileName(
    String name,
  ) {
    final cleaned = name
        .replaceAll(
          RegExp(r'[<>:"/\\|?*]'),
          '_',
        )
        .replaceAll(
          RegExp(r'\s+'),
          '_',
        );

    if (cleaned.isEmpty) {
      return 'Scanly_Note';
    }

    return cleaned.length > 80
        ? cleaned.substring(0, 80)
        : cleaned;
  }
}