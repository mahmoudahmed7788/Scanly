import 'package:flutter/material.dart';

class NotesSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final String searchText;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const NotesSearchBar({
    super.key,
    required this.controller,
    required this.searchText,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final colors =
        Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius:
            BorderRadius.circular(16),
        border: Border.all(
          color:
              colors.outline.withValues(
            alpha: .10,
          ),
        ),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: 'Search notes...',
          prefixIcon: Icon(
            Icons.search_rounded,
            color: colors.primary,
          ),
          suffixIcon:
              searchText.isNotEmpty
                  ? IconButton(
                      onPressed: onClear,
                      icon: const Icon(
                        Icons.close_rounded,
                      ),
                    )
                  : null,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
    );
  }
}