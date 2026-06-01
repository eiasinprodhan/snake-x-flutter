import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import '../storage/storage_service.dart';

class AudioService {
  final StorageService _storage;
  final AudioPlayer _eatPlayer = AudioPlayer()..setPlayerMode(PlayerMode.lowLatency);
  final AudioPlayer _clickPlayer = AudioPlayer()..setPlayerMode(PlayerMode.lowLatency);
  final AudioPlayer _gameOverPlayer = AudioPlayer()..setPlayerMode(PlayerMode.lowLatency);

  AudioService(this._storage) {
    _eatPlayer.setSource(AssetSource('audio/eat.mp3'));
    _clickPlayer.setSource(AssetSource('audio/click.mp3'));
    _gameOverPlayer.setSource(AssetSource('audio/game_over.mp3'));
  }

  void _play(AudioPlayer player, String assetPath) async {
    if (!_storage.isSoundEnabled()) return;
    try {
      // For short SFX, ensure we stop previous playback first
      // to avoid intermittent failures on rapid triggers.
      await player.stop();
      await player.play(AssetSource(assetPath));
    } catch (e) {
      debugPrint('Audio playback error: $e');
    }
  }

  void playEat() => _play(_eatPlayer, 'audio/eat.mp3');
  void playClick() => _play(_clickPlayer, 'audio/click.mp3');
  void playGameOver() => _play(_gameOverPlayer, 'audio/game_over.mp3');
}
