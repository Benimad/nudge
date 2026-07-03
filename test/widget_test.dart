import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nudge/main.dart';

void main() {
  testWidgets('App loads smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const NudgeApp());
    expect(find.byType(Scaffold), findsWidgets);
  });
}
