import 'package:flutter/material.dart';

class DocumentEmptyState extends StatelessWidget {
  final bool hasSearch;

  const DocumentEmptyState({
    super.key,
    required this.hasSearch,
  });

  @override
  Widget build(BuildContext context) {
    final colors =
        Theme.of(context).colorScheme;

    return ListView(
      physics:
          const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height:
              MediaQuery.of(context)
                  .size
                  .height *
              0.22,
        ),

        Center(
          child: Container(
            width: 92,
            height: 92,
            decoration:
                BoxDecoration(
              color: colors.error
                  .withValues(
                alpha: 0.10,
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              hasSearch
                  ? Icons.search_off_rounded
                  : Icons
                      .picture_as_pdf_rounded,
              size: 46,
              color: colors.error,
            ),
          ),
        ),

        const SizedBox(height: 20),

        Center(
          child: Text(
            hasSearch
                ? 'No documents found'
                : 'No PDF documents yet',
            style: TextStyle(
              fontSize: 19,
              fontWeight:
                  FontWeight.w700,
              color:
                  colors.onSurface,
            ),
          ),
        ),

        const SizedBox(height: 8),

        Padding(
          padding:
              const EdgeInsets.symmetric(
            horizontal: 30,
          ),
          child: Text(
            hasSearch
                ? 'Try searching with another document name or type.'
                : 'PDF files created by Scanly will appear here.',
            textAlign:
                TextAlign.center,
            style: TextStyle(
              color:
                  colors.onSurfaceVariant,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}