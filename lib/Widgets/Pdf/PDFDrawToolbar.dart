import 'package:flutter/material.dart';

class PDFDrawToolbar extends StatelessWidget {
  final bool eraser;
  final Color selectedColor;
  final double strokeWidth;
  final bool saving;

  final VoidCallback onPen;
  final VoidCallback onEraser;
  final VoidCallback onAddText;
  final VoidCallback onColorPicker;
  final ValueChanged<double> onStrokeWidthChanged;

  const PDFDrawToolbar({
    super.key,
    required this.eraser,
    required this.selectedColor,
    required this.strokeWidth,
    required this.saving,
    required this.onPen,
    required this.onEraser,
    required this.onAddText,
    required this.onColorPicker,
    required this.onStrokeWidthChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 10,
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Pen',
            onPressed: onPen,
            icon: Icon(
              Icons.edit_rounded,
              color: !eraser ? selectedColor : null,
            ),
          ),

          IconButton(
            tooltip: 'Eraser',
            onPressed: onEraser,
            icon: Icon(
              Icons.auto_fix_normal_rounded,
              color: eraser ? Colors.blue : null,
            ),
          ),

          IconButton(
            tooltip: 'Add Text',
            onPressed: saving ? null : onAddText,
            icon: const Icon(
              Icons.text_fields_rounded,
            ),
          ),

          const SizedBox(width: 6),

          GestureDetector(
            onTap: onColorPicker,
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: selectedColor,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.grey,
                ),
              ),
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Slider(
              min: 1,
              max: 20,
              value: strokeWidth,
              onChanged: onStrokeWidthChanged,
            ),
          ),

          Text(
            strokeWidth.round().toString(),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}