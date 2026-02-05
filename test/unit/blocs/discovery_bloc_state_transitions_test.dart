@Tags(['unit', 'blocs'])
library;

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

    // Remove manual tearDown to avoid LateInitializationError

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
        act: (bloc) => bloc.add(LoadDiscoveryStudies()),
        expect: () => [
          isA<DiscoveryLoading>(),
          isA<DiscoveryLoaded>(),
        ],
      );
    });

    group('Error Recovery', () {
      test('can recover from error state by retrying', () async {
        // Build bloc with mocked repository that fails once then succeeds
        int callCount = 0;
        when(testBase.mockRepository
                .fetchIndex(forceRefresh: anyNamed('forceRefresh')))
            .thenAnswer((_) async {
          if (callCount == 0) {
            callCount++;
            throw Exception('Network error');
          }
          return {'studies': []};
        });

        final bloc = DiscoveryBloc(
          repository: testBase.mockRepository,
          progressTracker: testBase.mockProgressTracker,
          favoritesService: testBase.mockFavoritesService,
        );

        final states = <DiscoveryState>[];
        final sub = bloc.stream.listen((s) => states.add(s));

        // Start first attempt (will fail)
        bloc.add(LoadDiscoveryStudies());

        // Wait until we observe DiscoveryError
        await expectLater(bloc.stream, emitsThrough(isA<DiscoveryError>()),
            reason: 'Should emit DiscoveryError after failed fetch');

        // Reconfigure mock to succeed and trigger retry
        testBase.mockEmptyIndexFetch();
        bloc.add(LoadDiscoveryStudies());

        // Wait until we observe a loaded state
        await expectLater(bloc.stream, emitsThrough(isA<DiscoveryLoaded>()),
            reason: 'Should emit DiscoveryLoaded after retry');

        await sub.cancel();
        await bloc.close();

        // Verify the sequence contains Error then Loaded
        final hasErrorThenLoaded =
            states.indexWhere((s) => s is DiscoveryError) >= 0 &&
                states.indexWhere((s) => s is DiscoveryLoaded) >
                    states.indexWhere((s) => s is DiscoveryError);
        expect(hasErrorThenLoaded, isTrue,
            reason:
                'States should include DiscoveryError followed by DiscoveryLoaded');
      });
    });

    group('ClearDiscoveryError Event', () {
      blocTest<DiscoveryBloc, DiscoveryState>(
        'clears error message from DiscoveryLoaded state',
        build: () => DiscoveryBloc(
          repository: testBase.mockRepository,
          progressTracker: testBase.mockProgressTracker,
          favoritesService: testBase.mockFavoritesService,
        ),
        seed: () => DiscoveryLoaded(
          availableStudyIds: [],
          loadedStudies: {},
          studyTitles: {},
          studySubtitles: {},
          studyEmojis: {},
          studyReadingMinutes: {},
          completedStudies: {},
          favoriteStudyIds: {},
          errorMessage: 'Some error',
          languageCode: 'es',
        ),
        act: (bloc) => bloc.add(ClearDiscoveryError()),
        expect: () => [
          isA<DiscoveryLoaded>()
              .having((s) => s.errorMessage, 'errorMessage', isNull),
        ],
      );
    });
  });
}
