import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'neu_colors.dart';

const NeuColors kLightNeu = NeuColors(
  background: Color(0xFFE9EDF2),
  surface: Color(0xFFE9EDF2),
  lightShadow: Color(0xFFFFFFFF),
  darkShadow: Color(0xFFC3C9D4),
  accent: Color(0xFF2E7D5B),
  text: Color(0xFF2B2F36),
  subtext: Color(0xFF8A919E),
);

const NeuColors kDarkNeu = NeuColors(
  background: Color(0xFF1B1E24),
  surface: Color(0xFF22262D),
  lightShadow: Color(0xFF2C313A),
  darkShadow: Color(0xFF12151A),
  accent: Color(0xFF4CAF8E),
  text: Color(0xFFE6E9EF),
  subtext: Color(0xFF8B93A1),
);

ThemeData buildAppTheme(Brightness brightness) {
  final neu = brightness == Brightness.light ? kLightNeu : kDarkNeu;
  final base = ThemeData(brightness: brightness, useMaterial3: true);
  final textTheme = GoogleFonts.cairoTextTheme(base.textTheme)
      .apply(bodyColor: neu.text, displayColor: neu.text);
  return base.copyWith(
    scaffoldBackgroundColor: neu.background,
    textTheme: textTheme,
    extensions: [neu],
    colorScheme: ColorScheme.fromSeed(
      seedColor: neu.accent,
      brightness: brightness,
    ).copyWith(surface: neu.background),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: neu.surface,
      contentTextStyle: textTheme.bodyMedium,
      behavior: SnackBarBehavior.floating,
    ),
  );
}
