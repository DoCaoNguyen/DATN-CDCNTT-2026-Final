import 'package:flutter/material.dart';

class CameraOverlayPainter extends CustomPainter {
  final bool isSelfie;

  CameraOverlayPainter({required this.isSelfie});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black.withValues(alpha: 0.7);
    final screenRect = Rect.fromLTWH(0, 0, size.width, size.height);
    Path cutoutPath = Path();

    if (isSelfie) {
      final double width = size.width * 0.7;
      final double height = width * 1.3;
      cutoutPath.addOval(
        Rect.fromCenter(
          center: Offset(size.width / 2, size.height / 2),
          width: width,
          height: height,
        ),
      );
    } else {
      final double width = size.width * 0.85;
      final double height = width * 0.63;
      cutoutPath.addRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(size.width / 2, size.height / 2),
            width: width,
            height: height,
          ),
          const Radius.circular(16),
        ),
      );
    }

    final backgroundPath = Path.combine(
      PathOperation.difference,
      Path()..addRect(screenRect),
      cutoutPath,
    );
    canvas.drawPath(backgroundPath, paint);

    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;
    canvas.drawPath(cutoutPath, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
