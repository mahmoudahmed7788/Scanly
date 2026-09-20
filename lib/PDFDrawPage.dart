import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class PDFDrawPage extends StatefulWidget {
  final Uint8List imageBytes;

  const PDFDrawPage({
    super.key,
    required this.imageBytes,
  });

  @override
  State<PDFDrawPage> createState() => _PDFDrawPageState();
}

class _PDFDrawPageState extends State<PDFDrawPage> {
  final GlobalKey _canvasKey = GlobalKey();

  final List<_DrawLine> _lines = [];
  final List<_DrawLine> _redoLines = [];
  final List<_TextItem> _texts = [];

  Color _selectedColor = Colors.red;
  double _strokeWidth = 4;
  bool _eraser = false;

  bool _saving = false;

  // =========================================================
  // Undo
  // =========================================================

  void _undo() {
    if (_lines.isEmpty && _texts.isEmpty) {
      return;
    }

    setState(() {
      if (_texts.isNotEmpty) {
        _texts.removeLast();
      } else if (_lines.isNotEmpty) {
        _redoLines.add(_lines.removeLast());
      }
    });
  }

  // =========================================================
  // Redo
  // =========================================================

  void _redo() {
    if (_redoLines.isEmpty) {
      return;
    }

    setState(() {
      _lines.add(_redoLines.removeLast());
    });
  }

  // =========================================================
  // Clear
  // =========================================================

  void _clear() {
    if (_lines.isEmpty && _texts.isEmpty) {
      return;
    }

    setState(() {
      _lines.clear();
      _redoLines.clear();
      _texts.clear();
    });
  }

  // =========================================================
  // Add Text
  // =========================================================

  Future<void> _addText() async {
    if (!mounted) {
      return;
    }

    final controller = TextEditingController();
    final focusNode = FocusNode();

    String? result;

    try {
      result = await showModalBottomSheet<String>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Theme.of(context).colorScheme.surface,
        builder: (sheetContext) {
          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Add Text',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Close',
                      onPressed: () {
                        Navigator.of(sheetContext).pop();
                      },
                      icon: const Icon(
                        Icons.close_rounded,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                TextField(
                  controller: controller,
                  focusNode: focusNode,
                  autofocus: true,
                  minLines: 1,
                  maxLines: 5,
                  textInputAction: TextInputAction.done,
                  decoration: InputDecoration(
                    hintText: 'Write something...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 14,
                    ),
                  ),
                  onSubmitted: (value) {
                    final text = value.trim();

                    if (text.isEmpty) {
                      return;
                    }

                    Navigator.of(sheetContext).pop(text);
                  },
                ),

                const SizedBox(height: 14),

                SizedBox(
                  height: 50,
                  child: FilledButton.icon(
                    onPressed: () {
                      final text = controller.text.trim();

                      if (text.isEmpty) {
                        return;
                      }

                      Navigator.of(sheetContext).pop(text);
                    },
                    icon: const Icon(
                      Icons.add_rounded,
                    ),
                    label: const Text(
                      'Add Text',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    } catch (e, stackTrace) {
      debugPrint('ADD TEXT ERROR: $e');
      debugPrint(stackTrace.toString());
    } finally {
      focusNode.dispose();
      controller.dispose();
    }

    if (!mounted) {
      return;
    }

    if (result == null || result.trim().isEmpty) {
      return;
    }

    setState(() {
      _texts.add(
        _TextItem(
          text: result!.trim(),
          position: const Offset(80, 100),
          color: _selectedColor,
        ),
      );
    });
  }

  // =========================================================
  // Save Edited Image
  // =========================================================

  Future<void> _saveImage() async {
    if (_saving) {
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      await Future<void>.delayed(
        const Duration(milliseconds: 50),
      );

      final renderObject =
          _canvasKey.currentContext?.findRenderObject();

      if (renderObject is! RenderRepaintBoundary) {
        throw Exception(
          'Canvas is not ready.',
        );
      }

      final image = await renderObject.toImage(
        pixelRatio: 2.5,
      );

      final byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );

      image.dispose();

      if (byteData == null) {
        throw Exception(
          'Unable to create image bytes.',
        );
      }

      final bytes = byteData.buffer.asUint8List();

      if (!mounted) {
        return;
      }

      Navigator.pop(
        context,
        Uint8List.fromList(bytes),
      );
    } catch (e, stackTrace) {
      debugPrint('SAVE IMAGE ERROR: $e');
      debugPrint(stackTrace.toString());

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Failed to save changes.',
            ),
          ),
        );
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  // =========================================================
  // Color Picker
  // =========================================================

  void _showColorPicker() {
    if (!mounted) {
      return;
    }

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
                return GestureDetector(
                  onTap: () {
                    if (!mounted) {
                      return;
                    }

                    setState(() {
                      _selectedColor = color;
                    });

                    Navigator.of(sheetContext).pop();
                  },
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.grey,
                        width: 1.5,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  // =========================================================
  // Page
  // =========================================================

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text(
          'Edit Page',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Undo',
            onPressed:
                (_lines.isEmpty && _texts.isEmpty)
                    ? null
                    : _undo,
            icon: const Icon(
              Icons.undo_rounded,
            ),
          ),
          IconButton(
            tooltip: 'Redo',
            onPressed:
                _redoLines.isEmpty
                    ? null
                    : _redo,
            icon: const Icon(
              Icons.redo_rounded,
            ),
          ),
          IconButton(
            tooltip: 'Clear',
            onPressed: _clear,
            icon: const Icon(
              Icons.delete_sweep_outlined,
            ),
          ),
          IconButton(
            tooltip: 'Save',
            onPressed: _saving ? null : _saveImage,
            icon: _saving
                ? const SizedBox(
                    width: 21,
                    height: 21,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(
                    Icons.check_rounded,
                  ),
          ),
        ],
      ),

      body: Column(
        children: [
          // ===================================================
          // Toolbar
          // ===================================================

          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            child: Row(
              children: [
                IconButton(
                  tooltip: 'Pen',
                  onPressed: () {
                    setState(() {
                      _eraser = false;
                    });
                  },
                  icon: Icon(
                    Icons.edit_rounded,
                    color: !_eraser
                        ? _selectedColor
                        : null,
                  ),
                ),

                IconButton(
                  tooltip: 'Eraser',
                  onPressed: () {
                    setState(() {
                      _eraser = true;
                    });
                  },
                  icon: Icon(
                    Icons.auto_fix_normal_rounded,
                    color: _eraser
                        ? Colors.blue
                        : null,
                  ),
                ),

                IconButton(
                  tooltip: 'Add Text',
                  onPressed: _saving
                      ? null
                      : _addText,
                  icon: const Icon(
                    Icons.text_fields_rounded,
                  ),
                ),

                const SizedBox(width: 6),

                GestureDetector(
                  onTap: _showColorPicker,
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: _selectedColor,
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
                    value: _strokeWidth,
                    onChanged: (value) {
                      setState(() {
                        _strokeWidth = value;
                      });
                    },
                  ),
                ),

                Text(
                  _strokeWidth.round().toString(),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // ===================================================
          // Canvas
          // ===================================================

          Expanded(
            child: Center(
              child: RepaintBoundary(
                key: _canvasKey,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return Container(
                      color: Colors.white,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          // Original image
                          Positioned.fill(
                            child: Image.memory(
                              widget.imageBytes,
                              fit: BoxFit.contain,
                              gaplessPlayback: true,
                              errorBuilder: (
                                context,
                                error,
                                stackTrace,
                              ) {
                                return const Center(
                                  child: Icon(
                                    Icons
                                        .broken_image_outlined,
                                    size: 60,
                                  ),
                                );
                              },
                            ),
                          ),

                          // Drawing layer
                          Positioned.fill(
                            child: GestureDetector(
                              behavior:
                                  HitTestBehavior.translucent,
                              onPanStart: (details) {
                                if (_saving) {
                                  return;
                                }

                                setState(() {
                                  _redoLines.clear();

                                  _lines.add(
                                    _DrawLine(
                                      points: [
                                        details.localPosition,
                                      ],
                                      color: _eraser
                                          ? Colors.white
                                          : _selectedColor,
                                      width: _strokeWidth,
                                      eraser: _eraser,
                                    ),
                                  );
                                });
                              },
                              onPanUpdate: (details) {
                                if (_saving ||
                                    _lines.isEmpty) {
                                  return;
                                }

                                setState(() {
                                  _lines.last.points.add(
                                    details.localPosition,
                                  );
                                });
                              },
                              onPanEnd: (_) {},
                              child: CustomPaint(
                                painter: _DrawingPainter(
                                  lines: _lines,
                                ),
                              ),
                            ),
                          ),

                          // Text layer
                          ..._texts.map(
                            (item) {
                              return Positioned(
                                left: item.position.dx,
                                top: item.position.dy,
                                child: GestureDetector(
                                  behavior:
                                      HitTestBehavior.opaque,
                                  onPanUpdate: (details) {
                                    if (_saving) {
                                      return;
                                    }

                                    setState(() {
                                      item.position +=
                                          details.delta;
                                    });
                                  },
                                  child: Container(
                                    padding:
                                        const EdgeInsets.all(
                                      6,
                                    ),
                                    decoration:
                                        BoxDecoration(
                                      color: Colors.transparent,
                                      borderRadius:
                                          BorderRadius.circular(
                                        6,
                                      ),
                                    ),
                                    child: Text(
                                      item.text,
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight:
                                            FontWeight.bold,
                                        color: item.color,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ===========================================================
// Drawing Line
// ===========================================================

class _DrawLine {
  final List<Offset> points;
  final Color color;
  final double width;
  final bool eraser;

  _DrawLine({
    required this.points,
    required this.color,
    required this.width,
    required this.eraser,
  });
}

// ===========================================================
// Text
// ===========================================================

class _TextItem {
  String text;
  Offset position;
  Color color;

  _TextItem({
    required this.text,
    required this.position,
    required this.color,
  });
}

// ===========================================================
// Painter
// ===========================================================

class _DrawingPainter extends CustomPainter {
  final List<_DrawLine> lines;

  _DrawingPainter({
    required this.lines,
  });

  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    for (final line in lines) {
      final paint = Paint()
        ..color = line.color
        ..strokeWidth = line.width
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      if (line.points.isEmpty) {
        continue;
      }

      if (line.points.length == 1) {
        canvas.drawCircle(
          line.points.first,
          line.width / 2,
          paint,
        );
        continue;
      }

      final path = Path();

      path.moveTo(
        line.points.first.dx,
        line.points.first.dy,
      );

      for (int i = 1; i < line.points.length; i++) {
        path.lineTo(
          line.points[i].dx,
          line.points[i].dy,
        );
      }

      canvas.drawPath(
        path,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(
    covariant _DrawingPainter oldDelegate,
  ) {
    return true;
  }
}