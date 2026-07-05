import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:nudge/core/theme/app_theme.dart';
import 'package:nudge/features/habits/screens/celebration_screen.dart';
import 'package:nudge/shared/widgets/brain_mascot.dart';

/// Widget smoke tests for service-free screens. (Screens that touch Firebase/
/// SQLite/notifications are covered by the on-device QA pass instead.)
void main() {
  Future<void> pumpWithTheme(WidgetTester tester, Widget child) async {
    await tester.pumpWidget(GetMaterialApp(
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      home: child,
    ));
    // Let entrance animations play out (finite, so a fixed pump is enough).
    await tester.pump(const Duration(seconds: 2));
  }

  testWidgets('celebration screen renders streak with singular day', (tester) async {
    await pumpWithTheme(tester, const CelebrationScreen(streak: 1));
    expect(find.textContaining('1 day'), findsOneWidget);
    expect(find.textContaining('1 days'), findsNothing);
    expect(find.text('Back to habits'), findsOneWidget);
  });

  testWidgets('celebration screen pluralizes multi-day streaks', (tester) async {
    await pumpWithTheme(tester, const CelebrationScreen(streak: 13));
    expect(find.textContaining('13 days'), findsOneWidget);
    expect(find.textContaining('+10 dopamine points'), findsOneWidget);
  });

  testWidgets('brain mascot paints without errors in both themes', (tester) async {
    await pumpWithTheme(tester, const Scaffold(body: Center(child: BrainMascot(size: 120))));
    expect(find.byType(BrainMascot), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
