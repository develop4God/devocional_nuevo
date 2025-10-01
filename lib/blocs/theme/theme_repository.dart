// lib/blocs/theme/theme_repository.dart
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

/// Repository for managing theme-related data persistence
class ThemeRepository {
  // SharedPreferences keys - keeping same as ThemeProvider for compatibility
  static const String _themeFamilyKey = 'theme_family_name';
  static const String _brightnessKey = 'theme_brightness';

  // Default values
  static const String defaultThemeFamily = 'Deep Purple';
  static const Brightness defaultBrightness = Brightness.light;

  /// Load theme family from SharedPreferences
  Future<String> loadThemeFamily() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedThemeFamily = prefs.getString(_themeFamilyKey);
      return savedThemeFamily ?? defaultThemeFamily;
    } catch (e) {
      return defaultThemeFamily;
    }
  }

  /// Save theme family to SharedPreferences
  Future<void> saveThemeFamily(String themeFamily) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themeFamilyKey, themeFamily);
    } catch (e) {
      // Fail silently but log error in debug mode
      assert(false, 'Failed to save theme family: $e');
    }
  }

  /// Load brightness from SharedPreferences
  Future<Brightness> loadBrightness() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedBrightnessString = prefs.getString(_brightnessKey);

      if (savedBrightnessString != null) {
        return savedBrightnessString == 'light'
            ? Brightness.light
            : Brightness.dark;
      }
      return defaultBrightness;
    } catch (e) {
      return defaultBrightness;
    }
  }

  /// Save brightness to SharedPreferences
  Future<void> saveBrightness(Brightness brightness) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final brightnessString =
          brightness == Brightness.light ? 'light' : 'dark';
      await prefs.setString(_brightnessKey, brightnessString);
    } catch (e) {
      // Fail silently but log error in debug mode
      assert(false, 'Failed to save brightness: $e');
    }
  }

  /// Load both theme family and brightness
  Future<Map<String, dynamic>> loadThemeSettings() async {
    final results = await Future.wait([
      loadThemeFamily(),
      loadBrightness(),
    ]);

    return {
      'themeFamily': results[0] as String,
      'brightness': results[1] as Brightness,
    };
  }
}
