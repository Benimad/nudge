import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../controllers/home_controller.dart';
import '../../../core/theme/app_theme.dart';
import 'package:intl/intl.dart';

class ProgressHeader extends StatelessWidget {
  const ProgressHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final HomeController controller = Get.find<HomeController>();
    final String dateStr = DateFormat('EEEE, MMMM d').format(DateTime.now());

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${controller.greeting}! 👋',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: context.colors.text,
                        letterSpacing: -0.5,
                        fontFamily: 'Inter',
                      ),
                    ).animate().fadeIn(duration: 450.ms).slideY(begin: 0.2, end: 0, curve: Curves.easeOutCubic),
                    const SizedBox(height: 6),
                    Obx(() => Text(
                          '$dateStr • ${controller.habits.length} habit${controller.habits.length == 1 ? '' : 's'}',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: context.colors.textVariant,
                            fontFamily: 'Inter',
                          ),
                        )).animate().fadeIn(duration: 450.ms, delay: 100.ms),
                  ],
                ),
              ),
              const _NotificationBell()
                  .animate()
                  .fadeIn(duration: 400.ms, delay: 150.ms)
                  .scale(begin: const Offset(0.7, 0.7), curve: Curves.easeOutBack),
            ],
          ),
          const SizedBox(height: 20),

          // Today's progress card — title, green bar, green percentage.
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: context.colors.surface,
              borderRadius: BorderRadius.circular(20),
              boxShadow: context.colors.cardShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Today's progress",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: context.colors.text,
                    fontFamily: 'Inter',
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Obx(() => TweenAnimationBuilder<double>(
                              duration: const Duration(milliseconds: 800),
                              curve: Curves.easeOutCubic,
                              tween: Tween<double>(begin: 0, end: controller.todayProgress.value),
                              builder: (context, value, _) {
                                return LinearProgressIndicator(
                                  value: value,
                                  minHeight: 10,
                                  backgroundColor: context.colors.divider,
                                  valueColor: AlwaysStoppedAnimation<Color>(context.colors.success),
                                );
                              },
                            )),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Obx(() => Text(
                          '${(controller.todayProgress.value * 100).toInt()}%',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: context.colors.success,
                            fontFamily: 'Inter',
                          ),
                        )),
                  ],
                ),
              ],
            ),
          ).animate().fadeIn(duration: 500.ms, delay: 200.ms).slideY(begin: 0.15, end: 0, curve: Curves.easeOutCubic),
        ],
      ),
    );
  }
}

class _NotificationBell extends StatelessWidget {
  const _NotificationBell();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Get.snackbar(
        'No new notifications',
        "You're all caught up.",
        snackPosition: SnackPosition.BOTTOM,
      ),
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: context.colors.surface,
          shape: BoxShape.circle,
          boxShadow: context.colors.cardShadow,
        ),
        child: Stack(
          children: [
            Center(
              child: Icon(Icons.notifications_none_rounded, color: context.colors.text, size: 24),
            ),
            Positioned(
              top: 10,
              right: 11,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: context.colors.primary, shape: BoxShape.circle),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
