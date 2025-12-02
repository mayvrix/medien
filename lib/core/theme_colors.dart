import 'package:flutter/material.dart';

/// Central color source (no hard-coded colors anywhere else).
/// Add warm mode later by extending AppPalette.
class AppPalette {
  final Color bg;          // surface background
  final Color card;        // cards / containers
  final Color primary;     // brand purple
  final Color onPrimary;   // text/icon on primary
  final Color text;        // main text
  final Color textMuted;   // secondary text
  final Color stroke;      // outlines
  final Color accent;      // CTA arrow
  final Color secondary;
  final Color icon;
  final Color blur;

  const AppPalette({
    required this.bg,
    required this.card,
    required this.primary,
    required this.onPrimary,
    required this.text,
    required this.textMuted,
    required this.stroke,
    required this.accent,
    required this.secondary,
    required this.icon,
    required this.blur,
  });

  /// LIGHT COOL
  factory AppPalette.light() => const AppPalette(
        bg: Color.fromARGB(255, 226, 227, 255),
        card: Color.fromARGB(255, 223, 209, 255),
        primary: Color.fromARGB(255, 91, 41, 228),
        onPrimary: Colors.white,
        text: Color(0xFF1E1A2E),
        textMuted: Color(0xFF645F7A),
        stroke: Color(0xFFCDC1FF),
        accent: Color(0xFF7B61FF),
        secondary:Color.fromARGB(255, 166, 158, 251),
        icon: Color.fromARGB(255, 203, 205, 253),
        blur:    Color.fromARGB(0, 255, 255, 255),
      );

  /// Dark COOL
  factory AppPalette.dark() => const AppPalette(
        bg: Color(0xFF0E0B19),
        card: Color(0xFF16122A),
        primary: Color.fromARGB(255, 97, 44, 255),
        onPrimary: Color.fromARGB(255, 0, 0, 0),
        text: Color(0xFFEDE9FF),
        textMuted: Color(0xFFB7B0D6),
        stroke: Color(0xFF2B2546),
        accent: Color(0xFFB39DFF),
        secondary:Color.fromARGB(255, 40, 43, 109),
        icon: Color.fromARGB(255, 203, 205, 253),
        blur:   Color.fromARGB(0, 0, 0, 0),
      );

  /// WARM LIGHT
  factory AppPalette.warmlight() => const AppPalette(
        bg: Color.fromARGB(255, 247, 255, 229),
        card: Color.fromARGB(255, 223, 253, 207),
        primary: Color.fromARGB(255, 90, 255, 49),
        onPrimary: Color.fromARGB(255, 255, 255, 255),
        text: Color(0xFF2B1B16),
        textMuted: Color(0xFF7A5E55),
        stroke: Color(0xFFFFD3BD),
        accent: Color(0xFFFF8A65),
        secondary:Color.fromARGB(255, 255, 168, 168),
        icon: Color.fromARGB(255, 120, 151, 104),
        blur:   Color.fromARGB(0, 255, 255, 255),
      );

        /// WARM DARK
  factory AppPalette.warmdark() => const AppPalette(
        bg:Color.fromARGB(255, 10, 18, 8),
        card: Color.fromARGB(255, 92, 122, 89),
        primary: Color.fromARGB(255, 124, 254, 77),
        onPrimary: Color.fromARGB(255, 0, 0, 0),
        text: Color.fromARGB(255, 255, 255, 255),
        textMuted: Color(0xFF7A5E55),
        stroke: Color(0xFFFFD3BD),
        accent: Color.fromARGB(255, 252, 179, 157),
        secondary:Color.fromARGB(255, 104, 52, 52),
        icon: Color.fromARGB(255, 83, 135, 57),
        blur:   Color.fromARGB(0, 0, 0, 0),
      );
}

/// Theme extension so we can read colors anywhere via:
/// `context.appColors`.
class AppColors extends ThemeExtension<AppColors> {
  final AppPalette palette;
  const AppColors(this.palette);

  @override
  AppColors copyWith({AppPalette? palette}) =>
      AppColors(palette ?? this.palette);

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    // Simple switch—no morphing needed.
    return t < 0.5 ? this : other;
  }
}

extension AppColorX on BuildContext {
  AppPalette get appColors =>
      Theme.of(this).extension<AppColors>()!.palette;
}
