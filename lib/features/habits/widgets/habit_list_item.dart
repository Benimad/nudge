import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/habit_model.dart';
import '../controllers/home_controller.dart';
import '../../../core/theme/app_theme.dart';
import 'add_habit_sheet.dart';
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

  void _openEditSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddHabitSheet(habit: widget.habit),
    );
  }

  String _streakLabel(int streak, DateTime createdAt) {
    if (streak > 0) return '🔥 $streak ${streak == 1 ? 'day' : 'days'}';
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
          // Long-press opens edit — tap stays reserved for the core
          // one-touch completion loop.
          onLongPress: () {
            HapticFeedback.selectionClick();
            _openEditSheet(context);
          },
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
                color: isCompleted ? context.colors.completedCard : context.colors.surface,
                borderRadius: BorderRadius.circular(20),
                boxShadow: isCompleted ? [] : context.colors.cardShadow,
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
                            color: isCompleted ? context.colors.outline : context.colors.text,
                            decoration: isCompleted ? TextDecoration.lineThrough : TextDecoration.none,
                            decorationColor: context.colors.outline,
                            decorationThickness: 1.6,
                            fontFamily: 'Inter',
                          ),
                          child: Text(widget.habit.name),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          _streakLabel(controller.getStreak(widget.habit.id), widget.habit.createdAt),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: context.colors.textVariant,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _openEditSheet(context),
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: Icon(Icons.chevron_right_rounded, color: context.colors.outlineVariant, size: 26),
                    ),
                  ),
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
