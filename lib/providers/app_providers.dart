import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/storage/storage_service.dart';
import '../services/audio/audio_service.dart';
import '../services/vibration/vibration_service.dart';
import '../services/ads/ad_manager.dart';

// We use a Provider for these since they are basically singletons
final sharedPrefsProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError(); // Initialized in main.dart
});

final storageServiceProvider = ChangeNotifierProvider<StorageService>((ref) {
  final prefs = ref.watch(sharedPrefsProvider);
  return StorageService(prefs);
});

final audioServiceProvider = Provider<AudioService>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return AudioService(storage);
});

final vibrationServiceProvider = Provider<VibrationService>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return VibrationService(storage);
});

final adManagerProvider = Provider<AdManager>((ref) {
  return AdManager();
});
