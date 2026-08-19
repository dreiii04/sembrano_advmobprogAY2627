import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/theme_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      // Enhancement 3: Moves the theme switch to the settings page.
      body: SwitchListTile(
        title: const Text('Dark mode'),
        subtitle: const Text('Toggle the application theme.'),
        value: themeProvider.isDark,
        onChanged: (_) => themeProvider.toggleTheme(),
      ),
    );
  }
}
