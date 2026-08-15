import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Custom clipper to draw regular or rounded Hexagons
class HexagonClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    final width = size.width;
    final height = size.height;

    // Pointed top hexagon
    path.moveTo(width * 0.5, 0);
    path.lineTo(width, height * 0.25);
    path.lineTo(width, height * 0.75);
    path.lineTo(width * 0.5, height);
    path.lineTo(0, height * 0.75);
    path.lineTo(0, height * 0.25);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

/// Custom Border Painter for Hexagonal outlines
class HexagonBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;

  HexagonBorderPainter({
    required this.color,
    this.strokeWidth = 2.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final width = size.width;
    final height = size.height;

    final path = Path()
      ..moveTo(width * 0.5, 0)
      ..lineTo(width, height * 0.25)
      ..lineTo(width, height * 0.75)
      ..lineTo(width * 0.5, height)
      ..lineTo(0, height * 0.75)
      ..lineTo(0, height * 0.25)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant HexagonBorderPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.strokeWidth != strokeWidth;
}

/// Decorative Hexagonal Grid Background Painter
class HexagonGridBackgroundPainter extends CustomPainter {
  final Color gridColor;

  HexagonGridBackgroundPainter({required this.gridColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = gridColor.withValues(alpha: 0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    const radius = 30.0;
    final heightStep = radius * 1.5;
    final widthStep = math.sqrt(3) * radius;

    for (double y = -radius; y < size.height + radius; y += heightStep) {
      final bool offset = ((y / heightStep).floor() % 2) == 1;
      final double startX = offset ? widthStep / 2 : 0.0;

      for (double x = startX - radius; x < size.width + radius; x += widthStep) {
        _drawHexagon(canvas, paint, Offset(x, y), radius);
      }
    }
  }

  void _drawHexagon(Canvas canvas, Paint paint, Offset center, double radius) {
    final path = Path();
    for (int i = 0; i < 6; i++) {
      final angle = (i * 60 + 30) * math.pi / 180;
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
