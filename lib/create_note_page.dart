import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:image_picker/image_picker.dart';
import 'package:scanly/Note_Model.dart';

class _PageEditorData {
  final String id;
  final QuillController controller;
  final FocusNode focusNode;
  final ScrollController scrollController;

  bool isLandscape;

  _PageEditorData({
    required this.id,
    required this.controller,
    required this.focusNode,
    required this.scrollController,
    this.isLandscape = false,
  });
}

class CreateNotePage extends StatefulWidget {
  final NoteModel? note;

  const CreateNotePage({
    super.key,
    this.note,
  });

  @override
  State<CreateNotePage> createState() => _CreateNotePageState();
}

class _CreateNotePageState extends State<CreateNotePage> {
  final ImagePicker _imagePicker = ImagePicker();

  final TextEditingController _titleController =
      TextEditingController();

  final List<_PageEditorData> _pages = [];
  final List<String> _imagePaths = [];
  final List<PdfAttachment> _pdfs = [];

  final List<Color> _noteColors = [
    const Color(0xFFFFF4E6),
    const Color(0xFFFFE8EC),
    const Color(0xFFE8F5E9),
    const Color(0xFFE3F2FD),
    const Color(0xFFEDE7F6),
    const Color(0xFFFFF8E1),
    const Color(0xFFE0F7FA),
    const Color(0xFFF3E5F5),
  ];

  static const List<String> _fontFamilies = [
    'Poppins',
    'Work Sans',
    'Roboto Slab',
  ];

  static const List<String> _fontSizes = [
    '10',
    '12',
    '14',
    '16',
    '18',
    '20',
    '24',
    '28',
    '32',
  ];

  int _currentPage = 0;
  bool _isPinned = false;
  int _colorValue = 0xFFFFF4E6;
  double _zoom = 1.0;

  _PageEditorData get _currentPageData => _pages[_currentPage];

  QuillController get _controller => _currentPageData.controller;

  @override
  void initState() {
    super.initState();

    _titleController.text = widget.note?.title ?? '';
    _isPinned = widget.note?.isPinned ?? false;
    _colorValue = widget.note?.colorValue ?? 0xFFFFF4E6;

    _imagePaths.addAll(widget.note?.imagePaths ?? []);
    _pdfs.addAll(widget.note?.pdfs ?? []);

    if (widget.note != null && widget.note!.pages.isNotEmpty) {
      for (final page in widget.note!.pages) {
        _pages.add(
          _createPage(
            id: page.id,
            quillData: page.quillData,
            isLandscape: page.isLandscape,
          ),
        );
      }
    } else {
      _pages.add(
        _createPage(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          quillData: widget.note?.quillData ?? [],
        ),
      );
    }
  }

  _PageEditorData _createPage({
    required String id,
    required List<dynamic> quillData,
    bool isLandscape = false,
  }) {
    Document document;

    try {
      if (quillData.isEmpty) {
        document = Document();
      } else {
        document = Document.fromJson(
          List<dynamic>.from(quillData),
        );
      }
    } catch (_) {
      document = Document();
    }

    final controller = QuillController(
      document: document,
      selection: const TextSelection.collapsed(
        offset: 0,
      ),
    );

    final focusNode = FocusNode();
    final scrollController = ScrollController();

    return _PageEditorData(
      id: id,
      controller: controller,
      focusNode: focusNode,
      scrollController: scrollController,
      isLandscape: isLandscape,
    );
  }

  @override
  void dispose() {
    for (final page in _pages) {
      page.controller.dispose();
      page.focusNode.dispose();
      page.scrollController.dispose();
    }

    _titleController.dispose();

    super.dispose();
  }

  void _addPage() {
    final page = _createPage(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      quillData: [],
    );

    setState(() {
      _pages.add(page);
      _currentPage = _pages.length - 1;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _currentPageData.focusNode.requestFocus();
      }
    });
  }

  void _deletePage() {
    if (_pages.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Theme.of(context).colorScheme.surface,
          content: Text(
            'You cannot delete the only page.',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
      );

      return;
    }

    final page = _pages[_currentPage];

    setState(() {
      _pages.removeAt(_currentPage);

      if (_currentPage >= _pages.length) {
        _currentPage = _pages.length - 1;
      }
    });

    page.controller.dispose();
    page.focusNode.dispose();
    page.scrollController.dispose();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _currentPageData.focusNode.requestFocus();
      }
    });
  }

  void _previousPage() {
    if (_currentPage <= 0) return;

    _currentPageData.focusNode.unfocus();

    setState(() {
      _currentPage--;
    });
  }

  void _nextPage() {
    if (_currentPage >= _pages.length - 1) return;

    _currentPageData.focusNode.unfocus();

    setState(() {
      _currentPage++;
    });
  }

  void _toggleOrientation() {
    setState(() {
      _currentPageData.isLandscape =
          !_currentPageData.isLandscape;
    });
  }

  Future<void> _pickImages() async {
    final images = await _imagePicker.pickMultiImage();

    if (images.isEmpty) return;

    setState(() {
      _imagePaths.addAll(
        images.map((image) => image.path),
      );
    });
  }

  Future<void> _pickPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result == null || result.files.isEmpty) {
      return;
    }

    final file = result.files.first;

    if (file.path == null) return;

    setState(() {
      _pdfs.add(
        PdfAttachment(
          path: file.path!,
          name: file.name,
          size: file.size,
        ),
      );
    });
  }

  void _removeImage(int index) {
    setState(() {
      _imagePaths.removeAt(index);
    });
  }

  void _removePdf(int index) {
    setState(() {
      _pdfs.removeAt(index);
    });
  }

  // ============================================================
  // TEXT FORMATTING
  // ============================================================

  void _applyAttribute(Attribute attribute) {
    final controller = _controller;

    controller.formatSelection(attribute);

    // Keep the editor focused after pressing toolbar buttons.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      _currentPageData.focusNode.requestFocus();

      setState(() {});
    });
  }

  void _applyValueAttribute(
    String key,
    String value,
  ) {
    final controller = _controller;

    controller.formatSelection(
      Attribute.fromKeyValue(
        key,
        value,
      ),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      _currentPageData.focusNode.requestFocus();

      setState(() {});
    });
  }

  void _applyFont(String font) {
    _controller.formatSelection(
      Attribute.fromKeyValue(
        Attribute.font.key,
        font,
      ),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      _currentPageData.focusNode.requestFocus();

      setState(() {});
    });
  }

  void _applyFontSize(String size) {
    _controller.formatSelection(
      Attribute.fromKeyValue(
        Attribute.size.key,
        size,
      ),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      _currentPageData.focusNode.requestFocus();

      setState(() {});
    });
  }

  bool _hasAttribute(String key) {
    final attributes =
        _controller.getSelectionStyle().attributes;

    if (attributes.containsKey(key)) {
      return true;
    }

    try {
      final toggled =
          _controller.toggledStyle.attributes;

      return toggled.containsKey(key);
    } catch (_) {
      return false;
    }
  }

  String _getCurrentFont() {
    final attributes =
        _controller.getSelectionStyle().attributes;

    return attributes[Attribute.font.key]
            ?.value
            ?.toString() ??
        'Poppins';
  }

  String _getCurrentFontSize() {
    final attributes =
        _controller.getSelectionStyle().attributes;

    return attributes[Attribute.size.key]
            ?.value
            ?.toString() ??
        '16';
  }

  // ============================================================
  // NOTE COLOR
  // ============================================================

  void _showColorPicker() {
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(28),
        ),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              24,
              18,
              24,
              30,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: theme.dividerColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Note Color',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 14,
                  runSpacing: 14,
                  children: _noteColors.map((color) {
                    final selected =
                        color.value == _colorValue;

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _colorValue = color.value;
                        });

                        Navigator.pop(context);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(
                          milliseconds: 180,
                        ),
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: selected
                                ? theme.colorScheme.primary
                                : Colors.transparent,
                            width: 3,
                          ),
                        ),
                        child: selected
                            ? Icon(
                                Icons.check,
                                color:
                                    theme.colorScheme.primary,
                              )
                            : null,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // ZOOM
  // ============================================================

  void _showZoomPicker() {
    double tempZoom = _zoom;

    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(28),
        ),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  24,
                  18,
                  24,
                  30,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: theme.dividerColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Icon(
                          Icons.zoom_in,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Editor Zoom',
                          style:
                              theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${(tempZoom * 100).round()}%',
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Slider(
                      value: tempZoom,
                      min: 0.8,
                      max: 1.6,
                      divisions: 16,
                      onChanged: (value) {
                        setModalState(() {
                          tempZoom = value;
                        });
                      },
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () {
                          setState(() {
                            _zoom = tempZoom;
                          });

                          Navigator.pop(context);
                        },
                        child: const Text('Apply'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ============================================================
  // FONT PICKER
  // ============================================================

  void _showFontFamilyPicker() {
    final currentFont = _getCurrentFont();
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(28),
        ),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: _fontFamilies.map((font) {
              final selected = currentFont == font;

              return ListTile(
                title: Text(
                  font,
                  style: TextStyle(
                    fontFamily: font,
                    fontSize: 17,
                  ),
                ),
                trailing: selected
                    ? Icon(
                        Icons.check_circle,
                        color: theme.colorScheme.primary,
                      )
                    : null,
                onTap: () {
                  _applyFont(font);
                  Navigator.pop(context);
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  // ============================================================
  // FONT SIZE PICKER
  // ============================================================

  void _showFontSizePicker() {
    final currentSize = _getCurrentFontSize();
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    showModalBottomSheet(
      context: context,
      backgroundColor: colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(28),
        ),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              20,
              20,
              20,
              24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Font Size',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _fontSizes.map((size) {
                    final selected =
                        size == currentSize;

                    return InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () {
                        _applyFontSize(size);
                        Navigator.pop(context);
                      },
                      child: Container(
                        width: 64,
                        height: 52,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: selected
                              ? colors.primary
                              : colors.surfaceContainerHighest,
                          borderRadius:
                              BorderRadius.circular(14),
                        ),
                        child: Text(
                          size,
                          style: TextStyle(
                            color: selected
                                ? Colors.white
                                : colors.onSurface,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // TEXT COLORS
  // ============================================================

  void _showTextColorPicker() {
    final colors = [
      Colors.black,
      const Color(0xFF292653),
      const Color(0xFF5B5FEF),
      const Color(0xFF7C5CFC),
      const Color(0xFF00838F),
      Colors.red,
      Colors.green,
      Colors.orange,
      Colors.white,
    ];

    _showColorSheet(
      title: 'Text Color',
      colors: colors,
      onSelected: (color) {
        _applyValueAttribute(
          Attribute.color.key,
          '#${color.value.toRadixString(16).substring(2)}',
        );
      },
    );
  }

  void _showBackgroundColorPicker() {
    final colors = [
      Colors.transparent,
      Colors.yellow.shade200,
      Colors.green.shade200,
      Colors.blue.shade200,
      Colors.pink.shade200,
      Colors.orange.shade200,
      Colors.purple.shade200,
    ];

    _showColorSheet(
      title: 'Text Background',
      colors: colors,
      onSelected: (color) {
        if (color == Colors.transparent) {
          _controller.formatSelection(
            Attribute.fromKeyValue(
              Attribute.background.key,
              null,
            ),
          );
        } else {
          _applyValueAttribute(
            Attribute.background.key,
            '#${color.value.toRadixString(16).substring(2)}',
          );
        }

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;

          _currentPageData.focusNode.requestFocus();
          setState(() {});
        });
      },
    );
  }

  void _showColorSheet({
    required String title,
    required List<Color> colors,
    required ValueChanged<Color> onSelected,
  }) {
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(28),
        ),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              24,
              18,
              24,
              30,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 14,
                  runSpacing: 14,
                  children: colors.map((color) {
                    return GestureDetector(
                      onTap: () {
                        onSelected(color);
                        Navigator.pop(context);
                      },
                      child: Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: color == Colors.transparent
                              ? theme.colorScheme.surface
                              : color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: theme.dividerColor,
                          ),
                        ),
                        child: color == Colors.transparent
                            ? Icon(
                                Icons.clear,
                                color:
                                    theme.colorScheme.onSurface,
                              )
                            : null,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // TOOLBAR
  // ============================================================

  Widget _toolbarButton({
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

  Widget _buildToolbar() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          _toolbarButton(
            icon: Icons.font_download_outlined,
            tooltip: 'Font Family',
            onPressed: _showFontFamilyPicker,
          ),

          _toolbarButton(
            icon: Icons.format_size,
            tooltip: 'Font Size',
            onPressed: _showFontSizePicker,
          ),

          _toolbarButton(
            icon: Icons.format_bold,
            tooltip: 'Bold',
            selected: _hasAttribute(Attribute.bold.key),
            onPressed: () {
              _applyAttribute(Attribute.bold);
            },
          ),

          _toolbarButton(
            icon: Icons.format_italic,
            tooltip: 'Italic',
            selected: _hasAttribute(Attribute.italic.key),
            onPressed: () {
              _applyAttribute(Attribute.italic);
            },
          ),

          _toolbarButton(
            icon: Icons.format_underlined,
            tooltip: 'Underline',
            selected: _hasAttribute(Attribute.underline.key),
            onPressed: () {
              _applyAttribute(Attribute.underline);
            },
          ),

          _toolbarButton(
            icon: Icons.format_strikethrough,
            tooltip: 'Strike',
            selected:
                _hasAttribute(Attribute.strikeThrough.key),
            onPressed: () {
              _applyAttribute(Attribute.strikeThrough);
            },
          ),

          _toolbarButton(
            icon: Icons.format_color_text,
            tooltip: 'Text Color',
            onPressed: _showTextColorPicker,
          ),

          _toolbarButton(
            icon: Icons.format_color_fill,
            tooltip: 'Background Color',
            onPressed: _showBackgroundColorPicker,
          ),

          _toolbarButton(
            icon: Icons.format_list_numbered,
            tooltip: 'Numbered List',
            onPressed: () {
              _applyAttribute(Attribute.ol);
            },
          ),

          _toolbarButton(
            icon: Icons.format_list_bulleted,
            tooltip: 'Bullet List',
            onPressed: () {
              _applyAttribute(Attribute.ul);
            },
          ),

          _toolbarButton(
            icon: Icons.format_align_left,
            tooltip: 'Align Left',
            onPressed: () {
              _applyValueAttribute(
                Attribute.align.key,
                'left',
              );
            },
          ),

          _toolbarButton(
            icon: Icons.format_align_center,
            tooltip: 'Align Center',
            onPressed: () {
              _applyValueAttribute(
                Attribute.align.key,
                'center',
              );
            },
          ),

          _toolbarButton(
            icon: Icons.format_align_right,
            tooltip: 'Align Right',
            onPressed: () {
              _applyValueAttribute(
                Attribute.align.key,
                'right',
              );
            },
          ),

          _toolbarButton(
            icon: Icons.format_indent_increase,
            tooltip: 'Indent',
            onPressed: () {
              _applyAttribute(Attribute.indentL1);
            },
          ),

          _toolbarButton(
            icon: Icons.format_quote,
            tooltip: 'Quote',
            onPressed: () {
              _applyAttribute(Attribute.blockQuote);
            },
          ),

          _toolbarButton(
            icon: Icons.undo,
            tooltip: 'Undo',
            onPressed: () {
              _controller.undo();

              if (mounted) {
                setState(() {});
              }
            },
          ),

          _toolbarButton(
            icon: Icons.redo,
            tooltip: 'Redo',
            onPressed: () {
              _controller.redo();

              if (mounted) {
                setState(() {});
              }
            },
          ),

          _toolbarButton(
            icon: Icons.format_clear,
            tooltip: 'Clear Formatting',
            onPressed: () {
              _controller.formatSelection(null);

              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;

                _currentPageData.focusNode.requestFocus();
                setState(() {});
              });
            },
          ),
        ],
      ),
    );
  }

  // ============================================================
  // EDITOR
  // ============================================================

  Widget _buildEditor() {
    final theme = Theme.of(context);

    final height =
        _currentPageData.isLandscape ? 360.0 : 520.0;

    return Container(
      width: double.infinity,
      height: height,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.25),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha:
                  theme.brightness == Brightness.dark ? 0.22 : 0.06,
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
              color: theme.colorScheme.surfaceContainerHighest
                  .withValues(alpha: 0.42),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(22),
              ),
            ),
            child: _buildToolbar(),
          ),

          Divider(
            height: 1,
            color: theme.dividerColor.withValues(alpha: 0.25),
          ),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                20,
                18,
                20,
                18,
              ),
              child: Transform.scale(
                scale: _zoom,
                alignment: Alignment.topLeft,
                child: QuillEditor.basic(
                  controller: _controller,
                  focusNode: _currentPageData.focusNode,
                  scrollController:
                      _currentPageData.scrollController,
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

  // ============================================================
  // PAGE NAVIGATION
  // ============================================================

  Widget _buildPageNavigation() {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed:
                _currentPage > 0 ? _previousPage : null,
            style: IconButton.styleFrom(
              backgroundColor: theme
                  .colorScheme
                  .surfaceContainerHighest
                  .withValues(alpha: 0.5),
            ),
            icon: const Icon(Icons.chevron_left),
          ),

          Expanded(
            child: Column(
              children: [
                Text(
                  'PAGE ${_currentPage + 1}',
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'of ${_pages.length}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color:
                        theme.colorScheme.onSurface.withValues(alpha: 0.55),
                  ),
                ),
              ],
            ),
          ),

          IconButton(
            onPressed:
                _currentPage < _pages.length - 1 ? _nextPage : null,
            style: IconButton.styleFrom(
              backgroundColor: theme
                  .colorScheme
                  .surfaceContainerHighest
                  .withValues(alpha: 0.5),
            ),
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ATTACHMENTS
  // ============================================================

  Widget _buildAttachments() {
    final theme = Theme.of(context);

    if (_imagePaths.isEmpty && _pdfs.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 22),

        Row(
          children: [
            Icon(
              Icons.attach_file,
              size: 20,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              'Attachments',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        if (_imagePaths.isNotEmpty)
          SizedBox(
            height: 105,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _imagePaths.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final path = _imagePaths[index];

                return Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.file(
                        File(path),
                        width: 105,
                        height: 105,
                        fit: BoxFit.cover,
                        errorBuilder:
                            (context, error, stackTrace) {
                          return Container(
                            width: 105,
                            height: 105,
                            decoration: BoxDecoration(
                              color: theme
                                  .colorScheme
                                  .surfaceContainerHighest,
                              borderRadius:
                                  BorderRadius.circular(16),
                            ),
                            child: Icon(
                              Icons.broken_image_outlined,
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.55),
                            ),
                          );
                        },
                      ),
                    ),

                    Positioned(
                      top: 6,
                      right: 6,
                      child: GestureDetector(
                        onTap: () => _removeImage(index),
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.62),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 17,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

        if (_pdfs.isNotEmpty)
          const SizedBox(height: 12),

        ...List.generate(
          _pdfs.length,
          (index) {
            final pdf = _pdfs[index];

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: theme
                    .colorScheme
                    .surfaceContainerHighest
                    .withValues(alpha: 0.42),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: theme.dividerColor.withValues(alpha: 0.22),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary
                          .withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.picture_as_pdf,
                      color: theme.colorScheme.primary,
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Text(
                      pdf.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  IconButton(
                    onPressed: () => _removePdf(index),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  // ============================================================
  // SAVE
  // ============================================================

  Future<void> _saveNote() async {
    _currentPageData.focusNode.unfocus();

    FocusManager.instance.primaryFocus?.unfocus();

    final now = DateTime.now();

    final pages = _pages.map((page) {
      final data =
          page.controller.document.toDelta().toJson();

      return NotePageModel(
        id: page.id,
        quillData: data,
        isLandscape: page.isLandscape,
      );
    }).toList();

    final firstPageData = pages.first.quillData;

    final note = NoteModel(
      id: widget.note?.id ??
          DateTime.now().microsecondsSinceEpoch.toString(),

      title: _titleController.text.trim().isEmpty
          ? 'Untitled Note'
          : _titleController.text.trim(),

      quillData: firstPageData,
      pages: pages,
      isPinned: _isPinned,
      colorValue: _colorValue,
      imagePaths: List<String>.from(_imagePaths),
      pdfs: List<PdfAttachment>.from(_pdfs),
      createdAt: widget.note?.createdAt ?? now,
      updatedAt: now,
    );

    if (!mounted) return;

    Navigator.of(context).pop(note);
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: colors.surface,
      resizeToAvoidBottomInset: true,

      appBar: AppBar(
        backgroundColor: colors.surface,
        foregroundColor: colors.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,

        leading: Padding(
          padding: const EdgeInsets.only(left: 8),
          child: IconButton(
            tooltip: 'Back',
            onPressed: () {
              Navigator.of(context).pop();
            },
            style: IconButton.styleFrom(
              backgroundColor:
                  colors.surfaceContainerHighest.withValues(
                alpha: isDark ? 0.55 : 0.7,
              ),
            ),
            icon: const Icon(Icons.arrow_back),
          ),
        ),

        titleSpacing: 8,

        title: Row(
          children: [
            Container(
              width: 8,
              height: 30,
              decoration: BoxDecoration(
                color: Color(_colorValue),
                borderRadius: BorderRadius.circular(10),
              ),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: TextField(
                controller: _titleController,
                maxLines: 1,
                textInputAction: TextInputAction.done,
                style: TextStyle(
                  color: colors.onSurface,
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                ),
                decoration: InputDecoration(
                  hintText: 'Note title',
                  hintStyle: TextStyle(
                    color: colors.onSurface.withValues(alpha: 0.45),
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
          ],
        ),

        actions: [
          IconButton(
            tooltip: 'Note color',
            onPressed: _showColorPicker,
            icon: Icon(
              Icons.palette_outlined,
              color: colors.primary,
            ),
          ),

          IconButton(
            tooltip: 'Zoom',
            onPressed: _showZoomPicker,
            icon: Icon(
              Icons.zoom_in,
              color: colors.primary,
            ),
          ),

          IconButton(
            tooltip: 'Orientation',
            onPressed: _toggleOrientation,
            icon: Icon(
              _currentPageData.isLandscape
                  ? Icons.stay_current_landscape
                  : Icons.stay_current_portrait,
              color: colors.primary,
            ),
          ),

          IconButton(
            tooltip: 'Pin',
            onPressed: () {
              setState(() {
                _isPinned = !_isPinned;
              });
            },
            icon: Icon(
              _isPinned
                  ? Icons.push_pin
                  : Icons.push_pin_outlined,
              color: _isPinned
                  ? colors.primary
                  : colors.onSurface.withValues(alpha: 0.75),
            ),
          ),

          const SizedBox(width: 4),

          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: IconButton(
              tooltip: 'Save',
              onPressed: _saveNote,
              style: IconButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.check),
            ),
          ),
        ],
      ),

      body: SafeArea(
        child: ListView(
          keyboardDismissBehavior:
              ScrollViewKeyboardDismissBehavior.manual,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            16,
            10,
            16,
            32,
          ),
          children: [
            _buildPageNavigation(),

            const SizedBox(height: 14),

            _buildEditor(),

            const SizedBox(height: 14),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _addPage,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Page'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: OutlinedButton.icon(
                    onPressed:
                        _pages.length > 1 ? _deletePage : null,
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Delete Page'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 52),
                      foregroundColor: colors.error,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickImages,
                    icon: const Icon(Icons.image_outlined),
                    label: const Text('Add Images'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickPdf,
                    icon: const Icon(Icons.picture_as_pdf),
                    label: const Text('Add PDF'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            _buildAttachments(),
          ],
        ),
      ),
    );
  }
}