import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_theme.dart';

/// Shimmering placeholder blocks shown while local data loads. Reads as
/// "content arriving" instead of a spinner's "please wait", and matches the
/// card geometry it replaces so nothing jumps on arrival.
class SkeletonCard extends StatelessWidget {
  final double height;
  final double borderRadius;

  const SkeletonCard({super.key, this.height = 84, this.borderRadius = 18});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: height,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: context.colors.cardShadow,
      ),
      child: Row(
        children: [
          _Block(width: 44, height: 44, shape: BoxShape.circle),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                _Block(width: 160, height: 14),
                SizedBox(height: 10),
                _Block(width: 90, height: 12),
              ],
            ),
          ),
        ],
      ),
    )
        .animate(onPlay: (c) => c.repeat())
        .shimmer(duration: 1400.ms, color: context.colors.background.withValues(alpha: 0.9));
  }
}

/// A list of [count] skeleton cards, for list-shaped loading states.
class SkeletonList extends StatelessWidget {
  final int count;
  final EdgeInsetsGeometry padding;

  const SkeletonList({
    super.key,
    this.count = 3,
    this.padding = const EdgeInsets.fromLTRB(24, 0, 24, 0),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Column(
        children: List.generate(count, (_) => const SkeletonCard()),
      ),
    );
  }
}

class _Block extends StatelessWidget {
  final double width;
  final double height;
  final BoxShape shape;

  const _Block({required this.width, required this.height, this.shape = BoxShape.rectangle});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: context.colors.surfaceContainer,
        shape: shape,
        borderRadius: shape == BoxShape.rectangle ? BorderRadius.circular(6) : null,
      ),
    );
  }
}
