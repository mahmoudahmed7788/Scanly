import 'dart:io';

import 'package:flutter/material.dart';
import 'package:scanly/Models/Note_Model.dart';

class ViewNoteImages extends StatelessWidget {
  final NoteModel note;

  const ViewNoteImages({
    super.key,
    required this.note,
  });

  @override
  Widget build(BuildContext context) {
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
                    color: Colors.white.withValues(
                      alpha: .7,
                    ),
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
}