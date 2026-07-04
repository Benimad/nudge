import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_theme.dart';

/// Amber banner that slides down from the top when task paralysis is detected
/// (triggered by HomeController after 35 min of inactivity). Slide + fade are
/// driven by a plain AnimationController — no third-party animation packages.
class ParalysisBanner extends StatefulWidget {
  const ParalysisBanner({super.key});

  @override
  State<ParalysisBanner> createState() => _ParalysisBannerState();
}

class _ParalysisBannerState extends State<ParalysisBanner> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 350));
    _slide = Tween<Offset>(begin: const Offset(0, -1), end: Offset.zero)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slide,
      child: FadeTransition(
        opacity: _controller,
        child: GestureDetector(
          onTap: () => Get.toNamed('/paralysis-mode'),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: context.colors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border(left: BorderSide(color: context.colors.warning, width: 3)),
              boxShadow: [
                BoxShadow(
                  color: context.colors.warning.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                const _PulsingAmberDot(),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Feeling stuck? Let me help',
                    style: TextStyle(fontWeight: FontWeight.w500, color: context.colors.text),
                  ),
                ),
                Icon(Icons.arrow_forward_ios, size: 14, color: context.colors.warning),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PulsingAmberDot extends StatefulWidget {
  const _PulsingAmberDot();

  @override
  State<_PulsingAmberDot> createState() => _PulsingAmberDotState();
}

class _PulsingAmberDotState extends State<_PulsingAmberDot> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.3, end: 1.0).animate(_controller),
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(color: context.colors.warning, shape: BoxShape.circle),
      ),
    );
  }
}
