// test/unit/blocs/discovery_bloc_state_transitions_test.dart
// Fast unit tests for DiscoveryBloc state transitions
// Tests BLoC logic without widget rendering overhead

import 'package:bloc_test/bloc_test.dart';
import 'package:devocional_nuevo/blocs/discovery/discovery_bloc.dart';
import 'package:devocional_nuevo/blocs/discovery/discovery_event.dart';
import 'package:devocional_nuevo/blocs/discovery/discovery_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/bloc_test_helper.dart';

void main() {
  group('DiscoveryBloc State Transitions - Fast Unit Tests', () {
    late DiscoveryBlocTestBase testBase;
    late DiscoveryBloc bloc;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      testBase = DiscoveryBlocTestBase();
      testBase.setupMocks();
    });

    tearDown(() {
      bloc.close();
    });

    group('LoadDiscoveryStudies Event', () {
      blocTest<DiscoveryBloc, DiscoveryState>(
        'emits [DiscoveryLoading, DiscoveryLoaded] when loading empty studies',
        build: () {
          testBase.mockEmptyIndexFetch();
          return DiscoveryBloc(
            repository: testBase.mockRepository,
            progressTracker: testBase.mockProgressTracker,
            favoritesService: testBase.mockFavoritesService,
          );
        },
        act: (bloc) => bloc.add(LoadDiscoveryStudies()),
        expect: () => [
          isA<DiscoveryLoading>(),
          isA<DiscoveryLoaded>()
              .having((s) => s.availableStudyIds, 'availableStudyIds', isEmpty)
              .having((s) => s.loadedStudies, 'loadedStudies', isEmpty),
        ],
        verify: (_) {
          verify(testBase.mockRepository
                  .fetchIndex(forceRefresh: anyNamed('forceRefresh')))
              .called(1);
        },
      );

      blocTest<DiscoveryBloc, DiscoveryState>(
        'emits [DiscoveryLoading, DiscoveryLoaded] with studies',
        build: () {
          final studies = [
            testBase.createSampleStudy(id: 'study-1', titleEs: 'Study 1'),
            testBase.createSampleStudy(id: 'study-2', titleEs: 'Study 2'),
          ];
          testBase.mockIndexFetchWithStudies(studies);
          return DiscoveryBloc(
            repository: testBase.mockRepository,
            progressTracker: testBase.mockProgressTracker,
            favoritesService: testBase.mockFavoritesService,
          );
        },
        act: (bloc) => bloc.add(LoadDiscoveryStudies()),
        expect: () => [
          isA<DiscoveryLoading>(),
          isA<DiscoveryLoaded>()
              .having((s) => s.availableStudyIds, 'availableStudyIds',
                  ['study-1', 'study-2'])
              .having((s) => s.studyTitles['study-1'], 'first title', 'Study 1')
              .having(
                  (s) => s.studyTitles['study-2'], 'second title', 'Study 2'),
        ],
      );

      blocTest<DiscoveryBloc, DiscoveryState>(
        'emits [DiscoveryLoading, DiscoveryError] when fetch fails',
        build: () {
          testBase.mockIndexFetchFailure('Network error');
          return DiscoveryBloc(
            repository: testBase.mockRepository,
            progressTracker: testBase.mockProgressTracker,
            favoritesService: testBase.mockFavoritesService,
          );
        },
        act: (bloc) => bloc.add(LoadDiscoveryStudies()),
        expect: () => [
          isA<DiscoveryLoading>(),
          isA<DiscoveryError>()
              .having((s) => s.message, 'message', contains('Network error')),
        ],
      );
    });

    group('Initial State Handling', () {
      test('starts in DiscoveryInitial state', () {
        bloc = DiscoveryBloc(
          repository: testBase.mockRepository,
          progressTracker: testBase.mockProgressTracker,
          favoritesService: testBase.mockFavoritesService,
        );

        expect(bloc.state, isA<DiscoveryInitial>());
      });

      blocTest<DiscoveryBloc, DiscoveryState>(
        'transitions from Initial to Loading when event added',
        build: () {
          testBase.mockEmptyIndexFetch();
          return DiscoveryBloc(
            repository: testBase.mockRepository,
            progressTracker: testBase.mockProgressTracker,
            favoritesService: testBase.mockFavoritesService,
          );
        },
        verify: (bloc) {
          // Initial state is DiscoveryInitial
          expect(bloc.state, isA<DiscoveryInitial>());
        },
        act: (bloc) => bloc.add(LoadDiscoveryStudies()),
        expect: () => [
          isA<DiscoveryLoading>(),
          isA<DiscoveryLoaded>(),
        ],
      );
    });

    group('Error Recovery', () {
      blocTest<DiscoveryBloc, DiscoveryState>(
        'can recover from error state by retrying',
        build: () {
          return DiscoveryBloc(
            repository: testBase.mockRepository,
            progressTracker: testBase.mockProgressTracker,
            favoritesService: testBase.mockFavoritesService,
          );
        },
        setUp: () {
          // First call fails
          when(testBase.mockRepository
                  .fetchIndex(forceRefresh: anyNamed('forceRefresh')))
              .thenThrow(Exception('Network error'));
        },
        act: (bloc) {
          // First attempt - will fail
          bloc.add(LoadDiscoveryStudies());

          // After error, reconfigure mock for success and retry
          return Future.delayed(const Duration(milliseconds: 50), () {
            testBase.mockEmptyIndexFetch();
            bloc.add(LoadDiscoveryStudies());
          });
        },
        expect: () => [
          isA<DiscoveryLoading>(),
          isA<DiscoveryError>(),
          isA<DiscoveryLoading>(),
          isA<DiscoveryLoaded>(),
        ],
      );
    });

    group('ClearDiscoveryError Event', () {
      blocTest<DiscoveryBloc, DiscoveryState>(
        'clears error and returns to initial state',
        build: () {
          testBase.mockIndexFetchFailure('Network error');
          return DiscoveryBloc(
            repository: testBase.mockRepository,
            progressTracker: testBase.mockProgressTracker,
            favoritesService: testBase.mockFavoritesService,
          );
        },
        act: (bloc) {
          // First trigger error
          bloc.add(LoadDiscoveryStudies());
          // Then clear it after error state is reached
          return Future.delayed(const Duration(milliseconds: 50), () {
            bloc.add(ClearDiscoveryError());
          });
        },
        expect: () => [
          isA<DiscoveryLoading>(),
          isA<DiscoveryError>(),
          isA<DiscoveryInitial>(),
        ],
      );
    });
  });
}
