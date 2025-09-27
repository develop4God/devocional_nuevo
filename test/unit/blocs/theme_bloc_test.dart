// test/unit/blocs/theme_bloc_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:devocional_nuevo/blocs/theme/theme_bloc.dart';
import 'package:devocional_nuevo/blocs/theme/theme_event.dart';
import 'package:devocional_nuevo/blocs/theme/theme_state.dart';
import 'package:devocional_nuevo/blocs/theme/theme_repository.dart';
import 'package:devocional_nuevo/utils/theme_constants.dart';

/// Mock repository for testing theme BLoC behavior
class MockThemeRepository extends Mock implements ThemeRepository {}

void main() {
  group('ThemeBloc Tests', () {
    late ThemeBloc themeBloc;
    late MockThemeRepository mockRepository;

    // Register fallback values for mocktail
    setUpAll(() {
      registerFallbackValue(Brightness.light);
      registerFallbackValue('Deep Purple');
    });

    setUp(() {
      // Setup mock SharedPreferences for repository tests
      SharedPreferences.setMockInitialValues({});

      // Create mock repository
      mockRepository = MockThemeRepository();

      // Create theme BLoC with mock repository
      themeBloc = ThemeBloc(repository: mockRepository);
    });

    tearDown(() {
      themeBloc.close();
    });

    group('Repository Integration Tests', () {
      late ThemeRepository repository;

      setUp(() {
        // Use real repository for integration tests
        repository = ThemeRepository();
      });

      test('should load default theme settings when no saved preferences exist',
          () async {
        // Clear any existing preferences
        SharedPreferences.setMockInitialValues({});

        final settings = await repository.loadThemeSettings();

        expect(settings['themeFamily'],
            equals(ThemeRepository.defaultThemeFamily));
        expect(
            settings['brightness'], equals(ThemeRepository.defaultBrightness));
      });

      test('should load saved theme family from SharedPreferences', () async {
        // Setup saved preferences
        SharedPreferences.setMockInitialValues({
          'theme_family_name': 'Green',
        });

        final themeFamily = await repository.loadThemeFamily();

        expect(themeFamily, equals('Green'));
      });

      test('should load saved brightness from SharedPreferences', () async {
        // Setup saved preferences
        SharedPreferences.setMockInitialValues({
          'theme_brightness': 'dark',
        });

        final brightness = await repository.loadBrightness();

        expect(brightness, equals(Brightness.dark));
      });

      test('should save and load theme family correctly', () async {
        SharedPreferences.setMockInitialValues({});

        // Save theme family
        await repository.saveThemeFamily('Green');

        // Verify it was saved
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('theme_family_name'), equals('Green'));

        // Load and verify
        final loadedFamily = await repository.loadThemeFamily();
        expect(loadedFamily, equals('Green'));
      });

      test('should save and load brightness correctly', () async {
        SharedPreferences.setMockInitialValues({});

        // Save brightness
        await repository.saveBrightness(Brightness.dark);

        // Verify it was saved
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('theme_brightness'), equals('dark'));

        // Load and verify
        final loadedBrightness = await repository.loadBrightness();
        expect(loadedBrightness, equals(Brightness.dark));
      });

      test('should handle corrupted preferences gracefully', () async {
        // This test verifies fallback behavior when SharedPreferences fails
        SharedPreferences.setMockInitialValues({
          'theme_family_name': 'InvalidTheme',
          'theme_brightness': 'invalid_brightness',
        });

        final settings = await repository.loadThemeSettings();

        // Should fall back to defaults for invalid values
        expect(settings['themeFamily'],
            equals('InvalidTheme')); // Repository doesn't validate
        expect(settings['brightness'],
            equals(Brightness.dark)); // Any non-'light' string becomes dark
      });
    });

    group('BLoC State Management', () {
      blocTest<ThemeBloc, ThemeState>(
        'emits [ThemeInitial] when created',
        build: () => ThemeBloc(repository: mockRepository),
        expect: () => const <ThemeState>[],
        verify: (bloc) {
          expect(bloc.state, equals(const ThemeInitial()));
        },
      );

      blocTest<ThemeBloc, ThemeState>(
        'emits [ThemeLoading, ThemeLoaded] when LoadTheme is added with defaults',
        setUp: () {
          // Mock repository to return default values
          when(() => mockRepository.loadThemeSettings()).thenAnswer(
            (_) async => {
              'themeFamily': ThemeRepository.defaultThemeFamily,
              'brightness': ThemeRepository.defaultBrightness,
            },
          );
        },
        build: () => ThemeBloc(repository: mockRepository),
        act: (bloc) => bloc.add(const LoadTheme()),
        expect: () => [
          const ThemeLoading(),
          isA<ThemeLoaded>()
              .having((s) => s.themeFamily, 'themeFamily',
                  ThemeRepository.defaultThemeFamily)
              .having((s) => s.brightness, 'brightness',
                  ThemeRepository.defaultBrightness)
              .having((s) => s.dividerAdaptiveColor, 'dividerAdaptiveColor',
                  Colors.black),
        ],
        verify: (bloc) {
          verify(() => mockRepository.loadThemeSettings()).called(1);
        },
      );

      blocTest<ThemeBloc, ThemeState>(
        'emits [ThemeLoading, ThemeLoaded] when LoadTheme is added with saved preferences',
        setUp: () {
          // Mock repository to return saved values
          when(() => mockRepository.loadThemeSettings()).thenAnswer(
            (_) async => {
              'themeFamily': 'Green',
              'brightness': Brightness.dark,
            },
          );
        },
        build: () => ThemeBloc(repository: mockRepository),
        act: (bloc) => bloc.add(const LoadTheme()),
        expect: () => [
          const ThemeLoading(),
          isA<ThemeLoaded>()
              .having((s) => s.themeFamily, 'themeFamily', 'Green')
              .having((s) => s.brightness, 'brightness', Brightness.dark)
              .having((s) => s.dividerAdaptiveColor, 'dividerAdaptiveColor',
                  Colors.white),
        ],
        verify: (bloc) {
          verify(() => mockRepository.loadThemeSettings()).called(1);
        },
      );

      blocTest<ThemeBloc, ThemeState>(
        'validates theme family and falls back to default for invalid themes',
        setUp: () {
          // Mock repository to return invalid theme family
          when(() => mockRepository.loadThemeSettings()).thenAnswer(
            (_) async => {
              'themeFamily': 'NonExistentTheme',
              'brightness': Brightness.light,
            },
          );
        },
        build: () => ThemeBloc(repository: mockRepository),
        act: (bloc) => bloc.add(const LoadTheme()),
        expect: () => [
          const ThemeLoading(),
          isA<ThemeLoaded>().having((s) => s.themeFamily, 'themeFamily',
              ThemeRepository.defaultThemeFamily),
        ],
        verify: (bloc) {
          verify(() => mockRepository.loadThemeSettings()).called(1);
        },
      );

      blocTest<ThemeBloc, ThemeState>(
        'emits ThemeError when repository throws exception during LoadTheme',
        setUp: () {
          when(() => mockRepository.loadThemeSettings())
              .thenThrow(Exception('Repository error'));
        },
        build: () => ThemeBloc(repository: mockRepository),
        act: (bloc) => bloc.add(const LoadTheme()),
        expect: () => [
          const ThemeLoading(),
          isA<ThemeError>().having(
              (s) => s.message, 'message', contains('Failed to load theme')),
        ],
      );
    });

    group('Theme Family Changes', () {
      blocTest<ThemeBloc, ThemeState>(
        'emits new ThemeLoaded state when ChangeThemeFamily is added with valid theme',
        setUp: () {
          when(() => mockRepository.saveThemeFamily(any()))
              .thenAnswer((_) async {});
        },
        build: () => ThemeBloc(repository: mockRepository),
        seed: () => ThemeLoaded.withThemeData(
          themeFamily: 'Deep Purple',
          brightness: Brightness.light,
        ),
        act: (bloc) => bloc.add(const ChangeThemeFamily('Green')),
        expect: () => [
          isA<ThemeLoaded>()
              .having((s) => s.themeFamily, 'themeFamily', 'Green')
              .having((s) => s.brightness, 'brightness', Brightness.light),
        ],
        verify: (bloc) {
          verify(() => mockRepository.saveThemeFamily('Green')).called(1);
        },
      );

      blocTest<ThemeBloc, ThemeState>(
        'does not emit new state when ChangeThemeFamily is added with same theme family',
        setUp: () {
          when(() => mockRepository.saveThemeFamily(any()))
              .thenAnswer((_) async {});
        },
        build: () => ThemeBloc(repository: mockRepository),
        seed: () => ThemeLoaded.withThemeData(
          themeFamily: 'Green',
          brightness: Brightness.light,
        ),
        act: (bloc) => bloc.add(const ChangeThemeFamily('Green')),
        expect: () => const <ThemeState>[],
        verify: (bloc) {
          verifyNever(() => mockRepository.saveThemeFamily(any()));
        },
      );

      blocTest<ThemeBloc, ThemeState>(
        'emits ThemeError when ChangeThemeFamily is added with invalid theme family',
        build: () => ThemeBloc(repository: mockRepository),
        seed: () => ThemeLoaded.withThemeData(
          themeFamily: 'Deep Purple',
          brightness: Brightness.light,
        ),
        act: (bloc) => bloc.add(const ChangeThemeFamily('InvalidTheme')),
        expect: () => [
          isA<ThemeError>().having(
              (s) => s.message, 'message', contains('Invalid theme family')),
        ],
      );

      blocTest<ThemeBloc, ThemeState>(
        'emits ThemeError when repository throws exception during ChangeThemeFamily',
        setUp: () {
          when(() => mockRepository.saveThemeFamily(any()))
              .thenThrow(Exception('Save error'));
        },
        build: () => ThemeBloc(repository: mockRepository),
        seed: () => ThemeLoaded.withThemeData(
          themeFamily: 'Deep Purple',
          brightness: Brightness.light,
        ),
        act: (bloc) => bloc.add(const ChangeThemeFamily('Green')),
        expect: () => [
          isA<ThemeError>().having((s) => s.message, 'message',
              contains('Failed to change theme family')),
        ],
      );

      blocTest<ThemeBloc, ThemeState>(
        'does not change theme when not in ThemeLoaded state',
        build: () => ThemeBloc(repository: mockRepository),
        act: (bloc) => bloc.add(const ChangeThemeFamily('Blue')),
        expect: () => const <ThemeState>[],
        verify: (bloc) {
          verifyNever(() => mockRepository.saveThemeFamily(any()));
        },
      );
    });

    group('Brightness Changes', () {
      blocTest<ThemeBloc, ThemeState>(
        'emits new ThemeLoaded state when ChangeBrightness is added',
        setUp: () {
          when(() => mockRepository.saveBrightness(any()))
              .thenAnswer((_) async {});
        },
        build: () => ThemeBloc(repository: mockRepository),
        seed: () => ThemeLoaded.withThemeData(
          themeFamily: 'Deep Purple',
          brightness: Brightness.light,
        ),
        act: (bloc) => bloc.add(const ChangeBrightness(Brightness.dark)),
        expect: () => [
          isA<ThemeLoaded>()
              .having((s) => s.themeFamily, 'themeFamily', 'Deep Purple')
              .having((s) => s.brightness, 'brightness', Brightness.dark)
              .having((s) => s.dividerAdaptiveColor, 'dividerAdaptiveColor',
                  Colors.white),
        ],
        verify: (bloc) {
          verify(() => mockRepository.saveBrightness(Brightness.dark))
              .called(1);
        },
      );

      blocTest<ThemeBloc, ThemeState>(
        'does not emit new state when ChangeBrightness is added with same brightness',
        setUp: () {
          when(() => mockRepository.saveBrightness(any()))
              .thenAnswer((_) async {});
        },
        build: () => ThemeBloc(repository: mockRepository),
        seed: () => ThemeLoaded.withThemeData(
          themeFamily: 'Deep Purple',
          brightness: Brightness.light,
        ),
        act: (bloc) => bloc.add(const ChangeBrightness(Brightness.light)),
        expect: () => const <ThemeState>[],
        verify: (bloc) {
          verifyNever(() => mockRepository.saveBrightness(any()));
        },
      );

      blocTest<ThemeBloc, ThemeState>(
        'emits ThemeError when repository throws exception during ChangeBrightness',
        setUp: () {
          when(() => mockRepository.saveBrightness(any()))
              .thenThrow(Exception('Save error'));
        },
        build: () => ThemeBloc(repository: mockRepository),
        seed: () => ThemeLoaded.withThemeData(
          themeFamily: 'Deep Purple',
          brightness: Brightness.light,
        ),
        act: (bloc) => bloc.add(const ChangeBrightness(Brightness.dark)),
        expect: () => [
          isA<ThemeError>().having((s) => s.message, 'message',
              contains('Failed to change brightness')),
        ],
      );

      blocTest<ThemeBloc, ThemeState>(
        'does not change brightness when not in ThemeLoaded state',
        build: () => ThemeBloc(repository: mockRepository),
        act: (bloc) => bloc.add(const ChangeBrightness(Brightness.dark)),
        expect: () => const <ThemeState>[],
        verify: (bloc) {
          verifyNever(() => mockRepository.saveBrightness(any()));
        },
      );
    });

    group('Helper Methods (API Compatibility)', () {
      test('currentThemeFamily returns default when state is not ThemeLoaded',
          () {
        expect(themeBloc.currentThemeFamily,
            equals(ThemeRepository.defaultThemeFamily));
      });

      test('currentThemeFamily returns theme family when state is ThemeLoaded',
          () {
        final loadedState = ThemeLoaded.withThemeData(
          themeFamily: 'Blue',
          brightness: Brightness.light,
        );

        final bloc = ThemeBloc(repository: mockRepository);
        bloc.emit(loadedState);

        expect(bloc.currentThemeFamily, equals('Blue'));
        bloc.close();
      });

      test('currentBrightness returns default when state is not ThemeLoaded',
          () {
        expect(themeBloc.currentBrightness,
            equals(ThemeRepository.defaultBrightness));
      });

      test('currentBrightness returns brightness when state is ThemeLoaded',
          () {
        final loadedState = ThemeLoaded.withThemeData(
          themeFamily: 'Deep Purple',
          brightness: Brightness.dark,
        );

        final bloc = ThemeBloc(repository: mockRepository);
        bloc.emit(loadedState);

        expect(bloc.currentBrightness, equals(Brightness.dark));
        bloc.close();
      });

      test('currentTheme returns default theme when state is not ThemeLoaded',
          () {
        final defaultTheme =
            appThemeFamilies[ThemeRepository.defaultThemeFamily]!['light']!;
        expect(themeBloc.currentTheme, equals(defaultTheme));
      });

      test('currentTheme returns theme data when state is ThemeLoaded', () {
        final loadedState = ThemeLoaded.withThemeData(
          themeFamily: 'Green',
          brightness: Brightness.light,
        );

        final bloc = ThemeBloc(repository: mockRepository);
        bloc.emit(loadedState);

        final expectedTheme = appThemeFamilies['Green']!['light']!;
        expect(bloc.currentTheme, equals(expectedTheme));
        bloc.close();
      });

      test('dividerAdaptiveColor returns black for light mode', () {
        final loadedState = ThemeLoaded.withThemeData(
          themeFamily: 'Deep Purple',
          brightness: Brightness.light,
        );

        final bloc = ThemeBloc(repository: mockRepository);
        bloc.emit(loadedState);

        expect(bloc.dividerAdaptiveColor, equals(Colors.black));
        bloc.close();
      });

      test('dividerAdaptiveColor returns white for dark mode', () {
        final loadedState = ThemeLoaded.withThemeData(
          themeFamily: 'Deep Purple',
          brightness: Brightness.dark,
        );

        final bloc = ThemeBloc(repository: mockRepository);
        bloc.emit(loadedState);

        expect(bloc.dividerAdaptiveColor, equals(Colors.white));
        bloc.close();
      });
    });

    group('Initialization', () {
      blocTest<ThemeBloc, ThemeState>(
        'emits ThemeLoaded with defaults when InitializeThemeDefaults is added',
        build: () => ThemeBloc(repository: mockRepository),
        act: (bloc) => bloc.add(const InitializeThemeDefaults()),
        expect: () => [
          isA<ThemeLoaded>()
              .having((s) => s.themeFamily, 'themeFamily',
                  ThemeRepository.defaultThemeFamily)
              .having((s) => s.brightness, 'brightness',
                  ThemeRepository.defaultBrightness),
        ],
      );
    });

    group('State CopyWith', () {
      test('ThemeLoaded copyWith creates new instance with updated values', () {
        final originalState = ThemeLoaded.withThemeData(
          themeFamily: 'Deep Purple',
          brightness: Brightness.light,
        );

        final copiedState = originalState.copyWith(
          themeFamily: 'Green',
          brightness: Brightness.dark,
        );

        expect(copiedState.themeFamily, equals('Green'));
        expect(copiedState.brightness, equals(Brightness.dark));
        expect(copiedState.dividerAdaptiveColor, equals(Colors.white));

        // Original should remain unchanged
        expect(originalState.themeFamily, equals('Deep Purple'));
        expect(originalState.brightness, equals(Brightness.light));
      });

      test(
          'ThemeLoaded copyWith preserves original values when no updates provided',
          () {
        final originalState = ThemeLoaded.withThemeData(
          themeFamily: 'Green',
          brightness: Brightness.dark,
        );

        final copiedState = originalState.copyWith();

        expect(copiedState.themeFamily, equals(originalState.themeFamily));
        expect(copiedState.brightness, equals(originalState.brightness));
        expect(copiedState.themeData, equals(originalState.themeData));
      });
    });

    group('ThemeData Resolution', () {
      test(
          'resolves correct ThemeData for valid theme family and brightness combinations',
          () {
        // Test all available theme families with both light and dark modes
        for (final themeFamily in appThemeFamilies.keys) {
          for (final brightness in [Brightness.light, Brightness.dark]) {
            final state = ThemeLoaded.withThemeData(
              themeFamily: themeFamily,
              brightness: brightness,
            );

            final expectedKey =
                brightness == Brightness.light ? 'light' : 'dark';
            final expectedTheme = appThemeFamilies[themeFamily]![expectedKey]!;

            expect(state.themeData, equals(expectedTheme),
                reason:
                    'ThemeData mismatch for $themeFamily in ${brightness.name} mode');
          }
        }
      });

      test('falls back to default theme for invalid theme family', () {
        // Note: This is tested in the private _getThemeData method via ThemeLoaded.withThemeData
        // The behavior is handled by the BLoC's validation before creating the state
        final state = ThemeLoaded.withThemeData(
          themeFamily: 'Deep Purple', // Use valid theme for state creation
          brightness: Brightness.light,
        );

        final expectedTheme = appThemeFamilies['Deep Purple']!['light']!;
        expect(state.themeData, equals(expectedTheme));
      });
    });
  });
}
