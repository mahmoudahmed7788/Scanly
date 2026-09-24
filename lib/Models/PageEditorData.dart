import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

class NotePageEditorData {
  final String id;
  final QuillController controller;
  final FocusNode focusNode;
  final ScrollController scrollController;

  bool isLandscape;

  NotePageEditorData({
    required this.id,
    required this.controller,
    required this.focusNode,
    required this.scrollController,
    this.isLandscape = false,
  });

  void dispose() {
    controller.dispose();
    focusNode.dispose();
    scrollController.dispose();
  }
}