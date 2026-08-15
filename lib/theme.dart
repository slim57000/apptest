import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static ThemeData light() => _themeFrom(
        ColorScheme.fromSeed(seedColor: const Color(0xFF6C5CE7)),
      );

  static ThemeData dark() => _themeFrom(
        ColorScheme.fromSeed(
          seedColor: const Color(0xFF6C5CE7),
          brightness: Brightness.dark,
        ),
      );

  static ThemeData _themeFrom(ColorScheme colorScheme) {
    final base = ThemeData(colorScheme: colorScheme, useMaterial3: true);
    return base.copyWith(
      textTheme: GoogleFonts.poppinsTextTheme(base.textTheme),
      scaffoldBackgroundColor: base.colorScheme.surface,
      cardTheme: const CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: base.colorScheme.surface,
        foregroundColor: base.colorScheme.onSurface,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: base.colorScheme.onSurface,
        ),
      ),
    );
  }
}

/// Palette de couleurs proposées pour une habitude (valeurs ARGB).
const List<int> habitColorPalette = [
  0xFF6C5CE7,
  0xFF00B894,
  0xFFE17055,
  0xFF0984E3,
  0xFFE84393,
  0xFFFDCB6E,
];

/// Emojis proposés pour une habitude.
const List<String> habitEmojiChoices = [
  '💧', '📖', '🏃', '🧘', '🥗', '😴', '💪', '🎯',
  '✍️', '🎨', '🚭', '🧹', '💰', '🌱', '🎵', '☀️',
];
