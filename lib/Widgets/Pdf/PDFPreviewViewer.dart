import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';

class PDFPreviewViewer extends StatelessWidget {
  final ColorScheme colors;
  final bool loading;
  final String? error;
  final PdfControllerPinch? controller;

  final ValueChanged<PdfDocument>? onDocumentLoaded;
  final ValueChanged<Object>? onDocumentError;

  const PDFPreviewViewer({
    super.key,
    required this.colors,
    required this.loading,
    required this.error,
    required this.controller,
    this.onDocumentLoaded,
    this.onDocumentError,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    if (loading) {
      return Container(
        margin: const EdgeInsets.fromLTRB(
          10,
          0,
          10,
          10,
        ),
        decoration: BoxDecoration(
          color:
              colors.surfaceContainerHighest,
          borderRadius:
              BorderRadius.circular(14),
        ),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (error != null ||
        controller == null) {
      return Container(
        margin: const EdgeInsets.fromLTRB(
          10,
          0,
          10,
          10,
        ),
        decoration: BoxDecoration(
          color:
              colors.surfaceContainerHighest,
          borderRadius:
              BorderRadius.circular(14),
        ),
        child: Center(
          child: Padding(
            padding:
                const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment:
                  MainAxisAlignment.center,
              children: [
                Icon(
                  Icons
                      .picture_as_pdf_outlined,
                  size: 56,
                  color: colors.error,
                ),
                const SizedBox(
                  height: 14,
                ),
                Text(
                  'PDF is not available',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight:
                        FontWeight.w800,
                    color:
                        colors.onSurface,
                  ),
                ),
                const SizedBox(
                  height: 8,
                ),
                Text(
                  error ??
                      'Could not open this PDF.',
                  textAlign:
                      TextAlign.center,
                  style: TextStyle(
                    color:
                        colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(
        10,
        0,
        10,
        10,
      ),
      decoration: BoxDecoration(
        color:
            colors.surfaceContainerHighest,
        borderRadius:
            BorderRadius.circular(14),
      ),
      clipBehavior:
          Clip.antiAlias,
      child: PdfViewPinch(
        controller: controller!,
        scrollDirection:
            Axis.vertical,
        backgroundDecoration:
            BoxDecoration(
          color:
              colors.surfaceContainerHighest,
        ),
        onDocumentLoaded:
            onDocumentLoaded,
        onDocumentError:
            onDocumentError,
      ),
    );
  }
}