import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:scanly/Widgets/Notes/NoteEditorToolbar.dart';

class NoteEditor extends StatelessWidget {
  final QuillController controller;
  final FocusNode focusNode;
  final ScrollController scrollController;

  final bool isLandscape;
  final double zoom;

  final VoidCallback onFontFamily;
  final VoidCallback onFontSize;
  final VoidCallback onTextColor;
  final VoidCallback onBackgroundColor;

  final void Function(Attribute attribute) onApplyAttribute;
  final void Function(String key, String value) onApplyValueAttribute;

  final bool Function(String key) hasAttribute;

  final VoidCallback onUndo;
  final VoidCallback onRedo;
  final VoidCallback onClearFormatting;

  const NoteEditor({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.scrollController,
    required this.isLandscape,
    required this.zoom,
    required this.onFontFamily,
    required this.onFontSize,
    required this.onTextColor,
    required this.onBackgroundColor,
    required this.onApplyAttribute,
    required this.onApplyValueAttribute,
    required this.hasAttribute,
    required this.onUndo,
    required this.onRedo,
    required this.onClearFormatting,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final height = isLandscape ? 360.0 : 520.0;

    return Container(
      width: double.infinity,
      height: height,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: theme.brightness == Brightness.dark ? 0.22 : 0.06,
            ),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            height: 58,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.42,
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(22),
              ),
            ),
            child: NoteEditorToolbar(
              controller: controller,
              onFontFamily: onFontFamily,
              onFontSize: onFontSize,
              onTextColor: onTextColor,
              onBackgroundColor: onBackgroundColor,
              onApplyAttribute: onApplyAttribute,
              onApplyValueAttribute: onApplyValueAttribute,
              hasAttribute: hasAttribute,
              onUndo: onUndo,
              onRedo: onRedo,
              onClearFormatting: onClearFormatting, onAttribute: (Attribute<dynamic> attribute) {  }, onValueAttribute: (String key, String value) {  }, onRefresh: () {  },
            ),
          ),

          Divider(height: 1, color: theme.dividerColor.withValues(alpha: 0.25)),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
              child: Transform.scale(
                scale: zoom,
                alignment: Alignment.topLeft,
                child: QuillEditor.basic(
                  controller: controller,
                  focusNode: focusNode,
                  scrollController: scrollController,
                  config: const QuillEditorConfig(
                    placeholder: 'Start writing...',
                    padding: EdgeInsets.zero,
                    autoFocus: false,
                    expands: true,
                    scrollable: true,
                    showCursor: true,
                    enableInteractiveSelection: true,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
