import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:math';
import '../../core/constants/app_constants.dart';
import '../../providers/app_providers.dart';
import '../../shared/themes/app_theme.dart';
import 'game_provider.dart';
import '../../features/game_over/game_over_screen.dart';

class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({super.key});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen>
    with TickerProviderStateMixin {
  bool _hasNavigatedToGameOver = false;
  late AnimationController _scorePopController;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _borderDangerController;
  late Animation<double> _borderDangerAnimation;
  int _lastScore = 0;
  bool _isBoosting = false;

  @override
  void initState() {
    super.initState();
    _hasNavigatedToGameOver = false;

    _scorePopController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2200),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Danger border pulsing animation
    _borderDangerController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);

    _borderDangerAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(
          parent: _borderDangerController, curve: Curves.easeInOut),
    );

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    Future.microtask(() {
      final gameState = ref.read(gameProvider);
      if (!gameState.isRevived) {
        ref.read(gameProvider.notifier).startGame();
      }
    });
  }

  @override
  void dispose() {
    _scorePopController.dispose();
    _pulseController.dispose();
    _borderDangerController.dispose();
    super.dispose();
  }

  void _activateBoost() {
    if (!_isBoosting) {
      setState(() => _isBoosting = true);
      ref.read(gameProvider.notifier).activateBoost();
      ref.read(vibrationServiceProvider).vibrate();
    }
  }

  void _deactivateBoost() {
    if (_isBoosting) {
      setState(() => _isBoosting = false);
      ref.read(gameProvider.notifier).deactivateBoost();
      ref.read(vibrationServiceProvider).vibrate();
    }
  }

  @override
  Widget build(BuildContext context) {
    final adManager = ref.read(adManagerProvider);
    final audio = ref.read(audioServiceProvider);
    final storage = ref.watch(storageServiceProvider);
    final snakeColor = storage.getSnakeColor();

    ref.listen<GameState>(gameProvider, (previous, next) {
      if (next.score != _lastScore) {
        _lastScore = next.score;
        _scorePopController.forward(from: 0);
      }

      if (next.isGameOver && !_hasNavigatedToGameOver) {
        _hasNavigatedToGameOver = true;
        ref.read(vibrationServiceProvider).vibrateHeavy();
        
        final finalScore = next.score;
        final currentHighScore = ref.read(storageServiceProvider).getHighScore();
        final displayedHighScore = finalScore > currentHighScore ? finalScore : currentHighScore;
        
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.pushReplacement(
            context,
            PageRouteBuilder(
              transitionDuration: const Duration(milliseconds: 500),
              pageBuilder: (_, __, ___) => GameOverScreen(
                score: finalScore,
                highScore: displayedHighScore,
              ),
              transitionsBuilder: (_, animation, __, child) {
                return FadeTransition(opacity: animation, child: child);
              },
            ),
          );
        });
      }
    });

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0A0E21),
              Color(0xFF0D1117),
              Color(0xFF161B2E),
              Color(0xFF0A0E1A),
            ],
            stops: [0.0, 0.35, 0.65, 1.0],
          ),
        ),
        child: Stack(
          children: [
            _buildHexGrid(),
            _buildScanLines(),
            _buildVignette(),
            _buildHudCorners(),
            Focus(
              autofocus: true,
              onKeyEvent: (node, event) {
                if (event is KeyDownEvent) {
                  final keyMap = {
                    LogicalKeyboardKey.arrowUp: GameDirection.up,
                    LogicalKeyboardKey.keyW: GameDirection.up,
                    LogicalKeyboardKey.arrowDown: GameDirection.down,
                    LogicalKeyboardKey.keyS: GameDirection.down,
                    LogicalKeyboardKey.arrowLeft: GameDirection.left,
                    LogicalKeyboardKey.keyA: GameDirection.left,
                    LogicalKeyboardKey.arrowRight: GameDirection.right,
                    LogicalKeyboardKey.keyD: GameDirection.right,
                  };

                  final dir = keyMap[event.logicalKey];
                  if (dir != null) {
                    ref.read(gameProvider.notifier).changeDirection(dir);
                    audio.playClick();
                    ref.read(vibrationServiceProvider).vibrate();
                    return KeyEventResult.handled;
                  }

                  if (event.logicalKey == LogicalKeyboardKey.space) {
                    ref.read(gameProvider.notifier).togglePause();
                    return KeyEventResult.handled;
                  }

                  if (event.logicalKey == LogicalKeyboardKey.shift) {
                    if (event is KeyDownEvent) {
                      _activateBoost();
                    } else if (event is KeyUpEvent) {
                      _deactivateBoost();
                    }
                    return KeyEventResult.handled;
                  }
                }
                return KeyEventResult.ignored;
              },
              child: SafeArea(
                child: Column(
                  children: [
                    _buildTopBar(audio, snakeColor),
                    Expanded(
                      child: Center(
                        child: AspectRatio(
                          aspectRatio: 1,
                          child: Container(
                            margin: const EdgeInsets.symmetric(
                              horizontal: AppConstants.paddingMedium,
                            ),
                            child: _buildGameBoard(storage, snakeColor),
                          ),
                        ),
                      ),
                    ),
                    _GameControls(
                      snakeColor: snakeColor,
                      isBoosting: _isBoosting,
                      onDirectionChanged: (dir) {
                        ref.read(gameProvider.notifier).changeDirection(dir);
                        audio.playClick();
                        ref.read(vibrationServiceProvider).vibrate();
                      },
                      onBoostStart: _activateBoost,
                      onBoostEnd: _deactivateBoost,
                    ),
                    if (!kIsWeb) _buildAdBanner(adManager),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════
  // ⬡ HEX GRID
  // ═══════════════════════════════════════════
  Widget _buildHexGrid() {
    return Positioned.fill(
      child: CustomPaint(
        painter: _HexGridPainter(),
      ).animate().fadeIn(duration: 1200.ms),
    );
  }

  // ═══════════════════════════════════════════
  // ▤ SCAN LINES
  // ═══════════════════════════════════════════
  Widget _buildScanLines() {
    return Positioned.fill(
      child: IgnorePointer(
        child: CustomPaint(painter: _ScanLinePainter()),
      ),
    );
  }

  // ═══════════════════════════════════════════
  // 🌑 VIGNETTE
  // ═══════════════════════════════════════════
  Widget _buildVignette() {
    return Positioned.fill(
      child: IgnorePointer(
        child: Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 0.92,
              colors: [
                Colors.transparent,
                Colors.black.withOpacity(0.4),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════
  // 🔲 HUD CORNERS
  // ═══════════════════════════════════════════
  Widget _buildHudCorners() {
    return Positioned.fill(
      child: IgnorePointer(
        child: CustomPaint(painter: _HudCornerPainter())
            .animate()
            .fadeIn(delay: 300.ms, duration: 600.ms),
      ),
    );
  }

  // ═══════════════════════════════════════════
  // 🎯 TOP BAR
  // ═══════════════════════════════════════════
  Widget _buildTopBar(dynamic audio, Color snakeColor) {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 8, 14, 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF111631).withOpacity(0.65),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withOpacity(0.05),
          width: 1,
        ),
      ),
      child: Consumer(
        builder: (context, ref, _) {
          final gameState = ref.watch(gameProvider);
          final storage = ref.watch(storageServiceProvider);
          final highScore = storage.getHighScore();

          return Row(
            children: [
              _buildTopBarButton(
                icon: Icons.arrow_back_ios_new_rounded,
                snakeColor: snakeColor,
                onTap: () {
                  audio.playClick();
                  ref.read(gameProvider.notifier).togglePause();
                  _showExitDialog(context, ref, audio, snakeColor);
                },
              ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.3, end: 0),

              const SizedBox(width: 10),

              Expanded(
                child: _buildScoreSection(
                    gameState.score, highScore, snakeColor),
              ),

              const SizedBox(width: 10),

              if (_isBoosting)
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD166).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFFFFD166).withOpacity(0.35),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.bolt_rounded,
                        color: Color(0xFFFFD166),
                        size: 14,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        'BOOST',
                        style: GoogleFonts.rajdhani(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFFFFD166),
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                )
                    .animate()
                    .fadeIn(duration: 200.ms)
                    .then()
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .scale(
                  begin: const Offset(1.0, 1.0),
                  end: const Offset(1.08, 1.08),
                  duration: 500.ms,
                ),

              _buildTopBarButton(
                icon: gameState.isPaused
                    ? Icons.play_arrow_rounded
                    : Icons.pause_rounded,
                isActive: gameState.isPaused,
                snakeColor: snakeColor,
                onTap: () {
                  audio.playClick();
                  ref.read(gameProvider.notifier).togglePause();
                },
              ).animate().fadeIn(duration: 400.ms).slideX(begin: 0.3, end: 0),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTopBarButton({
    required IconData icon,
    required Color snakeColor,
    bool isActive = false,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isActive
              ? snakeColor.withOpacity(0.14)
              : Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive
                ? snakeColor.withOpacity(0.3)
                : Colors.white.withOpacity(0.07),
            width: 1,
          ),
        ),
        child: Icon(
          icon,
          color: isActive ? snakeColor : Colors.white.withOpacity(0.5),
          size: 18,
        ),
      ),
    );
  }

  Widget _buildScoreSection(int score, int highScore, Color snakeColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.05),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'SCORE',
                style: GoogleFonts.rajdhani(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: Colors.white.withOpacity(0.3),
                  letterSpacing: 2,
                ),
              ),
              AnimatedBuilder(
                animation: _scorePopController,
                builder: (context, child) {
                  final scale = 1.0 +
                      (0.2 *
                          Curves.elasticOut
                              .transform(_scorePopController.value));
                  return Transform.scale(
                    scale: scale,
                    alignment: Alignment.centerLeft,
                    child: child,
                  );
                },
                child: Text(
                  '$score',
                  style: GoogleFonts.orbitron(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: snakeColor,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
          Container(
            width: 1,
            height: 28,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.white.withOpacity(0.08),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.emoji_events_rounded,
                    size: 10,
                    color: const Color(0xFFFFD166).withOpacity(0.55),
                  ),
                  const SizedBox(width: 3),
                  Text(
                    'BEST',
                    style: GoogleFonts.rajdhani(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFFFD166).withOpacity(0.45),
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
              Text(
                '$highScore',
                style: GoogleFonts.orbitron(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFFFD166).withOpacity(0.65),
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════
  // 🎮 GAME BOARD WITH DANGER BORDER
  // ═══════════════════════════════════════════
  Widget _buildGameBoard(dynamic storage, Color snakeColor) {
    return Consumer(
      builder: (context, ref, _) {
        final gameState = ref.watch(gameProvider);
        final bgColor = storage.getGameBgColor();
        final theme = GameThemes.getById(storage.getGameThemeId());
        final foodColor = theme.accentGradient.last;

        return AnimatedBuilder(
          animation: _borderDangerAnimation,
          builder: (context, child) {
            return Stack(
              children: [
                // ── DANGER BORDER (outer glow layer) ──
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: [
                      // Pulsing red danger glow
                      BoxShadow(
                        color: const Color(0xFFFF4D6D).withOpacity(
                            0.08 * _borderDangerAnimation.value),
                        blurRadius: 25,
                        spreadRadius: 3,
                      ),
                      // Snake color ambient glow
                      BoxShadow(
                        color: snakeColor.withOpacity(0.04),
                        blurRadius: 30,
                      ),
                      // Drop shadow
                      BoxShadow(
                        color: Colors.black.withOpacity(0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: CustomPaint(
                    foregroundPainter: _DangerBorderPainter(
                      dangerPulse: _borderDangerAnimation.value,
                      snakeColor: snakeColor,
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: Stack(
                          children: [
                            // Danger zone strips at edges
                            ..._buildDangerZones(snakeColor),
                            // Corner warning markers
                            ..._buildCornerWarnings(),
                            // Game canvas
                            CustomPaint(
                              painter: _GamePainter(
                                gameState,
                                snakeColor,
                                foodColor,
                                bgColor,
                                _isBoosting,
                              ),
                              size: Size.infinite,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // ── PAUSE OVERLAY ──
                if (gameState.isPaused) _buildPauseOverlay(snakeColor),
              ],
            );
          },
        );
      },
    );
  }

  // ── DANGER ZONE EDGE STRIPS ──
  List<Widget> _buildDangerZones(Color snakeColor) {
    const stripWidth = 3.0;
    return [
      // Top danger strip
      Positioned(
        top: 0,
        left: 0,
        right: 0,
        child: Container(
          height: stripWidth,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFFFF4D6D).withOpacity(0.0),
                const Color(0xFFFF4D6D).withOpacity(0.15),
                const Color(0xFFFF4D6D).withOpacity(0.25),
                const Color(0xFFFF4D6D).withOpacity(0.15),
                const Color(0xFFFF4D6D).withOpacity(0.0),
              ],
            ),
          ),
        ),
      ),
      // Bottom danger strip
      Positioned(
        bottom: 0,
        left: 0,
        right: 0,
        child: Container(
          height: stripWidth,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFFFF4D6D).withOpacity(0.0),
                const Color(0xFFFF4D6D).withOpacity(0.15),
                const Color(0xFFFF4D6D).withOpacity(0.25),
                const Color(0xFFFF4D6D).withOpacity(0.15),
                const Color(0xFFFF4D6D).withOpacity(0.0),
              ],
            ),
          ),
        ),
      ),
      // Left danger strip
      Positioned(
        top: 0,
        bottom: 0,
        left: 0,
        child: Container(
          width: stripWidth,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFFFF4D6D).withOpacity(0.0),
                const Color(0xFFFF4D6D).withOpacity(0.15),
                const Color(0xFFFF4D6D).withOpacity(0.25),
                const Color(0xFFFF4D6D).withOpacity(0.15),
                const Color(0xFFFF4D6D).withOpacity(0.0),
              ],
            ),
          ),
        ),
      ),
      // Right danger strip
      Positioned(
        top: 0,
        bottom: 0,
        right: 0,
        child: Container(
          width: stripWidth,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFFFF4D6D).withOpacity(0.0),
                const Color(0xFFFF4D6D).withOpacity(0.15),
                const Color(0xFFFF4D6D).withOpacity(0.25),
                const Color(0xFFFF4D6D).withOpacity(0.15),
                const Color(0xFFFF4D6D).withOpacity(0.0),
              ],
            ),
          ),
        ),
      ),
    ];
  }

  // ── CORNER WARNING MARKERS ──
  List<Widget> _buildCornerWarnings() {
    const size = 10.0;
    const dangerColor = Color(0xFFFF4D6D);

    Widget buildCorner(bool flipX, bool flipY) {
      return Transform.flip(
        flipX: flipX,
        flipY: flipY,
        child: SizedBox(
          width: size,
          height: size,
          child: CustomPaint(
            painter: _CornerWarningPainter(
              color: dangerColor.withOpacity(0.35),
            ),
          ),
        ),
      );
    }

    return [
      Positioned(top: 2, left: 2, child: buildCorner(false, false)),
      Positioned(top: 2, right: 2, child: buildCorner(true, false)),
      Positioned(bottom: 2, left: 2, child: buildCorner(false, true)),
      Positioned(bottom: 2, right: 2, child: buildCorner(true, true)),
    ];
  }

  Widget _buildPauseOverlay(Color snakeColor) {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0A0E21).withOpacity(0.88),
          borderRadius: BorderRadius.circular(2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: snakeColor.withOpacity(0.08),
                border: Border.all(
                  color: snakeColor.withOpacity(0.25),
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.pause_rounded,
                color: snakeColor,
                size: 36,
              ),
            )
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .scale(
              begin: const Offset(1.0, 1.0),
              end: const Offset(1.1, 1.1),
              duration: 1500.ms,
            ),
            const SizedBox(height: 22),
            ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                colors: [Colors.white, snakeColor.withOpacity(0.7)],
              ).createShader(bounds),
              child: Text(
                'PAUSED',
                style: GoogleFonts.rajdhani(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 8,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap play to continue',
              style: GoogleFonts.rajdhani(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white.withOpacity(0.35),
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ).animate().fadeIn(duration: 300.ms),
    );
  }

  // ═══════════════════════════════════════════
  // 📢 AD BANNER
  // ═══════════════════════════════════════════
  Widget _buildAdBanner(dynamic adManager) {
    final bannerAd = adManager.loadBannerAd();
    if (bannerAd == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        border: Border(
          top: BorderSide(
            color: Colors.white.withOpacity(0.05),
            width: 1,
          ),
        ),
      ),
      child: SizedBox(
        width: AdSize.banner.width.toDouble(),
        height: AdSize.banner.height.toDouble(),
        child: AdWidget(ad: bannerAd),
      ),
    );
  }

  // ═══════════════════════════════════════════
  // 🚪 EXIT DIALOG
  // ═══════════════════════════════════════════
  void _showExitDialog(
      BuildContext context, WidgetRef ref, dynamic audio, Color snakeColor) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.75),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: const Color(0xFF111631),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withOpacity(0.07),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 40,
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(painter: _DialogCornerPainter()),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFFF6B6B).withOpacity(0.08),
                      border: Border.all(
                        color: const Color(0xFFFF6B6B).withOpacity(0.28),
                        width: 1.5,
                      ),
                    ),
                    child: const Icon(
                      Icons.warning_amber_rounded,
                      color: Color(0xFFFF6B6B),
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'LEAVE GAME?',
                    style: GoogleFonts.rajdhani(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your current progress\nwill be lost.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.rajdhani(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withOpacity(0.35),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 28),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            audio.playClick();
                            Navigator.pop(ctx);
                            ref.read(gameProvider.notifier).togglePause();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: GameThemes.getById(
                                  ref
                                      .read(storageServiceProvider)
                                      .getGameThemeId(),
                                ).accentGradient,
                              ),
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: snakeColor.withOpacity(0.3),
                                  blurRadius: 14,
                                ),
                              ],
                            ),
                            child: Stack(
                              children: [
                                Positioned.fill(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(14),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [
                                            Colors.white.withOpacity(0.12),
                                            Colors.transparent,
                                          ],
                                          stops: const [0.0, 0.5],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Center(
                                  child: Text(
                                    'CONTINUE',
                                    style: GoogleFonts.rajdhani(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w900,
                                      color: const Color(0xFF0A0E21),
                                      letterSpacing: 2,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            audio.playClick();
                            Navigator.pop(ctx);
                            Navigator.pop(context);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.04),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: const Color(0xFFFF6B6B)
                                    .withOpacity(0.25),
                                width: 1.5,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                'LEAVE',
                                style: GoogleFonts.rajdhani(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                  color: const Color(0xFFFF6B6B)
                                      .withOpacity(0.7),
                                  letterSpacing: 2,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════
// 🎮 GAME CONTROLS — CIRCULAR D-PAD
// ═══════════════════════════════════════════════════
class _GameControls extends StatelessWidget {
  final Function(GameDirection) onDirectionChanged;
  final VoidCallback onBoostStart;
  final VoidCallback onBoostEnd;
  final Color snakeColor;
  final bool isBoosting;

  const _GameControls({
    required this.onDirectionChanged,
    required this.onBoostStart,
    required this.onBoostEnd,
    required this.snakeColor,
    required this.isBoosting,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.paddingLarge,
        vertical: 12,
      ),
      child: SizedBox(
        width: 280,
        height: 280,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Outer ring
            Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: snakeColor.withOpacity(0.06),
                  width: 1,
                ),
              ),
            ),
            // Inner ring
            Container(
              width: 230,
              height: 230,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withOpacity(0.03),
                  width: 1,
                ),
              ),
            ),
            // UP
            Positioned(
              top: 10,
              child: _CircularControlBtn(
                icon: Icons.keyboard_arrow_up_rounded,
                dir: GameDirection.up,
                snakeColor: snakeColor,
                onTap: onDirectionChanged,
              ),
            ),
            // DOWN
            Positioned(
              bottom: 10,
              child: _CircularControlBtn(
                icon: Icons.keyboard_arrow_down_rounded,
                dir: GameDirection.down,
                snakeColor: snakeColor,
                onTap: onDirectionChanged,
              ),
            ),
            // LEFT
            Positioned(
              left: 10,
              child: _CircularControlBtn(
                icon: Icons.keyboard_arrow_left_rounded,
                dir: GameDirection.left,
                snakeColor: snakeColor,
                onTap: onDirectionChanged,
              ),
            ),
            // RIGHT
            Positioned(
              right: 10,
              child: _CircularControlBtn(
                icon: Icons.keyboard_arrow_right_rounded,
                dir: GameDirection.right,
                snakeColor: snakeColor,
                onTap: onDirectionChanged,
              ),
            ),
            // CENTER BOOST
            _BoostButton(
              snakeColor: snakeColor,
              isBoosting: isBoosting,
              onStart: onBoostStart,
              onEnd: onBoostEnd,
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════
// ⬤ CIRCULAR CONTROL BUTTON
// ═══════════════════════════════════════════════════
class _CircularControlBtn extends StatefulWidget {
  final IconData icon;
  final GameDirection dir;
  final Function(GameDirection) onTap;
  final Color snakeColor;

  const _CircularControlBtn({
    required this.icon,
    required this.dir,
    required this.onTap,
    required this.snakeColor,
  });

  @override
  State<_CircularControlBtn> createState() => _CircularControlBtnState();
}

class _CircularControlBtnState extends State<_CircularControlBtn>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 80),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.85).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        setState(() => _isPressed = true);
        _controller.forward();
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        _controller.reverse();
        widget.onTap(widget.dir);
      },
      onTapCancel: () {
        setState(() => _isPressed = false);
        _controller.reverse();
      },
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          );
        },
        child: Container(
          width: 85,
          height: 85,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _isPressed
                ? widget.snakeColor.withOpacity(0.18)
                : const Color(0xFF111631).withOpacity(0.7),
            border: Border.all(
              color: _isPressed
                  ? widget.snakeColor.withOpacity(0.5)
                  : Colors.white.withOpacity(0.08),
              width: 2.0,
            ),
            boxShadow: [
              if (_isPressed)
                BoxShadow(
                  color: widget.snakeColor.withOpacity(0.25),
                  blurRadius: 22,
                  spreadRadius: 3,
                ),
              BoxShadow(
                color: Colors.black.withOpacity(0.4),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white
                          .withOpacity(_isPressed ? 0.1 : 0.03),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              Icon(
                widget.icon,
                color: _isPressed
                    ? widget.snakeColor
                    : Colors.white.withOpacity(0.45),
                size: 42,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════
// ⚡ BOOST CENTER BUTTON
// ═══════════════════════════════════════════════════
class _BoostButton extends StatefulWidget {
  final Color snakeColor;
  final bool isBoosting;
  final VoidCallback onStart;
  final VoidCallback onEnd;

  const _BoostButton({
    required this.snakeColor,
    required this.isBoosting,
    required this.onStart,
    required this.onEnd,
  });

  @override
  State<_BoostButton> createState() => _BoostButtonState();
}

class _BoostButtonState extends State<_BoostButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 80),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        setState(() => _isPressed = true);
        _controller.forward();
        widget.onStart();
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        _controller.reverse();
        widget.onEnd();
      },
      onTapCancel: () {
        setState(() => _isPressed = false);
        _controller.reverse();
        widget.onEnd();
      },
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          );
        },
        child: Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: widget.isBoosting
                ? const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFFD166), Color(0xFFF59E0B)],
            )
                : null,
            color: widget.isBoosting
                ? null
                : const Color(0xFF111631).withOpacity(0.85),
            border: Border.all(
              color: widget.isBoosting
                  ? const Color(0xFFFFD166).withOpacity(0.7)
                  : widget.snakeColor.withOpacity(0.15),
              width: 3,
            ),
            boxShadow: [
              if (widget.isBoosting)
                BoxShadow(
                  color: const Color(0xFFFFD166).withOpacity(0.4),
                  blurRadius: 30,
                  spreadRadius: 6,
                ),
              BoxShadow(
                color: Colors.black.withOpacity(0.45),
                blurRadius: 15,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 86,
                height: 86,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withOpacity(
                          widget.isBoosting ? 0.2 : 0.04),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.bolt_rounded,
                    color: widget.isBoosting
                        ? const Color(0xFF0A0E21)
                        : widget.snakeColor.withOpacity(0.5),
                    size: 38,
                  ),
                  Text(
                    widget.isBoosting ? 'FULL SPEED' : 'BOOST',
                    style: GoogleFonts.rajdhani(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: widget.isBoosting
                          ? const Color(0xFF0A0E21)
                          : Colors.white.withOpacity(0.3),
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════
// 🎨 GAME PAINTER — UNIFORM PIXEL SNAKE
// ═══════════════════════════════════════════════════
class _GamePainter extends CustomPainter {
  final GameState state;
  final Color snakeColor;
  final Color foodColor;
  final Color bgColor;
  final bool isBoosting;

  _GamePainter(
      this.state, this.snakeColor, this.foodColor, this.bgColor, this.isBoosting);

  @override
  void paint(Canvas canvas, Size size) {
    if (state.snake.isEmpty) return;

    final double cellW = size.width / AppConstants.gridCount;
    final double cellH = size.height / AppConstants.gridCount;

    _drawCheckerboard(canvas, size, cellW, cellH);
    _drawFood(canvas, cellW, cellH);
    _drawUniformSnake(canvas, size, cellW, cellH);
  }

  // ═══════════════════════════════════════════
  // ♟ CHECKERBOARD
  // ═══════════════════════════════════════════
  void _drawCheckerboard(Canvas canvas, Size size, double cellW, double cellH) {
    final darkCell = Paint()..color = bgColor;
    final lightCell = Paint()
      ..color = Color.lerp(bgColor, Colors.white, 0.04)!;

    for (int row = 0; row < AppConstants.gridCount; row++) {
      for (int col = 0; col < AppConstants.gridCount; col++) {
        final isLight = (row + col) % 2 == 0;
        canvas.drawRect(
          Rect.fromLTWH(col * cellW, row * cellH, cellW, cellH),
          isLight ? lightCell : darkCell,
        );
      }
    }
  }

  // ═══════════════════════════════════════════
  // 🍎 FOOD — pixel block
  // ═══════════════════════════════════════════
  void _drawFood(Canvas canvas, double cellW, double cellH) {
    final center = Offset(
      state.food.dx * cellW + cellW / 2,
      state.food.dy * cellH + cellH / 2,
    );
    final pixelSize = cellW * 0.78;

    // Outer glow
    canvas.drawCircle(
      center,
      cellW * 1.2,
      Paint()
        ..color = foodColor.withOpacity(0.12)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
    );

    // Mid glow
    canvas.drawCircle(
      center,
      cellW * 0.7,
      Paint()
        ..color = foodColor.withOpacity(0.2)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );

    final foodRect = Rect.fromCenter(
      center: center,
      width: pixelSize,
      height: pixelSize,
    );

    // Shadow
    canvas.drawRRect(
      RRect.fromRectAndRadius(foodRect.translate(1, 2), const Radius.circular(3)),
      Paint()
        ..color = Colors.black.withOpacity(0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );

    // Main block
    canvas.drawRRect(
      RRect.fromRectAndRadius(foodRect, const Radius.circular(3)),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(foodColor, Colors.white, 0.25)!,
            foodColor,
            Color.lerp(foodColor, Colors.black, 0.15)!,
          ],
        ).createShader(foodRect),
    );

    // Highlight pixels
    final hl = pixelSize * 0.28;
    canvas.drawRect(
      Rect.fromLTWH(center.dx - pixelSize * 0.24, center.dy - pixelSize * 0.24, hl, hl),
      Paint()..color = Colors.white.withOpacity(0.35),
    );
    canvas.drawRect(
      Rect.fromLTWH(center.dx + pixelSize * 0.04, center.dy + pixelSize * 0.04, hl * 0.6, hl * 0.6),
      Paint()..color = Colors.white.withOpacity(0.12),
    );
  }

  // ═══════════════════════════════════════════
  // 🐍 UNIFORM PIXEL SNAKE (same size head to tail)
  // ═══════════════════════════════════════════
  void _drawUniformSnake(Canvas canvas, Size size, double cellW, double cellH) {
    final snake = state.snake;
    if (snake.isEmpty) return;

    final pixelSize = cellW * 0.82;
    final cornerRadius = cellW * 0.14;

    // ── Speed shadows during boost ──
    if (isBoosting && snake.length > 2) {
      _drawSpeedShadows(canvas, snake, cellW, cellH, pixelSize, cornerRadius);
    }

    // ── Draw all segments uniformly (tail → head) ──
    for (int i = snake.length - 1; i >= 0; i--) {
      final seg = snake[i];
      final isHead = i == 0;

      final x = seg.dx * cellW + (cellW - pixelSize) / 2;
      final y = seg.dy * cellH + (cellH - pixelSize) / 2;
      final rect = Rect.fromLTWH(x, y, pixelSize, pixelSize);

      // ── Drop shadow ──
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          rect.translate(1, 2.5),
          Radius.circular(cornerRadius),
        ),
        Paint()
          ..color = Colors.black.withOpacity(0.35)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );

      // ── Head glow ──
      if (isHead) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect.inflate(4), Radius.circular(cornerRadius + 2)),
          Paint()
            ..color = snakeColor.withOpacity(isBoosting ? 0.28 : 0.14)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
        );
      }

      // ── Dark outline ──
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect.inflate(1.2), Radius.circular(cornerRadius + 0.5)),
        Paint()..color = Color.lerp(snakeColor, Colors.black, 0.4)!,
      );

      // ── Body fill (uniform gradient) ──
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(cornerRadius)),
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.lerp(snakeColor, Colors.white, 0.2)!,
              snakeColor,
              Color.lerp(snakeColor, Colors.black, 0.12)!,
            ],
          ).createShader(rect),
      );

      // ── Pixel cross-hair pattern (same on every segment) ──
      final innerPad = pixelSize * 0.22;
      final lineColor = Colors.white.withOpacity(0.07);

      canvas.drawLine(
        Offset(rect.center.dx, rect.top + innerPad),
        Offset(rect.center.dx, rect.bottom - innerPad),
        Paint()..color = lineColor..strokeWidth = 0.6,
      );
      canvas.drawLine(
        Offset(rect.left + innerPad, rect.center.dy),
        Offset(rect.right - innerPad, rect.center.dy),
        Paint()..color = lineColor..strokeWidth = 0.6,
      );

      // ── Top-left pixel highlight ──
      final hlSize = pixelSize * 0.17;
      canvas.drawRect(
        Rect.fromLTWH(rect.left + 3, rect.top + 3, hlSize, hlSize),
        Paint()..color = Colors.white.withOpacity(0.1),
      );

      // ── Bottom-right pixel detail ──
      canvas.drawRect(
        Rect.fromLTWH(
          rect.right - hlSize - 3,
          rect.bottom - hlSize - 3,
          hlSize * 0.7,
          hlSize * 0.7,
        ),
        Paint()..color = Colors.black.withOpacity(0.08),
      );

      // ── Eyes only on head ──
      if (isHead) {
        _drawPixelEyes(canvas, rect, cellW);
      }
    }
  }

  // ═══════════════════════════════════════════
  // 👀 PIXEL EYES (square style)
  // ═══════════════════════════════════════════
  void _drawPixelEyes(Canvas canvas, Rect headRect, double cellW) {
    final eyeSize = cellW * 0.16;
    final pupilSize = cellW * 0.08;
    final center = headRect.center;
    final eyeOff = cellW * 0.18;

    late Offset leftEye, rightEye, pupilDir;

    switch (state.direction) {
      case GameDirection.up:
        leftEye = Offset(center.dx - eyeOff, center.dy - eyeOff * 0.3);
        rightEye = Offset(center.dx + eyeOff, center.dy - eyeOff * 0.3);
        pupilDir = const Offset(0, -1);
        break;
      case GameDirection.down:
        leftEye = Offset(center.dx - eyeOff, center.dy + eyeOff * 0.3);
        rightEye = Offset(center.dx + eyeOff, center.dy + eyeOff * 0.3);
        pupilDir = const Offset(0, 1);
        break;
      case GameDirection.left:
        leftEye = Offset(center.dx - eyeOff * 0.3, center.dy - eyeOff);
        rightEye = Offset(center.dx - eyeOff * 0.3, center.dy + eyeOff);
        pupilDir = const Offset(-1, 0);
        break;
      case GameDirection.right:
        leftEye = Offset(center.dx + eyeOff * 0.3, center.dy - eyeOff);
        rightEye = Offset(center.dx + eyeOff * 0.3, center.dy + eyeOff);
        pupilDir = const Offset(1, 0);
        break;
    }

    for (final eye in [leftEye, rightEye]) {
      // Socket shadow
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: eye, width: eyeSize + 3, height: eyeSize + 3),
          const Radius.circular(2),
        ),
        Paint()
          ..color = Color.lerp(snakeColor, Colors.black, 0.5)!.withOpacity(0.4)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
      );

      // White square
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: eye, width: eyeSize, height: eyeSize),
          const Radius.circular(2),
        ),
        Paint()..color = Colors.white,
      );

      // Pupil square
      final shift = pupilSize * 0.35;
      final pc = Offset(
        eye.dx + pupilDir.dx * shift,
        eye.dy + pupilDir.dy * shift,
      );
      canvas.drawRect(
        Rect.fromCenter(center: pc, width: pupilSize, height: pupilSize),
        Paint()..color = const Color(0xFF111111),
      );

      // Tiny shine
      canvas.drawRect(
        Rect.fromLTWH(
          pc.dx - pupilSize * 0.35,
          pc.dy - pupilSize * 0.35,
          pupilSize * 0.35,
          pupilSize * 0.35,
        ),
        Paint()..color = Colors.white.withOpacity(0.7),
      );
    }
  }

  // ═══════════════════════════════════════════
  // 💨 SPEED SHADOW TRAILS
  // ═══════════════════════════════════════════
  void _drawSpeedShadows(Canvas canvas, List<Offset> snake, double cellW,
      double cellH, double pixelSize, double cornerRadius) {
    late Offset dirOffset;
    switch (state.direction) {
      case GameDirection.up:
        dirOffset = const Offset(0, 1);
        break;
      case GameDirection.down:
        dirOffset = const Offset(0, -1);
        break;
      case GameDirection.left:
        dirOffset = const Offset(1, 0);
        break;
      case GameDirection.right:
        dirOffset = const Offset(-1, 0);
        break;
    }

    // Ghost copies behind head
    for (int ghost = 1; ghost <= 3; ghost++) {
      final hp = snake.first;
      final gx = (hp.dx + dirOffset.dx * ghost) * cellW + (cellW - pixelSize) / 2;
      final gy = (hp.dy + dirOffset.dy * ghost) * cellH + (cellH - pixelSize) / 2;
      final gr = Rect.fromLTWH(gx, gy, pixelSize, pixelSize);
      final op = (0.18 - ghost * 0.05).clamp(0.02, 0.18);

      canvas.drawRRect(
        RRect.fromRectAndRadius(gr, Radius.circular(cornerRadius)),
        Paint()
          ..color = snakeColor.withOpacity(op)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 2.0 + ghost * 2),
      );
    }

    // Motion streaks
    final hc = Offset(
      snake.first.dx * cellW + cellW / 2,
      snake.first.dy * cellH + cellH / 2,
    );

    for (int line = 0; line < 4; line++) {
      final perp = (line - 1.5) * cellW * 0.2;
      late Offset ls, le;

      if (dirOffset.dx != 0) {
        ls = Offset(
          hc.dx + dirOffset.dx * cellW * (1.5 + line * 0.5),
          hc.dy + perp,
        );
        le = Offset(ls.dx + dirOffset.dx * cellW * 0.6, ls.dy);
      } else {
        ls = Offset(
          hc.dx + perp,
          hc.dy + dirOffset.dy * cellW * (1.5 + line * 0.5),
        );
        le = Offset(ls.dx, ls.dy + dirOffset.dy * cellW * 0.6);
      }

      canvas.drawLine(
        ls,
        le,
        Paint()
          ..color = snakeColor.withOpacity((0.2 - line * 0.04).clamp(0.02, 0.2))
          ..strokeWidth = 1.5
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _GamePainter oldDelegate) =>
      oldDelegate.state != state ||
          oldDelegate.snakeColor != snakeColor ||
          oldDelegate.foodColor != foodColor ||
          oldDelegate.bgColor != bgColor ||
          oldDelegate.isBoosting != isBoosting;
}

// ═══════════════════════════════════════════
// 🚨 DANGER BORDER PAINTER
// ═══════════════════════════════════════════
class _DangerBorderPainter extends CustomPainter {
  final double dangerPulse;
  final Color snakeColor;

  _DangerBorderPainter({required this.dangerPulse, required this.snakeColor});

  @override
  void paint(Canvas canvas, Size size) {
    final borderRadius = 2.0;
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(borderRadius));

    // ── Layer 1: Outer danger glow ──
    final outerGlow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..color = const Color(0xFFFF4D6D).withOpacity(0.06 * dangerPulse)
      ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 8);
    canvas.drawRRect(rrect, outerGlow);

    // ── Layer 2: Main danger border ──
    final dangerBorder = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          const Color(0xFFFF4D6D).withOpacity(0.35 * dangerPulse),
          const Color(0xFFFF6B6B).withOpacity(0.15),
          const Color(0xFFFF4D6D).withOpacity(0.35 * dangerPulse),
          const Color(0xFFFF6B6B).withOpacity(0.15),
          const Color(0xFFFF4D6D).withOpacity(0.35 * dangerPulse),
        ],
        stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
      ).createShader(rect);
    canvas.drawRRect(rrect, dangerBorder);

    // ── Layer 3: Inner warning line ──
    final innerRect = Rect.fromLTRB(
      rect.left + 4, rect.top + 4, rect.right - 4, rect.bottom - 4,
    );
    final innerRRect = RRect.fromRectAndRadius(
      innerRect, Radius.circular(borderRadius),
    );
    final innerBorder = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..color = const Color(0xFFFF4D6D).withOpacity(0.08);
    canvas.drawRRect(innerRRect, innerBorder);

    // ── Layer 4: Danger hash marks on each edge ──
    _drawHashMarks(canvas, size, dangerPulse);
  }

  void _drawHashMarks(Canvas canvas, Size size, double pulse) {
    final paint = Paint()
      ..color = const Color(0xFFFF4D6D).withOpacity(0.12 * pulse)
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;

    const spacing = 18.0;
    const markLen = 6.0;

    // Top edge
    for (double x = spacing; x < size.width - spacing; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, markLen), paint);
    }
    // Bottom edge
    for (double x = spacing; x < size.width - spacing; x += spacing) {
      canvas.drawLine(
          Offset(x, size.height), Offset(x, size.height - markLen), paint);
    }
    // Left edge
    for (double y = spacing; y < size.height - spacing; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(markLen, y), paint);
    }
    // Right edge
    for (double y = spacing; y < size.height - spacing; y += spacing) {
      canvas.drawLine(
          Offset(size.width, y), Offset(size.width - markLen, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _DangerBorderPainter oldDelegate) =>
      oldDelegate.dangerPulse != dangerPulse;
}

// ═══════════════════════════════════════════
// ⚠ CORNER WARNING PAINTER
// ═══════════════════════════════════════════
class _CornerWarningPainter extends CustomPainter {
  final Color color;
  _CornerWarningPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // L-shape warning bracket
    canvas.drawLine(
      Offset(0, size.height),
      const Offset(0, 0),
      paint,
    );
    canvas.drawLine(
      const Offset(0, 0),
      Offset(size.width, 0),
      paint,
    );

    // Small danger dot
    canvas.drawCircle(
      const Offset(0, 0),
      1.5,
      Paint()
        ..color = color
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ═══════════════════════════════════════════
// ⬡ HEX GRID PAINTER
// ═══════════════════════════════════════════
class _HexGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.009)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    const hexSize = 40.0;
    final w = hexSize * 1.732;
    final h = hexSize * 2;

    for (double row = -1; row * h * 0.75 < size.height + h; row++) {
      for (double col = -1; col * w < size.width + w; col++) {
        final offset = (row % 2 == 0) ? 0.0 : w / 2;
        _drawHex(
            canvas, Offset(col * w + offset, row * h * 0.75), hexSize, paint);
      }
    }
  }

  void _drawHex(Canvas canvas, Offset center, double size, Paint paint) {
    final path = Path();
    for (int i = 0; i < 6; i++) {
      final angle = (pi / 180) * (60 * i - 30);
      final x = center.dx + size * cos(angle);
      final y = center.dy + size * sin(angle);
      i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ═══════════════════════════════════════════
// ▤ SCAN LINE PAINTER
// ═══════════════════════════════════════════
class _ScanLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.03)
      ..strokeWidth = 1;
    for (double y = 0; y < size.height; y += 3) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ═══════════════════════════════════════════
// 🔲 HUD CORNER PAINTER
// ═══════════════════════════════════════════
class _HudCornerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF00FF88).withOpacity(0.06)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const len = 22.0;
    const pad = 14.0;

    canvas.drawLine(Offset(pad, pad + len), Offset(pad, pad), paint);
    canvas.drawLine(Offset(pad, pad), Offset(pad + len, pad), paint);
    canvas.drawLine(Offset(size.width - pad, pad + len),
        Offset(size.width - pad, pad), paint);
    canvas.drawLine(Offset(size.width - pad, pad),
        Offset(size.width - pad - len, pad), paint);
    canvas.drawLine(Offset(pad, size.height - pad - len),
        Offset(pad, size.height - pad), paint);
    canvas.drawLine(Offset(pad, size.height - pad),
        Offset(pad + len, size.height - pad), paint);
    canvas.drawLine(Offset(size.width - pad, size.height - pad - len),
        Offset(size.width - pad, size.height - pad), paint);
    canvas.drawLine(Offset(size.width - pad, size.height - pad),
        Offset(size.width - pad - len, size.height - pad), paint);

    final dotPaint = Paint()
      ..color = const Color(0xFF00FF88).withOpacity(0.12)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(pad, pad), 2, dotPaint);
    canvas.drawCircle(Offset(size.width - pad, pad), 2, dotPaint);
    canvas.drawCircle(Offset(pad, size.height - pad), 2, dotPaint);
    canvas.drawCircle(
        Offset(size.width - pad, size.height - pad), 2, dotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ═══════════════════════════════════════════
// ⌐ DIALOG CORNER PAINTER
// ═══════════════════════════════════════════
class _DialogCornerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF00FF88).withOpacity(0.1)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const len = 16.0;
    const pad = 12.0;

    canvas.drawLine(Offset(pad, pad + len), Offset(pad, pad), paint);
    canvas.drawLine(Offset(pad, pad), Offset(pad + len, pad), paint);
    canvas.drawLine(Offset(size.width - pad, pad + len),
        Offset(size.width - pad, pad), paint);
    canvas.drawLine(Offset(size.width - pad, pad),
        Offset(size.width - pad - len, pad), paint);
    canvas.drawLine(Offset(pad, size.height - pad - len),
        Offset(pad, size.height - pad), paint);
    canvas.drawLine(Offset(pad, size.height - pad),
        Offset(pad + len, size.height - pad), paint);
    canvas.drawLine(Offset(size.width - pad, size.height - pad - len),
        Offset(size.width - pad, size.height - pad), paint);
    canvas.drawLine(Offset(size.width - pad, size.height - pad),
        Offset(size.width - pad - len, size.height - pad), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}