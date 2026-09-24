import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:image_picker/image_picker.dart';
import 'package:scanly/Models/Note_Model.dart';
import 'package:scanly/Models/PageEditorData.dart';
import 'package:scanly/Widgets/Notes/NoteAttachments.dart';
import 'package:scanly/Widgets/Notes/NoteEditor.dart';
import 'package:scanly/Widgets/Notes/NotePageNavigation.dart';
import 'package:scanly/Widgets/Notes/NotePickerSheets.dart';

class CreateNotePage extends StatefulWidget {
  final NoteModel? note;

  const CreateNotePage({super.key, this.note});

  @override
  State<CreateNotePage> createState() => _CreateNotePageState();
}

class _CreateNotePageState extends State<CreateNotePage> {
  final ImagePicker _imagePicker = ImagePicker();

  final TextEditingController _titleController = TextEditingController();

  final List<NotePageEditorData> _pages = [];
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

  NotePageEditorData get _currentPageData => _pages[_currentPage];

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

  NotePageEditorData _createPage({
    required String id,
    required List<dynamic> quillData,
    bool isLandscape = false,
  }) {
    Document document;

    try {
      if (quillData.isEmpty) {
        document = Document();
      } else {
        document = Document.fromJson(List<dynamic>.from(quillData));
      }
    } catch (_) {
      document = Document();
    }

    final controller = QuillController(
      document: document,
      selection: const TextSelection.collapsed(offset: 0),
    );

    final focusNode = FocusNode();
    final scrollController = ScrollController();

    return NotePageEditorData(
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
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
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
      _currentPageData.isLandscape = !_currentPageData.isLandscape;
    });
  }

  Future<void> _pickImages() async {
    final images = await _imagePicker.pickMultiImage();

    if (images.isEmpty) return;

    setState(() {
      _imagePaths.addAll(images.map((image) => image.path));
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
        PdfAttachment(path: file.path!, name: file.name, size: file.size),
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
    _controller.formatSelection(attribute);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      _currentPageData.focusNode.requestFocus();

      setState(() {});
    });
  }

  void _applyValueAttribute(String key, String value) {
    _controller.formatSelection(Attribute.fromKeyValue(key, value));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      _currentPageData.focusNode.requestFocus();

      setState(() {});
    });
  }

  void _applyFont(String font) {
    _controller.formatSelection(
      Attribute.fromKeyValue(Attribute.font.key, font),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      _currentPageData.focusNode.requestFocus();

      setState(() {});
    });
  }

  void _applyFontSize(String size) {
    _controller.formatSelection(
      Attribute.fromKeyValue(Attribute.size.key, size),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      _currentPageData.focusNode.requestFocus();

      setState(() {});
    });
  }

  bool _hasAttribute(String key) {
    final attributes = _controller.getSelectionStyle().attributes;

    if (attributes.containsKey(key)) {
      return true;
    }

    try {
      final toggled = _controller.toggledStyle.attributes;

      return toggled.containsKey(key);
    } catch (_) {
      return false;
    }
  }

  String _getCurrentFont() {
    final attributes = _controller.getSelectionStyle().attributes;

    return attributes[Attribute.font.key]?.value?.toString() ?? 'Poppins';
  }

  String _getCurrentFontSize() {
    final attributes = _controller.getSelectionStyle().attributes;

    return attributes[Attribute.size.key]?.value?.toString() ?? '16';
  }

  // ============================================================
  // PICKERS
  // ============================================================

  Future<void> _showColorPicker() async {
    await NotePickerSheets.showNoteColorPicker(
      context: context,
      colors: _noteColors,
      currentColorValue: _colorValue,
      onSelected: (color) {
        setState(() {
          _colorValue = color.value;
        });
      },
    );
  }

  Future<void> _showZoomPicker() async {
    await NotePickerSheets.showZoomPicker(
      context: context,
      currentZoom: _zoom,
      onApply: (value) {
        setState(() {
          _zoom = value;
        });
      },
    );
  }

  Future<void> _showFontFamilyPicker() async {
    await NotePickerSheets.showFontFamilyPicker(
      context: context,
      currentFont: _getCurrentFont(),
      fonts: _fontFamilies,
      onSelected: _applyFont,
    );
  }

  Future<void> _showFontSizePicker() async {
    await NotePickerSheets.showFontSizePicker(
      context: context,
      currentSize: _getCurrentFontSize(),
      sizes: _fontSizes,
      onSelected: _applyFontSize,
    );
  }

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

    NotePickerSheets.showColorSheet(
      context: context,
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

    NotePickerSheets.showColorSheet(
      context: context,
      title: 'Text Background',
      colors: colors,
      onSelected: (color) {
        if (color == Colors.transparent) {
          _controller.formatSelection(
            Attribute.fromKeyValue(Attribute.background.key, null),
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

  // ============================================================
  // SAVE
  // ============================================================

  Future<void> _saveNote() async {
    _currentPageData.focusNode.unfocus();

    FocusManager.instance.primaryFocus?.unfocus();

    final now = DateTime.now();

    final pages = _pages.map((page) {
      final data = page?.controller.document.toDelta().toJson();

      return NotePageModel(
        id: page!.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
        quillData: data ?? <dynamic>[],
        isLandscape: page.isLandscape ?? false,
      );
    }).toList();

    final firstPageData = pages.first.quillData;

    final note = NoteModel(
      id: widget.note?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
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
              backgroundColor: colors.surfaceContainerHighest.withValues(
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
            icon: Icon(Icons.palette_outlined, color: colors.primary),
          ),

          IconButton(
            tooltip: 'Zoom',
            onPressed: _showZoomPicker,
            icon: Icon(Icons.zoom_in, color: colors.primary),
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
              _isPinned ? Icons.push_pin : Icons.push_pin_outlined,
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
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.manual,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 32),
          children: [
            NotePageNavigation(
              currentPage: _currentPage,
              pageCount: _pages.length,
              onPrevious: _previousPage,
              onNext: _nextPage,
            ),

            const SizedBox(height: 14),

            NoteEditor(
              controller: _controller,
              focusNode: _currentPageData.focusNode,
              scrollController: _currentPageData.scrollController,
              isLandscape: _currentPageData.isLandscape,
              zoom: _zoom,
              onFontFamily: _showFontFamilyPicker,
              onFontSize: _showFontSizePicker,
              onTextColor: _showTextColorPicker,
              onBackgroundColor: _showBackgroundColorPicker,
              onApplyAttribute: _applyAttribute,
              onApplyValueAttribute: _applyValueAttribute,
              hasAttribute: _hasAttribute,
              onUndo: () {
                _controller.undo();

                if (mounted) {
                  setState(() {});
                }
              },
              onRedo: () {
                _controller.redo();

                if (mounted) {
                  setState(() {});
                }
              },
              onClearFormatting: () {
                _controller.formatSelection(null);

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!mounted) return;

                  _currentPageData.focusNode.requestFocus();
                  setState(() {});
                });
              },
            ),

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
                    onPressed: _pages.length > 1 ? _deletePage : null,
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

            NoteAttachments(
              imagePaths: _imagePaths,
              pdfs: _pdfs,
              onRemoveImage: _removeImage,
              onRemovePdf: _removePdf,
            ),
          ],
        ),
      ),
    );
  }
}

extension on Object? {
  bool? get isLandscape => null;

  get controller => null;

  String? get id => null;
}
