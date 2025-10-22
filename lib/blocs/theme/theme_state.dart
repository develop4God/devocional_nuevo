// lib/blocs/theme/theme_state.dart
import 'package:devocional_nuevo/utils/theme_constants.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// States for theme functionality
abstract class ThemeState extends Equatable {
  const ThemeState();

  @override
  List<Object?> get props => [];
}

/// Initial state before theme is loaded
class ThemeInitial extends ThemeState {
  const ThemeInitial();
}

/// Loading theme from storage
class ThemeLoading extends ThemeState {
  const ThemeLoading();
}

/// Theme loaded and active
class ThemeLoaded extends ThemeState {
  final String themeFamily;
  final Brightness brightness;
  final ThemeData themeData;

  const ThemeLoaded({
    required this.themeFamily,
    required this.brightness,
    required this.themeData,
  });

  /// Get adaptive divider color based on brightness
  Color get dividerAdaptiveColor {
    return brightness == Brightness.dark ? Colors.white : Colors.black;
  }

  /// Get system UI overlay style for current theme
  SystemUiOverlayStyle get systemUiOverlayStyle {
    final navBarColor =
        themeData.appBarTheme.backgroundColor ?? themeData.colorScheme.primary;
    final iconBrightness =
        brightness == Brightness.dark ? Brightness.light : Brightness.dark;

    return SystemUiOverlayStyle(
      systemNavigationBarColor: navBarColor,
      systemNavigationBarIconBrightness: iconBrightness,
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: iconBrightness,
    );
  }

  @override
  List<Object?> get props => [themeFamily, brightness, themeData];

  /// Create a copy with updated values
  ThemeLoaded copyWith({
    String? themeFamily,
    Brightness? brightness,
    ThemeData? themeData,
  }) {
    return ThemeLoaded(
      themeFamily: themeFamily ?? this.themeFamily,
      brightness: brightness ?? this.brightness,
      themeData: themeData ?? this.themeData,
    );
  }

  /// Helper to get current ThemeData based on family and brightness
  static ThemeData _getThemeData(String themeFamily, Brightness brightness) {
    final brightnessKey = brightness == Brightness.light ? 'light' : 'dark';
    return appThemeFamilies[themeFamily]?[brightnessKey] ??
        appThemeFamilies['Deep Purple']!['light']!;
  }

  /// Create ThemeLoaded with automatic ThemeData resolution
  factory ThemeLoaded.withThemeData({
    required String themeFamily,
    required Brightness brightness,
  }) {
    return ThemeLoaded(
      themeFamily: themeFamily,
      brightness: brightness,
      themeData: _getThemeData(themeFamily, brightness),
    );
  }
}

/// Error state
class ThemeError extends ThemeState {
  final String message;

  const ThemeError(this.message);

  @override
  List<Object?> get props => [message];
}
