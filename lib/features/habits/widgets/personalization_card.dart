import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_theme.dart';

/// One-time card on Home that closes the loop on onboarding: it quotes the
/// first goal the user picked and points at the feature built for it, so the
/// onboarding questions visibly paid off. Dismissed once, gone forever.
class PersonalizationCard extends StatefulWidget {
  const PersonalizationCard({super.key});

  @override
  State<PersonalizationCard> createState() => _PersonalizationCardState();
}

class _PersonalizationCardState extends State<PersonalizationCard> {
  static const _dismissedKey = 'personalization_card_dismissed';

  String? _goal;
  bool _visible = false;

  static const Map<String, String> _tips = {
    'Build daily routines':
        'Habits anchored to a time of day stick best — your reminders are already set up for that.',
    'Manage task paralysis':
        'When you freeze, Paralysis mode breaks any task into 30-second steps. It finds you — no need to look for it.',
    'Improve focus sessions':
        'Try a 25-minute focus session — you work alongside other real people, never alone.',
    'Track medications':
        'A "Take medication" habit with a soft nudge is the most streak-friendly habit in Nudge.',
    'Reduce overwhelm':
        'One habit is enough to start. Small is the strategy, not the compromise.',
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_dismissedKey) ?? false) return;
    final raw = prefs.getString('user_goals');
    if (raw == null) return;
    try {
      final goals = (jsonDecode(raw) as List).cast<String>();
      final match = goals.firstWhere(_tips.containsKey, orElse: () => '');
      if (match.isNotEmpty && mounted) {
        setState(() {
          _goal = match;
          _visible = true;
        });
      }
    } catch (_) {
      // Malformed prefs — just never show the card.
    }
  }

  Future<void> _dismiss() async {
    setState(() => _visible = false);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_dismissedKey, true);
  }

  @override
  Widget build(BuildContext context) {
    if (!_visible || _goal == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
        decoration: BoxDecoration(
          color: context.colors.selectedGoal,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: context.colors.primary.withValues(alpha: 0.18)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.auto_awesome, color: context.colors.primary, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Because you chose “$_goal”',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: context.colors.text,
                      fontFamily: 'Inter',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _tips[_goal]!,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      height: 1.35,
                      color: context.colors.textVariant,
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: _dismiss,
              icon: Icon(Icons.close_rounded, size: 18, color: context.colors.outline),
              visualDensity: VisualDensity.compact,
              tooltip: 'Dismiss',
            ),
          ],
        ),
      ).animate().fadeIn(duration: 450.ms, delay: 300.ms).slideY(begin: 0.15, end: 0, curve: Curves.easeOutCubic),
    );
  }
}
