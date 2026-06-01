// lib/features/settings/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../shared/themes/app_theme.dart';
import '../../providers/app_providers.dart';
import '../../core/constants/app_constants.dart';
import 'dart:math';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen>
    with TickerProviderStateMixin {
  late double _speed;
  late bool _sound;
  late bool _vibration;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

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
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    final storage = ref.read(storageServiceProvider);
    _speed = storage.getGameSpeed();
    _sound = storage.isSoundEnabled();
    _vibration = storage.isVibrationEnabled();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final storage = ref.watch(storageServiceProvider);
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

            // Layer 2: Vignette
            _buildVignette(),

            // Layer 3: Scan lines
            _buildScanLines(),

            // Layer 4: HUD corners
            _buildHudCorners(),

            // Layer 5: Ambient glow orbs
            ..._buildGlowOrbs(size),

            // Layer 6: Content
            SafeArea(
              child: Column(
                children: [
                  // ─── TOP BAR ───
                  _buildTopBar(audio),

                  // ─── SCROLLABLE CONTENT ───
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 6),

                          // ── APPEARANCE ──
                          _buildSectionHeader(
                            icon: Icons.palette_rounded,
                            label: 'APPEARANCE',
                            color: const Color(0xFF00FF88),
                            delay: 200,
                          ),
                          const SizedBox(height: 10),
                          _buildHudCard(
                            delay: 260,
                            accentColor: const Color(0xFF00FF88),
                            child: _buildThemeSetting(storage, audio),
                          ),

                          const SizedBox(height: 22),

                          // ── GAMEPLAY ──
                          _buildSectionHeader(
                            icon: Icons.speed_rounded,
                            label: 'GAMEPLAY',
                            color: const Color(0xFFFFD166),
                            delay: 360,
                          ),
                          const SizedBox(height: 10),
                          _buildHudCard(
                            delay: 420,
                            accentColor: const Color(0xFFFFD166),
                            child: _buildSpeedSetting(storage, audio),
                          ),

                          const SizedBox(height: 22),

                          // ── AUDIO & FEEDBACK ──
                          _buildSectionHeader(
                            icon: Icons.tune_rounded,
                            label: 'AUDIO & FEEDBACK',
                            color: const Color(0xFF4F6EF7),
                            delay: 520,
                          ),
                          const SizedBox(height: 10),
                          _buildHudCard(
                            delay: 580,
                            accentColor: const Color(0xFF4F6EF7),
                            child: Column(
                              children: [
                                _buildToggleRow(
                                  title: 'Sound Effects',
                                  subtitle: 'Game audio and click sounds',
                                  icon: _sound
                                      ? Icons.volume_up_rounded
                                      : Icons.volume_off_rounded,
                                  iconColor: const Color(0xFF4F6EF7),
                                  value: _sound,
                                  activeColor: const Color(0xFF4F6EF7),
                                  onChanged: (val) {
                                    audio.playClick();
                                    storage.saveSoundEnabled(val);
                                    setState(() => _sound = val);
                                  },
                                ),
                                _buildHudDivider(const Color(0xFF4F6EF7)),
                                _buildToggleRow(
                                  title: 'Haptic Feedback',
                                  subtitle:
                                  'Vibration on controls and events',
                                  icon: _vibration
                                      ? Icons.vibration_rounded
                                      : Icons.phonelink_erase_rounded,
                                  iconColor: const Color(0xFFA78BFA),
                                  value: _vibration,
                                  activeColor: const Color(0xFFA78BFA),
                                  onChanged: (val) {
                                    audio.playClick();
                                    storage.saveVibrationEnabled(val);
                                    setState(() => _vibration = val);
                                  },
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 30),

                          // ── SAVE BUTTON ──
                          _buildSaveButton(audio),

                          const SizedBox(height: 14),

                          // ── RESET OPTION ──
                          _buildResetOption(storage, audio),

                          const SizedBox(height: 30),
                        ],
                      ),
                    ),
                  ),
                ],
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
      ).animate().fadeIn(duration: 1400.ms),
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
              radius: 0.9,
              colors: [
                Colors.transparent,
                Colors.black.withOpacity(0.45),
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
  // 🔲 HUD CORNERS
  // ═══════════════════════════════════════════
  Widget _buildHudCorners() {
    return Positioned.fill(
      child: IgnorePointer(
        child: CustomPaint(
          painter: _HudCornerPainter(),
        ).animate().fadeIn(delay: 300.ms, duration: 700.ms),
      ),
    );
  }

  // ═══════════════════════════════════════════
  // 🟢 AMBIENT GLOW ORBS
  // ═══════════════════════════════════════════
  List<Widget> _buildGlowOrbs(Size size) {
    return [
      Positioned(
        top: -80,
        right: -60,
        child: Container(
          width: 220,
          height: 220,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                const Color(0xFF4F6EF7).withOpacity(0.05),
                Colors.transparent,
              ],
            ),
          ),
        ).animate().fadeIn(duration: 1200.ms),
      ),
      Positioned(
        bottom: size.height * 0.3,
        left: -70,
        child: Container(
          width: 180,
          height: 180,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                const Color(0xFF00FF88).withOpacity(0.04),
                Colors.transparent,
              ],
            ),
          ),
        ).animate().fadeIn(delay: 400.ms, duration: 1200.ms),
      ),
    ];
  }

  // ═══════════════════════════════════════════
  // 🎯 TOP BAR
  // ═══════════════════════════════════════════
  Widget _buildTopBar(dynamic audio) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF111631).withOpacity(0.6),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withOpacity(0.06),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Back button
          GestureDetector(
            onTap: () {
              audio.playClick();
              Navigator.pop(context);
            },
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.04),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withOpacity(0.08),
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white.withOpacity(0.5),
                size: 18,
              ),
            ),
          ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.3, end: 0),

          const SizedBox(width: 14),

          // Title block
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [Color(0xFFFFFFFF), Color(0xFFCCE5D9)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ).createShader(bounds),
                child: Text(
                  'SETTINGS',
                  style: GoogleFonts.rajdhani(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 4,
                    height: 1,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Customize your experience',
                style: GoogleFonts.rajdhani(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withOpacity(0.28),
                  letterSpacing: 1,
                ),
              ),
            ],
          ).animate().fadeIn(delay: 100.ms, duration: 400.ms),

          const Spacer(),

          // Settings badge
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFF00FF88)
                      .withOpacity(0.06 + 0.04 * _pulseAnimation.value),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF00FF88).withOpacity(
                        0.15 + 0.1 * _pulseAnimation.value),
                    width: 1,
                  ),
                ),
                child: const Icon(
                  Icons.tune_rounded,
                  color: Color(0xFF00FF88),
                  size: 20,
                ),
              );
            },
          ).animate().fadeIn(duration: 400.ms).slideX(begin: 0.3, end: 0),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.15, end: 0);
  }

  // ═══════════════════════════════════════════
  // 📌 SECTION HEADER
  // ═══════════════════════════════════════════
  Widget _buildSectionHeader({
    required IconData icon,
    required String label,
    required Color color,
    required int delay,
  }) {
    return Row(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(9),
            color: color.withOpacity(0.1),
            border: Border.all(
              color: color.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: GoogleFonts.rajdhani(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: color.withOpacity(0.75),
            letterSpacing: 3,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color.withOpacity(0.18),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    )
        .animate()
        .fadeIn(delay: Duration(milliseconds: delay), duration: 400.ms)
        .slideX(begin: -0.12, end: 0);
  }

  // ═══════════════════════════════════════════
  // 🃏 HUD CARD
  // ═══════════════════════════════════════════
  Widget _buildHudCard({
    required int delay,
    required Color accentColor,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF111631).withOpacity(0.55),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withOpacity(0.055),
          width: 1,
        ),
      ),
      child: Stack(
        children: [
          // Left accent bar
          Positioned(
            left: 0,
            top: 16,
            bottom: 16,
            child: Container(
              width: 2,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(18),
                ),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    accentColor.withOpacity(0.5),
                    accentColor.withOpacity(0.1),
                  ],
                ),
              ),
            ),
          ),

          // Top-right corner bracket
          Positioned(
            top: 0,
            right: 0,
            child: SizedBox(
              width: 20,
              height: 20,
              child: CustomPaint(
                painter: _CardBracketPainter(
                  color: accentColor.withOpacity(0.18),
                ),
              ),
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 16, 4),
            child: child,
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: Duration(milliseconds: delay), duration: 500.ms)
        .slideY(begin: 0.08, end: 0, curve: Curves.easeOut);
  }

  Widget _buildHudDivider(Color color) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      height: 1,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            color.withOpacity(0.1),
            Colors.transparent,
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════
  // 🎨 THEME SETTING
  // ═══════════════════════════════════════════
  Widget _buildThemeSetting(dynamic storage, dynamic audio) {
    final currentId = storage.getGameThemeId();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.style_rounded,
                color: Colors.white.withOpacity(0.35),
                size: 17,
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Theme',
                    style: GoogleFonts.rajdhani(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Colors.white.withOpacity(0.82),
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text(
                    'Snake color & arena background',
                    style: GoogleFonts.rajdhani(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withOpacity(0.28),
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: GameThemes.all.map((theme) {
              final isSelected = currentId == theme.id;
              final isLast = theme == GameThemes.all.last;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: isLast ? 0 : 8),
                  child: _buildThemeCard(
                    theme: theme,
                    isSelected: isSelected,
                    onTap: () {
                      audio.playClick();
                      storage.saveGameTheme(theme.id);
                      setState(() {});
                    },
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeCard({
    required GameThemeData theme,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? theme.snakeColor.withOpacity(0.65)
                : Colors.white.withOpacity(0.06),
            width: isSelected ? 1.5 : 1,
          ),
          color: isSelected
              ? theme.snakeColor.withOpacity(0.07)
              : Colors.white.withOpacity(0.02),
          boxShadow: isSelected
              ? [
            BoxShadow(
              color: theme.snakeColor.withOpacity(0.18),
              blurRadius: 16,
            ),
          ]
              : null,
        ),
        child: Column(
          children: [
            // ── Preview ──
            ClipRRect(
              borderRadius:
              const BorderRadius.vertical(top: Radius.circular(13)),
              child: Container(
                height: 60,
                color: theme.bgColor,
                child: Stack(
                  children: [
                    CustomPaint(
                      size: const Size(double.infinity, 60),
                      painter: _MiniHexGridPainter(),
                    ),
                    Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(4, (i) {
                          final opacity = 1.0 - i * 0.18;
                          final isHead = i == 0;
                          return Container(
                            margin:
                            const EdgeInsets.symmetric(horizontal: 2),
                            width: isHead ? 14 : 11,
                            height: isHead ? 14 : 11,
                            decoration: BoxDecoration(
                              color: theme.snakeColor.withOpacity(opacity),
                              borderRadius:
                              BorderRadius.circular(isHead ? 3 : 2),
                              boxShadow: isHead
                                  ? [
                                BoxShadow(
                                  color: theme.snakeColor
                                      .withOpacity(0.5),
                                  blurRadius: 10,
                                ),
                              ]
                                  : null,
                            ),
                          );
                        }),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Label ──
            Padding(
              padding:
              const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
              child: Column(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    width: 16,
                    height: 16,
                    margin: const EdgeInsets.only(bottom: 4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected
                          ? theme.snakeColor
                          : Colors.transparent,
                      border: Border.all(
                        color: isSelected
                            ? theme.snakeColor
                            : Colors.white.withOpacity(0.12),
                        width: 1.5,
                      ),
                    ),
                    child: isSelected
                        ? const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 10,
                    )
                        : null,
                  ),
                  Text(
                    theme.name,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.rajdhani(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: isSelected
                          ? theme.snakeColor
                          : Colors.white.withOpacity(0.35),
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════
  // ⚡ SPEED SETTING
  // ═══════════════════════════════════════════
  Widget _buildSpeedSetting(dynamic storage, dynamic audio) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.speed_rounded,
                color: Colors.white.withOpacity(0.35),
                size: 17,
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Game Speed',
                    style: GoogleFonts.rajdhani(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Colors.white.withOpacity(0.82),
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text(
                    'Control how fast the snake moves',
                    style: GoogleFonts.rajdhani(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withOpacity(0.28),
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _buildSpeedChip(
                label: 'SLOW',
                icon: Icons.directions_walk_rounded,
                sublabel: 'CASUAL',
                value: AppConstants.slowSnakeSpeed,
                color: const Color(0xFF00C9A7),
                storage: storage,
                audio: audio,
              ),
              const SizedBox(width: 8),
              _buildSpeedChip(
                label: 'NORMAL',
                icon: Icons.directions_run_rounded,
                sublabel: 'BALANCED',
                value: AppConstants.defaultSnakeSpeed,
                color: const Color(0xFFFFD166),
                storage: storage,
                audio: audio,
              ),
              const SizedBox(width: 8),
              _buildSpeedChip(
                label: 'FAST',
                icon: Icons.bolt_rounded,
                sublabel: 'EXPERT',
                value: AppConstants.fastSnakeSpeed,
                color: const Color(0xFFFF6B6B),
                storage: storage,
                audio: audio,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSpeedChip({
    required String label,
    required String sublabel,
    required IconData icon,
    required double value,
    required Color color,
    required dynamic storage,
    required dynamic audio,
  }) {
    final isSelected = _speed == value;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          audio.playClick();
          storage.saveGameSpeed(value);
          setState(() => _speed = value);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? color.withOpacity(0.12)
                : Colors.white.withOpacity(0.03),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected
                  ? color.withOpacity(0.45)
                  : Colors.white.withOpacity(0.06),
              width: isSelected ? 1.5 : 1,
            ),
            boxShadow: isSelected
                ? [
              BoxShadow(
                color: color.withOpacity(0.15),
                blurRadius: 14,
              ),
            ]
                : null,
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected
                    ? color
                    : Colors.white.withOpacity(0.25),
                size: 22,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: GoogleFonts.rajdhani(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: isSelected
                      ? color
                      : Colors.white.withOpacity(0.28),
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                sublabel,
                style: GoogleFonts.rajdhani(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: isSelected
                      ? color.withOpacity(0.6)
                      : Colors.white.withOpacity(0.15),
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════
  // 🔧 TOGGLE ROW
  // ═══════════════════════════════════════════
  Widget _buildToggleRow({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required bool value,
    required Color activeColor,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 13),
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(11),
              color: iconColor.withOpacity(value ? 0.14 : 0.04),
              border: Border.all(
                color: iconColor.withOpacity(value ? 0.25 : 0.08),
                width: 1,
              ),
            ),
            child: Icon(
              icon,
              color: value ? iconColor : Colors.white.withOpacity(0.25),
              size: 18,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.rajdhani(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Colors.white.withOpacity(0.82),
                    letterSpacing: 0.3,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.rajdhani(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withOpacity(0.28),
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => onChanged(!value),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 54,
              height: 30,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                color: value
                    ? activeColor.withOpacity(0.18)
                    : Colors.white.withOpacity(0.05),
                border: Border.all(
                  color: value
                      ? activeColor.withOpacity(0.45)
                      : Colors.white.withOpacity(0.08),
                  width: 1,
                ),
                boxShadow: value
                    ? [
                  BoxShadow(
                    color: activeColor.withOpacity(0.15),
                    blurRadius: 10,
                  ),
                ]
                    : null,
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                alignment:
                value ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: value
                        ? activeColor
                        : Colors.white.withOpacity(0.22),
                    boxShadow: value
                        ? [
                      BoxShadow(
                        color: activeColor.withOpacity(0.4),
                        blurRadius: 8,
                      ),
                    ]
                        : null,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════
  // 💾 SAVE BUTTON
  // ═══════════════════════════════════════════
  Widget _buildSaveButton(dynamic audio) {
    return GestureDetector(
      onTap: () {
        audio.playClick();
        Navigator.pop(context);
      },
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
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    color: Color(0xFF0A0E21),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'SAVE & EXIT',
                  style: GoogleFonts.rajdhani(
                    fontSize: 18,
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
        .fadeIn(delay: 700.ms, duration: 500.ms)
        .slideY(begin: 0.2, end: 0, curve: Curves.easeOut)
        .then(delay: 200.ms)
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .scale(
      begin: const Offset(1.0, 1.0),
      end: const Offset(1.015, 1.015),
      duration: 2200.ms,
    );
  }

  // ═══════════════════════════════════════════
  // 🗑️ RESET OPTION
  // ═══════════════════════════════════════════
  Widget _buildResetOption(dynamic storage, dynamic audio) {
    return Center(
      child: GestureDetector(
        onTap: () => _showResetDialog(storage, audio),
        child: Container(
          padding:
          const EdgeInsets.symmetric(horizontal: 22, vertical: 11),
          decoration: BoxDecoration(
            color: const Color(0xFFFF6B6B).withOpacity(0.04),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: const Color(0xFFFF6B6B).withOpacity(0.14),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.restart_alt_rounded,
                color: const Color(0xFFFF6B6B).withOpacity(0.55),
                size: 17,
              ),
              const SizedBox(width: 8),
              Text(
                'RESET TO DEFAULTS',
                style: GoogleFonts.rajdhani(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFFFF6B6B).withOpacity(0.55),
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: 850.ms, duration: 400.ms);
  }

  // ═══════════════════════════════════════════
  // 🗑️ RESET DIALOG
  // ═══════════════════════════════════════════
  void _showResetDialog(dynamic storage, dynamic audio) {
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
                  child: CustomPaint(
                    painter: _DialogCornerPainter(),
                  ),
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
                        color:
                        const Color(0xFFFF6B6B).withOpacity(0.28),
                        width: 1.5,
                      ),
                    ),
                    child: const Icon(
                      Icons.restart_alt_rounded,
                      color: Color(0xFFFF6B6B),
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'RESET SETTINGS?',
                    style: GoogleFonts.rajdhani(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'All settings will be restored\nto their defaults.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.rajdhani(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withOpacity(0.35),
                      letterSpacing: 0.5,
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
                          },
                          child: Container(
                            padding:
                            const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.04),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.09),
                                width: 1,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                'CANCEL',
                                style: GoogleFonts.rajdhani(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color:
                                  Colors.white.withOpacity(0.45),
                                  letterSpacing: 2,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            audio.playClick();
                            storage.saveGameTheme(
                                GameThemes.defaultThemeId);
                            storage.saveGameSpeed(
                                AppConstants.defaultSnakeSpeed);
                            storage.saveSoundEnabled(true);
                            storage.saveVibrationEnabled(true);
                            setState(() {
                              _speed = AppConstants.defaultSnakeSpeed;
                              _sound = true;
                              _vibration = true;
                            });
                            Navigator.pop(ctx);
                          },
                          child: Container(
                            padding:
                            const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFFFF6B6B),
                                  Color(0xFFFF4D4D),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFFF6B6B)
                                      .withOpacity(0.3),
                                  blurRadius: 14,
                                ),
                              ],
                            ),
                            child: Stack(
                              children: [
                                Positioned.fill(
                                  child: ClipRRect(
                                    borderRadius:
                                    BorderRadius.circular(14),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [
                                            Colors.white
                                                .withOpacity(0.12),
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
                                    'RESET',
                                    style: GoogleFonts.rajdhani(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                      letterSpacing: 2,
                                    ),
                                  ),
                                ),
                              ],
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
      ..color = Colors.black.withOpacity(0.032)
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
      ..color = const Color(0xFF00FF88).withOpacity(0.07)
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
      ..color = const Color(0xFF00FF88).withOpacity(0.14)
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

// ═══════════════════════════════════════════
// ⬡ MINI HEX GRID (theme card preview)
// ═══════════════════════════════════════════
class _MiniHexGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.04)
      ..strokeWidth = 0.4
      ..style = PaintingStyle.stroke;

    const hexSize = 10.0;
    final w = hexSize * 1.732;
    final h = hexSize * 2;

    for (double row = -1; row * h * 0.75 < size.height + h; row++) {
      for (double col = -1; col * w < size.width + w; col++) {
        final offset = (row % 2 == 0) ? 0.0 : w / 2;
        final path = Path();
        for (int i = 0; i < 6; i++) {
          final angle = (pi / 180) * (60 * i - 30);
          final x = col * w + offset + hexSize * cos(angle);
          final y = row * h * 0.75 + hexSize * sin(angle);
          i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
        }
        path.close();
        canvas.drawPath(path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}