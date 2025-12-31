// lib/blocs/theme/theme_bloc.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:devocional_nuevo/utils/theme_constants.dart';
import 'theme_event.dart';
import 'theme_state.dart';
import 'theme_repository.dart';

/// BLoC for managing theme functionality
class ThemeBloc extends Bloc<ThemeEvent, ThemeState> {
  final ThemeRepository _repository;

  ThemeBloc({ThemeRepository? repository})
      : _repository = repository ?? ThemeRepository(),
        super(const ThemeInitial()) {
    // Register event handlers
    on<LoadTheme>(_onLoadTheme);
    on<ChangeThemeFamily>(_onChangeThemeFamily);
    on<ChangeBrightness>(_onChangeBrightness);
    on<InitializeThemeDefaults>(_onInitializeThemeDefaults);
  }

  /// Load theme settings from storage
  Future<void> _onLoadTheme(LoadTheme event, Emitter<ThemeState> emit) async {
    try {
      emit(const ThemeLoading());

      final settings = await _repository.loadThemeSettings();
      final themeFamily = settings['themeFamily'] as String;
      final brightness = settings['brightness'] as Brightness;

      // Validate theme family exists in constants
      final validatedThemeFamily = appThemeFamilies.containsKey(themeFamily)
          ? themeFamily
          : ThemeRepository.defaultThemeFamily;

      emit(
        ThemeLoaded.withThemeData(
          themeFamily: validatedThemeFamily,
          brightness: brightness,
        ),
      );
    } catch (e) {
      emit(ThemeError('Failed to load theme: ${e.toString()}'));
    }
  }

  /// Change theme family (color scheme)
  Future<void> _onChangeThemeFamily(
    ChangeThemeFamily event,
    Emitter<ThemeState> emit,
  ) async {
    if (state is! ThemeLoaded) return;

    final currentState = state as ThemeLoaded;

    // Don't change if it's the same family
    if (currentState.themeFamily == event.themeFamily) return;

    // Validate theme family exists
    if (!appThemeFamilies.containsKey(event.themeFamily)) {
      emit(ThemeError('Invalid theme family: ${event.themeFamily}'));
      return;
    }

    try {
      // Save to repository
      await _repository.saveThemeFamily(event.themeFamily);

      // Emit new state
      emit(
        ThemeLoaded.withThemeData(
          themeFamily: event.themeFamily,
          brightness: currentState.brightness,
        ),
      );
    } catch (e) {
      emit(ThemeError('Failed to change theme family: ${e.toString()}'));
    }
  }

  /// Change brightness (light/dark mode)
  Future<void> _onChangeBrightness(
    ChangeBrightness event,
    Emitter<ThemeState> emit,
  ) async {
    if (state is! ThemeLoaded) return;

    final currentState = state as ThemeLoaded;

    // Don't change if it's the same brightness
    if (currentState.brightness == event.brightness) return;

    try {
      // Save to repository
      await _repository.saveBrightness(event.brightness);

      // Emit new state
      emit(
        ThemeLoaded.withThemeData(
          themeFamily: currentState.themeFamily,
          brightness: event.brightness,
        ),
      );
    } catch (e) {
      emit(ThemeError('Failed to change brightness: ${e.toString()}'));
    }
  }

  /// Initialize with defaults (for testing environments)
  Future<void> _onInitializeThemeDefaults(
    InitializeThemeDefaults event,
    Emitter<ThemeState> emit,
  ) async {
    emit(
      ThemeLoaded.withThemeData(
        themeFamily: ThemeRepository.defaultThemeFamily,
        brightness: ThemeRepository.defaultBrightness,
      ),
    );
  }

  /// Helper method for immediate theme access (compatible with old API)
  String get currentThemeFamily {
    final currentState = state;
    if (currentState is ThemeLoaded) {
      return currentState.themeFamily;
    }
    return ThemeRepository.defaultThemeFamily;
  }

  /// Helper method for immediate brightness access (compatible with old API)
  Brightness get currentBrightness {
    final currentState = state;
    if (currentState is ThemeLoaded) {
      return currentState.brightness;
    }
    return ThemeRepository.defaultBrightness;
  }

  /// Helper method for immediate theme data access (compatible with old API)
  ThemeData get currentTheme {
    final currentState = state;
    if (currentState is ThemeLoaded) {
      return currentState.themeData;
    }
    // Return default theme as fallback
    return appThemeFamilies[ThemeRepository.defaultThemeFamily]!['light']!;
  }

  /// Helper method for adaptive divider color (compatible with old API)
  Color get dividerAdaptiveColor {
    final currentState = state;
    if (currentState is ThemeLoaded) {
      return currentState.dividerAdaptiveColor;
    }
    return Colors.black; // Default for light mode
  }
}
