import 'package:flutter/material.dart';

class DrawLine {
  final List<Offset> points;
  final Color color;
  final double width;
  final bool eraser;

  DrawLine({
    required this.points,
    required this.color,
    required this.width,
    required this.eraser,
  });
}