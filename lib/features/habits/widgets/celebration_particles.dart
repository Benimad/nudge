import 'dart:math';
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

/// 8 particles (6px circles, purple/mint/amber/coral) exploding outward from
/// center over 400ms, fading out in the last 100ms. Pure CustomPainter driven
/// by an externally-owned AnimationController — no third-party packages.
class CelebrationParticles extends StatelessWidget {
  final Animation<double> animation;
  final double size;

  const CelebrationParticles({super.key, required this.animation, this.size = 160});

  static const List<Color> _colors = [
    AppTheme.primaryColor, // purple
    AppTheme.successColor, // mint green
    AppTheme.warningColor, // amber
    Color(0xFFE76F51), // coral
  ];

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        return CustomPaint(
          size: Size.square(size),
          painter: _ParticleBurstPainter(progress: animation.value, colors: _colors),
        );
      },
    );
  }
}

class _ParticleBurstPainter extends CustomPainter {
  final double progress; // 0.0 -> 1.0 across the 400ms burst
  final List<Color> colors;

  static const int _particleCount = 8;
  static const double _particleDiameter = 6;
  static const double _travelDistance = 70;

  _ParticleBurstPainter({required this.progress, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    // Fade out over the last 100ms of a 400ms burst = last 25% of progress.
    final opacity = progress > 0.75 ? ((1.0 - progress) / 0.25).clamp(0.0, 1.0) : 1.0;
    if (opacity <= 0) return;

    final center = size.center(Offset.zero);
    final distance = Curves.easeOut.transform(progress) * _travelDistance;

    for (int i = 0; i < _particleCount; i++) {
      final angle = (2 * pi / _particleCount) * i;
      final offset = center + Offset(cos(angle), sin(angle)) * distance;
      final paint = Paint()..color = colors[i % colors.length].withValues(alpha: opacity);
      canvas.drawCircle(offset, _particleDiameter / 2, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticleBurstPainter oldDelegate) => oldDelegate.progress != progress;
}
