import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart' as pdf;
import 'package:pdf/widgets.dart' as pw;

import 'package:scanly/Core/DocumentStorage.dart';
import 'package:scanly/Core/Scanly_Items.dart';
import 'package:scanly/Models/DocumentModel.dart';
import 'package:scanly/Models/PreparedImage.dart';
import 'package:scanly/core/ScanlyActivityService.dart';

class PDFGeneratorService {
  PDFGeneratorService._();

  static const MethodChannel _nativeChannel =
      MethodChannel('scanly/share');

  // ============================================================
  // PREPARE IMAGE
  // ============================================================

  static PreparedImage? prepareImageSync(
    String path,
  ) {
    try {
      final file = File(path);

      if (!file.existsSync()) {
        debugPrint(
          'IMAGE FILE DOES NOT EXIST: $path',
        );

        return null;
      }

      final bytes = file.readAsBytesSync();

      if (bytes.isEmpty) {
        return null;
      }

      final decoded = img.decodeImage(bytes);

      if (decoded == null) {
        return null;
      }

      img.Image image = decoded;

      if (image.width > 1400) {
        image = img.copyResize(
          image,
          width: 1400,
        );
      }

      final jpg = img.encodeJpg(
        image,
        quality: 72,
      );

      return PreparedImage(
        bytes: Uint8List.fromList(jpg),
        width: image.width,
        height: image.height,
      );
    } catch (e) {
      debugPrint(
        'PREPARE IMAGE ERROR: $e',
      );

      return null;
    }
  }

  static Future<PreparedImage?> prepareImage(
    String path,
  ) async {
    return prepareImageSync(path);
  }

  // ============================================================
  // PAGE FORMAT
  // ============================================================

  static pdf.PdfPageFormat pageFormatForImage(
    int width,
    int height,
  ) {
    if (width >= height) {
      return const pdf.PdfPageFormat(
        841.89,
        595.28,
      );
    }

    return const pdf.PdfPageFormat(
      595.28,
      841.89,
    );
  }

  // ============================================================
  // ACTIVITY ITEM
  // ============================================================

  static String itemId(
    String path,
  ) {
    return 'pdf_${path.hashCode}';
  }

  static ScanlyItem createItem({
    required String path,
    required String fileName,
  }) {
    return ScanlyItem(
      id: itemId(path),
      title: 'PDF Document',
      subtitle: fileName,
      type: 'pdf',
      route: '/pdf-preview',
      data: path,
      createdAt:
          DateTime.now().millisecondsSinceEpoch,
    );
  }

  // ============================================================
  // SCANLY BRANDING
  // ============================================================

  static pw.Widget buildScanlyBranding(
    Uint8List? logoBytes,
  ) {
    final logo = logoBytes == null
        ? null
        : pw.MemoryImage(
            logoBytes,
          );

    return pw.Container(
      height: 42,
      padding: const pw.EdgeInsets.only(
        top: 6,
        bottom: 4,
      ),
      decoration: pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(
            color: pdf.PdfColors.grey400,
            width: 0.6,
          ),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment:
            pw.MainAxisAlignment.center,
        crossAxisAlignment:
            pw.CrossAxisAlignment.center,
        children: [
          if (logo != null)
            pw.SizedBox(
              width: 28,
              height: 28,
              child: pw.Image(
                logo,
                fit: pw.BoxFit.contain,
              ),
            )
          else
            pw.Container(
              width: 28,
              height: 28,
              alignment: pw.Alignment.center,
              decoration: pw.BoxDecoration(
                color: pdf.PdfColors.indigo,
                borderRadius:
                    pw.BorderRadius.circular(7),
              ),
              child: pw.Text(
                'S',
                style: pw.TextStyle(
                  color: pdf.PdfColors.white,
                  fontSize: 15,
                  fontWeight:
                      pw.FontWeight.bold,
                ),
              ),
            ),
          pw.SizedBox(
            width: 8,
          ),
          pw.Text(
            'Scanly',
            style: pw.TextStyle(
              color: pdf.PdfColors.indigo,
              fontSize: 14,
              fontWeight:
                  pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PUBLIC COPY
  // ============================================================

  static Future<void> savePublicCopyInBackground({
    required String filePath,
    required String fileName,
  }) async {
    try {
      await _nativeChannel.invokeMethod(
        'saveFileToScanly',
        {
          'filePath': filePath,
          'fileName': fileName,
          'mimeType': 'application/pdf',
          'folder': 'Documents',
        },
      );

      debugPrint(
        'PDF public copy saved successfully.',
      );
    } catch (e) {
      debugPrint(
        'PUBLIC PDF SAVE ERROR: $e',
      );
    }
  }

  // ============================================================
  // BACKGROUND SAVE
  // ============================================================

  static Future<void> finishBackgroundSave({
    required DocumentModel document,
    required ScanlyItem item,
    required String fileName,
  }) async {
    try {
      await DocumentStorage.saveDocument(
        document,
      );
    } catch (e) {
      debugPrint(
        'BACKGROUND DOCUMENT SAVE ERROR: $e',
      );
    }

    try {
      await ScanlyActivityService.addRecent(
        item,
      );
    } catch (e) {
      debugPrint(
        'BACKGROUND ACTIVITY SAVE ERROR: $e',
      );
    }

    if (document.filePath != null) {
      await savePublicCopyInBackground(
        filePath: document.filePath!,
        fileName: fileName,
      );
    }
  }

  // ============================================================
  // CREATE PDF
  // ============================================================

  static Future<DocumentModel> createPdf({
    required List<String> imagePaths,
    required String documentName,
    required Uint8List? logoBytes,
  }) async {
    if (imagePaths.isEmpty) {
      throw Exception(
        'No images selected',
      );
    }

    final pdfDocument = pw.Document();

    // ==========================================================
    // LOCAL DIRECTORY
    // ==========================================================

    final appDirectory =
        await getApplicationDocumentsDirectory();

    final documentsDirectory = Directory(
      '${appDirectory.path}/Scanly/Documents',
    );

    await documentsDirectory.create(
      recursive: true,
    );

    final timestamp =
        DateTime.now().millisecondsSinceEpoch;

    final pagesDirectory = Directory(
      '${documentsDirectory.path}/'
      '${documentName}_pages_$timestamp',
    );

    await pagesDirectory.create(
      recursive: true,
    );

    final savedPageImagePaths = <String>[];

    // ==========================================================
    // PROCESS IMAGES
    // ==========================================================

    for (
      int i = 0;
      i < imagePaths.length;
      i++
    ) {
      final selectedPath = imagePaths[i];

      final prepared = await prepareImage(
        selectedPath,
      );

      if (prepared == null) {
        continue;
      }

      final imageBytes = prepared.bytes;

      // --------------------------------------------------------
      // SAVE PAGE IMAGE
      // --------------------------------------------------------

      final pagePath =
          '${pagesDirectory.path}/'
          'page_'
          '${(i + 1).toString().padLeft(3, '0')}'
          '.jpg';

      final pageFile = File(pagePath);

      await pageFile.writeAsBytes(
        imageBytes,
        flush: false,
      );

      savedPageImagePaths.add(
        pagePath,
      );

      // --------------------------------------------------------
      // ADD IMAGE TO PDF
      // --------------------------------------------------------

      final pdfImage =
          pw.MemoryImage(imageBytes);

      final pageFormat =
          pageFormatForImage(
        prepared.width,
        prepared.height,
      );

      const brandingHeight = 42.0;

      final imageAreaHeight =
          pageFormat.height -
              brandingHeight;

      pdfDocument.addPage(
        pw.Page(
          pageFormat: pageFormat,
          margin: pw.EdgeInsets.zero,
          build: (context) {
            return pw.Column(
              children: [
                pw.SizedBox(
                  height: imageAreaHeight,
                  width: double.infinity,
                  child: pw.Center(
                    child: pw.Padding(
                      padding:
                          const pw.EdgeInsets.all(8),
                      child: pw.Image(
                        pdfImage,
                        fit: pw.BoxFit.contain,
                      ),
                    ),
                  ),
                ),
                buildScanlyBranding(
                  logoBytes,
                ),
              ],
            );
          },
        ),
      );
    }

    // ==========================================================
    // VALIDATE
    // ==========================================================

    if (savedPageImagePaths.isEmpty) {
      throw Exception(
        'No valid images were processed',
      );
    }

    // ==========================================================
    // GENERATE PDF
    // ==========================================================

    final pdfBytes =
        await pdfDocument.save();

    // ==========================================================
    // PDF FILE NAME
    // ==========================================================

    var fileName =
        '$documentName.pdf';

    var pdfPath =
        '${documentsDirectory.path}/$fileName';

    var pdfFile = File(pdfPath);

    int counter = 1;

    while (await pdfFile.exists()) {
      fileName =
          '$documentName ($counter).pdf';

      pdfPath =
          '${documentsDirectory.path}/$fileName';

      pdfFile = File(pdfPath);

      counter++;
    }

    await pdfFile.writeAsBytes(
      pdfBytes,
      flush: false,
    );

    // ==========================================================
    // DOCUMENT MODEL
    // ==========================================================

    final documentId =
        pdfFile.path.hashCode.toString();

    final scanlyDocument =
        DocumentModel(
      id: documentId,
      title: documentName,
      date: DateTime.now().toIso8601String(),
      type: 'pdf',
      filePath: pdfFile.path,
      isFavorite: false,
      imagePaths:
          List<String>.from(
        savedPageImagePaths,
      ),
    );

    return scanlyDocument;
  }
}