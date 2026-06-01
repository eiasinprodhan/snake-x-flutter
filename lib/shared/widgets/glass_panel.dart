// glass_panel.dart
import 'package:flutter/material.dart';
import 'package:glassmorphism/glassmorphism.dart';
import '../../shared/themes/app_theme.dart';
import '../../core/constants/app_constants.dart';

class GlassPanel extends StatelessWidget {
  final Widget child;
  final double blur;
  final double opacity;
  final EdgeInsetsGeometry padding;

  const GlassPanel({
    super.key,
    required this.child,
    this.blur = 18,
    this.opacity = 0.08,
    this.padding = const EdgeInsets.all(20),
  });

  @override
  Widget build(BuildContext context) {
    return GlassmorphicContainer(
      width: double.infinity,
      height: double.infinity,
      borderRadius: AppConstants.borderRadiusLarge,
      blur: blur,
      alignment: Alignment.center,
      border: 1.5,
      linearGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withOpacity(opacity),
          Colors.white.withOpacity(0.02),
        ],
      ),
      borderGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppTheme.gameGreen.withOpacity(0.3),
          AppTheme.gameBlue.withOpacity(0.15),
          AppTheme.gamePurple.withOpacity(0.2),
        ],
      ),
      child: Padding(
        padding: padding,
        child: child,
      ),
    );
  }
}