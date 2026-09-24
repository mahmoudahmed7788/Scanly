import 'package:flutter/material.dart';

class PDFDrawColorPicker {
  PDFDrawColorPicker._();

  static void show({
    required BuildContext context,
    required Color selectedColor,
    required ValueChanged<Color> onColorSelected,
  }) {
    final colors = <Color>[
      Colors.red,
      Colors.black,
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.white,
    ];

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Wrap(
              spacing: 18,
              runSpacing: 18,
              children: colors.map((color) {
                final isSelected = color.value == selectedColor.value;

                return GestureDetector(
                  onTap: () {
                    onColorSelected(color);

                    Navigator.of(sheetContext).pop();
                  },
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected
                            ? Colors.blue
                            : Colors.grey,
                        width: isSelected ? 3 : 1.5,
                      ),
                    ),
                    child: isSelected
                        ? Icon(
                            Icons.check_rounded,
                            color: color.computeLuminance() > .5
                                ? Colors.black
                                : Colors.white,
                          )
                        : null,
                  ),
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }
}