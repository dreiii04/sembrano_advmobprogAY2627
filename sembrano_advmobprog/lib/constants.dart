import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

var host = dotenv.env['HOST'];

class AppConstants {
  const AppConstants._();

  static const appName = 'NU Marketplace';
  static const homeRoute = '/home';
  static const settingsRoute = '/settings';

  static ThemeData lightTheme = ThemeData(
    colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
    fontFamily: 'Poppins',
    useMaterial3: true,
  );

  static ThemeData darkTheme = ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.blue,
      brightness: Brightness.dark,
    ),
    fontFamily: 'Poppins',
    useMaterial3: true,
  );
}
