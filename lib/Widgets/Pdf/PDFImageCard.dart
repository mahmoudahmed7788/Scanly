import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class PDFImageCard extends StatelessWidget {
  final XFile image;
  final int index;
  final bool isCreating;
  final VoidCallback onRemove;

  const PDFImageCard({
    super.key,
    required this.image,
    required this.index,
    required this.isCreating,
    required this.onRemove,
  });

  Widget _buildImageError(
    ColorScheme colors,
  ) {
    return SizedBox(
      height: 260,

      child: Column(
        mainAxisAlignment:
            MainAxisAlignment.center,

        children: [

          Icon(
            Icons
                .broken_image_outlined,
            size: 52,
            color:
                colors.error,
          ),

          const SizedBox(
            height: 10,
          ),

          Text(
            'Unable to preview image',

            style:
                TextStyle(
              color:
                  colors.onSurface,
              fontWeight:
                  FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final colors =
        Theme.of(context)
            .colorScheme;

    final file =
        File(image.path);

    return Container(
      margin:
          const EdgeInsets.only(
        bottom: 16,
      ),

      decoration:
          BoxDecoration(
        color:
            colors.surfaceContainerHighest,

        borderRadius:
            BorderRadius.circular(
          20,
        ),

        border:
            Border.all(
          color:
              colors.onSurface.withValues(
            alpha: 0.08,
          ),
        ),

        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withValues(
              alpha: 0.05,
            ),
            blurRadius: 12,
            offset:
                const Offset(
              0,
              4,
            ),
          ),
        ],
      ),

      clipBehavior:
          Clip.antiAlias,

      child: Column(
        children: [

          // ====================================================
          // IMAGE
          // ====================================================

          Stack(
            children: [

              Container(
                width:
                    double.infinity,

                constraints:
                    const BoxConstraints(
                  minHeight: 220,
                  maxHeight: 500,
                ),

                color:
                    colors.surface,

                child:
                    file.existsSync()
                        ? Image.file(
                            file,

                            width:
                                double.infinity,

                            fit:
                                BoxFit.contain,

                            errorBuilder:
                                (
                              context,
                              error,
                              stackTrace,
                            ) {
                              return _buildImageError(
                                colors,
                              );
                            },
                          )
                        : _buildImageError(
                            colors,
                          ),
              ),

              // ==================================================
              // PAGE NUMBER
              // ==================================================

              Positioned(
                top: 12,
                left: 12,

                child: Container(
                  padding:
                      const EdgeInsets
                          .symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),

                  decoration:
                      BoxDecoration(
                    color:
                        Colors.black
                            .withValues(
                      alpha: 0.70,
                    ),

                    borderRadius:
                        BorderRadius.circular(
                      20,
                    ),
                  ),

                  child: Text(
                    'Page ${index + 1}',

                    style:
                        const TextStyle(
                      color:
                          Colors.white,
                      fontSize: 12,
                      fontWeight:
                          FontWeight.w800,
                    ),
                  ),
                ),
              ),

              // ==================================================
              // REMOVE BUTTON
              // ==================================================

              Positioned(
                top: 10,
                right: 10,

                child: Material(
                  color:
                      Colors.black
                          .withValues(
                    alpha: 0.70,
                  ),

                  shape:
                      const CircleBorder(),

                  child: InkWell(
                    customBorder:
                        const CircleBorder(),

                    onTap:
                        isCreating
                            ? null
                            : onRemove,

                    child:
                        const Padding(
                      padding:
                          EdgeInsets.all(
                        9,
                      ),

                      child: Icon(
                        Icons
                            .close_rounded,
                        color:
                            Colors.white,
                        size: 21,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          // ====================================================
          // IMAGE NAME + DRAG
          // ====================================================

          Padding(
            padding:
                const EdgeInsets.fromLTRB(
              14,
              11,
              10,
              11,
            ),

            child: Row(
              children: [

                Expanded(
                  child: Text(
                    image.name,

                    maxLines: 1,

                    overflow:
                        TextOverflow.ellipsis,

                    style:
                        TextStyle(
                      fontSize: 13,
                      fontWeight:
                          FontWeight.w600,
                      color:
                          colors.onSurface,
                    ),
                  ),
                ),

                const SizedBox(
                  width: 8,
                ),

                // ==================================================
                // DRAG HANDLE
                // ==================================================

                ReorderableDelayedDragStartListener(
                  index: index,

                  enabled:
                      !isCreating,

                  child: Container(
                    padding:
                        const EdgeInsets.all(
                      8,
                    ),

                    decoration:
                        BoxDecoration(
                      color:
                          colors.primary
                              .withValues(
                        alpha: 0.10,
                      ),

                      borderRadius:
                          BorderRadius.circular(
                        10,
                      ),
                    ),

                    child: Icon(
                      Icons
                          .drag_indicator_rounded,
                      color:
                          colors.primary,
                      size: 22,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}