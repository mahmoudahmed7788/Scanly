import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

class NoteEditorToolbar extends StatelessWidget {
  final QuillController controller;
  final bool Function(String key) hasAttribute;

  final VoidCallback onFontFamily;
  final VoidCallback onFontSize;
  final VoidCallback onTextColor;
  final VoidCallback onBackgroundColor;

  final void Function(Attribute attribute) onAttribute;
  final void Function(String key, String value) onValueAttribute;

  final VoidCallback onRefresh;

  const NoteEditorToolbar({
    super.key,
    required this.controller,
    required this.hasAttribute,
    required this.onFontFamily,
    required this.onFontSize,
    required this.onTextColor,
    required this.onBackgroundColor,
    required this.onAttribute,
    required this.onValueAttribute,
    required this.onRefresh, required void Function(Attribute<dynamic> attribute) onApplyAttribute, required void Function(String key, String value) onApplyValueAttribute, required VoidCallback onUndo, required VoidCallback onRedo, required VoidCallback onClearFormatting,
  });

  Widget _button({
    required BuildContext context,
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
    bool selected = false,
  }) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        style: IconButton.styleFrom(
          backgroundColor: selected
              ? theme.colorScheme.primary.withValues(alpha: 0.16)
              : Colors.transparent,
          foregroundColor: selected
              ? theme.colorScheme.primary
              : theme.colorScheme.onSurface.withValues(alpha: 0.78),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        icon: Icon(
          icon,
          size: 19,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          _button(
            context: context,
            icon: Icons.font_download_outlined,
            tooltip: 'Font Family',
            onPressed: onFontFamily,
          ),

          _button(
            context: context,
            icon: Icons.format_size,
            tooltip: 'Font Size',
            onPressed: onFontSize,
          ),

          _button(
            context: context,
            icon: Icons.format_bold,
            tooltip: 'Bold',
            selected: hasAttribute(Attribute.bold.key),
            onPressed: () {
              onAttribute(Attribute.bold);
            },
          ),

          _button(
            context: context,
            icon: Icons.format_italic,
            tooltip: 'Italic',
            selected: hasAttribute(Attribute.italic.key),
            onPressed: () {
              onAttribute(Attribute.italic);
            },
          ),

          _button(
            context: context,
            icon: Icons.format_underlined,
            tooltip: 'Underline',
            selected: hasAttribute(Attribute.underline.key),
            onPressed: () {
              onAttribute(Attribute.underline);
            },
          ),

          _button(
            context: context,
            icon: Icons.format_strikethrough,
            tooltip: 'Strike',
            selected: hasAttribute(
              Attribute.strikeThrough.key,
            ),
            onPressed: () {
              onAttribute(Attribute.strikeThrough);
            },
          ),

          _button(
            context: context,
            icon: Icons.format_color_text,
            tooltip: 'Text Color',
            onPressed: onTextColor,
          ),

          _button(
            context: context,
            icon: Icons.format_color_fill,
            tooltip: 'Background Color',
            onPressed: onBackgroundColor,
          ),

          _button(
            context: context,
            icon: Icons.format_list_numbered,
            tooltip: 'Numbered List',
            onPressed: () {
              onAttribute(Attribute.ol);
            },
          ),

          _button(
            context: context,
            icon: Icons.format_list_bulleted,
            tooltip: 'Bullet List',
            onPressed: () {
              onAttribute(Attribute.ul);
            },
          ),

          _button(
            context: context,
            icon: Icons.format_align_left,
            tooltip: 'Align Left',
            onPressed: () {
              onValueAttribute(
                Attribute.align.key,
                'left',
              );
            },
          ),

          _button(
            context: context,
            icon: Icons.format_align_center,
            tooltip: 'Align Center',
            onPressed: () {
              onValueAttribute(
                Attribute.align.key,
                'center',
              );
            },
          ),

          _button(
            context: context,
            icon: Icons.format_align_right,
            tooltip: 'Align Right',
            onPressed: () {
              onValueAttribute(
                Attribute.align.key,
                'right',
              );
            },
          ),

          _button(
            context: context,
            icon: Icons.format_indent_increase,
            tooltip: 'Indent',
            onPressed: () {
              onAttribute(Attribute.indentL1);
            },
          ),

          _button(
            context: context,
            icon: Icons.format_quote,
            tooltip: 'Quote',
            onPressed: () {
              onAttribute(Attribute.blockQuote);
            },
          ),

          _button(
            context: context,
            icon: Icons.undo,
            tooltip: 'Undo',
            onPressed: () {
              controller.undo();
              onRefresh();
            },
          ),

          _button(
            context: context,
            icon: Icons.redo,
            tooltip: 'Redo',
            onPressed: () {
              controller.redo();
              onRefresh();
            },
          ),

          _button(
            context: context,
            icon: Icons.format_clear,
            tooltip: 'Clear Formatting',
            onPressed: () {
              controller.formatSelection(null);
              onRefresh();
            },
          ),
        ],
      ),
    );
  }
}