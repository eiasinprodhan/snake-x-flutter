import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/app_providers.dart';
import '../../services/storage/storage_service.dart';
import '../../services/audio/audio_service.dart';

enum GameDirection { up, down, left, right }

class GameState {
  final List<Offset> snake;
  final Offset food;
  final GameDirection direction;
  final int score;
  final bool isPaused;
  final bool isGameOver;
  final bool isBoosting;
  final bool isRevived;

  GameState({
    required this.snake,
    required this.food,
    required this.direction,
    required this.score,
    this.isPaused = false,
    this.isGameOver = false,
    this.isBoosting = false,
    this.isRevived = false,
  });

  GameState copyWith({
    List<Offset>? snake,
    Offset? food,
    GameDirection? direction,
    int? score,
    bool? isPaused,
    bool? isGameOver,
    bool? isBoosting,
    bool? isRevived,
  }) {
    return GameState(
      snake: snake ?? this.snake,
      food: food ?? this.food,
      direction: direction ?? this.direction,
      score: score ?? this.score,
      isPaused: isPaused ?? this.isPaused,
      isGameOver: isGameOver ?? this.isGameOver,
      isBoosting: isBoosting ?? this.isBoosting,
      isRevived: isRevived ?? this.isRevived,
    );
  }
}

class GameNotifier extends StateNotifier<GameState> {
  final StorageService _storage;
  final AudioService _audio;
  Timer? _gameTimer;
  Timer? _boostTimer;
  final Random _random = Random();

  // ── Boost config ──────────────────────────────
  // Factor by which the interval is divided when boosting
  // e.g. 0.45 → ~2.2× faster
  static const double _boostFactor = 0.45;

  GameNotifier(this._storage, this._audio)
      : super(GameState(
    snake: [
      const Offset(10, 10),
      const Offset(10, 11),
      const Offset(10, 12),
    ],
    food: const Offset(5, 5),
    direction: GameDirection.up,
    score: 0,
  ));

  // ══════════════════════════════════════════════
  // PUBLIC API
  // ══════════════════════════════════════════════

  void startGame() {
    _cancelTimers();
    state = GameState(
      snake: [
        const Offset(10, 10),
        const Offset(10, 11),
        const Offset(10, 12),
      ],
      food: _generateFood([
        const Offset(10, 10),
        const Offset(10, 11),
        const Offset(10, 12),
      ]),
      direction: GameDirection.up,
      score: 0,
      isRevived: false,
    );
    _startTimer();
  }

  void changeDirection(GameDirection newDir) {
    if (newDir == GameDirection.up &&
        state.direction == GameDirection.down) return;
    if (newDir == GameDirection.down &&
        state.direction == GameDirection.up) return;
    if (newDir == GameDirection.left &&
        state.direction == GameDirection.right) return;
    if (newDir == GameDirection.right &&
        state.direction == GameDirection.left) return;

    state = state.copyWith(direction: newDir);
  }

  void togglePause() {
    if (state.isGameOver) return;

    final nowPaused = !state.isPaused;
    state = state.copyWith(isPaused: nowPaused);

    if (nowPaused) {
      // Pause — cancel movement timer but keep boost state intact
      _gameTimer?.cancel();
      _gameTimer = null;
    } else {
      // Resume — restart at current speed (boost-aware)
      _startTimer();
    }
  }

  // ── Boost ──────────────────────────────────────

  /// Speeds up the snake.
  void activateBoost() {
    if (state.isBoosting || state.isPaused || state.isGameOver) return;

    state = state.copyWith(isBoosting: true);

    // Restart timer at boosted speed
    _startTimer();
  }

  /// Returns the snake to normal speed.
  void deactivateBoost() {
    if (!state.isBoosting) return;

    if (!mounted) return;

    state = state.copyWith(isBoosting: false);

    // Restart timer at normal speed (only if game is still running)
    if (!state.isPaused && !state.isGameOver) {
      _startTimer();
    }
  }

  // ══════════════════════════════════════════════
  // INTERNAL
  // ══════════════════════════════════════════════

  void _startTimer() {
    _gameTimer?.cancel();
    _gameTimer = null;

    final baseSpeed = _storage.getGameSpeed(); // e.g. 200 ms
    final interval = state.isBoosting
        ? (baseSpeed * _boostFactor).clamp(50, baseSpeed).toInt()
        : baseSpeed.toInt();

    _gameTimer = Timer.periodic(
      Duration(milliseconds: interval),
          (_) => _tick(),
    );
  }

  void _tick() {
    if (state.isPaused || state.isGameOver) return;
    _moveSnake();
  }

  void _moveSnake() {
    final head = state.snake.first;
    late final Offset newHead;

    switch (state.direction) {
      case GameDirection.up:
        newHead = Offset(head.dx, head.dy - 1);
        break;
      case GameDirection.down:
        newHead = Offset(head.dx, head.dy + 1);
        break;
      case GameDirection.left:
        newHead = Offset(head.dx - 1, head.dy);
        break;
      case GameDirection.right:
        newHead = Offset(head.dx + 1, head.dy);
        break;
    }

    // Wall collision
    if (newHead.dx < 0 ||
        newHead.dx >= AppConstants.gridCount ||
        newHead.dy < 0 ||
        newHead.dy >= AppConstants.gridCount) {
      _gameOver();
      return;
    }

    // Self collision
    if (state.snake.contains(newHead)) {
      _gameOver();
      return;
    }

    final newSnake = List<Offset>.from(state.snake)..insert(0, newHead);

    if (newHead == state.food) {
      // Ate food — grow + score
      _audio.playEat();
      state = state.copyWith(
        snake: newSnake,
        food: _generateFood(newSnake),
        score: state.score + 10,
      );
    } else {
      newSnake.removeLast();
      state = state.copyWith(snake: newSnake);
    }
  }

  void _gameOver() {
    _cancelTimers();
    state = state.copyWith(isGameOver: true, isBoosting: false);
    _storage.saveHighScore(state.score);
    _audio.playGameOver();
  }

  void revive() {
    if (!state.isGameOver) return;

    // Reset snake to a safe starting position but KEEP score
    state = state.copyWith(
      snake: [
        const Offset(10, 10),
        const Offset(10, 11),
        const Offset(10, 12),
      ],
      direction: GameDirection.up,
      isGameOver: false,
      isPaused: false,
      isBoosting: false,
      isRevived: true,
    );

    // Restart the timer
    _startTimer();
  }

  Offset _generateFood(List<Offset> snake) {
    while (true) {
      final food = Offset(
        _random.nextInt(AppConstants.gridCount).toDouble(),
        _random.nextInt(AppConstants.gridCount).toDouble(),
      );
      if (!snake.contains(food)) return food;
    }
  }

  void _cancelTimers() {
    _gameTimer?.cancel();
    _gameTimer = null;
    _boostTimer?.cancel();
    _boostTimer = null;
  }

  // Keep the old public name so nothing else breaks
  // ignore: unused_element
  void moveSnake() => _moveSnake();

  void gameOver() => _gameOver();

  @override
  void dispose() {
    _cancelTimers();
    super.dispose();
  }
}

final gameProvider =
StateNotifierProvider<GameNotifier, GameState>((ref) {
  final storage = ref.watch(storageServiceProvider);
  final audio = ref.watch(audioServiceProvider);
  return GameNotifier(storage, audio);
});