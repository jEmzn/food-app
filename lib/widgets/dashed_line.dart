import 'package:app1/config/app_theme.dart';
import 'package:flutter/material.dart';

class DashedLine extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    double dashWidth = 8;
    double dashSpace = 8;
    double startX = 0;
    final paint = Paint()
      ..color = AppTheme.primaryColor
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    while (startX < size.width) {
      canvas.drawLine(Offset(startX, 0), Offset(startX + dashWidth, 0), paint);
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
