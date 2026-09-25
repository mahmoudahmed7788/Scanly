import 'package:flutter/material.dart';

class PDFEmptyState extends StatelessWidget {
  final ColorScheme colors;
  final bool isCreating;
  final VoidCallback onAddImages;

  const PDFEmptyState({
    super.key,
    required this.colors,
    required this.isCreating,
    required this.onAddImages,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return LayoutBuilder(
      builder: (
        context,
        constraints,
      ) {
        return ListView(
          keyboardDismissBehavior:
              ScrollViewKeyboardDismissBehavior
                  .onDrag,

          padding:
              const EdgeInsets.fromLTRB(
            24,
            30,
            24,
            40,
          ),

          children: [

            ConstrainedBox(
              constraints:
                  BoxConstraints(
                minHeight:
                    constraints.maxHeight -
                        70,
              ),

              child: Column(
                mainAxisAlignment:
                    MainAxisAlignment.center,

                children: [

                  // ==================================================
                  // ICON
                  // ==================================================

                  Container(
                    width: 110,
                    height: 110,

                    decoration:
                        BoxDecoration(
                      color:
                          colors.primary
                              .withValues(
                        alpha: 0.10,
                      ),

                      shape:
                          BoxShape.circle,
                    ),

                    child: Icon(
                      Icons
                          .photo_library_outlined,
                      size: 54,
                      color:
                          colors.primary,
                    ),
                  ),

                  const SizedBox(
                    height: 20,
                  ),

                  // ==================================================
                  // TITLE
                  // ==================================================

                  Text(
                    'No Images Added',

                    style:
                        TextStyle(
                      fontSize: 21,
                      fontWeight:
                          FontWeight.w800,
                      color:
                          colors.onSurface,
                    ),
                  ),

                  const SizedBox(
                    height: 8,
                  ),

                  // ==================================================
                  // DESCRIPTION
                  // ==================================================

                  Text(
                    'Add images and they will appear here as PDF pages.',

                    textAlign:
                        TextAlign.center,

                    style:
                        TextStyle(
                      fontSize: 14,
                      color:
                          colors.onSurface
                              .withValues(
                        alpha: 0.60,
                      ),
                    ),
                  ),

                  const SizedBox(
                    height: 22,
                  ),

                  // ==================================================
                  // ADD BUTTON
                  // ==================================================

                  FilledButton.icon(
                    onPressed:
                        isCreating
                            ? null
                            : onAddImages,

                    icon:
                        const Icon(
                      Icons
                          .add_photo_alternate_rounded,
                    ),

                    label:
                        const Text(
                      'Add Images',
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}