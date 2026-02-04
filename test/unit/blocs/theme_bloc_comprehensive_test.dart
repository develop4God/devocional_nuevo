// test/unit/blocs/theme_bloc_comprehensive_test.dart

import 'package:devocional_nuevo/blocs/theme/theme_bloc.dart';
import 'package:devocional_nuevo/blocs/theme/theme_event.dart';
import 'package:devocional_nuevo/blocs/theme/theme_state.dart';
import 'package:devocional_nuevo/utils/theme_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

@Tags(['unit', 'blocs'])
void main() {
  group('ThemeBloc - Comprehensive Real User Behavior Tests', () {
    late ThemeBloc bloc;

    setUp(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      SharedPreferences.setMockInitialValues({});
      bloc = ThemeBloc();
    });

    tearDown(() async {
      await bloc.close();
    });

    group('Initial State and Loading', () {
      test('Bloc starts in initial state', () {
        final newBloc = ThemeBloc();
        expect(newBloc.state, isA<ThemeInitial>());
        newBloc.close();
      });

      test('User loads theme settings for first time - defaults applied',
          () async {
        bloc.add(LoadTheme());
        await Future.delayed(const Duration(milliseconds: 100));

        final state = bloc.state as ThemeLoaded;
        expect(state.themeFamily, isNotNull);
        expect(state.brightness, isNotNull);
        expect(state.themeData, isNotNull);
      });

      test('User initializes theme defaults', () async {
        bloc.add(InitializeThemeDefaults());
        await Future.delayed(const Duration(milliseconds: 100));

        final state = bloc.state as ThemeLoaded;
        expect(state.themeFamily, isNotNull);
        expect(state.brightness, isNotNull);
      });
    });

    group('User Scenario: Changing theme family (color schemes)', () {
      test('User changes to different theme family', () async {
        bloc.add(LoadTheme());
        await Future.delayed(const Duration(milliseconds: 100));

        final initialState = bloc.state as ThemeLoaded;
        final initialFamily = initialState.themeFamily;

        // Find a different theme family to switch to
        final differentFamily = appThemeFamilies.keys.firstWhere(
          (family) => family != initialFamily,
          orElse: () => appThemeFamilies.keys.first,
        );

        bloc.add(ChangeThemeFamily(differentFamily));
        await Future.delayed(const Duration(milliseconds: 100));

        final newState = bloc.state as ThemeLoaded;
        expect(newState.themeFamily, equals(differentFamily));
        expect(newState.themeData, isNotNull);
      });

      test('User tries to change to same theme family - no change', () async {
        bloc.add(LoadTheme());
        await Future.delayed(const Duration(milliseconds: 100));

        final initialState = bloc.state as ThemeLoaded;
        final currentFamily = initialState.themeFamily;

        bloc.add(ChangeThemeFamily(currentFamily));
        await Future.delayed(const Duration(milliseconds: 100));

        final newState = bloc.state as ThemeLoaded;
        expect(newState.themeFamily, equals(currentFamily));
      });

      test('User switches between multiple theme families', () async {
        bloc.add(LoadTheme());
        await Future.delayed(const Duration(milliseconds: 100));

        // Get available theme families
        final themeFamilies = appThemeFamilies.keys.toList();
        if (themeFamilies.length < 2) {
          // Skip if not enough themes
          return;
        }

        // Switch to first theme
        bloc.add(ChangeThemeFamily(themeFamilies[0]));
        await Future.delayed(const Duration(milliseconds: 50));

        var state = bloc.state as ThemeLoaded;
        expect(state.themeFamily, equals(themeFamilies[0]));

        // Switch to second theme
        bloc.add(ChangeThemeFamily(themeFamilies[1]));
        await Future.delayed(const Duration(milliseconds: 50));

        state = bloc.state as ThemeLoaded;
        expect(state.themeFamily, equals(themeFamilies[1]));

        // Switch back to first theme
        bloc.add(ChangeThemeFamily(themeFamilies[0]));
        await Future.delayed(const Duration(milliseconds: 50));

        state = bloc.state as ThemeLoaded;
        expect(state.themeFamily, equals(themeFamilies[0]));
      });

      test('Invalid theme family results in error', () async {
        bloc.add(LoadTheme());
        await Future.delayed(const Duration(milliseconds: 100));

        bloc.add(ChangeThemeFamily('invalid_theme_family_xyz'));
        await Future.delayed(const Duration(milliseconds: 100));

        final state = bloc.state;
        expect(state, isA<ThemeError>());
      });
    });

    group('User Scenario: Changing brightness (light/dark mode)', () {
      test('User switches from light to dark mode', () async {
        bloc.add(LoadTheme());
        await Future.delayed(const Duration(milliseconds: 100));

        var state = bloc.state as ThemeLoaded;
        final initialBrightness = state.brightness;

        final targetBrightness = initialBrightness == Brightness.light
            ? Brightness.dark
            : Brightness.light;

        bloc.add(ChangeBrightness(targetBrightness));
        await Future.delayed(const Duration(milliseconds: 100));

        state = bloc.state as ThemeLoaded;
        expect(state.brightness, equals(targetBrightness));
        expect(state.themeData.brightness, equals(targetBrightness));
      });

      test('User toggles between light and dark mode multiple times', () async {
        bloc.add(LoadTheme());
        await Future.delayed(const Duration(milliseconds: 100));

        // Toggle to dark
        bloc.add(ChangeBrightness(Brightness.dark));
        await Future.delayed(const Duration(milliseconds: 50));

        var state = bloc.state as ThemeLoaded;
        expect(state.brightness, equals(Brightness.dark));

        // Toggle to light
        bloc.add(ChangeBrightness(Brightness.light));
        await Future.delayed(const Duration(milliseconds: 50));

        state = bloc.state as ThemeLoaded;
        expect(state.brightness, equals(Brightness.light));

        // Toggle back to dark
        bloc.add(ChangeBrightness(Brightness.dark));
        await Future.delayed(const Duration(milliseconds: 50));

        state = bloc.state as ThemeLoaded;
        expect(state.brightness, equals(Brightness.dark));
      });

      test('Brightness change preserves theme family', () async {
        bloc.add(LoadTheme());
        await Future.delayed(const Duration(milliseconds: 100));

        var state = bloc.state as ThemeLoaded;
        final themeFamily = state.themeFamily;

        bloc.add(ChangeBrightness(Brightness.dark));
        await Future.delayed(const Duration(milliseconds: 100));

        state = bloc.state as ThemeLoaded;
        expect(state.themeFamily, equals(themeFamily),
            reason: 'Theme family should remain unchanged');
        expect(state.brightness, equals(Brightness.dark));
      });
    });

    group('User Scenario: Combined theme and brightness changes', () {
      test('User changes both theme family and brightness', () async {
        bloc.add(LoadTheme());
        await Future.delayed(const Duration(milliseconds: 100));

        final initialState = bloc.state as ThemeLoaded;

        // Get a different theme family
        final themeFamilies = appThemeFamilies.keys.toList();
        final differentFamily = themeFamilies.firstWhere(
          (family) => family != initialState.themeFamily,
          orElse: () => themeFamilies.first,
        );

        // Change theme family
        bloc.add(ChangeThemeFamily(differentFamily));
        await Future.delayed(const Duration(milliseconds: 50));

        // Change brightness
        bloc.add(ChangeBrightness(Brightness.dark));
        await Future.delayed(const Duration(milliseconds: 50));

        final finalState = bloc.state as ThemeLoaded;
        expect(finalState.themeFamily, equals(differentFamily));
        expect(finalState.brightness, equals(Brightness.dark));
      });
    });

    group('Data Persistence', () {
      test('Theme settings persist after closing and reopening bloc', () async {
        bloc.add(LoadTheme());
        await Future.delayed(const Duration(milliseconds: 100));

        final themeFamilies = appThemeFamilies.keys.toList();
        if (themeFamilies.isNotEmpty) {
          bloc.add(ChangeThemeFamily(themeFamilies.first));
          await Future.delayed(const Duration(milliseconds: 50));
        }

        bloc.add(ChangeBrightness(Brightness.dark));
        await Future.delayed(const Duration(milliseconds: 100));

        final state = bloc.state as ThemeLoaded;
        final savedFamily = state.themeFamily;
        final savedBrightness = state.brightness;

        await bloc.close();

        // Create new bloc (simulating app restart)
        final bloc2 = ThemeBloc();
        bloc2.add(LoadTheme());
        await Future.delayed(const Duration(milliseconds: 100));

        final loadedState = bloc2.state as ThemeLoaded;
        expect(loadedState.themeFamily, equals(savedFamily),
            reason: 'Theme family should persist');
        expect(loadedState.brightness, equals(savedBrightness),
            reason: 'Brightness should persist');

        await bloc2.close();
      });
    });

    group('Theme Data Validation', () {
      test('ThemeData object is properly generated', () async {
        bloc.add(LoadTheme());
        await Future.delayed(const Duration(milliseconds: 100));

        final state = bloc.state as ThemeLoaded;
        expect(state.themeData, isNotNull);
        expect(state.themeData.brightness, equals(state.brightness));
        expect(state.themeData.primaryColor, isNotNull);
      });

      test('All available theme families are valid', () {
        // Verify all registered theme families can be loaded
        for (final family in appThemeFamilies.keys) {
          expect(appThemeFamilies[family], isNotNull,
              reason: 'Theme family $family should have theme data');
        }
      });

      test('Theme data changes when theme family changes', () async {
        bloc.add(LoadTheme());
        await Future.delayed(const Duration(milliseconds: 100));

        final initialState = bloc.state as ThemeLoaded;
        final initialThemeData = initialState.themeData;

        final themeFamilies = appThemeFamilies.keys.toList();
        if (themeFamilies.length < 2) return;

        final differentFamily = themeFamilies.firstWhere(
          (family) => family != initialState.themeFamily,
          orElse: () => themeFamilies.first,
        );

        bloc.add(ChangeThemeFamily(differentFamily));
        await Future.delayed(const Duration(milliseconds: 100));

        final newState = bloc.state as ThemeLoaded;
        final newThemeData = newState.themeData;

        // Theme data should be different (different primary color likely)
        expect(newThemeData, isNot(equals(initialThemeData)));
      });

      test('Theme data changes when brightness changes', () async {
        bloc.add(LoadTheme());
        await Future.delayed(const Duration(milliseconds: 100));

        var state = bloc.state as ThemeLoaded;
        final initialThemeData = state.themeData;
        final oppositeBrightness = state.brightness == Brightness.light
            ? Brightness.dark
            : Brightness.light;

        bloc.add(ChangeBrightness(oppositeBrightness));
        await Future.delayed(const Duration(milliseconds: 100));

        state = bloc.state as ThemeLoaded;
        final newThemeData = state.themeData;

        expect(newThemeData.brightness, equals(oppositeBrightness));
        expect(newThemeData.brightness,
            isNot(equals(initialThemeData.brightness)));
      });
    });

    group('Edge Cases', () {
      test('Rapid theme changes are handled correctly', () async {
        bloc.add(LoadTheme());
        await Future.delayed(const Duration(milliseconds: 100));

        final themeFamilies = appThemeFamilies.keys.toList();
        if (themeFamilies.length < 2) return;

        // Rapid changes
        bloc.add(ChangeThemeFamily(themeFamilies[0]));
        bloc.add(ChangeBrightness(Brightness.dark));
        if (themeFamilies.length > 1) {
          bloc.add(ChangeThemeFamily(themeFamilies[1]));
        }
        bloc.add(ChangeBrightness(Brightness.light));

        await Future.delayed(const Duration(milliseconds: 200));

        final state = bloc.state;
        expect(state, isA<ThemeLoaded>());
      });
    });
  });
}
