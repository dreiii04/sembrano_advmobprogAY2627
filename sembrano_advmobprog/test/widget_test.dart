import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sembrano_advmobprog/providers/theme_provider.dart';
import 'package:sembrano_advmobprog/screens/settings_screen.dart';

void main() {
  testWidgets('settings switch toggles the theme', (tester) async {
    final themeProvider = ThemeProvider();

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: themeProvider,
        child: const MaterialApp(home: SettingsScreen()),
      ),
    );

    expect(themeProvider.isDark, isFalse);
    await tester.tap(find.byType(SwitchListTile));
    await tester.pump();
    expect(themeProvider.isDark, isTrue);
  });
}
