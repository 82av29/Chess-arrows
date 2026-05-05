import 'dart:math';
import 'package:flutter/material.dart';
import 'models.dart';

class ArrowPainter extends CustomPainter {
  final List<ChessArrow> arrows;
  final BoardCalibration calibration;
  final double opacity;

  ArrowPainter({
    required this.arrows,
    required this.calibration,
    this.opacity = 0.85,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final arrow in arrows) {
      _drawArrow(
        canvas,
        calibration.squareToOffset(arrow.from),
        calibration.squareToOffset(arrow.to),
        arrow.color.withOpacity(opacity),
        calibration.squareSize,
      );
    }
  }

  void _drawArrow(
      Canvas canvas, Offset from, Offset to, Color color, double squareSize) {
    final double shaftWidth = squareSize * 0.18;
    final double headWidth = squareSize * 0.45;
    final double headLength = squareSize * 0.38;

    final dx = to.dx - from.dx;
    final dy = to.dy - from.dy;
    final length = sqrt(dx * dx + dy * dy);
    if (length == 0) return;

    final ux = dx / length;
    final uy = dy / length;
    final px = -uy;
    final py = ux;

    // Shorten start and end so arrow doesn't overlap piece centers too much
    final startOffset = squareSize * 0.3;
    final endOffset = squareSize * 0.15;

    final start = Offset(from.dx + ux * startOffset, from.dy + uy * startOffset);
    final end = Offset(to.dx - ux * endOffset, to.dy - uy * endOffset);

    final shaftEnd = Offset(
      end.dx - ux * headLength,
      end.dy - uy * headLength,
    );

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..strokeJoin = StrokeJoin.round;

    // Draw shaft
    final shaftPath = Path()
      ..moveTo(start.dx + px * shaftWidth / 2, start.dy + py * shaftWidth / 2)
      ..lineTo(shaftEnd.dx + px * shaftWidth / 2, shaftEnd.dy + py * shaftWidth / 2)
      ..lineTo(shaftEnd.dx - px * shaftWidth / 2, shaftEnd.dy - py * shaftWidth / 2)
      ..lineTo(start.dx - px * shaftWidth / 2, start.dy - py * shaftWidth / 2)
      ..close();

    canvas.drawPath(shaftPath, paint);

    // Draw arrowhead (triangle)
    final headPath = Path()
      ..moveTo(end.dx, end.dy)
      ..lineTo(shaftEnd.dx + px * headWidth / 2, shaftEnd.dy + py * headWidth / 2)
      ..lineTo(shaftEnd.dx - px * headWidth / 2, shaftEnd.dy - py * headWidth / 2)
      ..close();

    canvas.drawPath(headPath, paint);
  }

  @override
  bool shouldRepaint(ArrowPainter oldDelegate) =>
      oldDelegate.arrows != arrows || oldDelegate.opacity != opacity;
}
