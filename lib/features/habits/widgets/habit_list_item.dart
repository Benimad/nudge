import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/habit_model.dart';
import '../controllers/home_controller.dart';
import '../../../core/theme/app_theme.dart';
import 'habit_check_circle.dart';

class HabitListItem extends StatefulWidget {
  final HabitModel habit;
  final int index;

  const HabitListItem({super.key, required this.habit, this.index = 0});

  @override
  State<HabitListItem> createState() => _HabitListItemState();
}

class _HabitListItemState extends State<HabitListItem> {
  bool _isPressed = false;

  String _streakLabel(int streak, DateTime createdAt) {
    if (streak > 0) return '🔥 $streak days';
    final isBrandNew = DateTime.now().difference(createdAt).inDays < 1;
    return isBrandNew ? 'New habit' : 'Yesterday missed · no shame';
  }

  @override
  Widget build(BuildContext context) {
    final HomeController controller = Get.find<HomeController>();

    return RepaintBoundary(
      child: Obx(() {
        final bool isCompleted = controller.isCompleted(widget.habit.id);

        return GestureDetector(
          onTapDown: (_) => setState(() => _isPressed = true),
          onTapUp: (_) => setState(() => _isPressed = false),
          onTapCancel: () => setState(() => _isPressed = false),
          onTap: () => controller.toggleHabit(widget.habit),
          child: AnimatedScale(
            scale: _isPressed ? 0.97 : 1.0,
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOutCubic,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              decoration: BoxDecoration(
                color: isCompleted ? AppTheme.completedCardColor : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: isCompleted ? [] : AppTheme.cardShadow,
              ),
              child: Row(
                children: [
                  HabitCheckCircle(isCompleted: isCompleted, size: 44),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 300),
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.2,
                            color: isCompleted ? AppTheme.outlineColor : AppTheme.textColor,
                            decoration: isCompleted ? TextDecoration.lineThrough : TextDecoration.none,
                            decorationColor: AppTheme.outlineColor,
                            decorationThickness: 1.6,
                            fontFamily: 'Inter',
                          ),
                          child: Text(widget.habit.name),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          _streakLabel(controller.getStreak(widget.habit.id), widget.habit.createdAt),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.textVariantColor,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.chevron_right_rounded, color: Color(0xFFB9B9C0), size: 26),
                ],
              ),
            ),
          ),
        )
            .animate()
            .fadeIn(duration: 400.ms, delay: (300 + widget.index * 80).ms)
            .slideY(begin: 0.25, end: 0, curve: Curves.easeOutCubic);
      }),
    );
  }
}
