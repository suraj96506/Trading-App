import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Base HSL colors – vibrant yet harmonious.
  static const _primaryHue = 210; // cool blue

  // Light theme
  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: HSLColor.fromAHSL(1.0, double.parse(_primaryHue.toString()), 0.6, 0.5).toColor(),
    scaffoldBackgroundColor: Colors.white,
    textTheme: GoogleFonts.interTextTheme(),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      foregroundColor: Colors.black87,
    ),
    cardTheme: CardThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      color: Colors.white.withValues(alpha: 0.85), // glass-morphism effect
      margin: const EdgeInsets.all(12),
    ),
    // Subtle micro-animations via splashFactory etc.
    splashFactory: InkRipple.splashFactory,
  );

  // Dark theme – complementary dark palette.
  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: HSLColor.fromAHSL(1.0, double.parse(_primaryHue.toString()), 0.4, 0.6).toColor(),
    scaffoldBackgroundColor: const Color(0xFF121212),
    textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      foregroundColor: Colors.white70,
    ),
    cardTheme: CardThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      color: const Color(0xFF1E1E1E).withValues(alpha: 0.85),
      margin: const EdgeInsets.all(12),
    ),
    splashFactory: InkRipple.splashFactory,
  );
}
