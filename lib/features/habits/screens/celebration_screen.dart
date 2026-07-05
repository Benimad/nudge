import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_theme.dart';
import '../widgets/celebration_particles.dart';

class CelebrationScreen extends StatelessWidget {
  final int streak;

  const CelebrationScreen({super.key, required this.streak});

  static Map<String, String> _messages(int streak) {
    final rand = Random();
    List<Map<String, String>> variants;
    if (streak == 0) {
      variants = const [
        {'title': 'First step!', 'subtitle': 'Every journey starts with one. Proud of you.'},
        {'title': 'Fresh start!', 'subtitle': "You showed up today. That's the whole game."},
      ];
    } else if (streak == 1) {
      variants = const [
        {'title': 'One day down!', 'subtitle': 'The hardest part is starting — you did it.'},
      ];
    } else if (streak < 7) {
      variants = const [
        {'title': 'Building momentum', 'subtitle': 'Every single task counts — even the small ones.'},
        {'title': 'Keep it rolling', 'subtitle': "Progress isn't a straight line. This still counts."},
      ];
    } else {
      variants = const [
        {'title': 'Unstoppable!', 'subtitle': 'This is who you are now.'},
        {'title': "You're on fire!", 'subtitle': 'Small steps compound. Look at you go.'},
      ];
    }
    return variants[rand.nextInt(variants.length)];
  }

  @override
  Widget build(BuildContext context) {
    final messages = _messages(streak);
    final softMintBg = context.isDarkTheme ? const Color(0xFF16332A) : const Color(0xFFEAF8F1);
    return Scaffold(
      backgroundColor: context.colors.background,
      body: SafeArea(
        // Scroll-safe on short screens (small phones, landscape, split-screen):
        // the column fills the viewport when content fits, scrolls when not.
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
              const Spacer(),
              // Top Star Icon with light green circle
              Center(
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    color: softMintBg,
                    shape: BoxShape.circle,
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      const _CelebrationBurst(),
                      Icon(
                        Icons.star_rounded,
                        color: context.colors.success,
                        size: 96,
                      ).animate().scale(
                            duration: 600.ms,
                            curve: Curves.elasticOut,
                          ),
                      // Decorative sparks around the star
                      _buildSpark(context, const Offset(-50, -45), -0.7),
                      _buildSpark(context, const Offset(50, -45), 0.7),
                      _buildSpark(context, const Offset(-65, 10), -1.4),
                      _buildSpark(context, const Offset(65, 10), 1.4),
                      _buildSpark(context, const Offset(-35, 60), -2.2),
                      _buildSpark(context, const Offset(35, 60), 2.2),
                    ],
                  ),
                ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.8, 0.8)),
              ),
              const SizedBox(height: 32),

              Text(
                messages['title']!,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: context.colors.text,
                  fontFamily: 'Inter',
                  letterSpacing: -0.5,
                ),
              ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0),

              const SizedBox(height: 12),

              Text(
                messages['subtitle']!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: context.colors.textVariant,
                  fontFamily: 'Inter',
                  height: 1.4,
                ),
              ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2, end: 0),
              
              const SizedBox(height: 24),
              
              // Dopamine Points Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: context.colors.success,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: context.colors.success.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.auto_awesome, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text(
                      '+10 dopamine points',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 400.ms).scale(curve: Curves.easeOutBack),
              
              const SizedBox(height: 32),
              
              // Streak Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                decoration: BoxDecoration(
                  color: softMintBg,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Stack(
                  children: [
                    // Decorative corners
                    Positioned(
                      top: 0,
                      left: 0,
                      child: const Icon(Icons.auto_awesome, color: Color(0xFF67C290), size: 24),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: const Icon(Icons.music_note_rounded, color: Color(0xFF67C290), size: 20),
                    ),
                    Positioned(
                      top: 10,
                      right: 10,
                      child: const Icon(Icons.flare, color: Color(0xFF67C290), size: 16),
                    ),
                    Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              streak > 0 ? '🔥' : '✨',
                              style: const TextStyle(fontSize: 32),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              streak > 0 ? '$streak ${streak == 1 ? 'day' : 'days'}' : 'Day one',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w800,
                                color: context.colors.success,
                                fontFamily: 'Inter',
                                letterSpacing: -1,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          streak > 0
                              ? "You're building something amazing.\nProud of you!"
                              : 'Every streak starts somewhere.\nThis is yours.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: context.isDarkTheme ? context.colors.text : const Color(0xFF2C4336),
                            fontFamily: 'Inter',
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.1, end: 0),
              
              const Spacer(),
              
              // Back Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton.icon(
                  onPressed: () => Get.back(),
                  icon: const Icon(Icons.star_border_rounded, size: 22),
                  label: const Text(
                    'Back to habits',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Inter',
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: context.colors.text,
                    side: BorderSide(color: context.colors.outlineVariant, width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                  ),
                ),
              ).animate().fadeIn(delay: 600.ms),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSpark(BuildContext context, Offset offset, double angle) {
    return Transform.translate(
      offset: offset,
      child: Transform.rotate(
        angle: angle,
        child: Container(
          width: 4,
          height: 12,
          decoration: BoxDecoration(
            color: context.colors.success,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }
}

class _CelebrationBurst extends StatefulWidget {
  const _CelebrationBurst();

  @override
  State<_CelebrationBurst> createState() => _CelebrationBurstState();
}

class _CelebrationBurstState extends State<_CelebrationBurst> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 500))..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CelebrationParticles(animation: _controller, size: 220);
  }
}
