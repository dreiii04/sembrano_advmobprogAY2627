import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ThemeModel with ChangeNotifier {
  bool _isDark = false;

  // Getter function: exposes whether dark mode is currently enabled.
  bool get isDark => _isDark;

  // it toggle betweenlight and dark
  void toggleTheme() {
    _isDark = !_isDark;
    notifyListeners();
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeModel = context.watch<ThemeModel>();

    return Scaffold(
      appBar: AppBar(title: const Text('App State Example')),
      body: Center(
        child: SwitchListTile(
          title: const Text('Dark mode'),
          subtitle: const Text('Toggle the application theme.'),
          value: themeModel.isDark,
          // Change the theme when switch is used.
          onChanged: (_) => themeModel.toggleTheme(),
        ),
      ),
    );
  }
}
