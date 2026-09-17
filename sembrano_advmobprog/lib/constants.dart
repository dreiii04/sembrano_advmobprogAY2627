import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

final host = dotenv.env['HOST'] ?? 'https://dummyjson.com';

class AppConstants {
  const AppConstants._();

  static const appName = 'NU Marketplace';
  static const splashRoute = '/';
  static const signinRoute = '/signin';
  static const signupRoute = '/signup';
  static const homeRoute = '/home';
  static const settingsRoute = '/settings';
  static const cartUserId = 5;

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
