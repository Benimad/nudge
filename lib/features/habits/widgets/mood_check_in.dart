import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/theme/app_theme.dart';

/// A once-a-day, low-friction mood check-in. Writes to the `moods` table (which
/// previously had no UI writing to it) so the AI coach and stats can correlate
/// mood with follow-through. Dismisses itself for the rest of the day once
/// answered or skipped — no nagging.
class MoodCheckIn extends StatefulWidget {
  const MoodCheckIn({super.key});

  @override
  State<MoodCheckIn> createState() => _MoodCheckInState();
}

class _MoodCheckInState extends State<MoodCheckIn> {
  bool _visible = false;
  bool _done = false;

  static const _faces = [
    (score: 1, emoji: '😔', label: 'Low'),
    (score: 2, emoji: '😕', label: 'Meh'),
    (score: 3, emoji: '😐', label: 'Okay'),
    (score: 4, emoji: '🙂', label: 'Good'),
    (score: 5, emoji: '😄', label: 'Great'),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  String get _todayKey {
    final n = DateTime.now();
    return 'mood_logged_${n.year}-${n.month}-${n.day}';
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    if (!(prefs.getBool(_todayKey) ?? false) && mounted) {
      setState(() => _visible = true);
    }
  }

  Future<void> _pick(int score) async {
    HapticFeedback.selectionClick();
    await DatabaseHelper.instance.insertMood(score: score);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_todayKey, true);
    if (mounted) setState(() => _done = true);
    // Let the thank-you linger briefly, then collapse.
    await Future.delayed(const Duration(milliseconds: 1100));
    if (mounted) setState(() => _visible = false);
  }

  Future<void> _skip() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_todayKey, true);
    if (mounted) setState(() => _visible = false);
  }

  @override
  Widget build(BuildContext context) {
    if (!_visible) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 14, 12, 16),
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: context.colors.cardShadow,
        ),
        child: _done
            ? Row(
                children: [
                  Icon(Icons.favorite_rounded, color: context.colors.primary, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Thanks for checking in 💜',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: context.colors.text,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ),
                ],
              ).animate().fadeIn(duration: 250.ms)
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'How\'s your brain today?',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: context.colors.text,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: _skip,
                        child: Semantics(
                          button: true,
                          label: 'Skip mood check-in',
                          child: Icon(Icons.close_rounded, size: 18, color: context.colors.outline),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: _faces.map((f) {
                      return Semantics(
                        button: true,
                        label: 'Mood: ${f.label}',
                        child: GestureDetector(
                          onTap: () => _pick(f.score),
                          child: Column(
                            children: [
                              Text(f.emoji, style: const TextStyle(fontSize: 30)),
                              const SizedBox(height: 4),
                              Text(
                                f.label,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: context.colors.textVariant,
                                  fontFamily: 'Inter',
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
      ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.15, end: 0, curve: Curves.easeOutCubic),
    );
  }
}
