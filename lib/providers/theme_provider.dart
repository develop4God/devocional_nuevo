// lib/providers/theme_provider.dart
// Este archivo maneja la lógica de cambio de temas y notifica a los oyentes sobre los cambios.

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Importa shared_preferences
import 'package:devocional_nuevo/utils/theme_constants.dart'; // Importa las constantes de tema

class ThemeProvider extends ChangeNotifier {
  static const String _themeKey = 'theme_name'; // Clave para guardar el nombre del tema

  // Tema por defecto al iniciar la aplicación
  ThemeData _currentTheme = lightThemePurple;
  String _currentThemeName = 'Deep Purple (Light)';

  ThemeProvider() {
    _loadThemePreference(); // Cargar la preferencia de tema al inicializar
  }

  ThemeData get currentTheme => _currentTheme;
  String get currentThemeName => _currentThemeName;

  // Método para establecer el tema
  void setTheme(String themeName) {
    switch (themeName) {
      case 'Deep Purple (Light)':
        _currentTheme = lightThemePurple;
        break;
      case 'Deep Purple (Dark)':
        _currentTheme = darkThemePurple;
        break;
      case 'Light Green (Light)':
        _currentTheme = lightThemeGreen;
        break;
      case 'Light Green (Dark)':
        _currentTheme = darkThemeGreen;
        break;
      case 'Cyan (Light)':
        _currentTheme = lightThemeCyan;
        break;
      case 'Cyan (Dark)':
        _currentTheme = darkThemeCyan;
        break;
      case 'Light Blue (Light)':
        _currentTheme = lightThemeBlue;
        break;
      case 'Light Blue (Dark)':
        _currentTheme = darkThemeBlue;
        break;
      default:
        _currentTheme = lightThemePurple; // Tema por defecto si no coincide
    }
    _currentThemeName = themeName; // Actualiza el nombre del tema
    _saveThemePreference(themeName); // Guarda la preferencia del tema
    notifyListeners(); // Notifica a los widgets que escuchan
  }

  // Carga la preferencia de tema guardada
  Future<void> _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    final savedThemeName = prefs.getString(_themeKey);
    if (savedThemeName != null) {
      setTheme(savedThemeName); // Aplica el tema guardado
    }
  }

  // Guarda la preferencia de tema
  Future<void> _saveThemePreference(String themeName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, themeName);
  }
}
