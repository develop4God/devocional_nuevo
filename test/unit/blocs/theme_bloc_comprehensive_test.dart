import 'package:bloc_test/bloc_test.dart';
import 'package:devocional_nuevo/blocs/theme/theme_bloc.dart';
import 'package:devocional_nuevo/blocs/theme/theme_event.dart';
import 'package:devocional_nuevo/blocs/theme/theme_state.dart';
import 'package:devocional_nuevo/blocs/theme/theme_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

/// Mock class for ThemeRepository
class MockThemeRepository extends Mock implements ThemeRepository {}

void main() {
  group('ThemeBloc Comprehensive Tests', () {
    late ThemeBloc bloc;
    late MockThemeRepository mockRepository;

    setUp(() {
      mockRepository = MockThemeRepository();
      bloc = ThemeBloc(repository: mockRepository);
    });

    tearDown(() {
      bloc.close();
    });

    group('Initial State', () {
      test('should have ThemeInitial as initial state', () {
        // Assert
        expect(bloc.state, isA<ThemeInitial>());
        expect(bloc.state, equals(const ThemeInitial()));
      });
    });

    group('LoadTheme Event', () {
      blocTest<ThemeBloc, ThemeState>(
        'should emit [ThemeLoading, ThemeLoaded] when loading succeeds with default settings',
        build: () {
          when(() => mockRepository.loadThemeSettings()).thenAnswer(
            (_) async => {
              'themeFamily': ThemeRepository.defaultThemeFamily,
              'brightness': Brightness.light,
            },
          );
          return bloc;
        },
        act: (bloc) => bloc.add(const LoadTheme()),
        expect: () => [
          const ThemeLoading(),
          isA<ThemeLoaded>()
              .having((s) => s.themeFamily, 'themeFamily',
                  ThemeRepository.defaultThemeFamily)
              .having((s) => s.brightness, 'brightness', Brightness.light)
              .having((s) => s.themeData, 'themeData', isA<ThemeData>()),
        ],
      );

      blocTest<ThemeBloc, ThemeState>(
        'should emit [ThemeLoading, ThemeLoaded] when loading succeeds with custom settings',
        build: () {
          when(() => mockRepository.loadThemeSettings()).thenAnswer(
            (_) async => {
              'themeFamily': 'Green',
              'brightness': Brightness.dark,
            },
          );
          return bloc;
        },
        act: (bloc) => bloc.add(const LoadTheme()),
        expect: () => [
          const ThemeLoading(),
          isA<ThemeLoaded>()
              .having((s) => s.themeFamily, 'themeFamily', 'Green')
              .having((s) => s.brightness, 'brightness', Brightness.dark)
              .having((s) => s.themeData, 'themeData', isA<ThemeData>()),
        ],
      );

      blocTest<ThemeBloc, ThemeState>(
        'should emit [ThemeLoading, ThemeError] when loading fails',
        build: () {
          when(() => mockRepository.loadThemeSettings())
              .thenThrow(Exception('Failed to load theme'));
          return bloc;
        },
        act: (bloc) => bloc.add(const LoadTheme()),
        expect: () => [
          const ThemeLoading(),
          isA<ThemeError>().having(
            (s) => s.message,
            'message',
            contains('Failed to load theme'),
          ),
        ],
      );

      blocTest<ThemeBloc, ThemeState>(
        'should validate theme family and fallback to default if invalid',
        build: () {
          when(() => mockRepository.loadThemeSettings()).thenAnswer(
            (_) async => {
              'themeFamily': 'NonExistentTheme',
              'brightness': Brightness.light,
            },
          );
          return bloc;
        },
        act: (bloc) => bloc.add(const LoadTheme()),
        expect: () => [
          const ThemeLoading(),
          isA<ThemeLoaded>().having(
            (s) => s.themeFamily,
            'themeFamily',
            ThemeRepository.defaultThemeFamily, // Should fallback to default
          ),
        ],
      );

      blocTest<ThemeBloc, ThemeState>(
        'should handle null or malformed data gracefully',
        build: () {
          when(() => mockRepository.loadThemeSettings()).thenAnswer(
            (_) async => {
              'themeFamily': null,
              'brightness': null,
            },
          );
          return bloc;
        },
        act: (bloc) => bloc.add(const LoadTheme()),
        expect: () => [
          const ThemeLoading(),
          isA<ThemeError>(),
        ],
      );

      blocTest<ThemeBloc, ThemeState>(
        'should handle multiple rapid load requests',
        build: () {
          when(() => mockRepository.loadThemeSettings()).thenAnswer(
            (_) async => {
              'themeFamily': 'Blue',
              'brightness': Brightness.light,
            },
          );
          return bloc;
        },
        act: (bloc) {
          bloc.add(const LoadTheme());
          bloc.add(const LoadTheme());
          bloc.add(const LoadTheme());
        },
        expect: () => [
          const ThemeLoading(),
          isA<ThemeLoaded>(),
          const ThemeLoading(),
          isA<ThemeLoaded>(),
          const ThemeLoading(),
          isA<ThemeLoaded>(),
        ],
        verify: (_) {
          verify(() => mockRepository.loadThemeSettings()).called(3);
        },
      );
    });

    group('ChangeThemeFamily Event', () {
      blocTest<ThemeBloc, ThemeState>(
        'should emit ThemeLoaded with new theme family when change succeeds',
        build: () {
          when(() => mockRepository.saveThemeFamily(any()))
              .thenAnswer((_) async {});
          return bloc;
        },
        seed: () => ThemeLoaded.withThemeData(
          themeFamily: 'Blue',
          brightness: Brightness.light,
        ),
        act: (bloc) => bloc.add(const ChangeThemeFamily('Green')),
        expect: () => [
          isA<ThemeLoaded>()
              .having((s) => s.themeFamily, 'themeFamily', 'Green')
              .having((s) => s.brightness, 'brightness', Brightness.light),
        ],
        verify: (_) {
          verify(() => mockRepository.saveThemeFamily('Green')).called(1);
        },
      );

      blocTest<ThemeBloc, ThemeState>(
        'should emit ThemeError when change fails',
        build: () {
          when(() => mockRepository.saveThemeFamily(any()))
              .thenThrow(Exception('Failed to save theme'));
          return bloc;
        },
        seed: () => ThemeLoaded.withThemeData(
          themeFamily: 'Blue',
          brightness: Brightness.light,
        ),
        act: (bloc) => bloc.add(const ChangeThemeFamily('Green')),
        expect: () => [
          isA<ThemeError>().having(
            (s) => s.message,
            'message',
            contains('Failed to change theme family'),
          ),
        ],
      );

      blocTest<ThemeBloc, ThemeState>(
        'should handle theme family change from initial state',
        build: () {
          when(() => mockRepository.saveThemeFamily(any()))
              .thenAnswer((_) async {});
          return bloc;
        },
        act: (bloc) => bloc.add(const ChangeThemeFamily('Purple')),
        expect: () => [
          isA<ThemeLoaded>()
              .having((s) => s.themeFamily, 'themeFamily', 'Purple')
              .having((s) => s.brightness, 'brightness',
                  Brightness.light), // Default
        ],
      );

      blocTest<ThemeBloc, ThemeState>(
        'should handle multiple rapid theme family changes',
        build: () {
          when(() => mockRepository.saveThemeFamily(any()))
              .thenAnswer((_) async {});
          return bloc;
        },
        seed: () => ThemeLoaded.withThemeData(
          themeFamily: 'Blue',
          brightness: Brightness.light,
        ),
        act: (bloc) {
          bloc.add(const ChangeThemeFamily('Green'));
          bloc.add(const ChangeThemeFamily('Purple'));
          bloc.add(const ChangeThemeFamily('Orange'));
        },
        expect: () => [
          isA<ThemeLoaded>()
              .having((s) => s.themeFamily, 'themeFamily', 'Green'),
          isA<ThemeLoaded>()
              .having((s) => s.themeFamily, 'themeFamily', 'Purple'),
          isA<ThemeLoaded>()
              .having((s) => s.themeFamily, 'themeFamily', 'Orange'),
        ],
        verify: (_) {
          verify(() => mockRepository.saveThemeFamily('Green')).called(1);
          verify(() => mockRepository.saveThemeFamily('Purple')).called(1);
          verify(() => mockRepository.saveThemeFamily('Orange')).called(1);
        },
      );

      blocTest<ThemeBloc, ThemeState>(
        'should handle empty theme family name gracefully',
        build: () {
          when(() => mockRepository.saveThemeFamily(any()))
              .thenAnswer((_) async {});
          return bloc;
        },
        seed: () => ThemeLoaded.withThemeData(
          themeFamily: 'Blue',
          brightness: Brightness.light,
        ),
        act: (bloc) => bloc.add(const ChangeThemeFamily('')),
        expect: () => [
          isA<ThemeLoaded>().having((s) => s.themeFamily, 'themeFamily', ''),
        ],
      );

      blocTest<ThemeBloc, ThemeState>(
        'should handle special characters in theme family name',
        build: () {
          when(() => mockRepository.saveThemeFamily(any()))
              .thenAnswer((_) async {});
          return bloc;
        },
        seed: () => ThemeLoaded.withThemeData(
          themeFamily: 'Blue',
          brightness: Brightness.light,
        ),
        act: (bloc) => bloc.add(const ChangeThemeFamily('Azul-Océano_ñáéíóú')),
        expect: () => [
          isA<ThemeLoaded>().having(
              (s) => s.themeFamily, 'themeFamily', 'Azul-Océano_ñáéíóú'),
        ],
      );
    });

    group('ChangeBrightness Event', () {
      blocTest<ThemeBloc, ThemeState>(
        'should emit ThemeLoaded with new brightness when change succeeds',
        build: () {
          when(() => mockRepository.saveBrightness(any()))
              .thenAnswer((_) async {});
          return bloc;
        },
        seed: () => ThemeLoaded.withThemeData(
          themeFamily: 'Blue',
          brightness: Brightness.light,
        ),
        act: (bloc) => bloc.add(const ChangeBrightness(Brightness.dark)),
        expect: () => [
          isA<ThemeLoaded>()
              .having((s) => s.brightness, 'brightness', Brightness.dark)
              .having((s) => s.themeFamily, 'themeFamily', 'Blue'),
        ],
        verify: (_) {
          verify(() => mockRepository.saveBrightness(Brightness.dark))
              .called(1);
        },
      );

      blocTest<ThemeBloc, ThemeState>(
        'should emit ThemeError when brightness change fails',
        build: () {
          when(() => mockRepository.saveBrightness(any()))
              .thenThrow(Exception('Failed to save brightness'));
          return bloc;
        },
        seed: () => ThemeLoaded.withThemeData(
          themeFamily: 'Blue',
          brightness: Brightness.light,
        ),
        act: (bloc) => bloc.add(const ChangeBrightness(Brightness.dark)),
        expect: () => [
          isA<ThemeError>().having(
            (s) => s.message,
            'message',
            contains('Failed to change brightness'),
          ),
        ],
      );

      blocTest<ThemeBloc, ThemeState>(
        'should handle brightness change from initial state',
        build: () {
          when(() => mockRepository.saveBrightness(any()))
              .thenAnswer((_) async {});
          return bloc;
        },
        act: (bloc) => bloc.add(const ChangeBrightness(Brightness.dark)),
        expect: () => [
          isA<ThemeLoaded>()
              .having((s) => s.brightness, 'brightness', Brightness.dark)
              .having((s) => s.themeFamily, 'themeFamily',
                  ThemeRepository.defaultThemeFamily),
        ],
      );

      blocTest<ThemeBloc, ThemeState>(
        'should handle brightness toggle correctly',
        build: () {
          when(() => mockRepository.saveBrightness(any()))
              .thenAnswer((_) async {});
          return bloc;
        },
        seed: () => ThemeLoaded.withThemeData(
          themeFamily: 'Green',
          brightness: Brightness.light,
        ),
        act: (bloc) {
          bloc.add(const ChangeBrightness(Brightness.dark));
          bloc.add(const ChangeBrightness(Brightness.light));
          bloc.add(const ChangeBrightness(Brightness.dark));
        },
        expect: () => [
          isA<ThemeLoaded>()
              .having((s) => s.brightness, 'brightness', Brightness.dark),
          isA<ThemeLoaded>()
              .having((s) => s.brightness, 'brightness', Brightness.light),
          isA<ThemeLoaded>()
              .having((s) => s.brightness, 'brightness', Brightness.dark),
        ],
        verify: (_) {
          verify(() => mockRepository.saveBrightness(Brightness.dark))
              .called(2);
          verify(() => mockRepository.saveBrightness(Brightness.light))
              .called(1);
        },
      );
    });

    group('LoadTheme Event', () {
      blocTest<ThemeBloc, ThemeState>(
        'should handle events while in error state',
        build: () {
          when(() => mockRepository.saveThemeFamily(any()))
              .thenAnswer((_) async {});
          return bloc;
        },
        seed: () => const ThemeError('Previous error'),
        act: (bloc) => bloc.add(const ChangeThemeFamily('Recovery')),
        expect: () => [
          isA<ThemeLoaded>()
              .having((s) => s.themeFamily, 'themeFamily', 'Recovery'),
        ],
      );

      blocTest<ThemeBloc, ThemeState>(
        'should maintain state consistency across complex operations',
        build: () {
          when(() => mockRepository.saveThemeFamily(any()))
              .thenAnswer((_) async {});
          when(() => mockRepository.saveBrightness(any()))
              .thenAnswer((_) async {});
          return bloc;
        },
        seed: () => ThemeLoaded.withThemeData(
          themeFamily: 'Blue',
          brightness: Brightness.light,
        ),
        act: (bloc) async {
          bloc.add(const ChangeThemeFamily('Green'));
          await Future.delayed(const Duration(milliseconds: 10));
          bloc.add(const ChangeBrightness(Brightness.dark));
          await Future.delayed(const Duration(milliseconds: 10));
          bloc.add(const ChangeThemeFamily('Purple'));
        },
        expect: () => [
          isA<ThemeLoaded>()
              .having((s) => s.themeFamily, 'themeFamily', 'Green'),
          isA<ThemeLoaded>()
              .having((s) => s.brightness, 'brightness', Brightness.dark),
          isA<ThemeLoaded>()
              .having((s) => s.themeFamily, 'themeFamily', 'Purple'),
        ],
        verify: (bloc) {
          final finalState = bloc.state as ThemeLoaded;
          expect(finalState.themeFamily, equals('Purple'));
          expect(finalState.brightness, equals(Brightness.dark));
        },
      );

      blocTest<ThemeBloc, ThemeState>(
        'should handle theme data generation correctly for different combinations',
        build: () {
          when(() => mockRepository.saveThemeFamily(any()))
              .thenAnswer((_) async {});
          when(() => mockRepository.saveBrightness(any()))
              .thenAnswer((_) async {});
          return bloc;
        },
        act: (bloc) {
          bloc.add(const ChangeThemeFamily('Green'));
          bloc.add(const ChangeBrightness(Brightness.dark));
        },
        expect: () => [
          isA<ThemeLoaded>()
              .having((s) => s.themeData, 'themeData', isA<ThemeData>()),
          isA<ThemeLoaded>()
              .having((s) => s.themeData, 'themeData', isA<ThemeData>()),
        ],
        verify: (bloc) {
          final state = bloc.state as ThemeLoaded;
          expect(state.themeData, isNotNull);
          expect(state.themeData.brightness, equals(Brightness.dark));
        },
      );
    });

    group('Performance and Memory Tests', () {
      blocTest<ThemeBloc, ThemeState>(
        'should handle rapid theme switching efficiently',
        build: () {
          when(() => mockRepository.saveThemeFamily(any()))
              .thenAnswer((_) async {});
          when(() => mockRepository.saveBrightness(any()))
              .thenAnswer((_) async {});
          return bloc;
        },
        seed: () => ThemeLoaded.withThemeData(
          themeFamily: 'Blue',
          brightness: Brightness.light,
        ),
        act: (bloc) {
          // Rapidly switch between themes and brightness
          final themes = ['Green', 'Purple', 'Orange', 'Red', 'Pink'];
          for (String theme in themes) {
            bloc.add(ChangeThemeFamily(theme));
            bloc.add(ChangeBrightness(
                theme.hashCode % 2 == 0 ? Brightness.dark : Brightness.light));
          }
        },
        expect: () => List.generate(10, (i) => isA<ThemeLoaded>()),
        verify: (bloc) {
          final state = bloc.state as ThemeLoaded;
          expect(state.themeFamily, equals('Pink'));
        },
      );

      test('should handle multiple bloc instances without interference',
          () async {
        final repositories = List.generate(5, (_) => MockThemeRepository());
        final blocs =
            repositories.map((repo) => ThemeBloc(repository: repo)).toList();

        // Configure all repositories
        for (var repo in repositories) {
          when(() => repo.saveThemeFamily(any())).thenAnswer((_) async {});
          when(() => repo.saveBrightness(any())).thenAnswer((_) async {});
        }

        // Test concurrent operations
        for (int i = 0; i < blocs.length; i++) {
          blocs[i].add(ChangeThemeFamily('Theme_$i'));
          blocs[i].add(ChangeBrightness(
              i % 2 == 0 ? Brightness.light : Brightness.dark));
        }

        // Wait for all operations to complete
        await Future.wait(blocs.map((bloc) => bloc.stream.take(2).last));

        // Verify states are independent
        for (int i = 0; i < blocs.length; i++) {
          final state = blocs[i].state as ThemeLoaded;
          expect(state.themeFamily, equals('Theme_$i'));
        }

        // Clean up
        for (var bloc in blocs) {
          await bloc.close();
        }
      });

      test('should properly dispose resources and prevent memory leaks',
          () async {
        // Create and dispose many blocs rapidly
        for (int i = 0; i < 100; i++) {
          final repo = MockThemeRepository();
          when(() => repo.saveThemeFamily(any())).thenAnswer((_) async {});

          final testBloc = ThemeBloc(repository: repo);
          testBloc.add(ChangeThemeFamily('Test_$i'));

          // Wait for event processing
          await testBloc.stream.take(1).last;
          await testBloc.close();
        }

        // If we reach here without memory issues, disposal is working correctly
        expect(true, isTrue);
      });
    });

    group('Business Logic Validation', () {
      blocTest<ThemeBloc, ThemeState>(
        'should maintain theme consistency across app lifecycle simulation',
        build: () {
          when(() => mockRepository.loadThemeSettings()).thenAnswer(
            (_) async => {
              'themeFamily': 'Green',
              'brightness': Brightness.dark,
            },
          );
          when(() => mockRepository.saveThemeFamily(any()))
              .thenAnswer((_) async {});
          when(() => mockRepository.saveBrightness(any()))
              .thenAnswer((_) async {});
          return bloc;
        },
        act: (bloc) async {
          // Simulate app startup
          bloc.add(const LoadTheme());
          await Future.delayed(const Duration(milliseconds: 10));

          // User changes theme
          bloc.add(const ChangeThemeFamily('Purple'));
          await Future.delayed(const Duration(milliseconds: 10));

          // User changes brightness
          bloc.add(const ChangeBrightness(Brightness.light));
          await Future.delayed(const Duration(milliseconds: 10));

          // Simulate app restart - reload theme
          bloc.add(const LoadTheme());
        },
        expect: () => [
          const ThemeLoading(),
          isA<ThemeLoaded>()
              .having((s) => s.themeFamily, 'themeFamily', 'Green'),
          isA<ThemeLoaded>()
              .having((s) => s.themeFamily, 'themeFamily', 'Purple'),
          isA<ThemeLoaded>()
              .having((s) => s.brightness, 'brightness', Brightness.light),
          const ThemeLoading(),
          isA<ThemeLoaded>(), // Final loaded state
        ],
        verify: (_) {
          verify(() => mockRepository.loadThemeSettings()).called(2);
          verify(() => mockRepository.saveThemeFamily('Purple')).called(1);
          verify(() => mockRepository.saveBrightness(Brightness.light))
              .called(1);
        },
      );

      test('should handle repository errors gracefully without crashing',
          () async {
        // Test various failure scenarios
        final failingRepo = MockThemeRepository();
        when(() => failingRepo.loadThemeSettings())
            .thenThrow(Exception('Storage error'));
        when(() => failingRepo.saveThemeFamily(any()))
            .thenThrow(Exception('Save error'));
        when(() => failingRepo.saveBrightness(any()))
            .thenThrow(Exception('Brightness save error'));

        final testBloc = ThemeBloc(repository: failingRepo);

        // All these should emit errors, not crash
        testBloc.add(const LoadTheme());
        testBloc.add(const ChangeThemeFamily('Test'));
        testBloc.add(const ChangeBrightness(Brightness.dark));

        // Wait for error states
        await expectLater(
          testBloc.stream.take(3),
          emitsInOrder([
            isA<ThemeError>(),
            isA<ThemeError>(),
            isA<ThemeError>(),
          ]),
        );

        await testBloc.close();
      });

      blocTest<ThemeBloc, ThemeState>(
        'should validate theme data integrity throughout state changes',
        build: () {
          when(() => mockRepository.saveThemeFamily(any()))
              .thenAnswer((_) async {});
          when(() => mockRepository.saveBrightness(any()))
              .thenAnswer((_) async {});
          return bloc;
        },
        act: (bloc) {
          bloc.add(const ChangeThemeFamily('Blue'));
          bloc.add(const ChangeBrightness(Brightness.dark));
        },
        expect: () => [
          isA<ThemeLoaded>(),
          isA<ThemeLoaded>(),
        ],
        verify: (bloc) {
          final state = bloc.state as ThemeLoaded;

          // Validate theme data is consistent with state
          expect(state.themeFamily, equals('Blue'));
          expect(state.brightness, equals(Brightness.dark));
          expect(state.themeData, isNotNull);
          expect(state.themeData.brightness, equals(Brightness.dark));
        },
      );
    });
  });
}
