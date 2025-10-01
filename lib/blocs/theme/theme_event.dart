// lib/blocs/theme/theme_event.dart
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// Events for theme functionality
abstract class ThemeEvent extends Equatable {
  const ThemeEvent();

  @override
  List<Object?> get props => [];
}

/// Load theme settings from storage
class LoadTheme extends ThemeEvent {
  const LoadTheme();
}

/// Change theme family (color scheme)
class ChangeThemeFamily extends ThemeEvent {
  final String themeFamily;

  const ChangeThemeFamily(this.themeFamily);

  @override
  List<Object?> get props => [themeFamily];
}

/// Change brightness (light/dark mode)
class ChangeBrightness extends ThemeEvent {
  final Brightness brightness;

  const ChangeBrightness(this.brightness);

  @override
  List<Object?> get props => [brightness];
}

/// Initialize theme with defaults (for testing)
class InitializeThemeDefaults extends ThemeEvent {
  const InitializeThemeDefaults();
}
