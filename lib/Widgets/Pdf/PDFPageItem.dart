import 'dart:typed_data';

import 'package:flutter/material.dart';

class PDFPageItem {
  Uint8List bytes;
  int rotation;
  final Key key;

  PDFPageItem({
    required this.bytes,
    this.rotation = 0,
  }) : key = UniqueKey();
}