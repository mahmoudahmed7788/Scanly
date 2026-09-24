import 'package:flutter/material.dart';

class ImageToTextEmptyState extends StatelessWidget {
  const ImageToTextEmptyState({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 75,
          height: 75,
          decoration: BoxDecoration(
            color: const Color(0xFF5B5FEF).withOpacity(0.10),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.image_outlined,
            size: 38,
            color: Color(0xFF5B5FEF),
          ),
        ),

        const SizedBox(height: 16),

        const Text(
          'Select an image',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 6),

        Text(
          'Tap here to choose from gallery\nor take a photo',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}