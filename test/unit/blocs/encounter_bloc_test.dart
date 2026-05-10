@Tags(['critical', 'unit', 'blocs'])
library;

import 'package:bloc_test/bloc_test.dart';
import 'package:devocional_nuevo/blocs/encounter/encounter_bloc.dart';
import 'package:devocional_nuevo/blocs/encounter/encounter_event.dart';
import 'package:devocional_nuevo/blocs/encounter/encounter_state.dart';
import 'package:devocional_nuevo/models/encounter_card_model.dart';
import 'package:devocional_nuevo/models/encounter_index_entry.dart';
import 'package:devocional_nuevo/models/encounter_study.dart';
import 'package:devocional_nuevo/repositories/encounter_repository.dart';
import 'package:devocional_nuevo/services/encounter_progress_service.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockEncounterRepository extends Mock implements EncounterRepository {}

class MockEncounterProgressService extends Mock
    implements EncounterProgressService {}

class MockBaseCacheManager extends Mock implements BaseCacheManager {}

// --- Helpers ---

EncounterIndexEntry _fakeEntry({
  String id = 'test_001',
  String status = 'published',
}) =>
    EncounterIndexEntry(
      id: id,
      version: '1.0',
      emoji: '🌊',
      status: status,
      files: {'en': '$id.json'},
      titles: {'en': 'Test Encounter'},
      subtitles: {'en': 'Test Subtitle'},
      scriptureReference: {'en': 'John 1:1'},
      estimatedReadingMinutes: {'en': 5},
    );

EncounterStudy _fakeStudy({String id = 'test_001'}) => EncounterStudy(
      id: id,
      language: 'en',
      cards: [
        const EncounterCard(order: 1, type: 'cinematic_scene', title: 'Card 1'),
        const EncounterCard(order: 2, type: 'completion', title: 'Done'),
      ],
    );

// --- Tests ---

void main() {
  late MockEncounterRepository mockRepository;
  late MockEncounterProgressService mockProgressService;
  late MockBaseCacheManager mockCacheManager;

  setUp(() {
    mockRepository = MockEncounterRepository();
    mockProgressService = MockEncounterProgressService();
    mockCacheManager = MockBaseCacheManager();
    when(
      () => mockProgressService.loadCompletedIds(),
    ).thenAnswer((_) async => {});
    when(
      () => mockProgressService.markCompleted(any()),
    ).thenAnswer((_) async {});
  });

  group('EncounterBloc', () {
    // --- LoadEncounterIndex ---

    blocTest<EncounterBloc, EncounterState>(
      'LoadEncounterIndex emits [EncounterLoading, EncounterLoaded]',
      build: () {
        when(
          () => mockRepository.fetchIndex(),
        ).thenAnswer((_) async => [_fakeEntry()]);
        return EncounterBloc(
          repository: mockRepository,
          progressService: mockProgressService,
          cacheManager: mockCacheManager,
        );
      },
      act: (bloc) => bloc.add(LoadEncounterIndex()),
      expect: () => [isA<EncounterLoading>(), isA<EncounterLoaded>()],
    );

    blocTest<EncounterBloc, EncounterState>(
      'LoadEncounterIndex emits [EncounterLoading, EncounterError] on failure',
      build: () {
        when(
          () => mockRepository.fetchIndex(),
        ).thenThrow(Exception('network error'));
        return EncounterBloc(
          repository: mockRepository,
          progressService: mockProgressService,
          cacheManager: mockCacheManager,
        );
      },
      act: (bloc) => bloc.add(LoadEncounterIndex()),
      expect: () => [isA<EncounterLoading>(), isA<EncounterError>()],
    );

    blocTest<EncounterBloc, EncounterState>(
      'LoadEncounterIndex: loaded state contains index entries',
      build: () {
        when(
          () => mockRepository.fetchIndex(),
        ).thenAnswer((_) async => [_fakeEntry()]);
        return EncounterBloc(
          repository: mockRepository,
          progressService: mockProgressService,
          cacheManager: mockCacheManager,
        );
      },
      act: (bloc) => bloc.add(LoadEncounterIndex()),
      expect: () => [
        isA<EncounterLoading>(),
        isA<EncounterLoaded>().having((s) => s.index.length, 'index length', 1),
      ],
    );

    blocTest<EncounterBloc, EncounterState>(
      'LoadEncounterIndex restores persisted completedIds from storage',
      build: () {
        when(
          () => mockRepository.fetchIndex(),
        ).thenAnswer((_) async => [_fakeEntry()]);
        when(
          () => mockProgressService.loadCompletedIds(),
        ).thenAnswer((_) async => {'test_001'});
        return EncounterBloc(
          repository: mockRepository,
          progressService: mockProgressService,
          cacheManager: mockCacheManager,
        );
      },
      act: (bloc) => bloc.add(LoadEncounterIndex()),
      expect: () => [
        isA<EncounterLoading>(),
        isA<EncounterLoaded>().having(
          (s) => s.isCompleted('test_001'),
          'persisted completion restored',
          true,
        ),
      ],
    );

    // --- LoadEncounterStudy ---

    blocTest<EncounterBloc, EncounterState>(
      'LoadEncounterStudy adds study to loadedStudies',
      build: () {
        when(
          () => mockRepository.fetchIndex(),
        ).thenAnswer((_) async => [_fakeEntry()]);
        when(
          () => mockRepository.fetchStudy(
            'test_001',
            'en',
            filename: any(named: 'filename'),
            entry: any(named: 'entry'),
          ),
        ).thenAnswer((_) async => _fakeStudy());
        return EncounterBloc(
          repository: mockRepository,
          progressService: mockProgressService,
          cacheManager: mockCacheManager,
        );
      },
      seed: () => EncounterLoaded(index: [_fakeEntry()]),
      act: (bloc) => bloc.add(LoadEncounterStudy('test_001', 'en')),
      expect: () => [
        isA<EncounterLoaded>().having(
          (s) => s.isStudyLoaded('test_001'),
          'study loaded',
          true,
        ),
      ],
    );

    blocTest<EncounterBloc, EncounterState>(
      'LoadEncounterStudy twice - single network call (cache hit)',
      build: () {
        when(
          () => mockRepository.fetchStudy(
            'test_001',
            'en',
            filename: any(named: 'filename'),
            entry: any(named: 'entry'),
          ),
        ).thenAnswer((_) async => _fakeStudy());
        return EncounterBloc(
          repository: mockRepository,
          progressService: mockProgressService,
          cacheManager: mockCacheManager,
        );
      },
      seed: () => EncounterLoaded(
        index: [_fakeEntry()],
        loadedStudies: {'test_001': _fakeStudy()},
      ),
      act: (bloc) async {
        bloc.add(LoadEncounterStudy('test_001', 'en'));
        await Future.delayed(const Duration(milliseconds: 50));
        bloc.add(LoadEncounterStudy('test_001', 'en'));
      },
      expect: () => [],
      verify: (_) => verifyNever(
        () => mockRepository.fetchStudy(
          'test_001',
          'en',
          filename: any(named: 'filename'),
          entry: any(named: 'entry'),
        ),
      ),
    );

    // --- CompleteEncounter ---

    blocTest<EncounterBloc, EncounterState>(
      'CompleteEncounter adds id to completedIds and persists',
      build: () => EncounterBloc(
        repository: mockRepository,
        progressService: mockProgressService,
        cacheManager: mockCacheManager,
      ),
      seed: () => EncounterLoaded(index: [_fakeEntry()]),
      act: (bloc) => bloc.add(CompleteEncounter('test_001')),
      expect: () => [
        isA<EncounterLoaded>().having(
          (s) => s.isCompleted('test_001'),
          'is completed',
          true,
        ),
      ],
      verify: (_) =>
          verify(() => mockProgressService.markCompleted('test_001')).called(1),
    );

    blocTest<EncounterBloc, EncounterState>(
      'CompleteEncounter fires only once per session',
      build: () => EncounterBloc(
        repository: mockRepository,
        progressService: mockProgressService,
        cacheManager: mockCacheManager,
      ),
      seed: () => EncounterLoaded(index: [_fakeEntry()]),
      act: (bloc) async {
        bloc.add(CompleteEncounter('test_001'));
        await Future.delayed(const Duration(milliseconds: 10));
        bloc.add(CompleteEncounter('test_001'));
      },
      expect: () => [
        isA<EncounterLoaded>().having(
          (s) => s.completedIds.length,
          'completed count',
          1,
        ),
      ],
    );

    // --- EncounterLoaded.getPrerequisite() ---

    test('getPrerequisite returns null for first published encounter', () {
      final index = [_fakeEntry(id: 'first_001', status: 'published')];
      final state = EncounterLoaded(index: index);

      final result = state.getPrerequisite('first_001');

      expect(result, isNull, reason: 'First encounter has no prerequisite');
    });

    test('getPrerequisite returns previous published encounter', () {
      final index = [
        _fakeEntry(id: 'first_001', status: 'published'),
        _fakeEntry(id: 'second_002', status: 'published'),
      ];
      final state = EncounterLoaded(index: index);

      final result = state.getPrerequisite('second_002');

      expect(result, isNotNull);
      expect(result!.id, equals('first_001'));
    });

    test('getPrerequisite returns null if encounter not in published list', () {
      final index = [
        _fakeEntry(id: 'first_001', status: 'published'),
        _fakeEntry(id: 'coming_001', status: 'coming_soon'),
      ];
      final state = EncounterLoaded(index: index);

      final result = state.getPrerequisite('coming_001');

      expect(
        result,
        isNull,
        reason: 'Non-published encounter has no prerequisite',
      );
    });

    test('getPrerequisite returns null for non-existent encounter', () {
      final index = [_fakeEntry(id: 'first_001', status: 'published')];
      final state = EncounterLoaded(index: index);

      final result = state.getPrerequisite('nonexistent_999');

      expect(result, isNull);
    });

    test('getPrerequisite handles empty index gracefully', () {
      final state = EncounterLoaded(index: []);

      final result = state.getPrerequisite('any_id');

      expect(result, isNull);
    });

    // --- EncounterBloc._preloadFirstEncounterImages() ---

    blocTest<EncounterBloc, EncounterState>(
      'LoadEncounterIndex with empty index does not trigger preload',
      build: () {
        when(() => mockRepository.fetchIndex()).thenAnswer((_) async => []);
        return EncounterBloc(
          repository: mockRepository,
          progressService: mockProgressService,
          cacheManager: mockCacheManager,
        );
      },
      act: (bloc) => bloc.add(LoadEncounterIndex()),
      expect: () => [isA<EncounterLoading>(), isA<EncounterLoaded>()],
      verify: (bloc) {
        // Verify state emitted but no state changes from preload
        verifyNever(
          () => mockRepository.fetchStudy(
            any(),
            any(),
            filename: any(named: 'filename'),
            entry: any(named: 'entry'),
          ),
        );
      },
    );

    blocTest<EncounterBloc, EncounterState>(
      'LoadEncounterIndex emits no additional states during background preload',
      build: () {
        when(
          () => mockRepository.fetchIndex(),
        ).thenAnswer((_) async => [_fakeEntry()]);
        return EncounterBloc(
          repository: mockRepository,
          progressService: mockProgressService,
          cacheManager: mockCacheManager,
        );
      },
      act: (bloc) => bloc.add(LoadEncounterIndex()),
      // Should emit exactly 2 states (Loading, Loaded) — no extra states from preload
      expect: () => [isA<EncounterLoading>(), isA<EncounterLoaded>()],
    );
  });
}
