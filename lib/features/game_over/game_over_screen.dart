import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:snakex/features/game/game_provider.dart';
import '../../providers/app_providers.dart';
import '../../shared/themes/app_theme.dart';
import '../game/game_screen.dart';
import 'dart:math';

class GameOverScreen extends ConsumerStatefulWidget {
  final int score;
  final int highScore;

  const GameOverScreen({
    super.key,
    required this.score,
    required this.highScore,
  });

  @override
  ConsumerState<GameOverScreen> createState() => _GameOverScreenState();
}

class _GameOverScreenState extends ConsumerState<GameOverScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _countController;
  late Animation<int> _countAnimation;
  late AnimationController _rotateController;
  bool _isNewHighScore = false;

  // Store the final score and high score at time of game over
  int _finalScore = 0;
  int _highScore = 0;

  @override
  void initState() {
    super.initState();

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2200),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _rotateController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();

    _countController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    // Use passed scores
    _finalScore = widget.score;
    _highScore = widget.highScore;
    _isNewHighScore = _finalScore > 0 && _finalScore >= _highScore;

    // Build count animation with actual score
    _countAnimation = IntTween(begin: 0, end: _finalScore).animate(
      CurvedAnimation(parent: _countController, curve: Curves.easeOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _countController.forward();
    });
  }

  // Remove the old captureScores logic as it's no longer needed
  // ignore: unused_element
  void _captureScores() {
    // Logic moved to initState
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _countController.dispose();
    _rotateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final adManager = ref.read(adManagerProvider);
    final audio = ref.read(audioServiceProvider);
    final size = MediaQuery.of(context).size;

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
              Color(0xFF1A0A0F),
              Color(0xFF0A0E1A),
            ],
            stops: [0.0, 0.35, 0.65, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Layer 1: Hex grid
            _buildHexGrid(),

            // Layer 2: Vignette
            _buildVignette(),

            // Layer 3: Scan lines
            _buildScanLines(),

            // Layer 4: HUD corners
            _buildHudCorners(),

            // Layer 5: Glow orbs
            ..._buildGlowOrbs(size),

            // Layer 6: Dead snake particles
            ..._buildDeadParticles(size),

            // Layer 7: Rotating ring (behind skull)
            _buildRotatingRing(size),

            // Layer 8: Main content
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 30),

                      // ── GAME OVER ICON ──
                      _buildGameOverIcon(),

                      const SizedBox(height: 28),

                      // ── GAME OVER TITLE ──
                      _buildGameOverTitle(),

                      const SizedBox(height: 6),

                      // ── DEATH MESSAGE ──
                      _buildDeathMessage(_finalScore),

                      const SizedBox(height: 32),

                      // ── SCORE CARD ──
                      _buildScoreCard(_finalScore, _highScore),

                      const SizedBox(height: 14),

                      // ── NEW HIGH SCORE ──
                      if (_isNewHighScore) _buildNewHighScoreBadge(),

                      const SizedBox(height: 32),

                      // ── ACTION BUTTONS ──
                      _buildActionButtons(context, ref, audio, adManager),

                      const SizedBox(height: 20),

                      // ── BOTTOM DECO ──
                      _buildBottomDeco(),

                      const SizedBox(height: 20),
                    ],
                  ),
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
  // 🌑 VIGNETTE
  // ═══════════════════════════════════════════
  Widget _buildVignette() {
    return Positioned.fill(
      child: IgnorePointer(
        child: Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 0.85,
              colors: [
                Colors.transparent,
                Colors.black.withOpacity(0.5),
              ],
            ),
          ),
        ),
      ),
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
  // 🔲 HUD CORNERS
  // ═══════════════════════════════════════════
  Widget _buildHudCorners() {
    return Positioned.fill(
      child: IgnorePointer(
        child: CustomPaint(painter: _HudCornerPainter())
            .animate()
            .fadeIn(delay: 300.ms, duration: 700.ms),
      ),
    );
  }

  // ═══════════════════════════════════════════
  // 🔴 GLOW ORBS (red/danger tinted)
  // ═══════════════════════════════════════════
  List<Widget> _buildGlowOrbs(Size size) {
    return [
      // Top center — red glow
      Positioned(
        top: -100,
        left: size.width / 2 - 140,
        child: Container(
          width: 280,
          height: 280,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                const Color(0xFFFF4D6D).withOpacity(0.07),
                const Color(0xFFFF4D6D).withOpacity(0.02),
                Colors.transparent,
              ],
            ),
          ),
        )
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .scale(
          begin: const Offset(0.85, 0.85),
          end: const Offset(1.18, 1.18),
          duration: 3500.ms,
        ),
      ),

      // Bottom left — blue glow
      Positioned(
        bottom: -80,
        left: -60,
        child: Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                const Color(0xFF4F6EF7).withOpacity(0.04),
                Colors.transparent,
              ],
            ),
          ),
        ).animate().fadeIn(delay: 400.ms, duration: 1000.ms),
      ),

      // Right — purple glow
      Positioned(
        top: size.height * 0.45,
        right: -50,
        child: Container(
          width: 160,
          height: 160,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                const Color(0xFFA78BFA).withOpacity(0.04),
                Colors.transparent,
              ],
            ),
          ),
        ).animate().fadeIn(delay: 600.ms, duration: 1000.ms),
      ),
    ];
  }

  // ═══════════════════════════════════════════
  // 💀 DEAD SNAKE PARTICLES
  // ═══════════════════════════════════════════
  List<Widget> _buildDeadParticles(Size size) {
    final rng = Random(77);
    final colors = [
      const Color(0xFFFF4D6D),
      const Color(0xFFFF6B6B),
      const Color(0xFFA78BFA),
      const Color(0xFF4F6EF7),
    ];

    return List.generate(14, (i) {
      final x = rng.nextDouble() * size.width;
      final startY = size.height * (0.2 + rng.nextDouble() * 0.7);
      final s = 2.0 + rng.nextDouble() * 4;
      final c = colors[i % colors.length];
      final dur = 2000 + rng.nextInt(2000);

      return Positioned(
        left: x,
        top: startY,
        child: Transform.rotate(
          angle: rng.nextDouble() * pi * 2,
          child: Container(
            width: s,
            height: s,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(1),
              color: c.withOpacity(0.4),
              boxShadow: [
                BoxShadow(color: c.withOpacity(0.25), blurRadius: 5),
              ],
            ),
          ),
        )
            .animate(
          delay: Duration(milliseconds: i * 150),
          onPlay: (ctrl) => ctrl.repeat(),
        )
            .moveY(
          begin: 0,
          end: 60 + rng.nextDouble() * 80,
          duration: Duration(milliseconds: dur),
          curve: Curves.easeIn,
        )
            .fadeOut(
          delay: Duration(milliseconds: (dur * 0.6).toInt()),
          duration: Duration(milliseconds: (dur * 0.4).toInt()),
        )
            .scaleXY(begin: 1.0, end: 0.0, duration: Duration(milliseconds: dur)),
      );
    });
  }

  // ═══════════════════════════════════════════
  // 🔄 ROTATING RING
  // ═══════════════════════════════════════════
  Widget _buildRotatingRing(Size size) {
    return Positioned(
      top: size.height * 0.06,
      left: 0,
      right: 0,
      child: Center(
        child: AnimatedBuilder(
          animation: _rotateController,
          builder: (context, child) {
            return Transform.rotate(
              angle: _rotateController.value * 2 * pi,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFFF4D6D).withOpacity(0.05),
                    width: 1,
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: 0,
                      left: 80 - 4,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFFFF4D6D).withOpacity(0.4),
                          boxShadow: [
                            BoxShadow(
                              color:
                              const Color(0xFFFF4D6D).withOpacity(0.25),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      left: 80 - 3,
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color:
                          const Color(0xFF4F6EF7).withOpacity(0.3),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════
  // 💀 GAME OVER ICON
  // ═══════════════════════════════════════════
  Widget _buildGameOverIcon() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return SizedBox(
          width: 130,
          height: 130,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer glow ring
              Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Color.lerp(
                      const Color(0xFFFF4D6D).withOpacity(0.0),
                      const Color(0xFFFF4D6D).withOpacity(0.15),
                      _pulseAnimation.value,
                    )!,
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF4D6D)
                          .withOpacity(0.06 * _pulseAnimation.value),
                      blurRadius: 45,
                      spreadRadius: 12,
                    ),
                  ],
                ),
              ),

              // Inner circle
              Container(
                width: 95,
                height: 95,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF111631),
                  border: Border.all(
                    color: Color.lerp(
                      const Color(0xFFFF4D6D).withOpacity(0.15),
                      const Color(0xFFFF4D6D).withOpacity(0.5),
                      _pulseAnimation.value,
                    )!,
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF4D6D)
                          .withOpacity(0.1 * _pulseAnimation.value),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                    BoxShadow(
                      color: Colors.black.withOpacity(0.5),
                      blurRadius: 25,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const Text('💀', style: TextStyle(fontSize: 38)),
                    Positioned(
                      bottom: 10,
                      right: 10,
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFFFF4D6D),
                          boxShadow: [
                            BoxShadow(
                              color:
                              const Color(0xFFFF4D6D).withOpacity(0.5),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          color: Colors.white,
                          size: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Corner brackets
              Positioned(
                top: 8,
                left: 8,
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CustomPaint(
                    painter: _BracketPainter(
                      color: const Color(0xFFFF4D6D).withOpacity(0.25),
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 8,
                right: 8,
                child: Transform.rotate(
                  angle: pi,
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CustomPaint(
                      painter: _BracketPainter(
                        color: const Color(0xFF4F6EF7).withOpacity(0.2),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    )
        .animate()
        .fadeIn(duration: 700.ms)
        .scale(
      begin: const Offset(0.2, 0.2),
      end: const Offset(1.0, 1.0),
      curve: Curves.elasticOut,
      duration: 1100.ms,
    )
        .shake(
      delay: 700.ms,
      duration: 500.ms,
      hz: 4,
      offset: const Offset(5, 0),
    );
  }

  // ═══════════════════════════════════════════
  // 🏷️ GAME OVER TITLE
  // ═══════════════════════════════════════════
  Widget _buildGameOverTitle() {
    return Column(
      children: [
        // Accent line above
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 36,
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    const Color(0xFFFF4D6D).withOpacity(0.4),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                color: const Color(0xFFFF4D6D).withOpacity(0.5),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 10),
            Container(
              width: 36,
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFFF4D6D).withOpacity(0.4),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ],
        )
            .animate()
            .fadeIn(delay: 350.ms, duration: 500.ms)
            .scaleX(begin: 0, end: 1, curve: Curves.easeOut),

        const SizedBox(height: 14),

        // Title
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [
              Color(0xFFFFFFFF),
              Color(0xFFFFCCCC),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ).createShader(bounds),
          child: Text(
            'GAME OVER',
            style: GoogleFonts.rajdhani(
              fontSize: 42,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 8,
              height: 1,
              shadows: [
                Shadow(
                  color: const Color(0xFFFF4D6D).withOpacity(0.5),
                  blurRadius: 22,
                ),
              ],
            ),
          ),
        )
            .animate()
            .fadeIn(delay: 300.ms, duration: 600.ms)
            .slideY(begin: 0.25, end: 0, curve: Curves.easeOut),
      ],
    );
  }

  // ═══════════════════════════════════════════
  // 💬 DEATH MESSAGE
  // ═══════════════════════════════════════════
  Widget _buildDeathMessage(int score) {
    String message;
    if (score == 0) {
      message = 'Better luck next time!';
    } else if (score < 50) {
      message = 'Keep practicing, you\'ll improve!';
    } else if (score < 150) {
      message = 'Not bad! Try to beat your record.';
    } else if (score < 300) {
      message = 'Great run! You\'re getting better!';
    } else if (score < 500) {
      message = 'Amazing performance! 🔥';
    } else {
      message = 'Legendary snake master! 🐍👑';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(
            color: const Color(0xFFFF4D6D).withOpacity(0.25),
            width: 2,
          ),
          right: BorderSide(
            color: const Color(0xFFFF4D6D).withOpacity(0.25),
            width: 2,
          ),
        ),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: GoogleFonts.rajdhani(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: Colors.white.withOpacity(0.38),
          letterSpacing: 1,
        ),
      ),
    ).animate().fadeIn(delay: 550.ms, duration: 500.ms);
  }

  // ═══════════════════════════════════════════
  // 📊 SCORE CARD
  // ═══════════════════════════════════════════
  Widget _buildScoreCard(int score, int highScore) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFF111631).withOpacity(0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.055),
          width: 1,
        ),
      ),
      child: Stack(
        children: [
          // Left accent
          Positioned(
            left: 0,
            top: 12,
            bottom: 12,
            child: Container(
              width: 2,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF00FF88).withOpacity(0.4),
                    const Color(0xFFFFD166).withOpacity(0.3),
                  ],
                ),
              ),
            ),
          ),

          // Top-right bracket
          Positioned(
            top: 0,
            right: 0,
            child: SizedBox(
              width: 18,
              height: 18,
              child: CustomPaint(
                painter: _CardBracketPainter(
                  color: Colors.white.withOpacity(0.08),
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Column(
              children: [
                // Final Score
                _buildScoreRow(
                  label: 'FINAL SCORE',
                  icon: Icons.sports_score_rounded,
                  iconColor: const Color(0xFF00FF88),
                  isAnimated: true,
                  score: score,
                ),

                const SizedBox(height: 14),

                // Divider
                Container(
                  width: double.infinity,
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        Colors.white.withOpacity(0.06),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // Best Score
                _buildScoreRow(
                  label: 'BEST RECORD',
                  icon: Icons.emoji_events_rounded,
                  iconColor: const Color(0xFFFFD166),
                  isAnimated: false,
                  score: highScore,
                ),
              ],
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: 650.ms, duration: 600.ms)
        .slideY(begin: 0.15, end: 0, curve: Curves.easeOut);
  }

  Widget _buildScoreRow({
    required String label,
    required IconData icon,
    required Color iconColor,
    required bool isAnimated,
    required int score,
  }) {
    return Row(
      children: [
        // Icon badge
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(13),
            color: iconColor.withOpacity(0.1),
            border: Border.all(
              color: iconColor.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Icon(icon, color: iconColor, size: 22),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.rajdhani(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Colors.white.withOpacity(0.3),
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 2),
              isAnimated
                  ? AnimatedBuilder(
                animation: _countAnimation,
                builder: (context, child) {
                  return Text(
                    '${_countAnimation.value}',
                    style: GoogleFonts.orbitron(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: iconColor,
                      letterSpacing: 1,
                    ),
                  );
                },
              )
                  : Text(
                '$score',
                style: GoogleFonts.orbitron(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: iconColor.withOpacity(0.75),
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
        // Rank badge for final score
        if (isAnimated)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: iconColor.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Text(
              _getRankLabel(score),
              style: GoogleFonts.rajdhani(
                fontSize: 9,
                fontWeight: FontWeight.w800,
                color: iconColor.withOpacity(0.7),
                letterSpacing: 1,
              ),
            ),
          ),
      ],
    );
  }

  String _getRankLabel(int score) {
    if (score >= 500) return 'LEGEND';
    if (score >= 300) return 'MASTER';
    if (score >= 150) return 'ELITE';
    if (score >= 50) return 'SKILLED';
    if (score > 0) return 'ROOKIE';
    return 'NEW';
  }

  // ═══════════════════════════════════════════
  // 🏆 NEW HIGH SCORE BADGE
  // ═══════════════════════════════════════════
  Widget _buildNewHighScoreBadge() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFFFD166).withOpacity(0.12),
            const Color(0xFFFF8C42).withOpacity(0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFFFD166).withOpacity(0.22),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🎉', style: TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          Text(
            'NEW HIGH SCORE!',
            style: GoogleFonts.rajdhani(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: const Color(0xFFFFD166),
              letterSpacing: 3,
            ),
          ),
          const SizedBox(width: 10),
          const Text('🎉', style: TextStyle(fontSize: 20)),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: 1300.ms, duration: 500.ms)
        .shimmer(
      delay: 1600.ms,
      duration: 1500.ms,
      color: const Color(0xFFFFD166).withOpacity(0.3),
    )
        .then()
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .scale(
      begin: const Offset(1.0, 1.0),
      end: const Offset(1.03, 1.03),
      duration: 1200.ms,
    );
  }

  // ═══════════════════════════════════════════
  // 🎮 ACTION BUTTONS
  // ═══════════════════════════════════════════
  Widget _buildActionButtons(
      BuildContext context,
      WidgetRef ref,
      dynamic audio,
      dynamic adManager,
      ) {
    final gameState = ref.watch(gameProvider);

    return Column(
      children: [
        // ── REVIVE BUTTON (If available) ──
        if (!gameState.isRevived) ...[
          _buildReviveButton(
            context,
            ref,
            audio,
            adManager,
          ),
          const SizedBox(height: 14),
        ],

        // ── PLAY AGAIN — Primary CTA ──
        _buildPlayAgainButton(
          onTap: () {
            audio.playClick();
            ref.read(gameProvider.notifier).startGame();
            if (kIsWeb) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const GameScreen()),
              );
            } else {
              adManager.showInterstitial(() {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const GameScreen()),
                );
              });
            }
          },
        ),

        const SizedBox(height: 14),

        // ── SECONDARY ROW ──
        Row(
          children: [
            Expanded(
              child: _buildSecondaryBtn(
                icon: Icons.home_rounded,
                label: 'MENU',
                color: const Color(0xFF4F6EF7),
                delay: 950,
                onTap: () {
                  audio.playClick();
                  Navigator.of(context)
                      .popUntil((route) => route.isFirst);
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSecondaryBtn(
                icon: Icons.share_rounded,
                label: 'SHARE',
                color: Colors.white.withOpacity(0.35),
                delay: 1050,
                onTap: () {
                  audio.playClick();
                  final message = _isNewHighScore
                      ? 'I just set a NEW HIGH SCORE of $_finalScore in Snake X! 🐍🔥 Can you beat me?'
                      : 'I just scored $_finalScore in Snake X! 🐍 Check out this awesome game!';
                  Share.share(message);
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPlayAgainButton({required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 19),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF00FF88),
              Color(0xFF00E07A),
              Color(0xFF00CC6E),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00FF88).withOpacity(0.32),
              blurRadius: 22,
              offset: const Offset(0, 7),
            ),
            BoxShadow(
              color: const Color(0xFF00FF88).withOpacity(0.1),
              blurRadius: 45,
              spreadRadius: 6,
            ),
          ],
        ),
        child: Stack(
          children: [
            // Shine overlay
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withOpacity(0.14),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.5],
                    ),
                  ),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A0E21).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: const Icon(
                    Icons.replay_rounded,
                    color: Color(0xFF0A0E21),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'PLAY AGAIN',
                  style: GoogleFonts.rajdhani(
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF0A0E21),
                    letterSpacing: 3,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(delay: 850.ms, duration: 500.ms)
        .slideY(begin: 0.3, end: 0, curve: Curves.easeOut)
        .then(delay: 200.ms)
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .scale(
      begin: const Offset(1.0, 1.0),
      end: const Offset(1.02, 1.02),
      duration: 2200.ms,
    );
  }

  Widget _buildReviveButton(
      BuildContext context,
      WidgetRef ref,
      dynamic audio,
      dynamic adManager,
      ) {
    return GestureDetector(
      onTap: () {
        audio.playClick();
        adManager.showRewardedAd(
              () {
            // On Reward Earned
            ref.read(gameProvider.notifier).revive();
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const GameScreen()),
            );
          },
              () {
            // On Ad Closed/Failed
            // Do nothing, user stays on game over screen
          },
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: const Color(0xFF111631),
          border: Border.all(
            color: const Color(0xFFFFD166).withOpacity(0.4),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFFD166).withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD166).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.bolt_rounded,
                    color: Color(0xFFFFD166),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'REVIVE (WATCH AD)',
                  style: GoogleFonts.rajdhani(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFFFFD166),
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(delay: 750.ms, duration: 500.ms)
        .slideY(begin: 0.3, end: 0, curve: Curves.easeOut);
  }

  Widget _buildSecondaryBtn({
    required IconData icon,
    required String label,
    required Color color,
    required int delay,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withOpacity(0.18),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color.withOpacity(0.75), size: 22),
            const SizedBox(height: 5),
            Text(
              label,
              style: GoogleFonts.rajdhani(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: color.withOpacity(0.75),
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(
      delay: Duration(milliseconds: delay),
      duration: 500.ms,
    )
        .slideY(begin: 0.3, end: 0, curve: Curves.easeOut);
  }

  // ═══════════════════════════════════════════
  // 🏢 BOTTOM DECO
  // ═══════════════════════════════════════════
  Widget _buildBottomDeco() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 10,
          height: 10,
          child: CustomPaint(
            painter: _CornerDecoPainter(
              color: Colors.white.withOpacity(0.08),
            ),
          ),
        ),
        const SizedBox(width: 6),
        Container(
          width: 50,
          height: 1,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.transparent,
                Colors.white.withOpacity(0.06),
                Colors.transparent,
              ],
            ),
          ),
        ),
        const SizedBox(width: 6),
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            border: Border.all(
              color: const Color(0xFFFF4D6D).withOpacity(0.2),
              width: 1,
            ),
            borderRadius: BorderRadius.circular(2),
          ),
          child: Center(
            child: Container(
              width: 2,
              height: 2,
              decoration: BoxDecoration(
                color: const Color(0xFFFF4D6D).withOpacity(0.3),
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ),
        ),
        const SizedBox(width: 6),
        Container(
          width: 50,
          height: 1,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.transparent,
                Colors.white.withOpacity(0.06),
                Colors.transparent,
              ],
            ),
          ),
        ),
        const SizedBox(width: 6),
        Transform.flip(
          flipX: true,
          child: SizedBox(
            width: 10,
            height: 10,
            child: CustomPaint(
              painter: _CornerDecoPainter(
                color: Colors.white.withOpacity(0.08),
              ),
            ),
          ),
        ),
      ],
    ).animate().fadeIn(delay: 1400.ms, duration: 500.ms);
  }
}

// ═══════════════════════════════════════════
// ⬡ HEX GRID PAINTER
// ═══════════════════════════════════════════
class _HexGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.011)
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

    final dotPaint = Paint()
      ..color = Colors.white.withOpacity(0.018)
      ..style = PaintingStyle.fill;

    for (double row = -1; row * h * 0.75 < size.height + h; row++) {
      for (double col = -1; col * w < size.width + w; col++) {
        final offset = (row % 2 == 0) ? 0.0 : w / 2;
        canvas.drawCircle(
            Offset(col * w + offset, row * h * 0.75), 1.0, dotPaint);
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
      ..color = Colors.black.withOpacity(0.035)
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
      ..color = const Color(0xFFFF4D6D).withOpacity(0.07)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const len = 26.0;
    const pad = 18.0;

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
      ..color = const Color(0xFFFF4D6D).withOpacity(0.14)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(pad, pad), 2.5, dotPaint);
    canvas.drawCircle(Offset(size.width - pad, pad), 2.5, dotPaint);
    canvas.drawCircle(Offset(pad, size.height - pad), 2.5, dotPaint);
    canvas.drawCircle(
        Offset(size.width - pad, size.height - pad), 2.5, dotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ═══════════════════════════════════════════
// ⌐ BRACKET PAINTER
// ═══════════════════════════════════════════
class _BracketPainter extends CustomPainter {
  final Color color;
  _BracketPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path()
      ..moveTo(0, size.height * 0.45)
      ..lineTo(0, 0)
      ..lineTo(size.width * 0.45, 0);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ═══════════════════════════════════════════
// ⌐ CARD BRACKET PAINTER
// ═══════════════════════════════════════════
class _CardBracketPainter extends CustomPainter {
  final Color color;
  _CardBracketPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ═══════════════════════════════════════════
// ◣ CORNER DECO PAINTER
// ═══════════════════════════════════════════
class _CornerDecoPainter extends CustomPainter {
  final Color color;
  _CornerDecoPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
        Offset(0, size.height), Offset(size.width, 0), paint);
    canvas.drawLine(
        Offset(0, size.height), Offset(0, size.height * 0.45), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}