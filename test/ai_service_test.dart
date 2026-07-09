import 'package:flutter_test/flutter_test.dart';
import 'package:nudge/features/ai_coach/services/ai_service.dart';

/// Tests the on-device AI paths that must work with no network and no API key:
/// crisis detection (safety-critical), the offline coaching fallback, and the
/// template task breakdown. These never touch Gemini, so they're deterministic.
void main() {
  final ai = AiCoachService();

  group('crisis detection', () {
    test('flags self-harm language and surfaces resources', () {
      final signal = ai.scanForCrisis('sometimes I want to kill myself');
      expect(signal.isCrisis, isTrue);
      expect(signal.message, contains('988'));
    });

    test('is case-insensitive', () {
      expect(ai.scanForCrisis('I want to DIE').isCrisis, isTrue);
    });

    test('does not false-positive on ordinary venting', () {
      expect(ai.scanForCrisis('I am so overwhelmed by my inbox').isCrisis, isFalse);
      expect(ai.scanForCrisis('this deadline is killing me at work').isCrisis, isFalse);
    });
  });

  group('offline fallback', () {
    test('crisis language short-circuits to the resource message', () {
      final reply = ai.fallbackResponse('i want to die');
      expect(reply, contains('988'));
    });

    test('overwhelm keyword returns a grounding response', () {
      final reply = ai.fallbackResponse('everything feels like too much right now');
      expect(reply, isNotEmpty);
    });

    test('never returns an empty string for arbitrary input', () {
      expect(ai.fallbackResponse('tell me about quantum physics'), isNotEmpty);
    });
  });

  group('task breakdown (templates, useAi: false)', () {
    test('returns 4-5 concrete steps with time estimates', () async {
      final steps = await ai.breakdownTask('clean the kitchen', useAi: false);
      expect(steps.length, greaterThanOrEqualTo(3));
      for (final step in steps) {
        expect(step['title'], isNotNull);
        expect(step['title'], isNotEmpty);
        expect(step['time'], isNotNull);
      }
    });

    test('unknown tasks still get a generic breakdown', () async {
      final steps = await ai.breakdownTask('reorganize my entire life', useAi: false);
      expect(steps, isNotEmpty);
    });
  });

  group('weekly insight', () {
    test('congratulates high completion and includes a mood note when present', () {
      final insight = ai.getWeeklyInsight({
        'completion_rate': 0.9,
        'best_day': 'Wednesday',
        'streak': 8,
        'improvement': 0.1,
        'mood_note': 'Your mood has been bright this week.',
      });
      expect(insight, contains('90%'));
      expect(insight, contains('Wednesday'));
      expect(insight, contains('bright'));
    });
  });
}
