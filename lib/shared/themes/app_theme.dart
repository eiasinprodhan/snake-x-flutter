// app_theme.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ============================================================
  // 🎨 Cinematic Game Palette
  // ============================================================

  // Backgrounds
  static const Color backgroundPrimary = Color(0xFF0A0E21);
  static const Color backgroundSecondary = Color(0xFF111631);
  static const Color backgroundCard = Color(0xFF161B38);
  static const Color backgroundOverlay = Color(0xFF080C1A);

  // Game Colors
  static const Color gameGreen = Color(0xFF00FF88);
  static const Color gameRed = Color(0xFFFF6B6B);
  static const Color gameBlue = Color(0xFF4F6EF7);
  static const Color gameYellow = Color(0xFFFFD166);
  static const Color gamePurple = Color(0xFFA78BFA);
  static const Color gameOrange = Color(0xFFFB923C);
  static const Color gameTeal = Color(0xFF00C9A7);

  // Text
  static const Color textWhite = Color(0xFFFFFFFF);
  static const Color textLight = Color(0xFFE2E8F0);
  static const Color textMuted = Color(0xFF64748B);
  static const Color textDark = Color(0xFF0A0E21);

  // Borders & Misc
  static const Color border = Color(0xFF1E2548);
  static const Color borderLight = Color(0xFF2A3158);
  static const Color shadow = Color(0x60000000);

  // ============================================================
  // 🔄 Backward Compatibility
  // ============================================================
  static const Color backgroundDark = backgroundPrimary;
  static const Color surfaceDark = backgroundSecondary;
  static const Color accentPrimary = gameBlue;
  static const Color accentSecondary = gamePurple;
  static const Color accentTertiary = gameTeal;
  static const Color accentDanger = gameRed;
  static const Color accentYellow = gameYellow;
  static const Color accentOrange = gameOrange;
  static const Color accentPurple = gamePurple;
  static const Color textPrimary = textWhite;
  static const Color textSecondary = textMuted;
  static const Color textLight2 = textWhite;
  static const Color borderDark = border;
  static const Color success = gameGreen;
  static const Color shadowColor = shadow;

  // ============================================================
  // 🌈 Gradients
  // ============================================================
  static const LinearGradient bgGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0A0E21), Color(0xFF0D1117), Color(0xFF161B2E)],
  );

  static const LinearGradient greenGradient = LinearGradient(
    colors: [Color(0xFF00FF88), Color(0xFF00CC6E)],
  );

  static const LinearGradient blueGradient = LinearGradient(
    colors: [Color(0xFF4F6EF7), Color(0xFF3B5BDB)],
  );

  static const LinearGradient yellowGradient = LinearGradient(
    colors: [Color(0xFFFFD166), Color(0xFFF59E0B)],
  );

  static const LinearGradient redGradient = LinearGradient(
    colors: [Color(0xFFFF6B6B), Color(0xFFEF4444)],
  );

  static const LinearGradient purpleGradient = LinearGradient(
    colors: [Color(0xFFA78BFA), Color(0xFF8B5CF6)],
  );

  // ============================================================
  // 🎯 Themes
  // ============================================================
  static ThemeData get darkTheme => _buildTheme();
  static ThemeData get lightTheme => _buildTheme();

  static ThemeData _buildTheme() {
    final TextTheme textTheme = TextTheme(
      displayLarge: GoogleFonts.rajdhani(
        fontSize: 34, fontWeight: FontWeight.w800, color: textWhite,
      ),
      displayMedium: GoogleFonts.rajdhani(
        fontSize: 28, fontWeight: FontWeight.w700, color: textWhite,
      ),
      displaySmall: GoogleFonts.rajdhani(
        fontSize: 24, fontWeight: FontWeight.w700, color: textWhite,
      ),
      headlineMedium: GoogleFonts.rajdhani(
        fontSize: 20, fontWeight: FontWeight.w700, color: textWhite,
      ),
      headlineSmall: GoogleFonts.rajdhani(
        fontSize: 18, fontWeight: FontWeight.w600, color: textWhite,
      ),
      titleLarge: GoogleFonts.rajdhani(
        fontSize: 16, fontWeight: FontWeight.w700, color: textWhite,
      ),
      titleMedium: GoogleFonts.rajdhani(
        fontSize: 15, fontWeight: FontWeight.w600, color: textWhite,
      ),
      bodyLarge: GoogleFonts.rajdhani(
        fontSize: 16, fontWeight: FontWeight.w500, color: textLight,
      ),
      bodyMedium: GoogleFonts.rajdhani(
        fontSize: 14, fontWeight: FontWeight.w400, color: textMuted,
      ),
      bodySmall: GoogleFonts.rajdhani(
        fontSize: 12, fontWeight: FontWeight.w400, color: textMuted,
      ),
      labelLarge: GoogleFonts.rajdhani(
        fontSize: 14, fontWeight: FontWeight.w700, color: textWhite,
      ),
      labelMedium: GoogleFonts.rajdhani(
        fontSize: 12, fontWeight: FontWeight.w600, color: textMuted,
      ),
      labelSmall: GoogleFonts.rajdhani(
        fontSize: 11, fontWeight: FontWeight.w500, color: textMuted,
      ),
    );

    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: backgroundPrimary,
      primaryColor: gameGreen,
      useMaterial3: true,
      colorScheme: const ColorScheme.dark(
        primary: gameGreen,
        secondary: gameBlue,
        tertiary: gamePurple,
        surface: backgroundCard,
        error: gameRed,
        onPrimary: textDark,
        onSecondary: textWhite,
        onSurface: textWhite,
        onError: textWhite,
        outline: border,
      ),
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      cardTheme: CardThemeData(
        color: backgroundCard,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: gameGreen,
          foregroundColor: textDark,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: GoogleFonts.rajdhani(fontSize: 16, fontWeight: FontWeight.w800),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.rajdhani(
          fontSize: 20, fontWeight: FontWeight.w700, color: textWhite,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: backgroundCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: backgroundCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}