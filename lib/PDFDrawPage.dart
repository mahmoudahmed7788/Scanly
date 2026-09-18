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
  State<PDFDrawPage> createState() =>
      _PDFDrawPageState();
}

class _PDFDrawPageState
    extends State<PDFDrawPage> {
  final GlobalKey _canvasKey =
      GlobalKey();

  final List<_DrawLine> _lines = [];

  final List<_DrawLine> _redoLines = [];

  final List<_TextItem> _texts = [];

  Color _selectedColor =
      Colors.red;

  double _strokeWidth = 4;

  bool _eraser = false;

  Offset? _currentPoint;

  // =========================================================
  // Undo
  // =========================================================

  void _undo() {
    if (_lines.isEmpty &&
        _texts.isEmpty) {
      return;
    }

    setState(() {
      if (_lines.isNotEmpty) {
        _redoLines.add(
          _lines.removeLast(),
        );
      } else if (_texts.isNotEmpty) {
        _texts.removeLast();
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
      _lines.add(
        _redoLines.removeLast(),
      );
    });
  }

  // =========================================================
  // Clear
  // =========================================================

  void _clear() {
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
    final controller =
        TextEditingController();

    final text =
        await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Add Text',
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            maxLines: 4,
            decoration:
                const InputDecoration(
              hintText:
                  'Write something...',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(
                dialogContext,
              ),
              child:
                  const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final value =
                    controller.text.trim();

                if (value.isEmpty) {
                  return;
                }

                Navigator.pop(
                  dialogContext,
                  value,
                );
              },
              child:
                  const Text('Add'),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (text == null ||
        text.trim().isEmpty) {
      return;
    }

    setState(() {
      _texts.add(
        _TextItem(
          text: text,
          position:
              const Offset(100, 150),
          color: _selectedColor,
        ),
      );
    });
  }

  // =========================================================
  // Save Edited Image
  // =========================================================

  Future<void> _saveImage() async {
    try {
      final boundary =
          _canvasKey.currentContext
              ?.findRenderObject()
              as RenderRepaintBoundary?;

      if (boundary == null) {
        return;
      }

      final image =
          await boundary.toImage(
        pixelRatio: 2.5,
      );

      final byteData =
          await image.toByteData(
        format:
            ui.ImageByteFormat.png,
      );

      if (byteData == null) {
        return;
      }

      final bytes =
          byteData.buffer.asUint8List();

      if (!mounted) return;

      Navigator.pop(
        context,
        bytes,
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Failed to save changes.',
          ),
        ),
      );
    }
  }

  // =========================================================
  // Build
  // =========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
            onPressed: _lines.isEmpty &&
                    _texts.isEmpty
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
            onPressed: _saveImage,
            icon: const Icon(
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
            padding:
                const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            child: Row(
              children: [
                // Pen
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

                // Eraser
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

                // Text
                IconButton(
                  tooltip: 'Add Text',
                  onPressed: _addText,
                  icon: const Icon(
                    Icons.text_fields_rounded,
                  ),
                ),

                const SizedBox(width: 6),

                // Color
                GestureDetector(
                  onTap: _showColorPicker,
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration:
                        BoxDecoration(
                      color: _selectedColor,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // Stroke
                Expanded(
                  child: Slider(
                    min: 1,
                    max: 20,
                    value: _strokeWidth,
                    onChanged: (value) {
                      setState(() {
                        _strokeWidth =
                            value;
                      });
                    },
                  ),
                ),

                Text(
                  _strokeWidth
                      .round()
                      .toString(),
                  style:
                      const TextStyle(
                    fontWeight:
                        FontWeight.bold,
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
                  builder:
                      (context, constraints) {
                    return Container(
                      color: Colors.white,
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child:
                                Image.memory(
                              widget.imageBytes,
                              fit: BoxFit.contain,
                            ),
                          ),

                          Positioned.fill(
                            child:
                                GestureDetector(
                              behavior:
                                  HitTestBehavior
                                      .translucent,

                              onPanStart:
                                  (details) {
                                setState(() {
                                  _currentPoint =
                                      details
                                          .localPosition;

                                  _redoLines
                                      .clear();

                                  _lines.add(
                                    _DrawLine(
                                      points: [
                                        _currentPoint!
                                      ],
                                      color:
                                          _eraser
                                              ? Colors
                                                  .white
                                              : _selectedColor,
                                      width:
                                          _strokeWidth,
                                      eraser:
                                          _eraser,
                                    ),
                                  );
                                });
                              },

                              onPanUpdate:
                                  (details) {
                                setState(() {
                                  _currentPoint =
                                      details
                                          .localPosition;

                                  if (_lines
                                      .isEmpty) {
                                    return;
                                  }

                                  _lines
                                      .last
                                      .points
                                      .add(
                                    _currentPoint!,
                                  );
                                });
                              },

                              onPanEnd:
                                  (_) {
                                _currentPoint =
                                    null;
                              },

                              child:
                                  CustomPaint(
                                painter:
                                    _DrawingPainter(
                                  lines: _lines,
                                ),
                              ),
                            ),
                          ),

                          ..._texts.map(
                            (item) {
                              return Positioned(
                                left: item
                                    .position
                                    .dx,
                                top: item
                                    .position
                                    .dy,
                                child:
                                    GestureDetector(
                                  onPanUpdate:
                                      (details) {
                                    setState(() {
                                      item.position +=
                                          details.delta;
                                    });
                                  },
                                  child: Container(
                                    padding:
                                        const EdgeInsets
                                            .all(
                                      4,
                                    ),
                                    child: Text(
                                      item.text,
                                      style:
                                          TextStyle(
                                        fontSize:
                                            24,
                                        fontWeight:
                                            FontWeight
                                                .bold,
                                        color:
                                            item.color,
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

  // =========================================================
  // Color Picker
  // =========================================================

  void _showColorPicker() {
    final colors = [
      Colors.red,
      Colors.black,
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.white,
    ];

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding:
                const EdgeInsets.all(20),
            child: Wrap(
              spacing: 18,
              runSpacing: 18,
              children:
                  colors.map((color) {
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedColor =
                          color;
                    });

                    Navigator.pop(
                      context,
                    );
                  },
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration:
                        BoxDecoration(
                      color: color,
                      shape:
                          BoxShape.circle,
                      border: Border.all(
                        color: Colors.grey,
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

class _DrawingPainter
    extends CustomPainter {
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
        ..strokeCap =
            StrokeCap.round
        ..strokeJoin =
            StrokeJoin.round
        ..style = PaintingStyle.stroke;

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

      for (int i = 1;
          i < line.points.length;
          i++) {
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