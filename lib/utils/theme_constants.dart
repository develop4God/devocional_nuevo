// lib/utils/theme_constants.dart
// Este archivo define las constantes de ThemeData para los diferentes temas de la aplicación,
// agrupados por familia de color y modo (claro/oscuro).

import 'package:flutter/material.dart';

// Definición de temas base (pueden ser usados directamente si se desea, o como parte de las familias)
// Estos temas base ayudan a evitar la repetición de propiedades comunes como brightness, scaffoldBackgroundColor, etc.
final ThemeData _baseLightTheme = ThemeData(
  brightness: Brightness.light,
  scaffoldBackgroundColor: Colors.white,
  visualDensity: VisualDensity.adaptivePlatformDensity,
  // Tema por defecto para ElevatedButtons en modo claro
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      // El foreground color se establecerá por el colorScheme.onPrimary de cada tema específico
      // o se dejará que derive del tema si no se especifica aquí.
      // Para este base, lo dejaremos en blanco para que los copyWith lo definan.
    ),
  ),
);

final ThemeData _baseDarkTheme = ThemeData(
  brightness: Brightness.dark,
  scaffoldBackgroundColor: Colors.black87, // Un gris muy oscuro para el fondo del scaffold
  visualDensity: VisualDensity.adaptivePlatformDensity,
  // Tema por defecto para ElevatedButtons en modo oscuro
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      // El foreground color se establecerá por el colorScheme.onPrimary de cada tema específico
    ),
  ),
);

// --- Familias de Temas ---
// Este mapa organiza todos los temas disponibles por una "familia" de color (ej. 'Deep Purple')
// y luego por su modo de brillo ('light' o 'dark').
// El ThemeProvider utilizará este mapa para obtener el ThemeData correcto.
final Map<String, Map<String, ThemeData>> appThemeFamilies = {
  'Deep Purple': {
    'light': _baseLightTheme.copyWith(
      // Removido primarySwatch aquí, ya que se maneja en ColorScheme.fromSwatch
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white, // Color del texto/iconos en el AppBar
      ),
      colorScheme: ColorScheme.fromSwatch(
        primarySwatch: Colors.deepPurple,
        brightness: Brightness.light,
      ).copyWith(
        secondary: Colors.deepPurpleAccent, // Color de acento
        surface: Colors.white, // Corregido de 'background' a 'surface'
        onPrimary: Colors.white, // Color para texto/iconos sobre primary
        onSecondary: Colors.white, // Color para texto/iconos sobre secondary
        onSurface: Colors.black87, // Corregido de 'onBackground' a 'onSurface'
        error: Colors.red, // Color para errores
        onError: Colors.white, // Color para texto/iconos sobre error
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.deepPurple, // Color de fondo del botón
          foregroundColor: Colors.white, // Color del texto del botón
        ),
      ),
    ),
    'dark': _baseDarkTheme.copyWith(
      // Removido primarySwatch aquí
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.deepPurple.shade900, // Tono más oscuro para AppBar en modo oscuro
        foregroundColor: Colors.white,
      ),
      colorScheme: ColorScheme.fromSwatch(
        primarySwatch: Colors.deepPurple,
        brightness: Brightness.dark,
      ).copyWith(
        primary: Colors.deepPurple.shade700, // Tono principal para modo oscuro
        secondary: Colors.deepPurpleAccent.shade700,
        surface: const Color(0xFF121212), // Corregido de 'background' a 'surface'
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Colors.white, // Corregido de 'onBackground' a 'onSurface'
        error: Colors.redAccent,
        onError: Colors.white,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.deepPurple.shade700,
          foregroundColor: Colors.white,
        ),
      ),
    ),
  },
  'Light Green': {
    'light': _baseLightTheme.copyWith(
      // Removido primarySwatch aquí
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.lightGreen,
        foregroundColor: Colors.white, // Asegura buen contraste
      ),
      colorScheme: ColorScheme.fromSwatch(
        primarySwatch: Colors.lightGreen,
        brightness: Brightness.light,
      ).copyWith(
        secondary: Colors.lightGreenAccent,
        surface: Colors.white, // Corregido de 'background' a 'surface'
        onPrimary: Colors.white, // Asegura buen contraste
        onSecondary: Colors.black87,
        onSurface: Colors.black87, // Corregido de 'onBackground' a 'onSurface'
        error: Colors.red,
        onError: Colors.white,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.lightGreen,
          foregroundColor: Colors.black87,
        ),
      ),
    ),
    'dark': _baseDarkTheme.copyWith(
      // Removido primarySwatch aquí
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.lightGreen.shade900,
        foregroundColor: Colors.white,
      ),
      colorScheme: ColorScheme.fromSwatch(
        primarySwatch: Colors.lightGreen,
        brightness: Brightness.dark,
      ).copyWith(
        primary: Colors.lightGreen.shade700,
        secondary: Colors.lightGreenAccent.shade700,
        surface: const Color(0xFF121212), // Corregido de 'background' a 'surface'
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Colors.white, // Corregido de 'onBackground' a 'onSurface'
        error: Colors.redAccent,
        onError: Colors.white,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.lightGreen.shade700,
          foregroundColor: Colors.white,
        ),
      ),
    ),
  },
  'Cyan': {
    'light': _baseLightTheme.copyWith(
      // Removido primarySwatch aquí
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.cyan,
        foregroundColor: Colors.white, // Asegura buen contraste
      ),
      colorScheme: ColorScheme.fromSwatch(
        primarySwatch: Colors.cyan,
        brightness: Brightness.light,
      ).copyWith(
        secondary: Colors.cyanAccent,
        surface: Colors.white, // Corregido de 'background' a 'surface'
        onPrimary: Colors.white, // Asegura buen contraste
        onSecondary: Colors.black87,
        onSurface: Colors.black87, // Corregido de 'onBackground' a 'onSurface'
        error: Colors.red,
        onError: Colors.white,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.cyan,
          foregroundColor: Colors.black87,
        ),
      ),
    ),
    'dark': _baseDarkTheme.copyWith(
      // Removido primarySwatch aquí
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
        surface: const Color(0xFF121212), // Corregido de 'background' a 'surface'
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Colors.white, // Corregido de 'onBackground' a 'onSurface'
        error: Colors.redAccent,
        onError: Colors.white,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.cyan.shade700,
          foregroundColor: Colors.white,
        ),
      ),
    ),
  },
  'Light Blue': {
    'light': _baseLightTheme.copyWith(
      // Removido primarySwatch aquí
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      colorScheme: ColorScheme.fromSwatch(
        primarySwatch: Colors.blue,
        brightness: Brightness.light,
      ).copyWith(
        secondary: Colors.blueAccent,
        surface: Colors.white, // Corregido de 'background' a 'surface'
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Colors.black87, // Corregido de 'onBackground' a 'onSurface'
        error: Colors.red,
        onError: Colors.white,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
      ),
    ),
    'dark': _baseDarkTheme.copyWith(
      // Removido primarySwatch aquí
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
        surface: const Color(0xFF121212), // Corregido de 'background' a 'surface'
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Colors.white, // Corregido de 'onBackground' a 'onSurface'
        error: Colors.redAccent,
        onError: Colors.white,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue.shade700,
          foregroundColor: Colors.white,
        ),
      ),
    ),
  },
};
