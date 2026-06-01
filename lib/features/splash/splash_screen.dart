import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../shared/themes/app_theme.dart';
import '../menu/main_menu_screen.dart';
import 'dart:math';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _floatController;
  late Animation<double> _floatAnimation;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _progressController;
  late AnimationController _rotateController;
  late AnimationController _rotateController2;
  late AnimationController _scanController;

  @override
  void initState() {
    super.initState();

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    // Float animation
    _floatController = AnimationController(
      duration: const Duration(milliseconds: 2800),
      vsync: this,
    )..repeat(reverse: true);

    _floatAnimation = Tween<double>(begin: -8, end: 8).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    // Pulse glow animation
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Outer ring rotation
    _rotateController = AnimationController(
      duration: const Duration(seconds: 18),
      vsync: this,
    )..repeat();

    // Inner ring rotation (opposite)
    _rotateController2 = AnimationController(
      duration: const Duration(seconds: 12),
      vsync: this,
    )..repeat();

    // Scan line animation
    _scanController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();

    // Progress bar animation
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 2800),
      vsync: this,
    )..forward();

    // Navigate
    Future.delayed(const Duration(milliseconds: 3800), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 700),
            pageBuilder: (_, __, ___) => const MainMenuScreen(),
            transitionsBuilder: (_, animation, __, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _floatController.dispose();
    _pulseController.dispose();
    _progressController.dispose();
    _rotateController.dispose();
    _rotateController2.dispose();
    _scanController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
            // Layer 1: Hex grid
            _buildHexGrid(),

            // Layer 2: Diagonal accent lines
            _buildDiagonalLines(size),

            // Layer 3: Vignette
            _buildVignette(),

            // Layer 4: Scan lines
            _buildScanLines(),

            // Layer 5: Ember particles
            ..._buildEmberParticles(size),

            // Layer 6: Glow orbs
            ..._buildGlowOrbs(size),

            // Layer 7: Corner HUD decorations
            _buildHudCorners(size),

            // Layer 8: Rotating rings (behind logo)
            _buildRotatingRings(size),

            // Layer 9: Main content
            SafeArea(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 20),

                    // ── LOGO WITH ORBITAL RINGS ──
                    AnimatedBuilder(
                      animation: _floatAnimation,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(0, _floatAnimation.value),
                          child: child,
                        );
                      },
                      child: AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (context, child) {
                          return _buildCinematicLogo(_pulseAnimation.value);
                        },
                      ),
                    )
                        .animate()
                        .fadeIn(duration: 900.ms)
                        .scale(
                      begin: const Offset(0.2, 0.2),
                      end: const Offset(1.0, 1.0),
                      curve: Curves.elasticOut,
                      duration: 1300.ms,
                    ),

                    const SizedBox(height: 44),

                    // ── TITLE ──
                    _buildCinematicTitle(),

                    const SizedBox(height: 10),

                    // ── TAGLINE ──
                    _buildTagline(),

                    const SizedBox(height: 56),

                    // ── PROGRESS SECTION ──
                    _buildProgressSection(size),

                    const SizedBox(height: 16),

                    // ── LOADING TEXT ──
                    _buildLoadingText(),
                  ],
                ),
              ),
            ),

            // Layer 10: Bottom branding
            Positioned(
              bottom: 28,
              left: 0,
              right: 0,
              child: _buildCinematicBottom(),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════
  // ⬡ HEX GRID BACKGROUND
  // ═══════════════════════════════════════════
  Widget _buildHexGrid() {
    return Positioned.fill(
      child: CustomPaint(
        painter: _HexGridPainter(),
      ).animate().fadeIn(duration: 1600.ms, curve: Curves.easeOut),
    );
  }

  // ═══════════════════════════════════════════
  // ╱╱ DIAGONAL ACCENT LINES
  // ═══════════════════════════════════════════
  Widget _buildDiagonalLines(Size size) {
    return Positioned.fill(
      child: IgnorePointer(
        child: CustomPaint(
          painter: _DiagonalLinesPainter(size: size),
        ).animate().fadeIn(delay: 400.ms, duration: 1000.ms),
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
              radius: 0.88,
              colors: [
                Colors.transparent,
                Colors.black.withOpacity(0.55),
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
        child: CustomPaint(
          painter: _ScanLinePainter(),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════
  // 🔥 EMBER PARTICLES
  // ═══════════════════════════════════════════
  List<Widget> _buildEmberParticles(Size size) {
    final rng = Random(99);
    final colors = [
      const Color(0xFF00FF88),
      const Color(0xFF4F6EF7),
      const Color(0xFFFFD166),
      const Color(0xFFFF6B6B),
      const Color(0xFFA78BFA),
      const Color(0xFF00C9A7),
    ];

    return List.generate(16, (i) {
      final x = rng.nextDouble() * size.width;
      final startY = size.height * (0.25 + rng.nextDouble() * 0.65);
      final s = 1.5 + rng.nextDouble() * 3.0;
      final c = colors[i % colors.length];
      final dur = 2200 + rng.nextInt(2200);
      final rise = 70.0 + rng.nextDouble() * 130;

      return Positioned(
        left: x,
        top: startY,
        child: Container(
          width: s,
          height: s,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: c.withOpacity(0.65),
            boxShadow: [
              BoxShadow(color: c.withOpacity(0.35), blurRadius: 7),
            ],
          ),
        )
            .animate(
          delay: Duration(milliseconds: i * 180),
          onPlay: (ctrl) => ctrl.repeat(),
        )
            .moveY(
          begin: 0,
          end: -rise,
          duration: Duration(milliseconds: dur),
          curve: Curves.easeOut,
        )
            .fadeOut(
          delay: Duration(milliseconds: (dur * 0.65).toInt()),
          duration: Duration(milliseconds: (dur * 0.35).toInt()),
        )
            .scaleXY(
          begin: 1.0,
          end: 0.0,
          duration: Duration(milliseconds: dur),
        ),
      );
    });
  }

  // ═══════════════════════════════════════════
  // 🟢 AMBIENT GLOW ORBS
  // ═══════════════════════════════════════════
  List<Widget> _buildGlowOrbs(Size size) {
    return [
      // Top-center green
      Positioned(
        top: -120,
        left: size.width / 2 - 160,
        child: Container(
          width: 320,
          height: 320,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                const Color(0xFF00FF88).withOpacity(0.07),
                const Color(0xFF00FF88).withOpacity(0.02),
                Colors.transparent,
              ],
            ),
          ),
        )
            .animate()
            .fadeIn(duration: 1200.ms)
            .then()
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .scale(
          begin: const Offset(0.85, 0.85),
          end: const Offset(1.18, 1.18),
          duration: 3800.ms,
        ),
      ),

      // Bottom-right blue
      Positioned(
        bottom: -100,
        right: -70,
        child: Container(
          width: 280,
          height: 280,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                const Color(0xFF4F6EF7).withOpacity(0.05),
                Colors.transparent,
              ],
            ),
          ),
        ).animate().fadeIn(delay: 400.ms, duration: 1200.ms),
      ),

      // Left-center purple
      Positioned(
        top: size.height * 0.42,
        left: -90,
        child: Container(
          width: 220,
          height: 220,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                const Color(0xFFA78BFA).withOpacity(0.04),
                Colors.transparent,
              ],
            ),
          ),
        ).animate().fadeIn(delay: 600.ms, duration: 1200.ms),
      ),
    ];
  }

  // ═══════════════════════════════════════════
  // 🔲 HUD CORNER DECORATIONS
  // ═══════════════════════════════════════════
  Widget _buildHudCorners(Size size) {
    return Positioned.fill(
      child: IgnorePointer(
        child: CustomPaint(
          painter: _HudCornerPainter(),
        ).animate().fadeIn(delay: 600.ms, duration: 800.ms),
      ),
    );
  }

  // ═══════════════════════════════════════════
  // 🔄 ROTATING RINGS (background behind logo)
  // ═══════════════════════════════════════════
  Widget _buildRotatingRings(Size size) {
    return Positioned(
      top: size.height * 0.12,
      left: 0,
      right: 0,
      child: Center(
        child: SizedBox(
          width: 260,
          height: 260,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer ring
              AnimatedBuilder(
                animation: _rotateController,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: _rotateController.value * 2 * pi,
                    child: Container(
                      width: 258,
                      height: 258,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF00FF88).withOpacity(0.05),
                          width: 1,
                        ),
                      ),
                      child: Stack(
                        children: [
                          // Orbiting dot — top
                          Positioned(
                            top: 0,
                            left: 129 - 5,
                            child: Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFF00FF88)
                                    .withOpacity(0.55),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF00FF88)
                                        .withOpacity(0.3),
                                    blurRadius: 14,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // Orbiting dot — bottom
                          Positioned(
                            bottom: 0,
                            left: 129 - 3,
                            child: Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFF00FF88)
                                    .withOpacity(0.25),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

              // Middle ring — counter-rotate
              AnimatedBuilder(
                animation: _rotateController2,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: -_rotateController2.value * 2 * pi,
                    child: Container(
                      width: 210,
                      height: 210,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF4F6EF7).withOpacity(0.06),
                          width: 1,
                        ),
                      ),
                      child: Stack(
                        children: [
                          // Orbiting dot — right
                          Positioned(
                            right: 0,
                            top: 105 - 4,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFF4F6EF7)
                                    .withOpacity(0.45),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF4F6EF7)
                                        .withOpacity(0.25),
                                    blurRadius: 12,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // Orbiting square — left
                          Positioned(
                            left: 0,
                            top: 105 - 3,
                            child: Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(2),
                                color: const Color(0xFF4F6EF7)
                                    .withOpacity(0.2),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

              // Inner static ring
              Container(
                width: 168,
                height: 168,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF00FF88).withOpacity(0.04),
                    width: 1,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════
  // 🖼️ CINEMATIC LOGO
  // ═══════════════════════════════════════════
  Widget _buildCinematicLogo(double pulse) {
    return SizedBox(
      width: 175,
      height: 175,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer glow
          Container(
            width: 175,
            height: 175,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Color.lerp(
                  const Color(0xFF00FF88).withOpacity(0.0),
                  const Color(0xFF00FF88).withOpacity(0.12),
                  pulse,
                )!,
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00FF88)
                      .withOpacity(0.07 * pulse),
                  blurRadius: 60,
                  spreadRadius: 20,
                ),
              ],
            ),
          ),

          // Logo box
          Container(
            width: 128,
            height: 128,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(32),
              color: const Color(0xFF111631),
              border: Border.all(
                color: Color.lerp(
                  const Color(0xFF00FF88).withOpacity(0.1),
                  const Color(0xFF00FF88).withOpacity(0.5),
                  pulse,
                )!,
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00FF88)
                      .withOpacity(0.1 * pulse),
                  blurRadius: 35,
                  spreadRadius: 6,
                ),
                BoxShadow(
                  color: const Color(0xFF4F6EF7)
                      .withOpacity(0.06 * pulse),
                  blurRadius: 25,
                  spreadRadius: 4,
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.55),
                  blurRadius: 35,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: Stack(
                children: [
                  // Inner gradient sheen
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

                  // Top-left bracket accent
                  Positioned(
                    top: 0,
                    left: 0,
                    child: Container(
                      width: 38,
                      height: 2,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF00FF88).withOpacity(0.55),
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
                      height: 38,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            const Color(0xFF00FF88).withOpacity(0.55),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Bottom-right bracket accent
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 38,
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
                      height: 38,
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
                    padding: const EdgeInsets.all(22),
                    child: Image.asset(
                      'assets/images/logo.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Corner bracket decorations
          Positioned(
            top: 14,
            left: 14,
            child: _buildBracket(
              color: const Color(0xFF00FF88).withOpacity(0.3),
              flip: false,
            ),
          ),
          Positioned(
            bottom: 14,
            right: 14,
            child: _buildBracket(
              color: const Color(0xFF4F6EF7).withOpacity(0.25),
              flip: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBracket({required Color color, required bool flip}) {
    return Transform.flip(
      flipX: flip,
      flipY: flip,
      child: SizedBox(
        width: 18,
        height: 18,
        child: CustomPaint(
          painter: _BracketPainter(color: color),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════
  // 🏷️ CINEMATIC TITLE
  // ═══════════════════════════════════════════
  Widget _buildCinematicTitle() {
    return Column(
      children: [
        // Top accent line
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
                    const Color(0xFF00FF88).withOpacity(0.4),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                color: const Color(0xFF00FF88).withOpacity(0.45),
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
                    const Color(0xFF00FF88).withOpacity(0.4),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ],
        )
            .animate()
            .fadeIn(delay: 500.ms, duration: 600.ms)
            .scaleX(begin: 0.0, end: 1.0, curve: Curves.easeOut),

        const SizedBox(height: 16),

        // Title row
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // "SNAKE" with gradient mask
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
                  fontSize: 52,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 9,
                  height: 1,
                ),
              ),
            )
                .animate()
                .fadeIn(delay: 350.ms, duration: 700.ms)
                .slideX(begin: -0.22, end: 0, curve: Curves.easeOut),

            const SizedBox(width: 14),

            // "X" badge
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF00FF88),
                    Color(0xFF00CC6E),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00FF88).withOpacity(0.45),
                    blurRadius: 24,
                    spreadRadius: 2,
                  ),
                  BoxShadow(
                    color: const Color(0xFF00FF88).withOpacity(0.18),
                    blurRadius: 50,
                    spreadRadius: 10,
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Shine overlay
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.white.withOpacity(0.2),
                              Colors.transparent,
                            ],
                            stops: const [0.0, 0.55],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Center(
                    child: Text(
                      'X',
                      style: GoogleFonts.rajdhani(
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF0A0E21),
                        height: 1,
                      ),
                    ),
                  ),
                ],
              ),
            )
                .animate()
                .fadeIn(delay: 650.ms, duration: 500.ms)
                .scale(
              begin: const Offset(0.0, 0.0),
              end: const Offset(1.0, 1.0),
              curve: Curves.elasticOut,
              duration: 1000.ms,
            )
                .then(delay: 400.ms)
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .scale(
              begin: const Offset(1.0, 1.0),
              end: const Offset(1.07, 1.07),
              duration: 1800.ms,
              curve: Curves.easeInOut,
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
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(
            color: const Color(0xFF00FF88).withOpacity(0.28),
            width: 2,
          ),
          right: BorderSide(
            color: const Color(0xFF00FF88).withOpacity(0.28),
            width: 2,
          ),
        ),
      ),
      child: Text(
        'HUNT  ·  GROW  ·  CONQUER',
        style: GoogleFonts.rajdhani(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF00FF88).withOpacity(0.42),
          letterSpacing: 4,
        ),
      ),
    )
        .animate()
        .fadeIn(delay: 950.ms, duration: 500.ms)
        .slideY(begin: 0.3, end: 0, curve: Curves.easeOut);
  }

  // ═══════════════════════════════════════════
  // ⏳ PROGRESS SECTION
  // ═══════════════════════════════════════════
  Widget _buildProgressSection(Size size) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 55),
      child: Column(
        children: [
          // Progress bar with HUD frame
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF111631).withOpacity(0.6),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withOpacity(0.05),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                // Bar track
                AnimatedBuilder(
                  animation: _progressController,
                  builder: (context, child) {
                    final pct = _progressController.value;
                    return Stack(
                      children: [
                        // Track
                        Container(
                          height: 5,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(3),
                            color: Colors.white.withOpacity(0.05),
                          ),
                        ),
                        // Fill
                        FractionallySizedBox(
                          widthFactor: pct,
                          child: Container(
                            height: 5,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(3),
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFF00FF88),
                                  Color(0xFF00C9A7),
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF00FF88)
                                      .withOpacity(0.5),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Glowing tip
                        if (pct > 0.02)
                          Positioned(
                            left: ((size.width - 110 - 16) * pct) - 6,
                            top: -4,
                            child: Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFF00FF88),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF00FF88)
                                        .withOpacity(0.65),
                                    blurRadius: 14,
                                    spreadRadius: 3,
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 8),

                // Percent + label row
                AnimatedBuilder(
                  animation: _progressController,
                  builder: (context, child) {
                    final pct = _progressController.value;
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _getLoadingStage(pct),
                          style: GoogleFonts.rajdhani(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Colors.white.withOpacity(0.25),
                            letterSpacing: 1.5,
                          ),
                        ),
                        Text(
                          '${(pct * 100).toInt()}%',
                          style: GoogleFonts.orbitron(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color:
                            const Color(0xFF00FF88).withOpacity(0.65),
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          )
              .animate()
              .fadeIn(delay: 1100.ms, duration: 500.ms)
              .slideY(begin: 0.3, end: 0, curve: Curves.easeOut),
        ],
      ),
    );
  }

  String _getLoadingStage(double progress) {
    if (progress < 0.3) return 'LOADING ASSETS...';
    if (progress < 0.6) return 'INITIALIZING ENGINE...';
    if (progress < 0.85) return 'PREPARING ARENA...';
    return 'READY TO PLAY';
  }

  // ═══════════════════════════════════════════
  // 💬 LOADING TEXT
  // ═══════════════════════════════════════════
  Widget _buildLoadingText() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Animated dot indicators
        ...List.generate(3, (i) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF00FF88).withOpacity(0.4),
            ),
          )
              .animate(delay: Duration(milliseconds: 1400 + (i * 180)))
              .fadeIn(duration: 300.ms)
              .then()
              .animate(
            onPlay: (c) => c.repeat(reverse: true),
            delay: Duration(milliseconds: i * 220),
          )
              .scale(
            begin: const Offset(0.5, 0.5),
            end: const Offset(1.3, 1.3),
            duration: 700.ms,
          )
              .fadeOut(duration: 700.ms);
        }),
        const SizedBox(width: 10),
        Text(
          'LOADING',
          style: GoogleFonts.rajdhani(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Colors.white.withOpacity(0.22),
            letterSpacing: 3,
          ),
        )
            .animate()
            .fadeIn(delay: 1500.ms, duration: 400.ms),
      ],
    );
  }

  // ═══════════════════════════════════════════
  // 🏢 CINEMATIC BOTTOM
  // ═══════════════════════════════════════════
  Widget _buildCinematicBottom() {
    return Column(
      children: [
        // Decorative separator row
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Left deco
            SizedBox(
              width: 12,
              height: 12,
              child: CustomPaint(
                painter: _CornerDecoPainter(
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 70,
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    Colors.white.withOpacity(0.07),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Center diamond
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                border: Border.all(
                  color: const Color(0xFF00FF88).withOpacity(0.18),
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(2),
              ),
              child: Center(
                child: Container(
                  width: 3,
                  height: 3,
                  decoration: BoxDecoration(
                    color: const Color(0xFF00FF88).withOpacity(0.25),
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 70,
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    Colors.white.withOpacity(0.07),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Right deco (flipped)
            Transform.flip(
              flipX: true,
              child: SizedBox(
                width: 12,
                height: 12,
                child: CustomPaint(
                  painter: _CornerDecoPainter(
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        Text(
          'v1.0.0  ·  SNAKE X STUDIOS',
          style: GoogleFonts.rajdhani(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: Colors.white.withOpacity(0.11),
            letterSpacing: 3,
          ),
        ),
      ],
    ).animate().fadeIn(delay: 1900.ms, duration: 600.ms);
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
        final cx = col * w + offset;
        final cy = row * h * 0.75;
        _drawHex(canvas, Offset(cx, cy), hexSize, paint);
      }
    }

    // Intersection dots
    final dotPaint = Paint()
      ..color = Colors.white.withOpacity(0.02)
      ..style = PaintingStyle.fill;

    for (double row = -1; row * h * 0.75 < size.height + h; row++) {
      for (double col = -1; col * w < size.width + w; col++) {
        final offset = (row % 2 == 0) ? 0.0 : w / 2;
        canvas.drawCircle(
          Offset(col * w + offset, row * h * 0.75),
          1.1,
          dotPaint,
        );
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
  final Size size;
  _DiagonalLinesPainter({required this.size});

  @override
  void paint(Canvas canvas, Size canvasSize) {
    final p1 = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          const Color(0xFF00FF88).withOpacity(0.05),
          Colors.transparent,
        ],
      ).createShader(
          Rect.fromLTWH(0, 0, canvasSize.width * 0.4, canvasSize.height * 0.3))
      ..strokeWidth = 0.6;

    canvas.drawLine(
      const Offset(0, 0),
      Offset(canvasSize.width * 0.22, canvasSize.height * 0.18),
      p1,
    );

    final p2 = Paint()
      ..shader = LinearGradient(
        begin: Alignment.bottomRight,
        end: Alignment.topLeft,
        colors: [
          const Color(0xFF4F6EF7).withOpacity(0.045),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(canvasSize.width * 0.6,
          canvasSize.height * 0.7, canvasSize.width * 0.4, canvasSize.height * 0.3))
      ..strokeWidth = 0.6;

    canvas.drawLine(
      Offset(canvasSize.width, canvasSize.height),
      Offset(canvasSize.width * 0.78, canvasSize.height * 0.82),
      p2,
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
      ..color = const Color(0xFF00FF88).withOpacity(0.08)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const len = 28.0;
    const pad = 20.0;

    // Top-left
    canvas.drawLine(
        Offset(pad, pad + len), Offset(pad, pad), paint);
    canvas.drawLine(
        Offset(pad, pad), Offset(pad + len, pad), paint);

    // Top-right
    canvas.drawLine(
        Offset(size.width - pad, pad + len),
        Offset(size.width - pad, pad), paint);
    canvas.drawLine(
        Offset(size.width - pad, pad),
        Offset(size.width - pad - len, pad), paint);

    // Bottom-left
    canvas.drawLine(
        Offset(pad, size.height - pad - len),
        Offset(pad, size.height - pad), paint);
    canvas.drawLine(
        Offset(pad, size.height - pad),
        Offset(pad + len, size.height - pad), paint);

    // Bottom-right
    canvas.drawLine(
        Offset(size.width - pad, size.height - pad - len),
        Offset(size.width - pad, size.height - pad), paint);
    canvas.drawLine(
        Offset(size.width - pad, size.height - pad),
        Offset(size.width - pad - len, size.height - pad), paint);

    // Subtle corner dots
    final dotPaint = Paint()
      ..color = const Color(0xFF00FF88).withOpacity(0.15)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(pad, pad), 3, dotPaint);
    canvas.drawCircle(Offset(size.width - pad, pad), 3, dotPaint);
    canvas.drawCircle(Offset(pad, size.height - pad), 3, dotPaint);
    canvas.drawCircle(
        Offset(size.width - pad, size.height - pad), 3, dotPaint);
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