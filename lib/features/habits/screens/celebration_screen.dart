import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_theme.dart';

class CelebrationScreen extends StatelessWidget {
  final int streak;

  const CelebrationScreen({super.key, required this.streak});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
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
                  decoration: const BoxDecoration(
                    color: Color(0xFFEAF8F1),
                    shape: BoxShape.circle,
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        color: AppTheme.checkGreen,
                        size: 96,
                      ).animate().scale(
                            duration: 600.ms,
                            curve: Curves.elasticOut,
                          ),
                      // Decorative sparks around the star
                      _buildSpark(const Offset(-50, -45), -0.7),
                      _buildSpark(const Offset(50, -45), 0.7),
                      _buildSpark(const Offset(-65, 10), -1.4),
                      _buildSpark(const Offset(65, 10), 1.4),
                      _buildSpark(const Offset(-35, 60), -2.2),
                      _buildSpark(const Offset(35, 60), 2.2),
                    ],
                  ),
                ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.8, 0.8)),
              ),
              const SizedBox(height: 32),
              
              const Text(
                'Done! Great job.',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textColor,
                  fontFamily: 'Inter',
                  letterSpacing: -0.5,
                ),
              ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0),
              
              const SizedBox(height: 12),
              
              const Text(
                'Every single task counts —\neven the small ones.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textVariantColor,
                  fontFamily: 'Inter',
                  height: 1.4,
                ),
              ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2, end: 0),
              
              const SizedBox(height: 24),
              
              // Dopamine Points Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: AppTheme.checkGreen,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.checkGreen.withValues(alpha: 0.3),
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
                  color: const Color(0xFFEAF8F1),
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
                            const Text(
                              '🔥',
                              style: TextStyle(fontSize: 32),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '$streak days',
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.checkGreen,
                                fontFamily: 'Inter',
                                letterSpacing: -1,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'You\'re building something amazing.\nProud of you!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF2C4336),
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
                    foregroundColor: AppTheme.textColor,
                    side: BorderSide(color: AppTheme.outlineVariantColor, width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                  ),
                ),
              ).animate().fadeIn(delay: 600.ms),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSpark(Offset offset, double angle) {
    return Transform.translate(
      offset: offset,
      child: Transform.rotate(
        angle: angle,
        child: Container(
          width: 4,
          height: 12,
          decoration: BoxDecoration(
            color: AppTheme.checkGreen,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }
}
