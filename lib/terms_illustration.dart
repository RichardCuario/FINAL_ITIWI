import 'package:flutter/material.dart';

/// Scalable decorative artwork inspired by the Terms of Use header.
class TermsIllustration extends CustomPainter {
  const TermsIllustration();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 160, size.height / 150);
    final paint = Paint();
    void rect(
      double x,
      double y,
      double w,
      double h,
      Color color, [
      double radius = 2,
    ]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, w, h),
          Radius.circular(radius),
        ),
        paint..color = color,
      );
    }

    void line(
      double x,
      double y,
      double x2,
      double y2,
      Color color, [
      double width = 2,
    ]) {
      canvas.drawLine(
        Offset(x, y),
        Offset(x2, y2),
        Paint()
          ..color = color
          ..strokeWidth = width
          ..strokeCap = StrokeCap.round,
      );
    }

    const blue = Color(0xFF1878D2);
    const pale = Color(0xFFABD5FB);
    canvas.drawOval(
      const Rect.fromLTWH(1, 17, 158, 126),
      paint..color = const Color(0xFFD4EAFF),
    );
    canvas.drawCircle(const Offset(113, 32), 20, paint..color = pale);
    rect(94, 33, 40, 52, pale);
    line(113, 4, 113, 17, blue, 1);
    rect(114, 4, 8, 5, const Color(0xFF66B0ED), 0);
    for (final x in [100.0, 111.0, 122.0]) {
      rect(x, 37, 5, 12, const Color(0xFFEAF6FF));
      rect(x, 55, 5, 12, const Color(0xFFEAF6FF));
    }
    for (var i = 0; i < 4; i++) {
      canvas.drawOval(
        Rect.fromLTWH(8 + i * 4, 65 + i * 16, 13, 24),
        paint..color = const Color(0xFF85BEF1),
      );
      canvas.drawOval(
        Rect.fromLTWH(137 - i * 4, 59 + i * 18, 13, 27),
        paint..color = const Color(0xFF66ABE6),
      );
    }
    canvas.drawOval(const Rect.fromLTWH(6, 137, 146, 8), paint..color = pale);
    rect(28, 27, 15, 110, const Color(0xFF85BFF7), 8);
    final paper = Path()
      ..moveTo(37, 27)
      ..lineTo(92, 27)
      ..quadraticBezierTo(98, 27, 98, 38)
      ..lineTo(98, 49)
      ..lineTo(111, 49)
      ..lineTo(111, 128)
      ..quadraticBezierTo(111, 140, 99, 140)
      ..lineTo(42, 140)
      ..quadraticBezierTo(37, 140, 37, 130)
      ..close();
    canvas.drawShadow(paper, const Color(0xFF83B5E4), 3, false);
    canvas.drawPath(paper, paint..color = const Color(0xFFF5FBFF));
    // Balanced scales above the checklist.
    line(58, 39, 58, 61, blue);
    line(46, 43, 70, 43, blue);
    line(53, 62, 64, 62, blue);
    for (final x in [47.0, 69.0]) {
      line(x, 44, x - 5, 55, blue, 1);
      line(x, 44, x + 5, 55, blue, 1);
      canvas.drawArc(
        Rect.fromLTWH(x - 5, 51, 10, 8),
        0,
        3.14159,
        true,
        paint..color = blue,
      );
    }
    rect(47, 72, 56, 3, pale);
    rect(47, 82, 56, 3, pale);
    for (final y in [95.0, 114.0]) {
      rect(47, y, 10, 11, blue);
      line(49, y + 5, 51, y + 7, Colors.white, 1.4);
      line(51, y + 7, 55, y + 3, Colors.white, 1.4);
      rect(63, y + 1, 37, 3, pale);
      rect(63, y + 8, 27, 3, pale);
    }
    final shield = Path()
      ..moveTo(121, 103)
      ..lineTo(142, 111)
      ..lineTo(140, 130)
      ..quadraticBezierTo(137, 141, 121, 148)
      ..quadraticBezierTo(105, 141, 102, 130)
      ..lineTo(100, 111)
      ..close();
    canvas.drawShadow(shield, blue, 3, false);
    canvas.drawPath(shield, paint..color = blue);
    canvas.drawPath(
      shield,
      Paint()
        ..color = pale
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
    final roof = Path()
      ..moveTo(121, 112)
      ..lineTo(110, 118)
      ..lineTo(132, 118)
      ..close();
    canvas.drawPath(roof, paint..color = Colors.white);
    for (final x in [113.0, 120.0, 127.0]) {
      rect(x, 120, 3, 12, Colors.white, 0);
    }
    line(111, 134, 132, 134, Colors.white);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant TermsIllustration oldDelegate) => false;
}
