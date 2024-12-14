import 'package:flutter/material.dart';

final ThemeData lightTheme = ThemeData(
  brightness: Brightness.light,
  primaryColor: Color(0xFFF43C3C),
  colorScheme: ColorScheme.light(
    primary: Color(0xFFF43C3C),
    secondary: Color(0xFFF43C3C),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Color(0xFFE0E0E0), // Colors.grey[200]
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10), // Consistent corner rounding
      borderSide: BorderSide(color: Color(0xFF03DAC6)), // Input Border (focused)
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10), // Consistent corner rounding
      borderSide: BorderSide(color: Color(0xFF3E3E3E)), // Borders
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10), // Consistent corner rounding
      borderSide: BorderSide(color: Color(0xFF03DAC6)), // Input Border (focused)
    ),
  ),
  // Define other light theme properties
);

final ThemeData darkTheme = ThemeData(
  brightness: Brightness.dark,
  scaffoldBackgroundColor: Color(0xFF121212), // Background
  primaryColor: Color(0xFFF43C3C), // Primary Accent
  colorScheme: ColorScheme.dark(
    primary: Color(0xFFF43C3C), // Primary Accent
    secondary: Color(0xFF03DAC6), // Secondary Accent
    surface: Color(0xFF232323), // Surface
    background: Color(0xFF121212), // Background
    error: Color(0xFFCF6679), // Error
    onPrimary: Color(0xFFFFFFFF), // Primary Button Text
    onSecondary: Color(0xFF000000), // Secondary Button Text
    onSurface: Color(0xFFE0E0E0), // Primary Text
    onBackground: Color(0xFFE0E0E0), // Primary Text
    onError: Color(0xFFFFFFFF), // Error Text
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Color(0xFF424242), // Colors.grey[800]
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10), // Consistent corner rounding
      borderSide: BorderSide(color: Color(0xFF03DAC6)), // Input Border (focused)
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10), // Consistent corner rounding
      borderSide: BorderSide(color: Color(0xFF3E3E3E)), // Borders
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10), // Consistent corner rounding
      borderSide: BorderSide(color: Color(0xFF03DAC6)), // Input Border (focused)
    ),
  ),
  // Define other dark theme properties
  dividerColor: Color(0xFF2E2E2E), // Dividers
  buttonTheme: ButtonThemeData(
    buttonColor: Color(0xFFF43C3C), // Primary Button Background
    textTheme: ButtonTextTheme.primary,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ButtonStyle(
      backgroundColor: MaterialStateProperty.all(Color(0xFFF43C3C)), // Primary Button Background
      foregroundColor: MaterialStateProperty.all(Color(0xFFFFFFFF)), // Primary Button Text
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: ButtonStyle(
      foregroundColor: MaterialStateProperty.all(Color(0xFF82B1FF)), // Link Text
    ),
  ),
  shadowColor: Color(0x40000000), // Shadow 1
);