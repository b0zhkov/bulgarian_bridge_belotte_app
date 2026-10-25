import 'package:flutter/material.dart';

import '../models/card.dart';

/// Vector suit symbol, so suits look identical on every platform and never
/// fall back to emoji glyphs.
class SuitIcon extends StatelessWidget {
  const SuitIcon(this.suit, {super.key, this.size = 20, required this.color});
  final Suit suit;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: size,
    height: size,
    child: CustomPaint(painter: _SuitPainter(suit, color)),
  );
}

class _SuitPainter extends CustomPainter {
  _SuitPainter(this.suit, this.color);
  final Suit suit;
  final Color color;

  Path _heart(double s, {bool flip = false}) {
    final p = Path()
      ..moveTo(0.5, 0.92)
      ..cubicTo(0.30, 0.74, 0.04, 0.58, 0.04, 0.33)
      ..cubicTo(0.04, 0.16, 0.17, 0.05, 0.30, 0.05)
      ..cubicTo(0.40, 0.05, 0.47, 0.11, 0.5, 0.19)
      ..cubicTo(0.53, 0.11, 0.60, 0.05, 0.70, 0.05)
      ..cubicTo(0.83, 0.05, 0.96, 0.16, 0.96, 0.33)
      ..cubicTo(0.96, 0.58, 0.70, 0.74, 0.5, 0.92)
      ..close();
    final m = Matrix4.identity();
    if (flip) {
      m.translateByDouble(0, s, 0, 1);
      m.scaleByDouble(s, -s, 1, 1);
    } else {
      m.scaleByDouble(s, s, 1, 1);
    }
    return p.transform(m.storage);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final paint = Paint()
      ..color = color
      ..isAntiAlias = true;
    switch (suit) {
      case Suit.hearts:
        canvas.drawPath(_heart(s), paint);
      case Suit.diamonds:
        final p = Path()
          ..moveTo(0.5 * s, 0.02 * s)
          ..quadraticBezierTo(0.68 * s, 0.30 * s, 0.88 * s, 0.5 * s)
          ..quadraticBezierTo(0.68 * s, 0.70 * s, 0.5 * s, 0.98 * s)
          ..quadraticBezierTo(0.32 * s, 0.70 * s, 0.12 * s, 0.5 * s)
          ..quadraticBezierTo(0.32 * s, 0.30 * s, 0.5 * s, 0.02 * s)
          ..close();
        canvas.drawPath(p, paint);
      case Suit.spades:
        final body = _heart(
          s * 0.92,
          flip: true,
        ).shift(Offset(s * 0.04, -s * 0.06));
        canvas.drawPath(body, paint);
        canvas.drawPath(_stem(s), paint);
      case Suit.clubs:
        final r = s * 0.2;
        canvas.drawCircle(Offset(0.5 * s, 0.27 * s), r, paint);
        canvas.drawCircle(Offset(0.27 * s, 0.56 * s), r, paint);
        canvas.drawCircle(Offset(0.73 * s, 0.56 * s), r, paint);
        canvas.drawRect(
          Rect.fromLTWH(0.42 * s, 0.35 * s, 0.16 * s, 0.25 * s),
          paint,
        );
        canvas.drawPath(_stem(s), paint);
    }
  }

  Path _stem(double s) => Path()
    ..moveTo(0.5 * s, 0.55 * s)
    ..quadraticBezierTo(0.52 * s, 0.85 * s, 0.70 * s, 0.98 * s)
    ..lineTo(0.30 * s, 0.98 * s)
    ..quadraticBezierTo(0.48 * s, 0.85 * s, 0.5 * s, 0.55 * s)
    ..close();

  @override
  bool shouldRepaint(_SuitPainter old) =>
      old.suit != suit || old.color != color;
}
