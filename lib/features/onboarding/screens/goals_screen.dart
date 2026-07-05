import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/brain_mascot.dart';

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  final Set<String> _selectedGoals = {};

  static const List<Map<String, dynamic>> _goals = [
    {'title': 'Build daily routines', 'icon': Icons.calendar_month_outlined},
    {'title': 'Manage task paralysis', 'icon': Icons.assignment_outlined},
    {'title': 'Improve focus sessions', 'icon': Icons.gps_fixed_rounded},
    {'title': 'Track medications', 'icon': Icons.medication_outlined},
    {'title': 'Reduce overwhelm', 'icon': Icons.gesture_rounded},
  ];

  Future<void> _onContinue() async {
    if (_selectedGoals.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_goals', jsonEncode(_selectedGoals.toList()));
    Get.toNamed('/onboarding/reminders');
  }

  void _toggleGoal(String title) {
    final isSelected = _selectedGoals.contains(title);
    if (!isSelected && _selectedGoals.length >= 3) return;
    HapticFeedback.selectionClick();
    setState(() {
      isSelected ? _selectedGoals.remove(title) : _selectedGoals.add(title);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header: floating back button on the left, mascot centered.
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Stack(
                alignment: Alignment.topCenter,
                children: [
                  Align(
                    alignment: Alignment.topLeft,
                    child: GestureDetector(
                      onTap: () => Get.back(),
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: context.colors.surface,
                          shape: BoxShape.circle,
                          boxShadow: context.colors.cardShadow,
                        ),
                        child: Icon(Icons.chevron_left_rounded, color: context.colors.text, size: 30),
                      ),
                    ).animate().fadeIn(duration: 350.ms).scale(begin: const Offset(0.7, 0.7), curve: Curves.easeOutBack),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: const BrainMascot(size: 92)
                        .animate()
                        .scale(begin: const Offset(0.6, 0.6), duration: 550.ms, curve: Curves.elasticOut),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            Text(
              'What are your goals?',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w600,
                color: context.colors.text,
                fontFamily: 'Inter',
                height: 1.15,
              ),
            ).animate().fadeIn(duration: 450.ms, delay: 120.ms).slideY(begin: 0.25, end: 0, curve: Curves.easeOutCubic),
            const SizedBox(height: 10),
            Text(
              'Pick up to 3 — you can change these',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: context.colors.textVariant,
                fontFamily: 'Inter',
              ),
            ).animate().fadeIn(duration: 450.ms, delay: 220.ms).slideY(begin: 0.25, end: 0, curve: Curves.easeOutCubic),
            const SizedBox(height: 20),

            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                physics: const BouncingScrollPhysics(),
                itemCount: _goals.length,
                itemBuilder: (context, index) {
                  final title = _goals[index]['title'] as String;
                  final icon = _goals[index]['icon'] as IconData;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _GoalCard(
                      title: title,
                      icon: icon,
                      isSelected: _selectedGoals.contains(title),
                      onTap: () => _toggleGoal(title),
                    ),
                  )
                      .animate()
                      .fadeIn(duration: 400.ms, delay: (300 + index * 90).ms)
                      .slideY(begin: 0.3, end: 0, curve: Curves.easeOutCubic);
                },
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: SizedBox(
                width: double.infinity,
                height: 58,
                child: ElevatedButton(
                  onPressed: _selectedGoals.isEmpty ? null : _onContinue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.colors.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: context.colors.outlineVariant,
                    disabledForegroundColor: Colors.white,
                    shape: const StadiumBorder(),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Continue',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 18,
                      fontFamily: 'Inter',
                    ),
                  ),
                ),
              ).animate().fadeIn(duration: 450.ms, delay: 700.ms).slideY(begin: 0.5, end: 0, curve: Curves.easeOutCubic),
            ),
          ],
        ),
      ),
    );
  }
}

/// Goal card. Selected: lavender fill, purple accent bar flush on the left
/// edge and a purple check disc on the right. Unselected: white card with an
/// empty gray ring.
class _GoalCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _GoalCard({
    required this.title,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: isSelected ? context.colors.selectedGoal : context.colors.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: context.colors.cardShadow,
        ),
        child: Stack(
          children: [
            // Purple accent bar on the card's left edge, selected only.
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                width: isSelected ? 5 : 0,
                color: context.colors.primary,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
              child: Row(
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: context.colors.iconBubble,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: context.colors.primary, size: 27),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: context.colors.text,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    transitionBuilder: (child, anim) => ScaleTransition(
                      scale: CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
                      child: child,
                    ),
                    child: isSelected
                        ? Container(
                            key: const ValueKey('on'),
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: context.colors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.check_rounded, color: Colors.white, size: 20),
                          )
                        : Container(
                            key: const ValueKey('off'),
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: context.colors.outlineVariant, width: 2),
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
