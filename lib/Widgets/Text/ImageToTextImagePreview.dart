import 'dart:io';

import 'package:flutter/material.dart';

class ImageToTextImagePreview
    extends StatelessWidget {
  final File image;
  final VoidCallback onTap;

  const ImageToTextImagePreview({
    super.key,
    required this.image,
    required this.onTap,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final theme =
        Theme.of(context);

    final colors =
        theme.colorScheme;

    final isDark =
        theme.brightness ==
            Brightness.dark;

    return GestureDetector(
      onTap: onTap,

      child: Container(
        height: 280,
        width: double.infinity,

        decoration:
            BoxDecoration(
          color:
              colors.surface,

          borderRadius:
              BorderRadius.circular(
            20,
          ),

          border:
              Border.all(
            color:
                colors.primary
                    .withOpacity(
              0.20,
            ),
          ),

          boxShadow: [
            BoxShadow(
              color:
                  Colors.black
                      .withOpacity(
                isDark
                    ? 0.25
                    : 0.06,
              ),
              blurRadius: 14,
              offset:
                  const Offset(
                0,
                6,
              ),
            ),
          ],
        ),

        child: ClipRRect(
          borderRadius:
              BorderRadius.circular(
            20,
          ),

          child: Stack(
            fit: StackFit.expand,

            children: [

              // =================================================
              // IMAGE
              // =================================================

              Image.file(
                image,
                fit: BoxFit.cover,

                errorBuilder:
                    (
                  context,
                  error,
                  stackTrace,
                ) {
                  return Center(
                    child: Column(
                      mainAxisSize:
                          MainAxisSize.min,

                      children: [

                        Icon(
                          Icons
                              .broken_image_outlined,
                          size: 48,
                          color:
                              colors
                                  .onSurface
                                  .withOpacity(
                            0.45,
                          ),
                        ),

                        const SizedBox(
                          height: 10,
                        ),

                        Text(
                          'Unable to display image',
                          style:
                              TextStyle(
                            color:
                                colors
                                    .onSurface
                                    .withOpacity(
                              0.60,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

              // =================================================
              // IMAGE OVERLAY
              // =================================================

              Positioned.fill(
                child: Container(
                  decoration:
                      BoxDecoration(
                    gradient:
                        LinearGradient(
                      begin:
                          Alignment
                              .topCenter,

                      end:
                          Alignment
                              .bottomCenter,

                      colors: [
                        Colors.black
                            .withOpacity(
                          0.05,
                        ),
                        Colors.black
                            .withOpacity(
                          0.25,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // =================================================
              // CHANGE IMAGE BUTTON
              // =================================================

              Positioned(
                right: 14,
                bottom: 14,

                child: Material(
                  color:
                      Colors.black
                          .withOpacity(
                    0.60,
                  ),

                  borderRadius:
                      BorderRadius.circular(
                    14,
                  ),

                  child: InkWell(
                    borderRadius:
                        BorderRadius.circular(
                      14,
                    ),

                    onTap: onTap,

                    child:
                        const Padding(
                      padding:
                          EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),

                      child: Row(
                        mainAxisSize:
                            MainAxisSize.min,

                        children: [

                          Icon(
                            Icons
                                .image_outlined,
                            color:
                                Colors.white,
                            size: 19,
                          ),

                          SizedBox(
                            width: 7,
                          ),

                          Text(
                            'Change',
                            style:
                                TextStyle(
                              color:
                                  Colors.white,
                              fontWeight:
                                  FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}