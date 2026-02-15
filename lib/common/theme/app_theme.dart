import 'package:flutter/material.dart';

class AppTheme {
  static const _ubuntuOrange = Color(0xFFE95420);
  static const _aubergine = Color(0xFF2C001E);
  static const _warmGrey = Color(0xFF5E5E5E);
  static const _paper = Color(0xFFF7F3EE);
  static const _darkBg = Color(0xFF1F1B24);

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: _ubuntuOrange,
      brightness: Brightness.light,
      primary: _ubuntuOrange,
      secondary: _aubergine,
      surface: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: _paper,
      appBarTheme: AppBarTheme(
        centerTitle: true,
        backgroundColor: scheme.surface,
        foregroundColor: _aubergine,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        elevation: 1,
        margin: const EdgeInsets.all(8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      chipTheme: ChipThemeData.fromDefaults(
        secondaryColor: _ubuntuOrange,
        brightness: Brightness.light,
        labelStyle: const TextStyle(color: _warmGrey),
      ),
    );
  }

  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(
      seedColor: _ubuntuOrange,
      brightness: Brightness.dark,
      primary: _ubuntuOrange,
      secondary: const Color(0xFFE8B4D3),
      surface: const Color(0xFF2A2330),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: _darkBg,
      appBarTheme: AppBarTheme(
        centerTitle: true,
        backgroundColor: scheme.surface,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        elevation: 1,
        margin: const EdgeInsets.all(8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surface.withValues(alpha: 0.7),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
