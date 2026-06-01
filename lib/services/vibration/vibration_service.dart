import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:vibration/vibration.dart';
import '../storage/storage_service.dart';

class VibrationService {
  final StorageService _storage;

  VibrationService(this._storage);

  Future<void> vibrate() async {
    if (kIsWeb) return; // Vibration not supported on web
    if (!_storage.isVibrationEnabled()) return;
    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(duration: 50);
    }
  }

  Future<void> vibrateHeavy() async {
    if (kIsWeb) return; // Vibration not supported on web
    if (!_storage.isVibrationEnabled()) return;
    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(duration: 200);
    }
  }
}
