import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:scanly/Widgets/Pdf/DrawLine.dart';
import 'package:scanly/Widgets/Pdf/DrawingPainter.dart';
import 'package:scanly/Widgets/Pdf/PDFDrawColorPicker.dart';
import 'package:scanly/Widgets/Pdf/PDFDrawToolbar.dart';
import 'package:scanly/Widgets/Pdf/TextItem.dart';

class PDFDrawPage extends StatefulWidget {
  final Uint8List imageBytes;

  const PDFDrawPage({super.key, required this.imageBytes});

  @override
  State<PDFDrawPage> createState() => _PDFDrawPageState();
}

class _PDFDrawPageState extends State<PDFDrawPage> {
  final GlobalKey _canvasKey = GlobalKey();

  final List<DrawLine> _lines = [];
  final List<DrawLine> _redoLines = [];
  final List<TextItem> _texts = [];

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
                      icon: const Icon(Icons.close_rounded),
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
                    icon: const Icon(Icons.add_rounded),
                    label: const Text(
                      'Add Text',
                      style: TextStyle(fontWeight: FontWeight.w700),
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

    if (result == null || result!.trim().isEmpty) {
      return;
    }

    setState(() {
      _texts.add(
        TextItem(
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
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final renderObject = _canvasKey.currentContext?.findRenderObject();

      if (renderObject is! RenderRepaintBoundary) {
        throw Exception('Canvas is not ready.');
      }

      final image = await renderObject.toImage(pixelRatio: 2.5);

      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      image.dispose();

      if (byteData == null) {
        throw Exception('Unable to create image bytes.');
      }

      final bytes = byteData.buffer.asUint8List();

      if (!mounted) {
        return;
      }

      Navigator.pop(context, Uint8List.fromList(bytes));
    } catch (e, stackTrace) {
      debugPrint('SAVE IMAGE ERROR: $e');
      debugPrint(stackTrace.toString());

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Failed to save changes.')),
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

    PDFDrawColorPicker.show(
      context: context,
      selectedColor: _selectedColor,
      onColorSelected: (color) {
        if (!mounted) {
          return;
        }

        setState(() {
          _selectedColor = color;
        });
      },
    );
  }

  // =========================================================
  // Pen
  // =========================================================

  void _selectPen() {
    setState(() {
      _eraser = false;
    });
  }

  // =========================================================
  // Eraser
  // =========================================================

  void _selectEraser() {
    setState(() {
      _eraser = true;
    });
  }

  // =========================================================
  // Stroke Width
  // =========================================================

  void _changeStrokeWidth(double value) {
    setState(() {
      _strokeWidth = value;
    });
  }

  // =========================================================
  // Build
  // =========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,

      // =====================================================
      // App Bar
      // =====================================================
      appBar: AppBar(
        title: const Text(
          'Edit Page',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: 'Undo',
            onPressed: (_lines.isEmpty && _texts.isEmpty) ? null : _undo,
            icon: const Icon(Icons.undo_rounded),
          ),

          IconButton(
            tooltip: 'Redo',
            onPressed: _redoLines.isEmpty ? null : _redo,
            icon: const Icon(Icons.redo_rounded),
          ),

          IconButton(
            tooltip: 'Clear',
            onPressed: _clear,
            icon: const Icon(Icons.delete_sweep_outlined),
          ),

          IconButton(
            tooltip: 'Save',
            onPressed: _saving ? null : _saveImage,
            icon: _saving
                ? const SizedBox(
                    width: 21,
                    height: 21,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check_rounded),
          ),
        ],
      ),

      // =====================================================
      // Body
      // =====================================================
      body: Column(
        children: [
          // =================================================
          // Toolbar
          // =================================================
          PDFDrawToolbar(
            eraser: _eraser,
            selectedColor: _selectedColor,
            strokeWidth: _strokeWidth,
            saving: _saving,
            onPen: _selectPen,
            onEraser: _selectEraser,
            onAddText: _addText,
            onColorPicker: _showColorPicker,
            onStrokeWidthChanged: _changeStrokeWidth,
          ),

          // =================================================
          // Canvas
          // =================================================
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
                          // =================================
                          // Original Image
                          // =================================
                          Positioned.fill(
                            child: Image.memory(
                              widget.imageBytes,
                              fit: BoxFit.contain,
                              gaplessPlayback: true,
                              errorBuilder: (context, error, stackTrace) {
                                return const Center(
                                  child: Icon(
                                    Icons.broken_image_outlined,
                                    size: 60,
                                  ),
                                );
                              },
                            ),
                          ),

                          // =================================
                          // Drawing Layer
                          // =================================
                          Positioned.fill(
                            child: GestureDetector(
                              behavior: HitTestBehavior.translucent,

                              onPanStart: (details) {
                                if (_saving) {
                                  return;
                                }

                                setState(() {
                                  _redoLines.clear();

                                  _lines.add(
                                    DrawLine(
                                      points: [details.localPosition],
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
                                if (_saving || _lines.isEmpty) {
                                  return;
                                }

                                setState(() {
                                  _lines.last.points.add(details.localPosition);
                                });
                              },

                              onPanEnd: (_) {},

                              child: CustomPaint(
                                painter: DrawingPainter(lines: _lines),
                              ),
                            ),
                          ),

                          // =================================
                          // Text Layer
                          // =================================
                          ..._texts.map((item) {
                            return Positioned(
                              left: item.position.dx,
                              top: item.position.dy,
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onPanUpdate: (details) {
                                  if (_saving) {
                                    return;
                                  }

                                  setState(() {
                                    final index = _texts.indexOf(item);
                                    if (index != -1) {
                                      _texts[index] = TextItem(
                                        text: item.text,
                                        position: item.position + details.delta,
                                        color: item.color,
                                      );
                                    }
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.transparent,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    item.text,
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: item?.color,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
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

extension on Object? {
  ui.Color? get color => null;

  ui.Offset? get position => null;
}
