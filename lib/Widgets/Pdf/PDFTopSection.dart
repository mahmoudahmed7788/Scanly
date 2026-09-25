import 'package:flutter/material.dart';

class PDFTopSection extends StatelessWidget {
  final ColorScheme colors;
  final TextEditingController nameController;
  final bool isCreating;
  final bool hasImages;

  final VoidCallback onAddImages;
  final VoidCallback onCreatePdf;

  const PDFTopSection({
    super.key,
    required this.colors,
    required this.nameController,
    required this.isCreating,
    required this.hasImages,
    required this.onAddImages,
    required this.onCreatePdf,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        14,
        14,
        14,
        8,
      ),
      child: Column(
        children: [
          // ======================================================
          // PDF NAME
          // ======================================================

          TextField(
            controller: nameController,
            enabled: !isCreating,
            textInputAction:
                TextInputAction.done,
            decoration: InputDecoration(
              labelText: 'PDF Name',
              hintText: 'Enter PDF name',
              prefixIcon: const Icon(
                Icons.picture_as_pdf_rounded,
              ),
              filled: true,
              fillColor:
                  colors.surfaceContainer,
              border: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              enabledBorder:
                  OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(16),
                borderSide: BorderSide(
                  color:
                      colors.outlineVariant,
                ),
              ),
              focusedBorder:
                  OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: colors.primary,
                  width: 1.5,
                ),
              ),
            ),
          ),

          const SizedBox(
            height: 10,
          ),

          // ======================================================
          // BUTTONS
          // ======================================================

          Row(
            children: [
              // --------------------------------------------------
              // ADD IMAGES
              // --------------------------------------------------

              Expanded(
                child: OutlinedButton.icon(
                  onPressed:
                      isCreating
                          ? null
                          : onAddImages,
                  icon: const Icon(
                    Icons.add_photo_alternate_rounded,
                  ),
                  label: const Text(
                    'Add Images',
                    style: TextStyle(
                      fontWeight:
                          FontWeight.w700,
                    ),
                  ),
                  style:
                      OutlinedButton.styleFrom(
                    minimumSize:
                        const Size(
                      0,
                      52,
                    ),
                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(
                        16,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(
                width: 10,
              ),

              // --------------------------------------------------
              // CREATE PDF
              // --------------------------------------------------

              Expanded(
                child: FilledButton.icon(
                  onPressed:
                      isCreating ||
                              !hasImages
                          ? null
                          : onCreatePdf,
                  icon:
                      isCreating
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child:
                                  CircularProgressIndicator(
                                strokeWidth:
                                    2.2,
                              ),
                            )
                          : const Icon(
                              Icons
                                  .picture_as_pdf_rounded,
                            ),
                  label: Text(
                    isCreating
                        ? 'Creating...'
                        : 'Create PDF',
                    style: const TextStyle(
                      fontWeight:
                          FontWeight.w800,
                    ),
                  ),
                  style:
                      FilledButton.styleFrom(
                    minimumSize:
                        const Size(
                      0,
                      52,
                    ),
                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(
                        16,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}