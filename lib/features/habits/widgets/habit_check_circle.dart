import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

/// Habit check-off circle. Gray stroke when pending; on completion the ring
/// scales 1.0 -> 0.8 -> 1.1 -> 1.0 over 200ms while filling from white to
/// mint green with a white checkmark fading in. Pure Flutter animation
/// (AnimationController/TweenSequence) — no third-party animation packages.
class HabitCheckCircle extends StatefulWidget {
  final bool isCompleted;
  final double size;

  const HabitCheckCircle({
    super.key,
    required this.isCompleted,
    this.size = 32,
  });

  @override
  State<HabitCheckCircle> createState() => _HabitCheckCircleState();
}

class _HabitCheckCircleState extends State<HabitCheckCircle> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
      value: widget.isCompleted ? 1.0 : 0.0,
    );
    _scale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.8).chain(CurveTween(curve: Curves.easeOut)), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0.8, end: 1.1).chain(CurveTween(curve: Curves.easeOut)), weight: 45),
      TweenSequenceItem(tween: Tween(begin: 1.1, end: 1.0).chain(CurveTween(curve: Curves.easeIn)), weight: 25),
    ]).animate(_controller);
  }

  @override
  void didUpdateWidget(covariant HabitCheckCircle oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isCompleted != oldWidget.isCompleted) {
      widget.isCompleted ? _controller.forward(from: 0) : _controller.reverse(from: 1);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;
        final fillColor = Color.lerp(context.colors.surface, context.colors.success, t)!;
        final borderColor = Color.lerp(context.colors.outlineVariant, context.colors.success, t)!;
        return Transform.scale(
          scale: _scale.value,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              color: fillColor,
              shape: BoxShape.circle,
              border: Border.all(color: borderColor, width: 2),
            ),
            child: t > 0
                ? Center(
                    child: Opacity(
                      opacity: t,
                      child: Icon(Icons.check, color: Colors.white, size: widget.size * 0.6),
                    ),
                  )
                : null,
          ),
        );
      },
    );
  }
}
