import 'package:flutter/material.dart';

/// Decorative clipboard, database and shield for the data information header.
class DataComplianceIllustration extends CustomPainter {
  const DataComplianceIllustration();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 160, size.height / 150);
    final paint = Paint();
    const blue = Color(0xFF2588E7);
    const pale = Color(0xFFADD8FF);
    const white = Color(0xFFF5FBFF);
    void rect(
      double x,
      double y,
      double w,
      double h,
      Color color, [
      double radius = 3,
    ]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, w, h),
          Radius.circular(radius),
        ),
        paint..color = color,
      );
    }

    void oval(Rect bounds, Color color) =>
        canvas.drawOval(bounds, paint..color = color);
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

    oval(const Rect.fromLTWH(0, 15, 158, 129), const Color(0xFFD7EDFF));
    // Municipal building and flag in the background.
    oval(const Rect.fromLTWH(99, 13, 37, 39), pale);
    rect(98, 32, 41, 65, pale);
    line(117, 3, 117, 15, const Color(0xFF76B7F1), 1);
    rect(118, 3, 10, 6, const Color(0xFF76B7F1), 0);
    for (final x in [104.0, 116.0, 128.0]) {
      rect(x, 33, 4, 13, const Color(0xFFE7F5FF));
      rect(x, 52, 4, 24, const Color(0xFFE7F5FF));
    }
    for (var i = 0; i < 4; i++) {
      canvas.save();
      canvas.translate(19 + i * 3, 69 + i * 18);
      canvas.rotate(-0.5);
      oval(const Rect.fromLTWH(-7, -15, 14, 31), const Color(0xFF91C9F9));
      canvas.restore();
      canvas.save();
      canvas.translate(143 - i * 4, 64 + i * 19);
      canvas.rotate(0.45);
      oval(const Rect.fromLTWH(-7, -15, 14, 31), const Color(0xFF7EBFF7));
      canvas.restore();
    }
    oval(const Rect.fromLTWH(7, 136, 147, 9), const Color(0xFFABD8FC));
    final clipboard = RRect.fromRectAndRadius(
      const Rect.fromLTWH(31, 43, 69, 94),
      const Radius.circular(7),
    );
    canvas.drawShadow(
      Path()..addRRect(clipboard),
      const Color(0xFF6FA9DB),
      4,
      false,
    );
    canvas.drawRRect(clipboard, paint..color = white);
    rect(48, 38, 34, 10, const Color(0xFF1472CC), 4);
    canvas.drawCircle(
      const Offset(65, 37),
      7,
      paint..color = const Color(0xFF1472CC),
    );
    canvas.drawCircle(const Offset(65, 35), 2, paint..color = pale);
    for (final y in [60.0, 81.0, 102.0]) {
      rect(41, y, 13, 14, blue);
      line(44, y + 7, 47, y + 10, Colors.white, 1.7);
      line(47, y + 10, 51, y + 4, Colors.white, 1.7);
      rect(60, y + 2, 29, 3, pale);
      rect(60, y + 9, 19, 3, pale);
    }
    // Stacked records represented by a blue database cylinder.
    rect(92, 87, 44, 47, blue, 0);
    oval(const Rect.fromLTWH(92, 125, 44, 16), blue);
    for (final y in [101.0, 116.0]) {
      canvas.drawArc(
        Rect.fromLTWH(92, y - 8, 44, 16),
        0,
        3.14159,
        false,
        Paint()
          ..color = pale
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }
    oval(const Rect.fromLTWH(92, 80, 44, 16), const Color(0xFF60ACF0));
    final shield = Path()
      ..moveTo(135, 97)
      ..lineTo(155, 105)
      ..lineTo(153, 124)
      ..quadraticBezierTo(151, 138, 135, 145)
      ..quadraticBezierTo(119, 138, 117, 124)
      ..lineTo(115, 105)
      ..close();
    canvas.drawShadow(shield, const Color(0xFF1760A8), 3, false);
    canvas.drawPath(
      shield,
      paint
        ..shader = const LinearGradient(
          colors: [Color(0xFF278FE9), Color(0xFF0950A4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(const Rect.fromLTWH(115, 97, 40, 48)),
    );
    paint.shader = null;
    canvas.drawPath(
      shield,
      Paint()
        ..color = white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(131, 110, 8, 13),
        const Radius.circular(5),
      ),
      Paint()
        ..color = white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );
    rect(128, 117, 14, 13, white);
    canvas.drawCircle(const Offset(135, 122), 1.8, paint..color = blue);
    line(135, 122, 135, 126, blue, 1.6);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant DataComplianceIllustration oldDelegate) => false;
}
