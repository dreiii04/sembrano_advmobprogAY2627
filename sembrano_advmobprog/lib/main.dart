import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'screens/counter_screen.dart';
import 'screens/settings_screen.dart';

// Main function: launches the app from its single entry point.
void main() => runApp(const SemSocialApp());

class SemSocialApp extends StatelessWidget {
  const SemSocialApp({super.key});

  // Build method: provides shared theme state to the entire application.
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      // Create function: creates the theme state shared by both screens.
      create: (_) => ThemeModel(),
      child: const _SemSocialAppView(),
    );
  }
}

class _SemSocialAppView extends StatelessWidget {
  const _SemSocialAppView();

  // Build method: configures the app theme, home screen, and named routes.
  @override
  Widget build(BuildContext context) {
    final themeModel = Provider.of<ThemeModel>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SemSocial',
      theme: themeModel.isDark ? ThemeData.dark() : ThemeData.light(),
      themeAnimationDuration: Duration.zero,
      home: const MyHomePage(),
      routes: {
        // Route builder function: creates the settings screen when requested.
        '/settings': (_) => const SettingsScreen(),
      },
    );
  }
}
