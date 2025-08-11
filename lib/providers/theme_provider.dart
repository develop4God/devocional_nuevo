// Este archivo maneja la lógica de cambio de temas y notifica a los oyentes sobre los cambios.

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Importa shared_preferences
import 'package:devocional_nuevo/utils/theme_constants.dart'; // Importa las constantes de tema

class ThemeProvider extends ChangeNotifier {
  // Claves para guardar las preferencias de tema de forma separada
  static const String _themeFamilyKey = 'theme_family_name';
  static const String _brightnessKey = 'theme_brightness';

  // Valores por defecto al iniciar la aplicación
  String _currentThemeFamily = 'Deep Purple'; // Familia de color por defecto
  Brightness _currentBrightness =
      Brightness.light; // Modo de brillo por defecto
  // MODIFICADO: El tema inicial ahora se obtiene del mapa appThemeFamilies
  ThemeData _currentTheme = appThemeFamilies['Deep Purple']![
      'light']!; // Tema inicial (será actualizado al cargar preferencias)

  ThemeProvider() {
    _loadThemePreference(); // Cargar las preferencias de tema al inicializar
  }

  // Getters para acceder al tema actual, la familia de color y el brillo
  ThemeData get currentTheme => _currentTheme;
  String get currentThemeFamily => _currentThemeFamily;
  Brightness get currentBrightness => _currentBrightness;

  /// NUEVO: Getter para color de línea adaptativo según el modo (light/dark)
  /// Coloca este getter debajo de los getters existentes, **dentro** de la clase ThemeProvider.
  Color get dividerAdaptiveColor {
    return _currentBrightness == Brightness.dark ? Colors.white : Colors.black;
  }

  // Método interno para actualizar el ThemeData basado en la familia y el brillo actuales
  void _updateTheme() {
    final String brightnessKey =
        _currentBrightness == Brightness.light ? 'light' : 'dark';
    // Busca el tema en el mapa appThemeFamilies. Si no lo encuentra, usa el tema Deep Purple Light como fallback.
    _currentTheme = appThemeFamilies[_currentThemeFamily]?[brightnessKey] ??
        appThemeFamilies['Deep Purple']!['light']!;
    notifyListeners(); // Notifica a los widgets que escuchan sobre el cambio de tema
  }

  // Método para establecer la familia de colores del tema
  Future<void> setThemeFamily(String familyName) async {
    if (_currentThemeFamily == familyName) {
      return; // No hacer nada si es el mismo
    }
    _currentThemeFamily = familyName;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _themeFamilyKey, familyName); // Guarda la preferencia de la familia
    _updateTheme(); // Actualiza el tema y notifica a los oyentes
  }

  // Método para establecer el modo de brillo (claro/oscuro)
  Future<void> setBrightness(Brightness brightness) async {
    if (_currentBrightness == brightness) {
      return; // No hacer nada si es el mismo
    }
    _currentBrightness = brightness;
    final prefs = await SharedPreferences.getInstance();
    // Guarda la preferencia del brillo como string ('light' o 'dark')
    await prefs.setString(
        _brightnessKey, brightness == Brightness.light ? 'light' : 'dark');
    _updateTheme(); // Actualiza el tema y notifica a los oyentes
  }

  // Carga las preferencias de tema guardadas al inicio
  Future<void> _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    final savedThemeFamily = prefs.getString(_themeFamilyKey);
    final savedBrightnessString = prefs.getString(_brightnessKey);

    // Si hay una familia guardada y es válida, la usa
    if (savedThemeFamily != null &&
        appThemeFamilies.containsKey(savedThemeFamily)) {
      _currentThemeFamily = savedThemeFamily;
    }

    // Si hay un brillo guardado, lo usa
    if (savedBrightnessString != null) {
      _currentBrightness =
          savedBrightnessString == 'light' ? Brightness.light : Brightness.dark;
    }

    _updateTheme(); // Aplica las preferencias cargadas para establecer el tema inicial
  }
}
