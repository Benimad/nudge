import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/brain_mascot.dart';

/// Branded launch experience shown on every cold start, before routing to
/// onboarding or home. Pure Flutter animation (CustomPainter + flutter_animate,
/// same technique as [BrainMascot]) — no Lottie asset needed, so it adds zero
/// weight and works fully offline.
///
/// Sequence: ambient aura fades up → glow ripples pulse behind the mascot →
/// mascot pops in and floats while sparkles orbit → gradient wordmark and
/// tagline rise in with a shimmer sweep → whole scene scales up and fades out
/// into the first route.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _orbit;
  bool _exiting = false;

  @override
  void initState() {
    super.initState();
    _orbit = AnimationController(vsync: this, duration: const Duration(seconds: 7))..repeat();
    _start();
  }

  Future<void> _start() async {
    final prefs = await SharedPreferences.getInstance();
    // Sensory-safe UI keeps the splash short and calm instead of skipping it
    // outright, so launch still feels intentional rather than glitchy.
    final reduce = prefs.getBool('sensory_safe_ui') ?? false;
    final next = (prefs.getBool('onboarding_complete') ?? false) ? '/home' : '/onboarding/welcome';

    await Future.delayed(Duration(milliseconds: reduce ? 1000 : 2500));
    if (!mounted) return;
    setState(() => _exiting = true);
    await Future.delayed(const Duration(milliseconds: 430));
    if (!mounted) return;
    Get.offAllNamed(next);
  }

  @override
  void dispose() {
    _orbit.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.background,
      body: AnimatedOpacity(
        opacity: _exiting ? 0 : 1,
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOut,
        child: AnimatedScale(
          scale: _exiting ? 1.08 : 1,
          duration: const Duration(milliseconds: 420),
          curve: Curves.easeIn,
          child: Stack(
            children: [
              // Ambient aura — two soft color fields drifting behind everything.
              _AuraBlob(
                color: colors.primary,
                size: 380,
                alignment: const Alignment(-1.3, -0.9),
                drift: const Offset(30, 24),
              ),
              _AuraBlob(
                color: colors.success,
                size: 340,
                alignment: const Alignment(1.3, 1.0),
                drift: const Offset(-26, -30),
              ),

              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 260,
                      height: 260,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Expanding glow ripples behind the mascot.
                          for (final delay in [0, 900]) _GlowRipple(color: colors.primary, delay: delay),

                          // Soft steady halo so the mascot sits in light.
                          Container(
                            width: 220,
                            height: 220,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  colors.primary.withValues(alpha: 0.16),
                                  colors.primary.withValues(alpha: 0.0),
                                ],
                              ),
                            ),
                          ).animate().fadeIn(duration: 900.ms, curve: Curves.easeOut),

                          // Orbiting sparkles.
                          AnimatedBuilder(
                            animation: _orbit,
                            builder: (context, _) => CustomPaint(
                              size: const Size(250, 250),
                              painter: _SparkleOrbitPainter(
                                progress: _orbit.value,
                                primary: colors.primary,
                                accent: colors.success,
                              ),
                            ),
                          ).animate().fadeIn(duration: 700.ms, delay: 500.ms),

                          // The mascot itself — elastic pop, then a gentle float.
                          const BrainMascot(size: 150)
                              .animate()
                              .scale(
                                begin: const Offset(0.4, 0.4),
                                end: const Offset(1, 1),
                                duration: 850.ms,
                                curve: Curves.elasticOut,
                              )
                              .then()
                              .animate(onPlay: (c) => c.repeat(reverse: true))
                              .moveY(begin: 0, end: -7, duration: 2000.ms, curve: Curves.easeInOut),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Gradient wordmark with a shimmer sweep.
                    ShaderMask(
                      shaderCallback: (bounds) => AppTheme.textGradient.createShader(bounds),
                      child: const Text(
                        'Nudge',
                        style: TextStyle(
                          fontSize: 46,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          fontFamily: 'Inter',
                          letterSpacing: -1,
                          height: 1.1,
                        ),
                      ),
                    )
                        .animate()
                        .fadeIn(duration: 500.ms, delay: 550.ms)
                        .slideY(begin: 0.35, end: 0, curve: Curves.easeOutCubic)
                        .then(delay: 500.ms)
                        .shimmer(duration: 1100.ms, color: Colors.white.withValues(alpha: 0.55)),
                    const SizedBox(height: 10),

                    Text(
                      'Gentle habits for real brains',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: colors.textVariant,
                        fontFamily: 'Inter',
                      ),
                    )
                        .animate()
                        .fadeIn(duration: 500.ms, delay: 750.ms)
                        .slideY(begin: 0.4, end: 0, curve: Curves.easeOutCubic),
                  ],
                ),
              ),

              // Breathing loader dots pinned near the bottom.
              Align(
                alignment: const Alignment(0, 0.86),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(3, (i) {
                    return Container(
                      width: 9,
                      height: 9,
                      margin: const EdgeInsets.symmetric(horizontal: 5),
                      decoration: BoxDecoration(color: colors.primary, shape: BoxShape.circle),
                    )
                        .animate(onPlay: (c) => c.repeat(reverse: true))
                        .scaleXY(begin: 0.55, end: 1, duration: 600.ms, delay: (i * 180).ms, curve: Curves.easeInOut)
                        .fade(begin: 0.35, end: 1);
                  }),
                ).animate().fadeIn(duration: 400.ms, delay: 1000.ms),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Large, very soft radial color field that drifts slowly — reads as premium
/// ambient light rather than a flat background.
class _AuraBlob extends StatelessWidget {
  final Color color;
  final double size;
  final Alignment alignment;
  final Offset drift;

  const _AuraBlob({
    required this.color,
    required this.size,
    required this.alignment,
    required this.drift,
  });

  @override
  Widget build(BuildContext context) {
    final alpha = context.isDarkTheme ? 0.14 : 0.10;
    return Align(
      alignment: alignment,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color.withValues(alpha: alpha), color.withValues(alpha: 0.0)],
          ),
        ),
      )
          .animate()
          .fadeIn(duration: 1200.ms, curve: Curves.easeOut)
          .then()
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .move(begin: Offset.zero, end: drift, duration: 3200.ms, curve: Curves.easeInOut),
    );
  }
}

/// One expanding, fading ring — two of these offset in time read as a calm
/// radar-style pulse behind the mascot.
class _GlowRipple extends StatelessWidget {
  final Color color;
  final int delay;

  const _GlowRipple({required this.color, required this.delay});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 170,
      height: 170,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color.withValues(alpha: 0.35), width: 1.5),
      ),
    )
        .animate(onPlay: (c) => c.repeat())
        .scale(
          begin: const Offset(0.75, 0.75),
          end: const Offset(1.5, 1.5),
          duration: 1800.ms,
          delay: delay.ms,
          curve: Curves.easeOut,
        )
        .fadeOut(duration: 1800.ms, delay: delay.ms, curve: Curves.easeIn);
  }
}

/// Sparkles orbiting the mascot: alternating dots and 4-point stars whose
/// brightness breathes as they travel, on two slightly elliptical rings.
class _SparkleOrbitPainter extends CustomPainter {
  final double progress;
  final Color primary;
  final Color accent;

  _SparkleOrbitPainter({required this.progress, required this.primary, required this.accent});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    const count = 8;
    final angleBase = progress * 2 * math.pi;

    for (int i = 0; i < count; i++) {
      final angle = angleBase + i * 2 * math.pi / count;
      // Alternate between an inner and outer ring, slightly elliptical.
      final inner = i.isEven;
      final rx = inner ? 92.0 : 118.0;
      final ry = inner ? 84.0 : 108.0;
      final pos = center + Offset(math.cos(angle) * rx, math.sin(angle) * ry);

      // Breathe: each sparkle brightens/shrinks on its own phase.
      final pulse = 0.5 + 0.5 * math.sin(angle * 2 + i);
      final color = (i % 3 == 0 ? accent : primary).withValues(alpha: 0.25 + 0.45 * pulse);
      final radius = 1.8 + 1.9 * pulse;

      final paint = Paint()..color = color;
      if (i % 4 == 0) {
        _drawStar(canvas, pos, radius * 2.1, paint);
      } else {
        canvas.drawCircle(pos, radius, paint);
      }
    }
  }

  /// Minimal 4-point "sparkle" star.
  void _drawStar(Canvas canvas, Offset c, double r, Paint paint) {
    final path = Path()
      ..moveTo(c.dx, c.dy - r)
      ..quadraticBezierTo(c.dx, c.dy, c.dx + r, c.dy)
      ..quadraticBezierTo(c.dx, c.dy, c.dx, c.dy + r)
      ..quadraticBezierTo(c.dx, c.dy, c.dx - r, c.dy)
      ..quadraticBezierTo(c.dx, c.dy, c.dx, c.dy - r)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SparkleOrbitPainter old) =>
      old.progress != progress || old.primary != primary || old.accent != accent;
}
