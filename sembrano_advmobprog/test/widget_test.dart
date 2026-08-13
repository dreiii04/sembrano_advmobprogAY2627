import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sembrano_advmobprog/main.dart';

// Test main function: registers the widget tests that verify app behavior.
void main() {
  // Test function: opens settings from home and toggles the app theme.
  testWidgets('Settings button opens settings and toggles theme', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const SemSocialApp());

    expect(find.text('State Management Example'), findsOneWidget);
    expect(find.text('App State Example'), findsNothing);

    await tester.tap(find.byKey(const Key('settingsButton')));
    await tester.pumpAndSettle();

    expect(find.text('App State Example'), findsOneWidget);
    expect(
      Theme.of(tester.element(find.byType(Scaffold))).brightness,
      Brightness.light,
    );

    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();

    expect(
      Theme.of(tester.element(find.byType(Scaffold))).brightness,
      Brightness.dark,
    );
  });
}
