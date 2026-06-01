import 'package:flutter/material.dart';

class AppConstants {
  // Game Constants
  static const int gridCount = 20;
  static const double defaultSnakeSpeed = 150; // ms per move - faster for smoother gameplay
  static const double fastSnakeSpeed = 100;
  static const double slowSnakeSpeed = 250;

  // Ad IDs (Test IDs)
  static const String bannerAdUnitId = 'ca-app-pub-1068931647363761/3655692052';
  static const String interstitialAdUnitId = 'ca-app-pub-1068931647363761/8137862547';
  static const String rewardedAdUnitId = 'ca-app-pub-1068931647363761/5320127519';

  // Storage Keys
  static const String keyHighScore = 'high_score';
  static const String keySnakeColor = 'snake_color';
  static const String keyFoodColor = 'food_color';
  static const String keyGameSpeed = 'game_speed';
  static const String keySoundEnabled = 'sound_enabled';
  static const String keyVibrationEnabled = 'vibration_enabled';
  static const String keyGameBgColor = 'game_bg_color';
  static const String keyGameTheme = 'game_theme';

  // Design Constants
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;
  static const double borderRadiusLarge = 20.0;
}

// ─── Game Themes ───────────────────────────────────────────────────────────────
class GameThemeData {
  final String id;
  final String name;
  final String emoji;
  final Color snakeColor;
  final Color bgColor;
  final List<Color> accentGradient;

  const GameThemeData({
    required this.id,
    required this.name,
    required this.emoji,
    required this.snakeColor,
    required this.bgColor,
    required this.accentGradient,
  });
}

class GameThemes {
  static const String defaultThemeId = 'neon';

  static const List<GameThemeData> all = [
    GameThemeData(
      id: 'neon',
      name: 'Neon Night',
      emoji: '🟢',
      snakeColor: Color(0xFF00FF88),
      bgColor: Color(0xFF0A1628),
      accentGradient: [Color(0xFF00FF88), Color(0xFF00C9A7)],
    ),
    GameThemeData(
      id: 'cyber',
      name: 'Cyber Pulse',
      emoji: '🔵',
      snakeColor: Color(0xFF4F6EF7),
      bgColor: Color(0xFF1A1D3B),
      accentGradient: [Color(0xFF4F6EF7), Color(0xFF9B72F5)],
    ),
    GameThemeData(
      id: 'inferno',
      name: 'Inferno',
      emoji: '🌸',
      snakeColor: Color(0xFFFF6B9D),
      bgColor: Color(0xFF1A0A2E),
      accentGradient: [Color(0xFFFF6B9D), Color(0xFFFF4D6D)],
    ),
  ];

  static GameThemeData getById(String id) {
    return all.firstWhere((t) => t.id == id,
        orElse: () => all.first);
  }
}
