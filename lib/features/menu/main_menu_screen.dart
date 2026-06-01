// main_menu_screen.dart
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../shared/themes/app_theme.dart';
import '../../providers/app_providers.dart';
import '../game/game_screen.dart';
import '../settings/settings_screen.dart';
import 'dart:math';

class MainMenuScreen extends ConsumerStatefulWidget {
  const MainMenuScreen({super.key});

  @override
  ConsumerState<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends ConsumerState<MainMenuScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _snakeController;
  late AnimationController _rotateController;
  late AnimationController _waveController;

  int _hoveredButton = -1;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _snakeController = AnimationController(
      duration: const Duration(seconds: 6),
      vsync: this,
    )..repeat();

    _rotateController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();

    _waveController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    // Preload ads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(adManagerProvider).preloadRewarded();
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _snakeController.dispose();
    _rotateController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final adManager = ref.read(adManagerProvider);
    final audio = ref.read(audioServiceProvider);
    final storage = ref.read(storageServiceProvider);
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
              Color(0xFF161B2E),
              Color(0xFF0A0E1A),
            ],
            stops: [0.0, 0.35, 0.65, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Layer 1: Hex grid pattern
            _buildHexGrid(size),

            // Layer 2: Rotating ring behind logo
            _buildRotatingRing(size),

            // Layer 3: Diagonal accent lines
            _buildDiagonalLines(size),

            // Layer 4: Floating ember particles
            ..._buildEmberParticles(size),

            // Layer 5: Edge vignette
            _buildVignette(size),

            // Layer 6: Scan line effect
            _buildScanLines(size),

            // Layer 7: Main content
            SafeArea(
              child: Column(
                children: [
                  const Spacer(flex: 2),

                  // ── LOGO SECTION ──
                  AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return _buildCinematicLogo(_pulseAnimation.value, size);
                    },
                  )
                      .animate()
                      .fadeIn(duration: 1000.ms)
                      .scale(
                    begin: const Offset(0.3, 0.3),
                    end: const Offset(1.0, 1.0),
                    curve: Curves.elasticOut,
                    duration: 1200.ms,
                  ),

                  const SizedBox(height: 32),

                  // ── TITLE SECTION ──
                  _buildCinematicTitle(),

                  const SizedBox(height: 6),

                  _buildTagline(),

                  const SizedBox(height: 24),

                  // ── STATS BAR ──
                  _buildStatsBar(storage.getHighScore()),

                  const Spacer(flex: 2),

                  // ── MENU BUTTONS ──
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 36),
                    child: _buildCinematicButtons(context, audio, adManager),
                  ),

                  const Spacer(flex: 1),

                  // ── BOTTOM ──
                  _buildCinematicBottom(),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════
  // ⬡ HEXAGONAL GRID
  // ═══════════════════════════════════════════
  Widget _buildHexGrid(Size size) {
    return Positioned.fill(
      child: CustomPaint(
        painter: _HexGridPainter(),
      ).animate().fadeIn(duration: 1500.ms),
    );
  }

  // ═══════════════════════════════════════════
  // 🔄 ROTATING RING
  // ═══════════════════════════════════════════
  Widget _buildRotatingRing(Size size) {
    return Positioned(
      top: size.height * 0.08,
      left: 0,
      right: 0,
      child: Center(
        child: AnimatedBuilder(
          animation: _rotateController,
          builder: (context, child) {
            return Transform.rotate(
              angle: _rotateController.value * 2 * pi,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF00FF88).withOpacity(0.04),
                    width: 1,
                  ),
                ),
                child: Stack(
                  children: [
                    // Orbiting dot 1
                    Positioned(
                      top: 0,
                      left: 110 - 4,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF00FF88).withOpacity(0.5),
                          boxShadow: [
                            BoxShadow(
                              color:
                              const Color(0xFF00FF88).withOpacity(0.3),
                              blurRadius: 12,
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Orbiting dot 2
                    Positioned(
                      bottom: 0,
                      left: 110 - 3,
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF4F6EF7).withOpacity(0.4),
                          boxShadow: [
                            BoxShadow(
                              color:
                              const Color(0xFF4F6EF7).withOpacity(0.2),
                              blurRadius: 10,
                            ),
                          ],
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
  // ╱╱ DIAGONAL ACCENT LINES
  // ═══════════════════════════════════════════
  Widget _buildDiagonalLines(Size size) {
    return Positioned.fill(
      child: CustomPaint(
        painter: _DiagonalLinesPainter(),
      ).animate().fadeIn(delay: 400.ms, duration: 1000.ms),
    );
  }

  // ═══════════════════════════════════════════
  // 🔥 EMBER PARTICLES
  // ═══════════════════════════════════════════
  List<Widget> _buildEmberParticles(Size size) {
    final rng = Random(42);
    return List.generate(14, (i) {
      final x = rng.nextDouble() * size.width;
      final startY = size.height * (0.3 + rng.nextDouble() * 0.6);
      final s = 2.0 + rng.nextDouble() * 3;
      final colors = [
        const Color(0xFF00FF88),
        const Color(0xFF4F6EF7),
        const Color(0xFFFFD166),
        const Color(0xFFFF6B6B),
        const Color(0xFFA78BFA),
      ];
      final c = colors[i % colors.length];

      return Positioned(
        left: x,
        top: startY,
        child: Container(
          width: s,
          height: s,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: c.withOpacity(0.6),
            boxShadow: [
              BoxShadow(color: c.withOpacity(0.4), blurRadius: 6),
            ],
          ),
        )
            .animate(
          delay: Duration(milliseconds: i * 200),
          onPlay: (c) => c.repeat(),
        )
            .moveY(
          begin: 0,
          end: -(80 + rng.nextDouble() * 120),
          duration: Duration(milliseconds: 2500 + rng.nextInt(2000)),
          curve: Curves.easeOut,
        )
            .fadeOut(
          delay: Duration(milliseconds: 1800 + rng.nextInt(800)),
          duration: 600.ms,
        )
            .scaleXY(begin: 1.0, end: 0.0, duration: 3000.ms),
      );
    });
  }

  // ═══════════════════════════════════════════
  // 🌑 VIGNETTE
  // ═══════════════════════════════════════════
  Widget _buildVignette(Size size) {
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
  Widget _buildScanLines(Size size) {
    return Positioned.fill(
      child: IgnorePointer(
        child: CustomPaint(
          painter: _ScanLinePainter(),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════
  // 🖼️ CINEMATIC LOGO
  // ═══════════════════════════════════════════
  Widget _buildCinematicLogo(double pulse, Size size) {
    return SizedBox(
      width: 160,
      height: 160,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer glow ring
          Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Color.lerp(
                  const Color(0xFF00FF88).withOpacity(0.0),
                  const Color(0xFF00FF88).withOpacity(0.15),
                  pulse,
                )!,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color:
                  const Color(0xFF00FF88).withOpacity(0.06 * pulse),
                  blurRadius: 50,
                  spreadRadius: 15,
                ),
              ],
            ),
          ),

          // Mid ring
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFF00FF88).withOpacity(0.06),
                width: 1,
              ),
            ),
          ),

          // Logo container — hexagonal feel
          Container(
            width: 115,
            height: 115,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              color: const Color(0xFF111631),
              border: Border.all(
                color: Color.lerp(
                  const Color(0xFF00FF88).withOpacity(0.12),
                  const Color(0xFF00FF88).withOpacity(0.45),
                  pulse,
                )!,
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00FF88)
                      .withOpacity(0.08 * pulse),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.6),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(26),
              child: Stack(
                children: [
                  // Inner gradient overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color(0xFF00FF88).withOpacity(0.03),
                          Colors.transparent,
                          const Color(0xFF4F6EF7).withOpacity(0.03),
                        ],
                      ),
                    ),
                  ),

                  // Top-left corner accent
                  Positioned(
                    top: 0,
                    left: 0,
                    child: Container(
                      width: 35,
                      height: 2,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF00FF88).withOpacity(0.5),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 0,
                    left: 0,
                    child: Container(
                      width: 2,
                      height: 35,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            const Color(0xFF00FF88).withOpacity(0.5),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Bottom-right corner accent
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 35,
                      height: 2,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            const Color(0xFF4F6EF7).withOpacity(0.4),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 2,
                      height: 35,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            const Color(0xFF4F6EF7).withOpacity(0.4),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Logo image
                  Padding(
                    padding: const EdgeInsets.all(18),
                    child: Image.asset(
                      'assets/images/logo.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Decorative corner brackets (top-left)
          Positioned(
            top: 12,
            left: 12,
            child: _buildBracket(true),
          ),
          // Bottom-right bracket
          Positioned(
            bottom: 12,
            right: 12,
            child: Transform.rotate(
              angle: pi,
              child: _buildBracket(false),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBracket(bool isPrimary) {
    final color = isPrimary
        ? const Color(0xFF00FF88).withOpacity(0.25)
        : const Color(0xFF4F6EF7).withOpacity(0.2);
    return SizedBox(
      width: 16,
      height: 16,
      child: CustomPaint(
        painter: _BracketPainter(color: color),
      ),
    );
  }

  // ═══════════════════════════════════════════
  // 🏷️ CINEMATIC TITLE
  // ═══════════════════════════════════════════
  Widget _buildCinematicTitle() {
    return Column(
      children: [
        // Decorative line above
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    const Color(0xFF00FF88).withOpacity(0.4),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFF00FF88).withOpacity(0.5),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 40,
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF00FF88).withOpacity(0.4),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ],
        )
            .animate()
            .fadeIn(delay: 400.ms, duration: 600.ms)
            .scaleX(begin: 0.0, end: 1.0, curve: Curves.easeOut),

        const SizedBox(height: 14),

        // Main title row
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // "SNAKE" text with layered effect
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [
                  Color(0xFFFFFFFF),
                  Color(0xFFCCE5D9),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ).createShader(bounds),
              child: Text(
                'SNAKE',
                style: GoogleFonts.rajdhani(
                  fontSize: 48,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 8,
                  height: 1,
                ),
              ),
            )
                .animate()
                .fadeIn(delay: 300.ms, duration: 700.ms)
                .slideX(begin: -0.2, end: 0, curve: Curves.easeOut),

            const SizedBox(width: 12),

            // "X" badge — diamond shaped accent
            Transform.rotate(
              angle: 0,
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF00FF88),
                      Color(0xFF00CC6A),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00FF88).withOpacity(0.4),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                    BoxShadow(
                      color: const Color(0xFF00FF88).withOpacity(0.15),
                      blurRadius: 40,
                      spreadRadius: 8,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    'X',
                    style: GoogleFonts.rajdhani(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF0A0E21),
                      height: 1,
                    ),
                  ),
                ),
              ),
            )
                .animate()
                .fadeIn(delay: 600.ms, duration: 500.ms)
                .scale(
              begin: const Offset(0.0, 0.0),
              end: const Offset(1.0, 1.0),
              curve: Curves.elasticOut,
              duration: 900.ms,
            )
                .then(delay: 300.ms)
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .scale(
              begin: const Offset(1.0, 1.0),
              end: const Offset(1.06, 1.06),
              duration: 1800.ms,
            ),
          ],
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════
  // 📝 TAGLINE
  // ═══════════════════════════════════════════
  Widget _buildTagline() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(
            color: const Color(0xFF00FF88).withOpacity(0.3),
            width: 2,
          ),
          right: BorderSide(
            color: const Color(0xFF00FF88).withOpacity(0.3),
            width: 2,
          ),
        ),
      ),
      child: Text(
        'HUNT  ·  GROW  ·  CONQUER',
        style: GoogleFonts.rajdhani(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF00FF88).withOpacity(0.45),
          letterSpacing: 4,
        ),
      ),
    )
        .animate()
        .fadeIn(delay: 800.ms, duration: 500.ms)
        .slideY(begin: 0.3, end: 0, curve: Curves.easeOut);
  }

  // ═══════════════════════════════════════════
  // 📊 STATS BAR
  // ═══════════════════════════════════════════
  Widget _buildStatsBar(int highScore) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 50),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF111631).withOpacity(0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFFFD166).withOpacity(0.12),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Trophy icon with glow
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFFFD166).withOpacity(0.2),
                  const Color(0xFFFFD166).withOpacity(0.05),
                ],
              ),
            ),
            child: const Icon(
              Icons.emoji_events_rounded,
              color: Color(0xFFFFD166),
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'BEST RECORD',
                style: GoogleFonts.rajdhani(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Colors.white.withOpacity(0.35),
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                '$highScore',
                style: GoogleFonts.orbitron(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFFFD166),
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
          const SizedBox(width: 10),
          // Small rank indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFFFFD166).withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              _getRankLabel(highScore),
              style: GoogleFonts.rajdhani(
                fontSize: 9,
                fontWeight: FontWeight.w800,
                color: const Color(0xFFFFD166).withOpacity(0.7),
                letterSpacing: 1,
              ),
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: 1000.ms, duration: 500.ms)
        .slideY(begin: 0.3, end: 0, curve: Curves.easeOut);
  }

  String _getRankLabel(int score) {
    if (score >= 100) return 'LEGEND';
    if (score >= 50) return 'MASTER';
    if (score >= 25) return 'ELITE';
    if (score >= 10) return 'SKILLED';
    if (score > 0) return 'ROOKIE';
    return 'NEW';
  }

  // ═══════════════════════════════════════════
  // 🎮 CINEMATIC BUTTONS
  // ═══════════════════════════════════════════
  Widget _buildCinematicButtons(
      BuildContext context, dynamic audio, dynamic adManager) {
    return Column(
      children: [
        // ── PLAY BUTTON (Primary) ──
        _buildPlayButton(
          onTap: () {
            audio.playClick();
            if (kIsWeb) {
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const GameScreen()));
            } else {
              adManager.showInterstitial(() {
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const GameScreen()));
              });
            }
          },
        ),

        const SizedBox(height: 16),

        // ── SECONDARY BUTTONS ROW ──
        Row(
          children: [
            Expanded(
              child: _buildSecondaryBtn(
                icon: Icons.tune_rounded,
                label: 'SETTINGS',
                color: const Color(0xFF4F6EF7),
                delay: 600,
                onTap: () {
                  audio.playClick();
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const SettingsScreen()));
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSecondaryBtn(
                icon: Icons.logout_rounded,
                label: 'EXIT',
                color: const Color(0xFFFF6B6B),
                delay: 700,
                onTap: () {
                  audio.playClick();
                  SystemNavigator.pop();
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  // 🟢 PLAY BUTTON — Cinematic primary CTA
  Widget _buildPlayButton({required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
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
              color: const Color(0xFF00FF88).withOpacity(0.35),
              blurRadius: 25,
              spreadRadius: 0,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: const Color(0xFF00FF88).withOpacity(0.12),
              blurRadius: 50,
              spreadRadius: 8,
            ),
          ],
        ),
        child: Stack(
          children: [
            // Shine overlay
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withOpacity(0.15),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.5],
                    ),
                  ),
                ),
              ),
            ),
            // Content
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A0E21).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    color: Color(0xFF0A0E21),
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                Text(
                  'START GAME',
                  style: GoogleFonts.rajdhani(
                    fontSize: 20,
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
        .fadeIn(delay: 450.ms, duration: 600.ms)
        .slideY(begin: 0.4, end: 0, curve: Curves.easeOut)
        .then(delay: 300.ms)
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .scale(
      begin: const Offset(1.0, 1.0),
      end: const Offset(1.02, 1.02),
      duration: 2200.ms,
    );
  }

  // 🔵 SECONDARY BUTTON
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
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withOpacity(0.18),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.05),
              blurRadius: 15,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color.withOpacity(0.75), size: 24),
            const SizedBox(height: 6),
            Text(
              label,
              style: GoogleFonts.rajdhani(
                fontSize: 12,
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
        .slideY(begin: 0.4, end: 0, curve: Curves.easeOut);
  }

  // ═══════════════════════════════════════════
  // 🏢 CINEMATIC BOTTOM
  // ═══════════════════════════════════════════
  Widget _buildCinematicBottom() {
    return Column(
      children: [
        // Decorative separator
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildCornerDeco(false),
            const SizedBox(width: 6),
            Container(
              width: 60,
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    Colors.white.withOpacity(0.08),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            const SizedBox(width: 6),
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                border: Border.all(
                  color: const Color(0xFF00FF88).withOpacity(0.2),
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(2),
              ),
              child: Center(
                child: Container(
                  width: 3,
                  height: 3,
                  decoration: BoxDecoration(
                    color: const Color(0xFF00FF88).withOpacity(0.3),
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            Container(
              width: 60,
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    Colors.white.withOpacity(0.08),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            const SizedBox(width: 6),
            _buildCornerDeco(true),
          ],
        ),

        const SizedBox(height: 10),

        Text(
          'v1.0.0  ·  SNAKE X STUDIOS',
          style: GoogleFonts.rajdhani(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: Colors.white.withOpacity(0.12),
            letterSpacing: 3,
          ),
        ),
      ],
    ).animate().fadeIn(delay: 1400.ms, duration: 600.ms);
  }

  Widget _buildCornerDeco(bool flip) {
    return Transform.flip(
      flipX: flip,
      child: SizedBox(
        width: 10,
        height: 10,
        child: CustomPaint(
          painter: _CornerDecoPainter(),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════
// ⬡ HEX GRID PAINTER
// ═══════════════════════════════════════════
class _HexGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.012)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    const hexSize = 40.0;
    final w = hexSize * 1.732;
    final h = hexSize * 2;

    for (double row = -1; row * h * 0.75 < size.height + h; row++) {
      for (double col = -1; col * w < size.width + w; col++) {
        final offset = (row % 2 == 0) ? 0.0 : w / 2;
        final cx = col * w + offset;
        final cy = row * h * 0.75;
        _drawHex(canvas, Offset(cx, cy), hexSize, paint);
      }
    }

    // Add subtle dots at intersections
    final dotPaint = Paint()
      ..color = Colors.white.withOpacity(0.02)
      ..style = PaintingStyle.fill;

    for (double row = -1; row * h * 0.75 < size.height + h; row++) {
      for (double col = -1; col * w < size.width + w; col++) {
        final offset = (row % 2 == 0) ? 0.0 : w / 2;
        final cx = col * w + offset;
        final cy = row * h * 0.75;
        canvas.drawCircle(Offset(cx, cy), 1.2, dotPaint);
      }
    }
  }

  void _drawHex(Canvas canvas, Offset center, double size, Paint paint) {
    final path = Path();
    for (int i = 0; i < 6; i++) {
      final angle = (pi / 180) * (60 * i - 30);
      final x = center.dx + size * cos(angle);
      final y = center.dy + size * sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ═══════════════════════════════════════════
// ╱╱ DIAGONAL LINES PAINTER
// ═══════════════════════════════════════════
class _DiagonalLinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Top-left accent
    final p1 = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          const Color(0xFF00FF88).withOpacity(0.06),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width * 0.4, size.height * 0.3));
    canvas.drawLine(
      const Offset(0, 0),
      Offset(size.width * 0.25, size.height * 0.2),
      p1..strokeWidth = 0.5,
    );

    // Bottom-right accent
    final p2 = Paint()
      ..shader = LinearGradient(
        begin: Alignment.bottomRight,
        end: Alignment.topLeft,
        colors: [
          const Color(0xFF4F6EF7).withOpacity(0.05),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(
          size.width * 0.6, size.height * 0.7, size.width * 0.4, size.height * 0.3));
    canvas.drawLine(
      Offset(size.width, size.height),
      Offset(size.width * 0.75, size.height * 0.8),
      p2..strokeWidth = 0.5,
    );
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
      ..color = Colors.black.withOpacity(0.04)
      ..strokeWidth = 1;

    for (double y = 0; y < size.height; y += 3) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
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
      ..moveTo(0, size.height * 0.4)
      ..lineTo(0, 0)
      ..lineTo(size.width * 0.4, 0);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ═══════════════════════════════════════════
// ◣ CORNER DECO PAINTER
// ═══════════════════════════════════════════
class _CornerDecoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.08)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    canvas.drawLine(Offset(0, size.height), Offset(size.width, 0), paint);
    canvas.drawLine(
        Offset(0, size.height), Offset(0, size.height * 0.5), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}