import 'dart:math' as math;

import 'package:flutter/material.dart' hide Card;

import '../../../core/models/card.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/suit_icon.dart';

/// Minimalist card face: only the rank and the suit symbol, Offsuit style.
class PlayingCardView extends StatelessWidget {
  const PlayingCardView({
    super.key,
    required this.card,
    this.width = 72,
    this.faceUp = true,
    this.dimmed = false,
    this.highlighted = false,
    this.glow = false,
  });

  final Card? card;
  final double width;
  final bool faceUp;
  final bool dimmed;
  final bool highlighted;

  /// Hint glow around a suggested card.
  final bool glow;

  static const double aspect = 1.4;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final h = width * aspect;
    final radius = BorderRadius.circular(width * 0.16);
    final show = faceUp && card != null;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: width,
      height: h,
      decoration: BoxDecoration(
        borderRadius: radius,
        color: show ? c.cardFace : c.cardBack,
        border: show
            ? (glow ? Border.all(color: c.chipText, width: 2.5) : null)
            : Border.all(
                color: Colors.white,
                width: math.max(2, width * 0.035),
              ),
        boxShadow: [
          if (glow)
            BoxShadow(
              color: c.chipText.withValues(alpha: 0.85),
              blurRadius: 22,
              spreadRadius: 3,
            ),
          BoxShadow(
            color: Colors.black.withValues(alpha: highlighted ? 0.45 : 0.22),
            blurRadius: highlighted ? 18 : 10,
            offset: const Offset(0, 4),
          ),
        ],
        gradient: show
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  c.cardFace,
                  Color.lerp(c.cardFace, const Color(0xFFE6E6EA), 0.55)!,
                ],
              )
            : null,
      ),
      foregroundDecoration: dimmed
          ? BoxDecoration(
              borderRadius: radius,
              color: c.background.withValues(alpha: 0.55),
            )
          : null,
      child: ClipRRect(
        borderRadius: radius,
        child: show
            ? _Face(card: card!, width: width)
            : CustomPaint(painter: CardBackPainter(c.cardBackLine)),
      ),
    );
  }
}

class _Face extends StatelessWidget {
  const _Face({required this.card, required this.width});
  final Card card;
  final double width;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final color = card.suit.isRed ? c.cardRed : c.cardInk;
    return Stack(
      children: [
        Positioned(
          left: width * 0.14,
          top: width * 0.1,
          right: width * 0.06,
          height: width * 0.5,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.topLeft,
            child: Text(
              card.rank.label,
              style: TextStyle(
                fontSize: width * 0.42,
                height: 1.1,
                color: color,
                fontWeight: FontWeight.w400,
                letterSpacing: card.rank.label.length > 1 ? -width * 0.03 : 0,
              ),
            ),
          ),
        ),
        Positioned(
          left: width * 0.15,
          bottom: width * 0.13,
          child: SuitIcon(card.suit, size: width * 0.28, color: color),
        ),
      ],
    );
  }
}

/// Red patterned back with concentric rings and a dashed centre, like the
/// reference screenshots.
class CardBackPainter extends CustomPainter {
  CardBackPainter(this.line);
  final Color line;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = line
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.012;
    final center = size.center(Offset.zero);
    final w = size.width;
    // corner arcs
    for (final o in [
      Offset.zero,
      Offset(w, 0),
      Offset(0, size.height),
      Offset(w, size.height),
    ]) {
      for (var r = 0.18; r <= 0.6; r += 0.14) {
        canvas.drawCircle(o, w * r, p);
      }
    }
    for (final dy in [-0.42, 0.42]) {
      canvas.drawCircle(center + Offset(0, size.height * dy), w * 0.22, p);
    }
    canvas.drawCircle(center, w * 0.36, p);
    canvas.drawCircle(center, w * 0.27, p);
    final fill = Paint()..color = const Color(0xFFFFFFFF);
    canvas.drawCircle(center, w * 0.2, fill..color = const Color(0x33FFFFFF));
    final dash = Paint()
      ..color = const Color(0xFFFFFFFF)
      ..strokeWidth = w * 0.035
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 12; i++) {
      final a = i * math.pi / 6;
      final d = Offset(math.cos(a), math.sin(a));
      canvas.drawLine(center + d * w * 0.07, center + d * w * 0.14, dash);
    }
  }

  @override
  bool shouldRepaint(CardBackPainter old) => old.line != line;
}
