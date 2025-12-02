import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

final ThemeData _baseLightTheme = ThemeData(
  brightness: Brightness.light,
  scaffoldBackgroundColor: Colors.white,
  visualDensity: VisualDensity.adaptivePlatformDensity,
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(),
  ),
  inputDecorationTheme: InputDecorationTheme(
    contentPadding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
    labelStyle: const TextStyle(color: Colors.grey),
    hintStyle: const TextStyle(color: Colors.grey),
    floatingLabelStyle: const TextStyle(color: Colors.grey),
    errorStyle: TextStyle(color: Colors.red.shade700),
    border: const OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(4.0)),
      borderSide: BorderSide(color: Colors.grey, width: 1.0),
    ),
    enabledBorder: const OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(4.0)),
      borderSide: BorderSide(color: Colors.grey, width: 1.0),
    ),
    errorBorder: const OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(4.0)),
      borderSide: BorderSide(color: Colors.red, width: 1.0),
    ),
    focusedErrorBorder: const OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(4.0)),
      borderSide: BorderSide(color: Colors.red, width: 2.0),
    ),
  ),
  switchTheme: SwitchThemeData(
    thumbColor: WidgetStateProperty.resolveWith<Color?>((states) {
      if (!states.contains(WidgetState.selected)) {
        return Colors.grey[850];
      }
      return null;
    }),
    trackColor: WidgetStateProperty.resolveWith<Color?>((states) {
      if (!states.contains(WidgetState.selected)) {
        return Colors.grey;
      }
      return null;
    }),
    trackOutlineColor: WidgetStateProperty.resolveWith<Color?>((states) {
      if (!states.contains(WidgetState.selected)) {
        return Colors.grey;
      }
      return null;
    }),
  ),
);

final ThemeData _baseDarkTheme = ThemeData(
  brightness: Brightness.dark,
  scaffoldBackgroundColor: Colors.black87,
  visualDensity: VisualDensity.adaptivePlatformDensity,
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(),
  ),
  inputDecorationTheme: const InputDecorationTheme(
    contentPadding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
    labelStyle: TextStyle(color: Colors.white70),
    hintStyle: TextStyle(color: Colors.grey),
    floatingLabelStyle: TextStyle(color: Colors.white),
    errorStyle: TextStyle(color: Colors.redAccent),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(4.0)),
      borderSide: BorderSide(color: Colors.grey, width: 1.0),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(4.0)),
      borderSide: BorderSide(color: Colors.grey, width: 1.0),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(4.0)),
      borderSide: BorderSide(color: Colors.redAccent, width: 1.0),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(4.0)),
      borderSide: BorderSide(color: Colors.redAccent, width: 2.0),
    ),
  ),
  switchTheme: SwitchThemeData(
    thumbColor: WidgetStateProperty.resolveWith<Color?>((states) {
      if (!states.contains(WidgetState.selected)) {
        return Colors.white;
      }
      return null;
    }),
    trackColor: WidgetStateProperty.resolveWith<Color?>((states) {
      if (!states.contains(WidgetState.selected)) {
        return Colors.grey.shade700;
      }
      return null;
    }),
  ),
);

final Map<String, Map<String, ThemeData>> appThemeFamilies = {
  'Deep Purple': {
    'light': _baseLightTheme.copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      colorScheme: ColorScheme.fromSwatch(
        primarySwatch: Colors.deepPurple,
        brightness: Brightness.light,
      ).copyWith(
        secondary: Colors.deepPurpleAccent,
        surface: Colors.white,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Colors.black87,
        error: Colors.red,
        onError: Colors.white,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
            side: const BorderSide(color: Colors.black, width: 1.0),
          ),
        ),
      ),
      sliderTheme: SliderThemeData(
        inactiveTrackColor: Colors.grey[300],
        activeTrackColor: Colors.deepPurple,
        thumbColor: Colors.deepPurple,
        overlayColor: Colors.deepPurple.withAlpha(32),
        trackHeight: 4,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(25)),
          borderSide: BorderSide(color: Colors.black, width: 1.0),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(25)),
          borderSide: BorderSide(color: Colors.black, width: 1.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(25)),
          borderSide: BorderSide(color: Colors.black, width: 2.0),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(25)),
          borderSide: BorderSide(color: Colors.red, width: 1.0),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(25)),
          borderSide: BorderSide(color: Colors.red, width: 2.0),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Colors.black, width: 1.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
        ),
      ),
    ),
    'dark': _baseDarkTheme.copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.deepPurple.shade900,
        foregroundColor: Colors.white,
      ),
      colorScheme: ColorScheme.fromSwatch(
        primarySwatch: Colors.deepPurple,
        brightness: Brightness.dark,
      ).copyWith(
        primary: Colors.deepPurple.shade700,
        secondary: Colors.deepPurpleAccent.shade700,
        surface: const Color(0xFF121212),
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Colors.white,
        error: Colors.redAccent,
        onError: Colors.white,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.deepPurple.shade700,
          foregroundColor: Colors.white,
        ),
      ),
      sliderTheme: SliderThemeData(
        inactiveTrackColor: Colors.grey[600],
        activeTrackColor: Colors.deepPurpleAccent,
        thumbColor: Colors.deepPurpleAccent,
        overlayColor: Colors.deepPurpleAccent.withAlpha(32),
        trackHeight: 4,
      ),
      inputDecorationTheme: InputDecorationTheme(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(25)),
          borderSide: BorderSide(color: Colors.white, width: 1.0),
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(25)),
          borderSide: BorderSide(color: Colors.white, width: 1.0),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(25)),
          borderSide: BorderSide(color: Colors.white, width: 2.0),
        ),
        errorBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(25)),
          borderSide: BorderSide(color: Colors.red, width: 1.0),
        ),
        focusedErrorBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(25)),
          borderSide: BorderSide(color: Colors.red, width: 2.0),
        ),
        filled: true,
        fillColor: Colors.grey.shade800,
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Colors.white, width: 1.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
        ),
      ),
    ),
  },
  'Green': {
    'light': _baseLightTheme.copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      colorScheme: ColorScheme.fromSwatch(
        primarySwatch: Colors.green,
        brightness: Brightness.light,
      ).copyWith(
        secondary: Colors.greenAccent,
        surface: Colors.white,
        onPrimary: Colors.white,
        onSecondary: Colors.black87,
        onSurface: Colors.black87,
        error: Colors.red,
        onError: Colors.white,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.black87,
        ),
      ),
      sliderTheme: SliderThemeData(
        inactiveTrackColor: Colors.grey[300],
        activeTrackColor: Colors.green,
        thumbColor: Colors.green,
        overlayColor: Colors.green.withAlpha(32),
        trackHeight: 4,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(25)),
          borderSide: BorderSide(color: Colors.black, width: 1.0),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(25)),
          borderSide: BorderSide(color: Colors.black, width: 1.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(25)),
          borderSide: BorderSide(color: Colors.black, width: 2.0),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(25)),
          borderSide: BorderSide(color: Colors.red, width: 1.0),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(25)),
          borderSide: BorderSide(color: Colors.red, width: 2.0),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Colors.black, width: 1.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
        ),
      ),
    ),
    'dark': _baseDarkTheme.copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.green.shade900,
        foregroundColor: Colors.white,
      ),
      colorScheme: ColorScheme.fromSwatch(
        primarySwatch: Colors.green,
        brightness: Brightness.dark,
      ).copyWith(
        primary: Colors.green.shade700,
        secondary: Colors.lightGreenAccent.shade700,
        surface: const Color(0xFF121212),
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Colors.white,
        error: Colors.redAccent,
        onError: Colors.white,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green.shade700,
          foregroundColor: Colors.white,
        ),
      ),
      sliderTheme: SliderThemeData(
        inactiveTrackColor: Colors.grey[700],
        activeTrackColor: Colors.lightGreenAccent.shade700,
        thumbColor: Colors.lightGreenAccent.shade700,
        overlayColor: Colors.lightGreenAccent.shade700.withAlpha(32),
        trackHeight: 4,
      ),
      inputDecorationTheme: InputDecorationTheme(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(25)),
          borderSide: BorderSide(color: Colors.white, width: 1.0),
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(25)),
          borderSide: BorderSide(color: Colors.white, width: 1.0),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(25)),
          borderSide: BorderSide(color: Colors.white, width: 2.0),
        ),
        errorBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(25)),
          borderSide: BorderSide(color: Colors.red, width: 1.0),
        ),
        focusedErrorBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(25)),
          borderSide: BorderSide(color: Colors.red, width: 2.0),
        ),
        filled: true,
        fillColor: Colors.grey.shade800,
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Colors.white, width: 1.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
        ),
      ),
    ),
  },
  'Pink': {
    'light': _baseLightTheme.copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.pink,
        foregroundColor: Colors.white,
      ),
      colorScheme: ColorScheme.fromSwatch(
        primarySwatch: Colors.pink,
        brightness: Brightness.light,
      ).copyWith(
        secondary: Colors.pinkAccent,
        surface: Colors.white,
        onPrimary: Colors.white,
        onSecondary: Colors.black87,
        onSurface: Colors.black87,
        error: Colors.red,
        onError: Colors.white,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.pink,
          foregroundColor: Colors.black87,
        ),
      ),
      sliderTheme: SliderThemeData(
        inactiveTrackColor: Colors.grey[300],
        activeTrackColor: Colors.pink,
        thumbColor: Colors.pink,
        overlayColor: Colors.pink.withAlpha(32),
        trackHeight: 4,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(25)),
          borderSide: BorderSide(color: Colors.black, width: 1.0),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(25)),
          borderSide: BorderSide(color: Colors.black, width: 1.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(25)),
          borderSide: BorderSide(color: Colors.black, width: 2.0),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(25)),
          borderSide: BorderSide(color: Colors.red, width: 1.0),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(25)),
          borderSide: BorderSide(color: Colors.red, width: 2.0),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Colors.black, width: 1.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
        ),
      ),
    ),
    'dark': _baseDarkTheme.copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.pink.shade900,
        foregroundColor: Colors.white,
      ),
      colorScheme: ColorScheme.fromSwatch(
        primarySwatch: Colors.pink,
        brightness: Brightness.dark,
      ).copyWith(
        primary: Colors.pink.shade700,
        secondary: Colors.pinkAccent.shade700,
        surface: const Color(0xFF121212),
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Colors.white,
        error: Colors.redAccent,
        onError: Colors.white,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.pink.shade700,
          foregroundColor: Colors.white,
        ),
      ),
      sliderTheme: SliderThemeData(
        inactiveTrackColor: Colors.grey[600],
        activeTrackColor: Colors.pinkAccent.shade700,
        thumbColor: Colors.pinkAccent.shade700,
        overlayColor: Colors.pinkAccent.shade700.withAlpha(32),
        trackHeight: 4,
      ),
      inputDecorationTheme: InputDecorationTheme(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(25)),
          borderSide: BorderSide(color: Colors.white, width: 1.0),
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(25)),
          borderSide: BorderSide(color: Colors.white, width: 1.0),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(25)),
          borderSide: BorderSide(color: Colors.white, width: 2.0),
        ),
        errorBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(25)),
          borderSide: BorderSide(color: Colors.red, width: 1.0),
        ),
        focusedErrorBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(25)),
          borderSide: BorderSide(color: Colors.red, width: 2.0),
        ),
        filled: true,
        fillColor: Colors.grey.shade800,
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Colors.white, width: 1.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
        ),
      ),
    ),
  },
  'Cyan': {
    'light': _baseLightTheme.copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.cyan,
        foregroundColor: Colors.white,
      ),
      colorScheme: ColorScheme.fromSwatch(
        primarySwatch: Colors.cyan,
        brightness: Brightness.light,
      ).copyWith(
        secondary: Colors.cyanAccent,
        surface: Colors.white,
        onPrimary: Colors.white,
        onSecondary: Colors.black87,
        onSurface: Colors.black87,
        error: Colors.red,
        onError: Colors.white,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.cyan,
          foregroundColor: Colors.black87,
        ),
      ),
      sliderTheme: SliderThemeData(
        inactiveTrackColor: Colors.grey[300],
        activeTrackColor: Colors.cyan,
        thumbColor: Colors.cyan,
        overlayColor: Colors.cyan.withAlpha(32),
        trackHeight: 4,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(25)),
          borderSide: BorderSide(color: Colors.black, width: 1.0),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(25)),
          borderSide: BorderSide(color: Colors.black, width: 1.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(25)),
          borderSide: BorderSide(color: Colors.black, width: 2.0),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(25)),
          borderSide: BorderSide(color: Colors.red, width: 1.0),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(25)),
          borderSide: BorderSide(color: Colors.red, width: 2.0),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Colors.black, width: 1.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
        ),
      ),
    ),
    'dark': _baseDarkTheme.copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.cyan.shade900,
        foregroundColor: Colors.white,
      ),
      colorScheme: ColorScheme.fromSwatch(
        primarySwatch: Colors.cyan,
        brightness: Brightness.dark,
      ).copyWith(
        primary: Colors.cyan.shade700,
        secondary: Colors.cyanAccent.shade700,
        surface: const Color(0xFF121212),
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Colors.white,
        error: Colors.redAccent,
        onError: Colors.white,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.cyan.shade700,
          foregroundColor: Colors.white,
        ),
      ),
      sliderTheme: SliderThemeData(
        inactiveTrackColor: Colors.grey[600],
        activeTrackColor: Colors.cyanAccent.shade700,
        thumbColor: Colors.cyanAccent.shade700,
        overlayColor: Colors.cyanAccent.shade700.withAlpha(32),
        trackHeight: 4,
      ),
      inputDecorationTheme: InputDecorationTheme(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(25)),
          borderSide: BorderSide(color: Colors.white, width: 1.0),
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(25)),
          borderSide: BorderSide(color: Colors.white, width: 1.0),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(25)),
          borderSide: BorderSide(color: Colors.white, width: 2.0),
        ),
        errorBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(25)),
          borderSide: BorderSide(color: Colors.red, width: 1.0),
        ),
        focusedErrorBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(25)),
          borderSide: BorderSide(color: Colors.red, width: 2.0),
        ),
        filled: true,
        fillColor: Colors.grey.shade800,
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Colors.white, width: 1.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
        ),
      ),
    ),
  },
  'Light Blue': {
    'light': _baseLightTheme.copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      colorScheme: ColorScheme.fromSwatch(
        primarySwatch: Colors.blue,
        brightness: Brightness.light,
      ).copyWith(
        secondary: Colors.blueAccent,
        surface: Colors.white,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Colors.black87,
        error: Colors.red,
        onError: Colors.white,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
            side: const BorderSide(color: Colors.black, width: 1.0),
          ),
        ),
      ),
      sliderTheme: SliderThemeData(
        inactiveTrackColor: Colors.grey[300],
        activeTrackColor: Colors.blue,
        thumbColor: Colors.blue,
        overlayColor: Colors.blue.withAlpha(32),
        trackHeight: 4,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(25)),
          borderSide: BorderSide(color: Colors.black, width: 1.0),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(25)),
          borderSide: BorderSide(color: Colors.black, width: 1.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(25)),
          borderSide: BorderSide(color: Colors.black, width: 2.0),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(25)),
          borderSide: BorderSide(color: Colors.red, width: 1.0),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(25)),
          borderSide: BorderSide(color: Colors.red, width: 2.0),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Colors.black, width: 1.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
        ),
      ),
    ),
    'dark': _baseDarkTheme.copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.blue.shade900,
        foregroundColor: Colors.white,
      ),
      colorScheme: ColorScheme.fromSwatch(
        primarySwatch: Colors.blue,
        brightness: Brightness.dark,
      ).copyWith(
        primary: Colors.blue.shade700,
        secondary: Colors.blueAccent.shade700,
        surface: const Color(0xFF121212),
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Colors.white,
        error: Colors.redAccent,
        onError: Colors.white,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue.shade700,
          foregroundColor: Colors.white,
        ),
      ),
      sliderTheme: SliderThemeData(
        inactiveTrackColor: Colors.grey[600],
        activeTrackColor: Colors.blueAccent.shade700,
        thumbColor: Colors.blueAccent.shade700,
        overlayColor: Colors.blueAccent.shade700.withAlpha(32),
        trackHeight: 4,
      ),
      inputDecorationTheme: InputDecorationTheme(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(25)),
          borderSide: BorderSide(color: Colors.white, width: 1.0),
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(25)),
          borderSide: BorderSide(color: Colors.white, width: 1.0),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(25)),
          borderSide: BorderSide(color: Colors.white, width: 2.0),
        ),
        errorBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(25)),
          borderSide: BorderSide(color: Colors.red, width: 1.0),
        ),
        focusedErrorBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(25)),
          borderSide: BorderSide(color: Colors.red, width: 2.0),
        ),
        filled: true,
        fillColor: Colors.grey.shade800,
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Colors.white, width: 1.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
        ),
      ),
    ),
  },
};

const Map<String, String> themeDisplayNames = {
  'Deep Purple': 'Realeza',
  'Cyan': 'Obediencia',
  'Green': 'Vida',
  'Pink': 'Pureza',
  'Light Blue': 'Celestial',
};

const TextStyle settingsOptionTextStyle = TextStyle(fontSize: 20.0);

/// Consistent system UI overlay style for all themes
/// Dark gray navigation bar with white icons for better visibility
/// This ensures consistency across all pages and themes
const SystemUiOverlayStyle systemUiOverlayStyle = SystemUiOverlayStyle(
  // Status bar (top) - transparent to allow gradient from AppBar
  statusBarColor: Colors.transparent,
  statusBarIconBrightness: Brightness.light, // White icons on status bar
  statusBarBrightness: Brightness.dark, // For iOS

  // Navigation bar (bottom) - consistent dark gray with white buttons
  systemNavigationBarColor: Color(0xFF424242), // Dark gray (Material grey 800)
  systemNavigationBarIconBrightness:
      Brightness.light, // White navigation buttons
  systemNavigationBarDividerColor: Colors.transparent,
);
