import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_constants.dart';
import '../../shared/themes/app_theme.dart';
import 'package:flutter/material.dart';

class StorageService extends ChangeNotifier {
  final SharedPreferences _prefs;

  StorageService(this._prefs);

  int getHighScore() => _prefs.getInt(AppConstants.keyHighScore) ?? 0;
  
  Future<void> saveHighScore(int score) async {
    if (score > getHighScore()) {
      await _prefs.setInt(AppConstants.keyHighScore, score);
      notifyListeners();
    }
  }

  // ─── Theme ─────────────────────────────────────────────────────────────────

  String getGameThemeId() =>
      _prefs.getString(AppConstants.keyGameTheme) ?? GameThemes.defaultThemeId;

  Future<void> saveGameTheme(String id) async {
    await _prefs.setString(AppConstants.keyGameTheme, id);
    notifyListeners();
  }

  // ─── Color helpers (derived from current theme) ────────────────────────────

  Color getSnakeColor() => GameThemes.getById(getGameThemeId()).snakeColor;

  Color getGameBgColor() => GameThemes.getById(getGameThemeId()).bgColor;

  Color getFoodColor() {
    final colorVal = _prefs.getString(AppConstants.keyFoodColor);
    return colorVal != null ? Color(int.parse(colorVal)) : AppTheme.accentDanger;
  }

  Future<void> saveFoodColor(Color color) async {
    await _prefs.setString(AppConstants.keyFoodColor, color.value.toString());
    notifyListeners();
  }

  // ─── Speed ─────────────────────────────────────────────────────────────────

  double getGameSpeed() {
    return _prefs.getDouble(AppConstants.keyGameSpeed) ?? AppConstants.defaultSnakeSpeed;
  }

  Future<void> saveGameSpeed(double speed) async {
    await _prefs.setDouble(AppConstants.keyGameSpeed, speed);
    notifyListeners();
  }

  // ─── Sound & Vibration ─────────────────────────────────────────────────────

  bool isSoundEnabled() => _prefs.getBool(AppConstants.keySoundEnabled) ?? true;
  Future<void> saveSoundEnabled(bool enabled) async {
    await _prefs.setBool(AppConstants.keySoundEnabled, enabled);
    notifyListeners();
  }

  bool isVibrationEnabled() => _prefs.getBool(AppConstants.keyVibrationEnabled) ?? true;
  Future<void> saveVibrationEnabled(bool enabled) async {
    await _prefs.setBool(AppConstants.keyVibrationEnabled, enabled);
    notifyListeners();
  }
}
