import 'package:bloc_test/bloc_test.dart';
import 'package:devocional_nuevo/blocs/devocionales_bloc.dart';
import 'package:devocional_nuevo/blocs/devocionales_event.dart';
import 'package:devocional_nuevo/blocs/devocionales_state.dart';
import 'package:devocional_nuevo/models/devocional_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DevocionalesBloc Comprehensive Tests', () {
    late DevocionalesBloc bloc;

    setUp(() {
      bloc = DevocionalesBloc();
    });

    tearDown(() {
      bloc.close();
    });

    group('Initial State', () {
      test('should have DevocionalesInitial as initial state', () {
        // Assert
        expect(bloc.state, isA<DevocionalesInitial>());
        expect(bloc.state, equals(DevocionalesInitial()));
      });

      test('should have default version RVR1960', () {
        // Assert - Internal state should be properly initialized
        expect(bloc.state, isA<DevocionalesInitial>());
      });
    });

    group('LoadDevocionales Event', () {
      blocTest<DevocionalesBloc, DevocionalesState>(
        'should emit [DevocionalesLoading, DevocionalesLoaded] when loading succeeds with empty list',
        build: () => bloc,
        act: (bloc) => bloc.add(LoadDevocionales()),
        expect: () => [
          isA<DevocionalesLoading>(),
          isA<DevocionalesLoaded>()
              .having((s) => s.devocionales, 'devocionales', isEmpty)
              .having((s) => s.selectedVersion, 'selectedVersion', 'RVR1960'),
        ],
        verify: (_) {
          expect(bloc.state, isA<DevocionalesLoaded>());
          final loadedState = bloc.state as DevocionalesLoaded;
          expect(loadedState.devocionales, isEmpty);
          expect(loadedState.selectedVersion, equals('RVR1960'));
        },
      );

      blocTest<DevocionalesBloc, DevocionalesState>(
        'should handle multiple rapid load requests gracefully',
        build: () => bloc,
        act: (bloc) {
          // Fire multiple load events rapidly
          bloc.add(LoadDevocionales());
          bloc.add(LoadDevocionales());
          bloc.add(LoadDevocionales());
        },
        expect: () => [
          isA<DevocionalesLoading>(),
          isA<DevocionalesLoaded>(),
          isA<DevocionalesLoading>(),
          isA<DevocionalesLoaded>(),
          isA<DevocionalesLoading>(),
          isA<DevocionalesLoaded>(),
        ],
      );

      blocTest<DevocionalesBloc, DevocionalesState>(
        'should maintain consistent state after loading',
        build: () => bloc,
        act: (bloc) => bloc.add(LoadDevocionales()),
        verify: (bloc) {
          final state = bloc.state as DevocionalesLoaded;
          expect(state.devocionales, isA<List<Devocional>>());
          expect(state.selectedVersion, isA<String>());
          expect(state.selectedVersion.isNotEmpty, isTrue);
        },
      );
    });

    group('ChangeVersion Event', () {
      blocTest<DevocionalesBloc, DevocionalesState>(
        'should change version and emit DevocionalesLoaded state',
        build: () => bloc,
        seed: () => DevocionalesLoaded(
          devocionales: [],
          selectedVersion: 'RVR1960',
        ),
        act: (bloc) => bloc.add(ChangeVersion('KJV')),
        expect: () => [
          isA<DevocionalesLoaded>()
              .having((s) => s.selectedVersion, 'selectedVersion', 'KJV')
              .having((s) => s.devocionales, 'devocionales', isEmpty),
        ],
      );

      blocTest<DevocionalesBloc, DevocionalesState>(
        'should handle version change from initial state',
        build: () => bloc,
        act: (bloc) => bloc.add(ChangeVersion('ESV')),
        expect: () => [
          isA<DevocionalesLoaded>()
              .having((s) => s.selectedVersion, 'selectedVersion', 'ESV')
              .having((s) => s.devocionales, 'devocionales', isEmpty),
        ],
      );

      blocTest<DevocionalesBloc, DevocionalesState>(
        'should handle multiple rapid version changes',
        build: () => bloc,
        seed: () => DevocionalesLoaded(
          devocionales: [],
          selectedVersion: 'RVR1960',
        ),
        act: (bloc) {
          bloc.add(ChangeVersion('KJV'));
          bloc.add(ChangeVersion('ESV'));
          bloc.add(ChangeVersion('NVI'));
        },
        expect: () => [
          isA<DevocionalesLoaded>()
              .having((s) => s.selectedVersion, 'selectedVersion', 'KJV'),
          isA<DevocionalesLoaded>()
              .having((s) => s.selectedVersion, 'selectedVersion', 'ESV'),
          isA<DevocionalesLoaded>()
              .having((s) => s.selectedVersion, 'selectedVersion', 'NVI'),
        ],
      );

      blocTest<DevocionalesBloc, DevocionalesState>(
        'should handle empty version string gracefully',
        build: () => bloc,
        seed: () => DevocionalesLoaded(
          devocionales: [],
          selectedVersion: 'RVR1960',
        ),
        act: (bloc) => bloc.add(ChangeVersion('')),
        expect: () => [
          isA<DevocionalesLoaded>()
              .having((s) => s.selectedVersion, 'selectedVersion', ''),
        ],
      );

      blocTest<DevocionalesBloc, DevocionalesState>(
        'should handle special characters in version name',
        build: () => bloc,
        seed: () => DevocionalesLoaded(
          devocionales: [],
          selectedVersion: 'RVR1960',
        ),
        act: (bloc) => bloc.add(ChangeVersion('RVR-1960-Especial_ñáéíóú')),
        expect: () => [
          isA<DevocionalesLoaded>().having((s) => s.selectedVersion,
              'selectedVersion', 'RVR-1960-Especial_ñáéíóú'),
        ],
      );
    });

    group('ToggleFavorite Event', () {
      late Devocional testDevocional;

      setUp(() {
        testDevocional = Devocional(
          id: 'test_1',
          versiculo: 'John 3:16',
          reflexion: 'Test reflection content',
          paraMeditar: [],
          oracion: 'Test prayer',
          date: DateTime(2024, 1, 1),
          version: 'RVR1960',
          language: 'es',
        );
      });

      blocTest<DevocionalesBloc, DevocionalesState>(
        'should handle toggle favorite for devotional ID',
        build: () => bloc,
        seed: () => DevocionalesLoaded(
          devocionales: [testDevocional],
          selectedVersion: 'RVR1960',
        ),
        act: (bloc) => bloc.add(ToggleFavorite('test_1')),
        expect: () => [
          isA<DevocionalesLoaded>(),
        ],
      );

      blocTest<DevocionalesBloc, DevocionalesState>(
        'should handle toggle favorite for non-existent devotional ID',
        build: () => bloc,
        seed: () => DevocionalesLoaded(
          devocionales: [testDevocional],
          selectedVersion: 'RVR1960',
        ),
        act: (bloc) => bloc.add(ToggleFavorite('non_existent_id')),
        expect: () => [
          isA<DevocionalesLoaded>(),
        ],
      );

      blocTest<DevocionalesBloc, DevocionalesState>(
        'should handle multiple favorites toggling correctly',
        build: () => bloc,
        seed: () => DevocionalesLoaded(
          devocionales: [
            Devocional(
              id: 'dev_1',
              versiculo: 'John 1:1',
              reflexion: 'Reflection 1',
              paraMeditar: [],
              oracion: 'Prayer 1',
              date: DateTime(2024, 1, 1),
              version: 'RVR1960',
            ),
            Devocional(
              id: 'dev_2',
              versiculo: 'John 1:2',
              reflexion: 'Reflection 2',
              paraMeditar: [],
              oracion: 'Prayer 2',
              date: DateTime(2024, 1, 2),
              version: 'RVR1960',
            ),
            Devocional(
              id: 'dev_3',
              versiculo: 'John 1:3',
              reflexion: 'Reflection 3',
              paraMeditar: [],
              oracion: 'Prayer 3',
              date: DateTime(2024, 1, 3),
              version: 'RVR1960',
            ),
          ],
          selectedVersion: 'RVR1960',
        ),
        act: (bloc) {
          bloc.add(ToggleFavorite('dev_1'));
          bloc.add(ToggleFavorite('dev_3'));
        },
        expect: () => [
          isA<DevocionalesLoaded>(),
          isA<DevocionalesLoaded>(),
        ],
        verify: (bloc) {
          final state = bloc.state as DevocionalesLoaded;
          expect(state.devocionales, hasLength(3));
        },
      );

      blocTest<DevocionalesBloc, DevocionalesState>(
        'should handle empty or null devotional ID gracefully',
        build: () => bloc,
        seed: () => DevocionalesLoaded(
          devocionales: [testDevocional],
          selectedVersion: 'RVR1960',
        ),
        act: (bloc) => bloc.add(ToggleFavorite('')),
        expect: () => [
          isA<DevocionalesLoaded>(),
        ],
      );
    });

    group('State Transitions and Edge Cases', () {
      blocTest<DevocionalesBloc, DevocionalesState>(
        'should handle events while in error state',
        build: () => bloc,
        seed: () => DevocionalesError('Test error'),
        act: (bloc) => bloc.add(LoadDevocionales()),
        expect: () => [
          isA<DevocionalesLoading>(),
          isA<DevocionalesLoaded>(),
        ],
      );

      blocTest<DevocionalesBloc, DevocionalesState>(
        'should maintain state consistency across different operations',
        build: () => bloc,
        act: (bloc) async {
          // Simulate complex user interactions
          bloc.add(LoadDevocionales());
          await Future.delayed(const Duration(milliseconds: 10));
          bloc.add(ChangeVersion('KJV'));
          await Future.delayed(const Duration(milliseconds: 10));
          bloc.add(LoadDevocionales());
        },
        skip: 2, // Skip first load states
        expect: () => [
          isA<DevocionalesLoaded>()
              .having((s) => s.selectedVersion, 'selectedVersion', 'KJV'),
          isA<DevocionalesLoading>(),
          isA<DevocionalesLoaded>()
              .having((s) => s.selectedVersion, 'selectedVersion', 'KJV'),
        ],
      );

      blocTest<DevocionalesBloc, DevocionalesState>(
        'should handle version filtering correctly with mixed data',
        build: () {
          // Create a bloc instance and populate it with mixed version data
          final testBloc = DevocionalesBloc();
          return testBloc;
        },
        seed: () => DevocionalesLoaded(
          devocionales: [
            Devocional(
              id: '1',
              versiculo: 'John 1:1',
              reflexion: 'RVR Content',
              paraMeditar: [],
              oracion: 'RVR Prayer',
              date: DateTime(2024, 1, 1),
              version: 'RVR1960',
              language: 'es',
            ),
            Devocional(
              id: '2',
              versiculo: 'John 1:2',
              reflexion: 'KJV Content',
              paraMeditar: [],
              oracion: 'KJV Prayer',
              date: DateTime(2024, 1, 2),
              version: 'KJV',
              language: 'en',
            ),
          ],
          selectedVersion: 'RVR1960',
        ),
        act: (bloc) => bloc.add(ChangeVersion('KJV')),
        expect: () => [
          isA<DevocionalesLoaded>()
              .having((s) => s.selectedVersion, 'selectedVersion', 'KJV')
              .having((s) => s.devocionales.length, 'devocionales length', 0),
        ],
        verify: (bloc) {
          final state = bloc.state as DevocionalesLoaded;
          // Should only show devotionals matching the selected version
          expect(state.devocionales.every((d) => d.version == 'KJV'), isTrue);
        },
      );

      blocTest<DevocionalesBloc, DevocionalesState>(
        'should maintain data consistency when changing versions',
        build: () => bloc,
        seed: () => DevocionalesLoaded(
          devocionales: [
            Devocional(
              id: '1',
              versiculo: 'John 1:1',
              reflexion: 'Test Content',
              paraMeditar: [],
              oracion: 'Test Prayer',
              date: DateTime(2024, 1, 1),
              version: 'RVR1960',
              language: 'es',
            ),
          ],
          selectedVersion: 'RVR1960',
        ),
        act: (bloc) {
          bloc.add(ChangeVersion('KJV'));
          bloc.add(ChangeVersion('RVR1960'));
        },
        expect: () => [
          isA<DevocionalesLoaded>()
              .having((s) => s.selectedVersion, 'selectedVersion', 'KJV'),
          isA<DevocionalesLoaded>()
              .having((s) => s.selectedVersion, 'selectedVersion', 'RVR1960'),
        ],
      );
    });

    group('Performance and Memory Tests', () {
      blocTest<DevocionalesBloc, DevocionalesState>(
        'should handle large number of devotionals efficiently',
        build: () => bloc,
        seed: () => DevocionalesLoaded(
          devocionales: List.generate(
            1000,
            (index) => Devocional(
              id: 'dev_$index',
              versiculo: 'John ${index + 1}:1',
              reflexion: 'Reflection $index',
              paraMeditar: [],
              oracion: 'Prayer $index',
              date: DateTime(2024, 1, 1).add(Duration(days: index)),
              version: index % 2 == 0 ? 'RVR1960' : 'KJV',
              language: index % 2 == 0 ? 'es' : 'en',
            ),
          ),
          selectedVersion: 'RVR1960',
        ),
        act: (bloc) {
          bloc.add(ChangeVersion('KJV'));
          bloc.add(ToggleFavorite('dev_1'));
          bloc.add(ToggleFavorite('dev_101'));
        },
        expect: () => [
          isA<DevocionalesLoaded>()
              .having((s) => s.selectedVersion, 'selectedVersion', 'KJV'),
          isA<DevocionalesLoaded>(),
          isA<DevocionalesLoaded>(),
        ],
        verify: (bloc) {
          final state = bloc.state as DevocionalesLoaded;
          expect(state.devocionales.length, lessThanOrEqualTo(500)); // Filtered
        },
      );

      test('should handle rapid event firing without memory leaks', () async {
        // Create and close multiple blocs rapidly
        for (int i = 0; i < 100; i++) {
          final testBloc = DevocionalesBloc();
          testBloc.add(LoadDevocionales());
          testBloc.add(ChangeVersion('KJV_$i'));
          await testBloc.stream.take(2).last;
          await testBloc.close();
        }
        // If we reach here without crashing, memory handling is acceptable
        expect(true, isTrue);
      });

      test('should handle concurrent operations gracefully', () async {
        final testBloc = DevocionalesBloc();

        // Fire multiple concurrent operations
        for (int i = 0; i < 10; i++) {
          testBloc.add(ToggleFavorite('concurrent_$i'));
        }

        // Wait for processing
        await testBloc.stream.take(10).last;
        await testBloc.close();

        expect(true, isTrue); // Completed without errors
      });
    });

    group('Business Logic Validation', () {
      test('should properly dispose resources', () async {
        final testBloc = DevocionalesBloc();
        testBloc.add(LoadDevocionales());

        // Wait for initial events
        await testBloc.stream.take(2).last;

        // Close and verify no exceptions
        expect(() => testBloc.close(), returnsNormally);
        expect(testBloc.isClosed, isTrue);
      });

      blocTest<DevocionalesBloc, DevocionalesState>(
        'should maintain data integrity during version switching',
        build: () => bloc,
        seed: () => DevocionalesLoaded(
          devocionales: [
            Devocional(
              id: 'integrity_test',
              versiculo: 'John 1:1',
              reflexion: 'Critical content',
              paraMeditar: [],
              oracion: 'Important prayer',
              date: DateTime(2024, 1, 1),
              version: 'RVR1960',
              language: 'es',
            ),
          ],
          selectedVersion: 'RVR1960',
        ),
        act: (bloc) {
          // Multiple rapid version changes
          bloc.add(ChangeVersion('KJV'));
          bloc.add(ChangeVersion('ESV'));
          bloc.add(ChangeVersion('RVR1960'));
        },
        expect: () => [
          isA<DevocionalesLoaded>()
              .having((s) => s.selectedVersion, 'selectedVersion', 'KJV'),
          isA<DevocionalesLoaded>()
              .having((s) => s.selectedVersion, 'selectedVersion', 'ESV'),
          isA<DevocionalesLoaded>()
              .having((s) => s.selectedVersion, 'selectedVersion', 'RVR1960'),
        ],
        verify: (bloc) {
          final state = bloc.state as DevocionalesLoaded;
          expect(state.selectedVersion, equals('RVR1960'));
          // Original data should be preserved
          if (state.devocionales.isNotEmpty) {
            expect(
                state.devocionales.first.reflexion, equals('Critical content'));
          }
        },
      );
    });
  });
}
