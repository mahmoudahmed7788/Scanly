import 'package:flutter/material.dart';

class ImageToTextLanguageDropdown extends StatelessWidget {
  final String selectedLanguage;
  final List<Map<String, String>> languages;
  final bool disabled;
  final ValueChanged<String?> onChanged;

  const ImageToTextLanguageDropdown({
    super.key,
    required this.selectedLanguage,
    required this.languages,
    required this.disabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.grey.shade300,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedLanguage,
          isExpanded: true,
          icon: const Icon(
            Icons.keyboard_arrow_down,
          ),
          items: languages.map(
            (language) {
              return DropdownMenuItem<String>(
                value: language['code'],
                child: Text(
                  language['name'] ?? '',
                ),
              );
            },
          ).toList(),
          onChanged: disabled ? null : onChanged,
        ),
      ),
    );
  }
}