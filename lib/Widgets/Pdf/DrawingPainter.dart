import 'package:flutter/material.dart';
import 'DrawLine.dart';

class DrawingPainter extends CustomPainter {
  final List<DrawLine> lines;

  DrawingPainter({
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
    covariant DrawingPainter oldDelegate,
  ) {
    return true;
  }
}