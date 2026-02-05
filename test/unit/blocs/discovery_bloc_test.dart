@Tags(['critical', 'unit', 'blocs'])
library;

import 'package:bloc_test/bloc_test.dart';
import 'package:devocional_nuevo/blocs/discovery/discovery_bloc.dart';
import 'package:devocional_nuevo/blocs/discovery/discovery_event.dart';
import 'package:devocional_nuevo/blocs/discovery/discovery_state.dart';
import 'package:devocional_nuevo/models/discovery_devotional_model.dart';
import 'package:devocional_nuevo/models/discovery_section_model.dart';
import 'package:devocional_nuevo/repositories/discovery_repository.dart';
import 'package:devocional_nuevo/services/discovery_favorites_service.dart';
import 'package:devocional_nuevo/services/discovery_progress_tracker.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockDiscoveryRepository extends Mock implements DiscoveryRepository {}

class MockDiscoveryProgressTracker extends Mock
    implements DiscoveryProgressTracker {}

class MockDiscoveryFavoritesService extends Mock
    implements DiscoveryFavoritesService {}

class MockHttpClient extends Mock implements http.Client {}

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/shared_preferences'),
      (MethodCall methodCall) async {
        switch (methodCall.method) {
          case 'getAll':
            return <String, Object?>{};
          case 'setBool':
          case 'setDouble':
          case 'setInt':
          case 'setString':
          case 'setStringList':
          case 'remove':
          case 'clear':
            return true;
          default:
            return null;
        }
      },
    );
  });

  late MockDiscoveryRepository mockRepository;
  late MockDiscoveryProgressTracker mockProgressTracker;
  late MockDiscoveryFavoritesService mockFavoritesService;
  late DiscoveryBloc bloc;

  setUp(() {
    mockRepository = MockDiscoveryRepository();
    mockProgressTracker = MockDiscoveryProgressTracker();
    mockFavoritesService = MockDiscoveryFavoritesService();

    // Default stub for loadFavoriteIds - takes optional languageCode parameter
    when(() => mockFavoritesService.loadFavoriteIds(any()))
        .thenAnswer((_) async => <String>{});

    // Default stub for getProgress - return uncompleted progress
    // Fixed: getProgress takes 2 parameters (studyId, languageCode)
    when(() => mockProgressTracker.getProgress(any(), any()))
        .thenAnswer((_) async => DiscoveryProgress(
              studyId: 'test',
              completedSections: [],
              answeredQuestions: {},
              isCompleted: false,
            ));

    bloc = DiscoveryBloc(
      repository: mockRepository,
      progressTracker: mockProgressTracker,
      favoritesService: mockFavoritesService,
    );

    // IMPORTANT: This catch-all stub must be last, after any test-specific stubs
    when(() => mockRepository.fetchDiscoveryStudy(any(), any()))
        .thenAnswer((invocation) async => DiscoveryDevotional(
              id: 'dummy',
              versiculo: 'Dummy verse',
              reflexion: 'Dummy title',
              paraMeditar: [],
              oracion: 'Dummy prayer',
              date: DateTime(2026, 1, 1),
              cards: [],
              secciones: [],
              preguntasDiscovery: [],
              versiculoClave: 'Dummy key verse',
            ));
  });

  tearDown(() {
    bloc.close();
  });

  group('DiscoveryBloc', () {
    test('initial state is DiscoveryInitial', () {
      expect(bloc.state, isA<DiscoveryInitial>());
    });

    group('LoadDiscoveryStudies', () {
      final studyIds = ['estrella-manana-001', 'estrella-manana-002'];
      final mockIndex = {
        'studies': [
          {
            'id': 'estrella-manana-001',
            'version': '1.0',
            'files': {'es': 'file1.json', 'en': 'file1_en.json'},
            'titles': {'es': 'Study 1', 'en': 'Study 1 EN'},
            'subtitles': {'es': 'Subtitle 1', 'en': 'Subtitle 1 EN'},
            'emoji': '📖',
            'estimated_reading_minutes': {'es': 5, 'en': 5},
          },
          {
            'id': 'estrella-manana-002',
            'version': '1.0',
            'files': {'es': 'file2.json', 'en': 'file2_en.json'},
            'titles': {'es': 'Study 2', 'en': 'Study 2 EN'},
            'subtitles': {'es': 'Subtitle 2', 'en': 'Subtitle 2 EN'},
            'emoji': '✨',
            'estimated_reading_minutes': {'es': 6, 'en': 6},
          },
        ],
      };

      blocTest<DiscoveryBloc, DiscoveryState>(
        'emits [DiscoveryLoading, DiscoveryLoaded] when studies load successfully',
        build: () {
          when(() => mockRepository.fetchIndex(
                  forceRefresh: any(named: 'forceRefresh')))
              .thenAnswer((_) async => mockIndex);
          return bloc;
        },
        act: (bloc) => bloc.add(LoadDiscoveryStudies()),
        expect: () => [
          isA<DiscoveryLoading>(),
          isA<DiscoveryLoaded>()
              .having((s) => s.availableStudyIds, 'availableStudyIds', studyIds)
              .having((s) => s.loadedStudies, 'loadedStudies', isEmpty),
        ],
        verify: (_) {
          verify(() => mockRepository.fetchIndex(
              forceRefresh: any(named: 'forceRefresh'))).called(1);
        },
      );

      blocTest<DiscoveryBloc, DiscoveryState>(
        'emits [DiscoveryLoading, DiscoveryError] when loading fails',
        build: () {
          when(() => mockRepository.fetchIndex(
                  forceRefresh: any(named: 'forceRefresh')))
              .thenThrow(Exception('Network error'));
          return bloc;
        },
        act: (bloc) => bloc.add(LoadDiscoveryStudies()),
        expect: () => [
          isA<DiscoveryLoading>(),
          isA<DiscoveryError>()
              .having((s) => s.message, 'message', contains('Network error')),
        ],
      );
    });

    group('LoadDiscoveryStudy', () {
      final studyId = 'estrella-manana-001';
      final study = DiscoveryDevotional(
        id: studyId,
        versiculo: 'Test verse',
        reflexion: 'Test title',
        paraMeditar: [],
        oracion: 'Test prayer',
        date: DateTime(2026, 1, 15),
        cards: [],
        secciones: [
          DiscoverySection(tipo: 'natural', contenido: 'Test content'),
        ],
        preguntasDiscovery: ['Test question?'],
        versiculoClave: 'Test verse',
      );

      blocTest<DiscoveryBloc, DiscoveryState>(
        'emits [DiscoveryStudyLoading, DiscoveryLoaded] when study loads successfully',
        build: () {
          when(() => mockRepository.fetchDiscoveryStudy(studyId, any()))
              .thenAnswer((_) async => study);
          return bloc;
        },
        act: (bloc) => bloc.add(LoadDiscoveryStudy(studyId)),
        expect: () => [
          isA<DiscoveryStudyLoading>()
              .having((s) => s.studyId, 'studyId', studyId),
          isA<DiscoveryLoaded>()
              .having((s) => s.loadedStudies.containsKey(studyId),
                  'contains study', true)
              .having((s) => s.loadedStudies[studyId], 'loaded study',
                  equals(study)),
        ],
        verify: (_) {
          verify(() => mockRepository.fetchDiscoveryStudy(studyId, 'es'))
              .called(1);
        },
      );

      blocTest<DiscoveryBloc, DiscoveryState>(
        'emits error when study loading fails',
        build: () {
          when(() => mockRepository.fetchDiscoveryStudy(studyId, any()))
              .thenThrow(Exception('Study not found'));
          return bloc;
        },
        act: (bloc) => bloc.add(LoadDiscoveryStudy(studyId)),
        expect: () => [
          isA<DiscoveryStudyLoading>(),
          isA<DiscoveryError>()
              .having((s) => s.message, 'message', contains('Study not found')),
        ],
      );
    });

    group('MarkSectionCompleted', () {
      final studyId = 'test-001';
      final sectionIndex = 0;

      blocTest<DiscoveryBloc, DiscoveryState>(
        'calls progressTracker.markSectionCompleted',
        build: () {
          // Fixed: markSectionCompleted takes optional languageCode parameter
          when(() => mockProgressTracker.markSectionCompleted(
                  studyId, sectionIndex, any()))
              .thenAnswer((_) async => Future.value());
          return bloc;
        },
        seed: () => DiscoveryLoaded(
          availableStudyIds: [studyId],
          loadedStudies: {},
          studyTitles: {},
          studySubtitles: {},
          studyEmojis: {},
          studyReadingMinutes: {},
          completedStudies: {},
          favoriteStudyIds: {},
          languageCode: 'en',
        ),
        act: (bloc) => bloc.add(MarkSectionCompleted(studyId, sectionIndex)),
        verify: (_) {
          verify(() => mockProgressTracker.markSectionCompleted(
              studyId, sectionIndex, any())).called(1);
        },
      );
    });

    group('AnswerDiscoveryQuestion', () {
      final studyId = 'test-001';
      final questionIndex = 0;
      final answer = 'My answer';

      blocTest<DiscoveryBloc, DiscoveryState>(
        'calls progressTracker.answerQuestion',
        build: () {
          // Fixed: answerQuestion takes optional languageCode parameter
          when(() => mockProgressTracker.answerQuestion(
                  studyId, questionIndex, answer, any()))
              .thenAnswer((_) async => Future.value());
          return bloc;
        },
        seed: () => DiscoveryLoaded(
          availableStudyIds: [studyId],
          loadedStudies: {},
          studyTitles: {},
          studySubtitles: {},
          studyEmojis: {},
          studyReadingMinutes: {},
          completedStudies: {},
          favoriteStudyIds: {},
          languageCode: 'en',
        ),
        act: (bloc) =>
            bloc.add(AnswerDiscoveryQuestion(studyId, questionIndex, answer)),
        verify: (_) {
          verify(() => mockProgressTracker.answerQuestion(
              studyId, questionIndex, answer, any())).called(1);
        },
      );
    });

    group('CompleteDiscoveryStudy', () {
      final studyId = 'test-001';

      blocTest<DiscoveryBloc, DiscoveryState>(
        'calls progressTracker.completeStudy',
        build: () {
          // Fixed: completeStudy takes optional languageCode parameter
          when(() => mockProgressTracker.completeStudy(studyId, any()))
              .thenAnswer((_) async => Future.value());
          return bloc;
        },
        seed: () => DiscoveryLoaded(
          availableStudyIds: [studyId],
          loadedStudies: {},
          studyTitles: {},
          studySubtitles: {},
          studyEmojis: {},
          studyReadingMinutes: {},
          completedStudies: {},
          favoriteStudyIds: {},
          languageCode: 'en',
        ),
        act: (bloc) => bloc.add(CompleteDiscoveryStudy(studyId)),
        verify: (_) {
          verify(() => mockProgressTracker.completeStudy(studyId, any()))
              .called(1);
        },
      );
    });

    group('RefreshDiscoveryStudies', () {
      final studyIds = ['study-1', 'study-2', 'study-3'];
      final mockIndex = {
        'studies': [
          {
            'id': 'study-1',
            'version': '1.0',
            'files': {'es': 'file1.json', 'en': 'file1_en.json'},
            'titles': {'es': 'Study 1', 'en': 'Study 1 EN'},
            'subtitles': {'es': 'Subtitle 1', 'en': 'Subtitle 1 EN'},
            'emoji': '📖',
            'estimated_reading_minutes': {'es': 5, 'en': 5},
          },
          {
            'id': 'study-2',
            'version': '1.0',
            'files': {'es': 'file2.json', 'en': 'file2_en.json'},
            'titles': {'es': 'Study 2', 'en': 'Study 2 EN'},
            'subtitles': {'es': 'Subtitle 2', 'en': 'Subtitle 2 EN'},
            'emoji': '✨',
            'estimated_reading_minutes': {'es': 6, 'en': 6},
          },
          {
            'id': 'study-3',
            'version': '1.0',
            'files': {'es': 'file3.json', 'en': 'file3_en.json'},
            'titles': {'es': 'Study 3', 'en': 'Study 3 EN'},
            'subtitles': {'es': 'Subtitle 3', 'en': 'Subtitle 3 EN'},
            'emoji': '🌟',
            'estimated_reading_minutes': {'es': 7, 'en': 7},
          },
        ],
      };

      blocTest<DiscoveryBloc, DiscoveryState>(
        'refreshes available studies list',
        build: () {
          when(() => mockRepository.fetchIndex(forceRefresh: true))
              .thenAnswer((_) async => mockIndex);
          return bloc;
        },
        seed: () => DiscoveryLoaded(
          availableStudyIds: ['old-study'],
          loadedStudies: {},
          studyTitles: {},
          studySubtitles: {},
          studyEmojis: {},
          studyReadingMinutes: {},
          completedStudies: {},
          favoriteStudyIds: {},
          languageCode: 'en',
        ),
        act: (bloc) => bloc.add(RefreshDiscoveryStudies()),
        expect: () => [
          isA<DiscoveryLoaded>().having(
              (s) => s.availableStudyIds, 'availableStudyIds', studyIds),
        ],
      );
    });

    group('ClearDiscoveryError', () {
      blocTest<DiscoveryBloc, DiscoveryState>(
        'clears error message from DiscoveryLoaded state',
        build: () => bloc,
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
          languageCode: 'en',
        ),
        act: (bloc) => bloc.add(ClearDiscoveryError()),
        expect: () => [
          isA<DiscoveryLoaded>()
              .having((s) => s.errorMessage, 'errorMessage', isNull),
        ],
      );
    });

    group('State Management - lastUpdated', () {
      test('emits distinct states when progress updated', () async {
        final state1 = DiscoveryLoaded(
          availableStudyIds: [],
          loadedStudies: {},
          studyTitles: {},
          studySubtitles: {},
          studyEmojis: {},
          studyReadingMinutes: {},
          completedStudies: {},
          favoriteStudyIds: {},
          languageCode: 'en',
        );
        await Future.delayed(const Duration(milliseconds: 10));
        final state2 = DiscoveryLoaded(
          availableStudyIds: [],
          loadedStudies: {},
          studyTitles: {},
          studySubtitles: {},
          studyEmojis: {},
          studyReadingMinutes: {},
          completedStudies: {},
          favoriteStudyIds: {},
          languageCode: 'en',
        );
        // Different timestamps make states distinct for Equatable
        expect(state1, isNot(equals(state2)));
      });

      test('same state data with same timestamp are equal', () {
        final now = DateTime.now();
        final state1 = DiscoveryLoaded(
          availableStudyIds: ['test'],
          loadedStudies: {},
          studyTitles: {},
          studySubtitles: {},
          studyEmojis: {},
          studyReadingMinutes: {},
          completedStudies: {},
          favoriteStudyIds: {},
          lastUpdated: now,
          languageCode: 'en',
        );
        final state2 = DiscoveryLoaded(
          availableStudyIds: ['test'],
          loadedStudies: {},
          studyTitles: {},
          studySubtitles: {},
          studyEmojis: {},
          studyReadingMinutes: {},
          completedStudies: {},
          favoriteStudyIds: {},
          lastUpdated: now,
          languageCode: 'en',
        );
        expect(state1, equals(state2));
      });
    });
  });
}
