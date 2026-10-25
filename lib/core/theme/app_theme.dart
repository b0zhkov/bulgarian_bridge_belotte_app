import 'package:flutter/material.dart';

/// Design tokens inspired by Offsuit: pure black canvas, white cards,
/// dark-grey pill buttons, Comfortaa typography (bundled, Cyrillic).
@immutable
class BelotColors extends ThemeExtension<BelotColors> {
  const BelotColors({
    required this.background,
    required this.surface,
    required this.surfaceHigh,
    required this.outline,
    required this.textPrimary,
    required this.textSecondary,
    required this.cardFace,
    required this.cardInk,
    required this.cardRed,
    required this.cardBack,
    required this.cardBackLine,
    required this.accent,
    required this.chip,
    required this.chipText,
    required this.success,
    required this.danger,
    required this.teamUs,
    required this.teamThem,
  });

  final Color background;
  final Color surface;
  final Color surfaceHigh;
  final Color outline;
  final Color textPrimary;
  final Color textSecondary;
  final Color cardFace;
  final Color cardInk;
  final Color cardRed;
  final Color cardBack;
  final Color cardBackLine;
  final Color accent;
  final Color chip;
  final Color chipText;
  final Color success;
  final Color danger;

  /// Team accents: our partnership vs the opponents.
  final Color teamUs;
  final Color teamThem;

  static const dark = BelotColors(
    background: Color(0xFF000000),
    surface: Color(0xFF1C1C1E),
    surfaceHigh: Color(0xFF2C2C2E),
    outline: Color(0xFF3A3A3C),
    textPrimary: Color(0xFFFFFFFF),
    textSecondary: Color(0xFF8E8E93),
    cardFace: Color(0xFFFFFFFF),
    cardInk: Color(0xFF111111),
    cardRed: Color(0xFFE5483B),
    cardBack: Color(0xFFF2554A),
    cardBackLine: Color(0x66FFFFFF),
    accent: Color(0xFFFFFFFF),
    chip: Color(0xFF2C2C2E),
    chipText: Color(0xFFFFE45C),
    success: Color(0xFF34C759),
    danger: Color(0xFFFF453A),
    teamUs: Color(0xFF5AC8FA),
    teamThem: Color(0xFFFF9F0A),
  );

  static const light = BelotColors(
    background: Color(0xFFF4F4F6),
    surface: Color(0xFFFFFFFF),
    surfaceHigh: Color(0xFFE9E9EE),
    outline: Color(0xFFD8D8DE),
    textPrimary: Color(0xFF0A0A0A),
    textSecondary: Color(0xFF6E6E73),
    cardFace: Color(0xFFFFFFFF),
    cardInk: Color(0xFF111111),
    cardRed: Color(0xFFE5483B),
    cardBack: Color(0xFFF2554A),
    cardBackLine: Color(0x66FFFFFF),
    accent: Color(0xFF0A0A0A),
    chip: Color(0xFF1C1C1E),
    chipText: Color(0xFFFFE45C),
    success: Color(0xFF248A3D),
    danger: Color(0xFFD70015),
    teamUs: Color(0xFF0A84FF),
    teamThem: Color(0xFFE07800),
  );

  @override
  BelotColors copyWith() => this;

  @override
  BelotColors lerp(ThemeExtension<BelotColors>? other, double t) {
    if (other is! BelotColors) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return BelotColors(
      background: l(background, other.background),
      surface: l(surface, other.surface),
      surfaceHigh: l(surfaceHigh, other.surfaceHigh),
      outline: l(outline, other.outline),
      textPrimary: l(textPrimary, other.textPrimary),
      textSecondary: l(textSecondary, other.textSecondary),
      cardFace: l(cardFace, other.cardFace),
      cardInk: l(cardInk, other.cardInk),
      cardRed: l(cardRed, other.cardRed),
      cardBack: l(cardBack, other.cardBack),
      cardBackLine: l(cardBackLine, other.cardBackLine),
      accent: l(accent, other.accent),
      chip: l(chip, other.chip),
      chipText: l(chipText, other.chipText),
      success: l(success, other.success),
      danger: l(danger, other.danger),
      teamUs: l(teamUs, other.teamUs),
      teamThem: l(teamThem, other.teamThem),
    );
  }
}

extension BelotThemeX on BuildContext {
  BelotColors get colors => Theme.of(this).extension<BelotColors>()!;
}

class AppTheme {
  static ThemeData dark() => _build(Brightness.dark, BelotColors.dark);
  static ThemeData light() => _build(Brightness.light, BelotColors.light);

  static ThemeData _build(Brightness b, BelotColors c) {
    final base = ThemeData(
      brightness: b,
      useMaterial3: true,
      fontFamily: 'Comfortaa',
      scaffoldBackgroundColor: c.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: c.cardBack,
        brightness: b,
        surface: c.background,
      ),
      splashFactory: InkSparkle.splashFactory,
    );
    return base.copyWith(
      extensions: [c],
      textTheme: base.textTheme.apply(
        bodyColor: c.textPrimary,
        displayColor: c.textPrimary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: c.background,
        foregroundColor: c.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      dividerColor: c.outline,
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      ),
    );
  }
}

/// Type scale (Comfortaa is wide, so sizes are a touch smaller than Inter).
class AppText {
  static const double display = 52;
  static const double score = 26;
  static const double title = 20;
  static const double body = 16;
  static const double label = 14;
  static const double caption = 12;
}

/// Spacing scale.
class Gap {
  static const double xs = 4;
  static const double s = 8;
  static const double m = 12;
  static const double l = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double page = 20;
}
