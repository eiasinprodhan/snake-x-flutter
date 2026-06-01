// neon_button.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../shared/themes/app_theme.dart';

class NeonButton extends StatefulWidget {
  final String text;
  final VoidCallback onPressed;
  final Color color;
  final IconData? icon;

  const NeonButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.color = AppTheme.gameGreen,
    this.icon,
  });

  @override
  State<NeonButton> createState() => _NeonButtonState();
}

class _NeonButtonState extends State<NeonButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onPressed();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18.0, sigmaY: 18.0),
            child: Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              decoration: BoxDecoration(
                color: widget.color.withOpacity(_pressed ? 0.2 : 0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: widget.color.withOpacity(0.25),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: widget.color.withOpacity(0.08),
                    blurRadius: 15,
                    spreadRadius: 1,
                  ),
                  if (_pressed)
                    BoxShadow(
                      color: widget.color.withOpacity(0.2),
                      blurRadius: 25,
                      spreadRadius: 3,
                    ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.icon != null) ...[
                    Icon(widget.icon, color: widget.color, size: 18),
                    const SizedBox(width: 10),
                  ],
                  Text(
                    widget.text,
                    style: GoogleFonts.rajdhani(
                      color: widget.color,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    )
        .animate()
        .scale(duration: 150.ms, curve: Curves.easeOut);
  }
}