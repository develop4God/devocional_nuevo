// lib/utils/theme_constants.dart
// Este archivo define las constantes de ThemeData para los diferentes temas de la aplicación,
// agrupados por familia de color y modo (claro/oscuro).
//ajustes tema green y pink

import 'package:flutter/material.dart';
// Necesario para WidgetStateProperty y WidgetState

// Definición de temas base (pueden ser usados directamente si se desea, o como parte de las familias)
// Estos temas base ayudan a evitar la repetición de propiedades comunes como brightness, scaffoldBackgroundColor, etc.
final ThemeData _baseLightTheme = ThemeData(
  brightness: Brightness.light,
  scaffoldBackgroundColor: Colors.white,
  visualDensity: VisualDensity.adaptivePlatformDensity,
  // Tema por defecto para ElevatedButtons en modo claro (restaurado a su estado original)
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      // El foreground color se establecerá por el colorScheme.onPrimary de cada tema específico
      // o se dejará que derive del tema si no se especifica aquí.
      // Para este base, lo dejaremos en blanco para que los copyWith lo definan.
    ),
  ),
  // INICIO: Configuración para los temas de entrada de texto (InputDecorationTheme) para TODOS los temas claros
  inputDecorationTheme: InputDecorationTheme(
    contentPadding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
    labelStyle: const TextStyle(color: Colors.grey),
    hintStyle: const TextStyle(color: Colors.grey),
    floatingLabelStyle: const TextStyle(color: Colors.grey),
    errorStyle: TextStyle(color: Colors.red.shade700),
    // Borde general para todos los estados. Establece un gris visible por defecto.
    border: const OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(4.0)),
      borderSide: BorderSide(color: Colors.grey, width: 1.0),
    ),
    // Borde cuando el campo está habilitado pero no enfocado.
    enabledBorder: const OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(4.0)),
      borderSide: BorderSide(color: Colors.grey, width: 1.0),
    ),
    // Borde cuando hay un error y el campo no está enfocado.
    errorBorder: const OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(4.0)),
      borderSide: BorderSide(color: Colors.red, width: 1.0),
    ),
    // Borde cuando hay un error y el campo está enfocado.
    focusedErrorBorder: const OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(4.0)),
      borderSide: BorderSide(color: Colors.red, width: 2.0),
    ),
  ),
  // FIN: Configuración para los temas de entrada de texto

  // INICIO: Configuración CONSTANTE de SwitchThemeData para TODOS los temas claros
  switchTheme: SwitchThemeData(
    thumbColor: WidgetStateProperty.resolveWith<Color?>((Set<WidgetState> states) { // MODIFICADO: MaterialState a WidgetState
      if (!states.contains(WidgetState.selected)) {
        // Cuando el switch está inactivo (apagado), el pulgar es Colors.grey[850]
        return Colors.grey[850];
      }
      // Cuando el switch está activo, retornar null permite que la propiedad 'activeColor'
      // del propio widget Switch (en settings_page.dart) tome el control, usando colorScheme.primary.
      return null;
    }),
    trackColor: WidgetStateProperty.resolveWith<Color?>((Set<WidgetState> states) { // MODIFICADO: MaterialState a WidgetState
      if (!states.contains(WidgetState.selected)) {
        // Cuando el switch está inactivo (apagado), el riel es Colors.grey[300]
        return Colors.grey[300];
      }
      // Cuando el switch está activo, retornar null permite que la propiedad 'activeColor'
      // del propio widget Switch tome el control, usando colorScheme.primary.
      return null;
    }),
    trackOutlineColor: WidgetStateProperty.resolveWith<Color?>((Set<WidgetState> states) { // MODIFICADO: MaterialState a WidgetState
      if (!states.contains(WidgetState.selected)) {
        // Cuando el switch está inactivo (apagado), el borde es Colors.grey
        return Colors.grey;
      }
      return null; // Deja que el tema se encargue del estado activo
    }),
  ),
  // FIN: Configuración CONSTANTE de SwitchThemeData
);

final ThemeData _baseDarkTheme = ThemeData(
  brightness: Brightness.dark,
  scaffoldBackgroundColor: Colors.black87, // Un gris muy oscuro para el fondo del scaffold
  visualDensity: VisualDensity.adaptivePlatformDensity,
  // Tema por defecto para ElevatedButtons en modo oscuro (restaurado a su estado original)
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      // El foreground color se establecerá por el colorScheme.onPrimary de cada tema específico
    ),
  ),
  // INICIO: Configuración para los temas de entrada de texto (InputDecorationTheme) para TODOS los temas oscuros
  inputDecorationTheme: const InputDecorationTheme(
    contentPadding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
    labelStyle: TextStyle(color: Colors.white70),
    hintStyle: TextStyle(color: Colors.grey),
    floatingLabelStyle: TextStyle(color: Colors.white),
    errorStyle: TextStyle(color: Colors.redAccent),
    // Borde general para todos los estados. Establece un gris visible por defecto.
    border: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(4.0)),
      borderSide: BorderSide(color: Colors.grey, width: 1.0),
    ),
    // Borde cuando el campo está habilitado pero no enfocado.
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(4.0)),
      borderSide: BorderSide(color: Colors.grey, width: 1.0),
    ),
    // Borde cuando hay un error y el campo no está enfocado.
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(4.0)),
      borderSide: BorderSide(color: Colors.redAccent, width: 1.0),
    ),
    // Borde cuando hay un error y el campo está enfocado.
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(4.0)),
      borderSide: BorderSide(color: Colors.redAccent, width: 2.0),
    ),
  ),
  // FIN: Configuración para los temas de entrada de texto

  // INICIO: Configuración CONSTANTE de SwitchThemeData para TODOS los temas oscuros
  switchTheme: SwitchThemeData(
    thumbColor: WidgetStateProperty.resolveWith<Color?>((Set<WidgetState> states) { // MODIFICADO: MaterialState a WidgetState
      if (!states.contains(WidgetState.selected)) {
        // Cuando el switch está inactivo (apagado), el pulgar es blanco para visibilidad en fondos oscuros
        return Colors.white;
      }
      // Cuando el switch está activo, retornar null permite que la propiedad 'activeColor'
      // del propio widget Switch tome el control, usando colorScheme.primary.
      return null;
    }),
    trackColor: WidgetStateProperty.resolveWith<Color?>((Set<WidgetState> states) { // MODIFICADO: MaterialState a WidgetState
      if (!states.contains(WidgetState.selected)) {
        // Cuando el switch está inactivo (apagado), el riel es un gris oscuro para visibilidad en fondos oscuros
        return Colors.grey.shade700;
      }
      // Cuando el switch está activo, retornar null permite que la propiedad 'activeColor'
      // del propio widget Switch tome el control, usando colorScheme.primary.
      return null;
    }),
  ),
  // FIN: Configuración CONSTANTE de SwitchThemeData
);

// --- Familias de Temas ---
// Este mapa organiza todos los temas disponibles por una "familia" de color (ej. 'Deep Purple')
// y luego por su modo de brillo ('light' o 'dark').
// El ThemeProvider utilizará este mapa para obtener el ThemeData correcto.
final Map<String, Map<String, ThemeData>> appThemeFamilies = {
  'Deep Purple': {
    'light': _baseLightTheme.copyWith(
      // Eliminado 'primarySwatch' de aquí para evitar el error "isn't defined"
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
        // 'onBackground' ha sido reemplazado por 'onSurface'
        error: Colors.red, // Color para errores
        onError: Colors.white, // Color para texto/iconos sobre error
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
      // Eliminado switchTheme de aquí, se hereda de _baseLightTheme
    ),
    'dark': _baseDarkTheme.copyWith(
      // Eliminado 'primarySwatch' de aquí para evitar el error "isn't defined"
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
        // 'onBackground' ha sido reemplazado por 'onSurface'
        error: Colors.redAccent,
        onError: Colors.white,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.deepPurple.shade700,
          foregroundColor: Colors.white,
        ),
      ),
      // Eliminado switchTheme de aquí, se hereda de _baseDarkTheme
    ),
  },
  'Green': {
    'light': _baseLightTheme.copyWith(
      // Eliminado 'primarySwatch' de aquí para evitar el error "isn't defined"
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.green,
        foregroundColor: Colors.white, // Asegura buen contraste
      ),
      colorScheme: ColorScheme.fromSwatch(
        primarySwatch: Colors.green,
        brightness: Brightness.light,
      ).copyWith(
        secondary: Colors.greenAccent,
        surface: Colors.white, // Corregido de 'background' a 'surface'
        onPrimary: Colors.white, // Asegura buen contraste
        onSecondary: Colors.black87,
        onSurface: Colors.black87, // Corregido de 'onBackground' a 'onSurface'
        // 'onBackground' ha sido reemplazado por 'onSurface'
        error: Colors.red,
        onError: Colors.white,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.black87,
        ),
      ),
      // Eliminado switchTheme de aquí, se hereda de _baseLightTheme
    ),
    'dark': _baseDarkTheme.copyWith(
      // Eliminado 'primarySwatch' de aquí para evitar el error "isn't defined"
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.green.shade900,
        foregroundColor: Colors.white,
      ),
      colorScheme: ColorScheme.fromSwatch(
        primarySwatch: Colors.green,
        brightness: Brightness.dark,
      ).copyWith(
        primary: Colors.green.shade700,
        secondary: Colors.lightGreenAccent.shade700, // Manteniendo este para un acento consistente
        surface: const Color(0xFF121212),
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Colors.white,
        // 'onBackground' ha sido reemplazado por 'onSurface'
        error: Colors.redAccent,
        onError: Colors.white,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green.shade700,
          foregroundColor: Colors.white,
        ),
      ),
      // Eliminado switchTheme de aquí, se hereda de _baseDarkTheme
    ),
  },
  'Pink': { // INICIO: Nuevo tema 'Pink'
    'light': _baseLightTheme.copyWith(
      // Eliminado 'primarySwatch' de aquí para evitar el error "isn't defined"
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.pink,
        foregroundColor: Colors.white, // Asegura buen contraste
      ),
      colorScheme: ColorScheme.fromSwatch(
        primarySwatch: Colors.pink,
        brightness: Brightness.light,
      ).copyWith(
        secondary: Colors.pinkAccent,
        surface: Colors.white, // Corregido de 'background' a 'surface'
        onPrimary: Colors.white, // Asegura buen contraste
        onSecondary: Colors.black87,
        onSurface: Colors.black87, // Corregido de 'onBackground' a 'onSurface'
        // 'onBackground' ha sido reemplazado por 'onSurface'
        error: Colors.red,
        onError: Colors.white,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.pink,
          foregroundColor: Colors.black87,
        ),
      ),
      // Eliminado switchTheme de aquí, se hereda de _baseLightTheme
    ),
    'dark': _baseDarkTheme.copyWith(
      // Eliminado 'primarySwatch' de aquí para evitar el error "isn't defined"
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
        // 'onBackground' ha sido reemplazado por 'onSurface'
        error: Colors.redAccent,
        onError: Colors.white,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.pink.shade700,
          foregroundColor: Colors.white,
        ),
      ),
      // Eliminado switchTheme de aquí, se hereda de _baseDarkTheme
    ),
  }, // FIN: Nuevo tema 'Pink'
  'Cyan': {
    'light': _baseLightTheme.copyWith(
      // Eliminado 'primarySwatch' de aquí para evitar el error "isn't defined"
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.cyan,
        foregroundColor: Colors.white, // Asegura buen contraste
      ),
      colorScheme: ColorScheme.fromSwatch(
        primarySwatch: Colors.cyan,
        brightness: Brightness.light,
      ).copyWith(
        secondary: Colors.cyanAccent,
        surface: Colors.white,
        onPrimary: Colors.white, // Asegura buen contraste
        onSecondary: Colors.black87,
        onSurface: Colors.black87,
        // 'onBackground' ha sido reemplazado por 'onSurface'
        error: Colors.red,
        onError: Colors.white,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.cyan,
          foregroundColor: Colors.black87,
        ),
      ),
      // Eliminado switchTheme de aquí, se hereda de _baseLightTheme
    ),
    'dark': _baseDarkTheme.copyWith(
      // Eliminado 'primarySwatch' de aquí para evitar el error "isn't defined"
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
        // 'onBackground' ha sido reemplazado por 'onSurface'
        error: Colors.redAccent,
        onError: Colors.white,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.cyan.shade700,
          foregroundColor: Colors.white,
        ),
      ),
      // Eliminado switchTheme de aquí, se hereda de _baseDarkTheme
    ),
  },
  'Light Blue': {
    'light': _baseLightTheme.copyWith(
      // Eliminado 'primarySwatch' de aquí para evitar el error "isn't defined"
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
        // 'onBackground' ha sido reemplazado por 'onSurface'
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
      // Eliminado switchTheme de aquí, se hereda de _baseLightTheme
    ),
    'dark': _baseDarkTheme.copyWith(
      // Eliminado 'primarySwatch' de aquí para evitar el error "isn't defined"
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
        // 'onBackground' ha sido reemplazado por 'onSurface'
        error: Colors.redAccent,
        onError: Colors.white,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue.shade700,
          foregroundColor: Colors.white,
        ),
      ),
      // Eliminado switchTheme de aquí, se hereda de _baseDarkTheme
    ),
  },
};
// Constante para mapear los nombres internos de los temas a nombres amigables para el usuario
const Map<String, String> themeDisplayNames = {
  'Deep Purple': 'Realeza',
  'Cyan': 'Obediencia',
  'Green': 'Vida',
  'Pink': 'Pureza',
  'Light Blue': 'Celestial',
};
// Estilo de texto estandarizado para títulos de sección/opciones en SettingsPage
// Define un tamaño de fuente específico para ser usado con copyWith y merge.
const TextStyle settingsOptionTextStyle = TextStyle(fontSize: 20.0);