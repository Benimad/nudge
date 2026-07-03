import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_theme.dart';
import 'celebration_particles.dart';

class DopamineCelebration {
  static void show(int streak) {
    final messages = _getMessages(streak);
    final title = messages['title']!;
    final subtitle = messages['subtitle']!;

    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 500),
          tween: Tween(begin: 0.0, end: 1.0),
          curve: Curves.elasticOut,
          builder: (context, value, child) {
            return Transform.scale(
              scale: value,
              child: child,
            );
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 160,
                height: 160,
                child: Stack(
                  alignment: Alignment.center,
                  children: const [
                    _CelebrationBurst(),
                    Icon(
                      Icons.star_rounded,
                      color: AppTheme.successColor,
                      size: 120,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontFamily: 'Quicksand',
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.primaryColor,
                    fontFamily: 'Quicksand',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      barrierColor: Colors.black.withValues(alpha: 0.8),
      barrierDismissible: true,
    );

    Future.delayed(const Duration(seconds: 2), () {
      if (Get.isDialogOpen ?? false) {
        Get.back();
      }
    });
  }

  static Map<String, String> _getMessages(int streak) {
    if (streak == 0) {
      return {
        'title': 'First step!',
        'subtitle': '🌱 Fresh start — you got this',
      };
    }
    if (streak == 1) {
      return {
        'title': 'One day down!',
        'subtitle': '🔥 1 day streak — keep it rolling',
      };
    }
    if (streak < 3) {
      return {
        'title': 'Building momentum',
        'subtitle': '🔥 $streak day streak',
      };
    }
    if (streak < 7) {
      return {
        'title': 'You\'re on fire!',
        'subtitle': '🔥 $streak day streak — amazing',
      };
    }
    return {
      'title': 'Unstoppable!',
      'subtitle': '🔥 $streak day streak — legendary',
    };
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
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 400))..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CelebrationParticles(animation: _controller, size: 160);
  }
}
