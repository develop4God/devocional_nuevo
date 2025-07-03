// lib/utils/theme_constants.dart
// Este archivo define las constantes de ThemeData para los diferentes temas de la aplicación.

import 'package:flutter/material.dart';

// Temas Deep Purple
final ThemeData lightThemePurple = ThemeData(
  primarySwatch: Colors.deepPurple,
  brightness: Brightness.light,
  scaffoldBackgroundColor: Colors.white,
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.deepPurple,
    foregroundColor: Colors.white,
  ),
  visualDensity: VisualDensity.adaptivePlatformDensity,
  colorScheme: const ColorScheme.light(
    primary: Colors.deepPurple,
    secondary: Colors.deepPurpleAccent,
    surface: Colors.white,
    background: Colors.white,
    error: Colors.red,
    onPrimary: Colors.white,
    onSecondary: Colors.white,
    onSurface: Colors.black87,
    onBackground: Colors.black87,
    onError: Colors.white,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.deepPurple,
      foregroundColor: Colors.white,
    ),
  ),
);

final ThemeData darkThemePurple = ThemeData(
  primarySwatch: Colors.deepPurple,
  brightness: Brightness.dark,
  scaffoldBackgroundColor: Colors.black87,
  appBarTheme: AppBarTheme(
    backgroundColor: Colors.deepPurple.shade900,
    foregroundColor: Colors.white,
  ),
  visualDensity: VisualDensity.adaptivePlatformDensity,
  colorScheme: ColorScheme.dark(
    primary: Colors.deepPurple.shade700,
    secondary: Colors.deepPurpleAccent.shade700,
    surface: Colors.black87,
    background: Colors.black87,
    error: Colors.redAccent,
    onPrimary: Colors.white,
    onSecondary: Colors.white,
    onSurface: Colors.white,
    onBackground: Colors.white,
    onError: Colors.white,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.deepPurple.shade700,
      foregroundColor: Colors.white,
    ),
  ),
);

// Temas Light Green
final ThemeData lightThemeGreen = ThemeData(
  primarySwatch: Colors.lightGreen,
  brightness: Brightness.light,
  scaffoldBackgroundColor: Colors.white,
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.lightGreen,
    foregroundColor: Colors.white, // MODIFICADO: de Colors.black87 a Colors.white
  ),
  visualDensity: VisualDensity.adaptivePlatformDensity,
  colorScheme: const ColorScheme.light(
    primary: Colors.lightGreen,
    secondary: Colors.lightGreenAccent,
    surface: Colors.white,
    background: Colors.white,
    error: Colors.red,
    onPrimary: Colors.white, // MODIFICADO: de Colors.black87 a Colors.white
    onSecondary: Colors.black87,
    onSurface: Colors.black87,
    onBackground: Colors.black87,
    onError: Colors.white,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.lightGreen,
      foregroundColor: Colors.black87,
    ),
  ),
);

final ThemeData darkThemeGreen = ThemeData(
  primarySwatch: Colors.lightGreen,
  brightness: Brightness.dark,
  scaffoldBackgroundColor: Colors.black87,
  appBarTheme: AppBarTheme(
    backgroundColor: Colors.lightGreen.shade900,
    foregroundColor: Colors.white,
  ),
  visualDensity: VisualDensity.adaptivePlatformDensity,
  colorScheme: ColorScheme.dark(
    primary: Colors.lightGreen.shade700,
    secondary: Colors.lightGreenAccent.shade700,
    surface: Colors.black87,
    background: Colors.black87,
    error: Colors.redAccent,
    onPrimary: Colors.white,
    onSecondary: Colors.white,
    onSurface: Colors.white,
    onBackground: Colors.white,
    onError: Colors.white,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.lightGreen.shade700,
      foregroundColor: Colors.white,
    ),
  ),
);

// Temas Cyan
final ThemeData lightThemeCyan = ThemeData(
  primarySwatch: Colors.cyan,
  brightness: Brightness.light,
  scaffoldBackgroundColor: Colors.white,
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.cyan,
    foregroundColor: Colors.white, // MODIFICADO: de Colors.black87 a Colors.white
  ),
  visualDensity: VisualDensity.adaptivePlatformDensity,
  colorScheme: const ColorScheme.light(
    primary: Colors.cyan,
    secondary: Colors.cyanAccent,
    surface: Colors.white,
    background: Colors.white,
    error: Colors.red,
    onPrimary: Colors.white, // MODIFICADO: de Colors.black87 a Colors.white
    onSecondary: Colors.black87,
    onSurface: Colors.black87,
    onBackground: Colors.black87,
    onError: Colors.white,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.cyan,
      foregroundColor: Colors.black87,
    ),
  ),
);

final ThemeData darkThemeCyan = ThemeData(
  primarySwatch: Colors.cyan,
  brightness: Brightness.dark,
  scaffoldBackgroundColor: Colors.black87,
  appBarTheme: AppBarTheme(
    backgroundColor: Colors.cyan.shade900,
    foregroundColor: Colors.white,
  ),
  visualDensity: VisualDensity.adaptivePlatformDensity,
  colorScheme: ColorScheme.dark(
    primary: Colors.cyan.shade700,
    secondary: Colors.cyanAccent.shade700,
    surface: Colors.black87,
    background: Colors.black87,
    error: Colors.redAccent,
    onPrimary: Colors.white,
    onSecondary: Colors.white,
    onSurface: Colors.white,
    onBackground: Colors.white,
    onError: Colors.white,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.cyan.shade700,
      foregroundColor: Colors.white,
    ),
  ),
);

// Temas Light Blue
final ThemeData lightThemeBlue = ThemeData(
  primarySwatch: Colors.blue,
  brightness: Brightness.light,
  scaffoldBackgroundColor: Colors.white,
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.blue,
    foregroundColor: Colors.white,
  ),
  visualDensity: VisualDensity.adaptivePlatformDensity,
  colorScheme: const ColorScheme.light(
    primary: Colors.blue,
    secondary: Colors.blueAccent,
    surface: Colors.white,
    background: Colors.white,
    error: Colors.red,
    onPrimary: Colors.white,
    onSecondary: Colors.white,
    onSurface: Colors.black87,
    onBackground: Colors.black87,
    onError: Colors.white,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.blue,
      foregroundColor: Colors.white,
    ),
  ),
);

final ThemeData darkThemeBlue = ThemeData(
  primarySwatch: Colors.blue,
  brightness: Brightness.dark,
  scaffoldBackgroundColor: Colors.black87,
  appBarTheme: AppBarTheme(
    backgroundColor: Colors.blue.shade900,
    foregroundColor: Colors.white,
  ),
  visualDensity: VisualDensity.adaptivePlatformDensity,
  colorScheme: ColorScheme.dark(
    primary: Colors.blue.shade700,
    secondary: Colors.blueAccent.shade700,
    surface: Colors.black87,
    background: Colors.black87,
    error: Colors.redAccent,
    onPrimary: Colors.white,
    onSecondary: Colors.white,
    onSurface: Colors.white,
    onBackground: Colors.white,
    onError: Colors.white,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.blue.shade700,
      foregroundColor: Colors.white,
    ),
  ),
);
