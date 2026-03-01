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
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockEncounterRepository extends Mock implements EncounterRepository {}

// ─── Helpers ─────────────────────────────────────────────────────────────────

EncounterIndexEntry _fakeEntry({String id = 'test_001', String status = 'published'}) =>
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

// ─── Tests ───────────────────────────────────────────────────────────────────

void main() {
  late MockEncounterRepository mockRepository;

  setUp(() {
    mockRepository = MockEncounterRepository();
  });

  group('EncounterBloc', () {
    // ── LoadEncounterIndex ──────────────────────────────────────────────────

    blocTest<EncounterBloc, EncounterState>(
      'LoadEncounterIndex emits [EncounterLoading, EncounterLoaded]',
      build: () {
        when(() => mockRepository.fetchIndex())
            .thenAnswer((_) async => [_fakeEntry()]);
        return EncounterBloc(repository: mockRepository);
      },
      act: (bloc) => bloc.add(LoadEncounterIndex()),
      expect: () => [
        isA<EncounterLoading>(),
        isA<EncounterLoaded>(),
      ],
    );

    blocTest<EncounterBloc, EncounterState>(
      'LoadEncounterIndex emits [EncounterLoading, EncounterError] on failure',
      build: () {
        when(() => mockRepository.fetchIndex())
            .thenThrow(Exception('network error'));
        return EncounterBloc(repository: mockRepository);
      },
      act: (bloc) => bloc.add(LoadEncounterIndex()),
      expect: () => [
        isA<EncounterLoading>(),
        isA<EncounterError>(),
      ],
    );

    blocTest<EncounterBloc, EncounterState>(
      'LoadEncounterIndex: loaded state contains index entries',
      build: () {
        when(() => mockRepository.fetchIndex())
            .thenAnswer((_) async => [_fakeEntry()]);
        return EncounterBloc(repository: mockRepository);
      },
      act: (bloc) => bloc.add(LoadEncounterIndex()),
      expect: () => [
        isA<EncounterLoading>(),
        isA<EncounterLoaded>().having(
          (s) => s.index.length,
          'index length',
          1,
        ),
      ],
    );

    // ── LoadEncounterStudy ──────────────────────────────────────────────────

    blocTest<EncounterBloc, EncounterState>(
      'LoadEncounterStudy adds study to loadedStudies',
      build: () {
        when(() => mockRepository.fetchIndex())
            .thenAnswer((_) async => [_fakeEntry()]);
        when(() => mockRepository.fetchStudy('test_001', 'en'))
            .thenAnswer((_) async => _fakeStudy());
        return EncounterBloc(repository: mockRepository);
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
      'LoadEncounterStudy twice → single network call (cache hit)',
      build: () {
        when(() => mockRepository.fetchStudy('test_001', 'en'))
            .thenAnswer((_) async => _fakeStudy());
        return EncounterBloc(repository: mockRepository);
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
      // Should emit nothing because study is already cached
      expect: () => [],
      verify: (_) => verifyNever(
        () => mockRepository.fetchStudy('test_001', 'en'),
      ),
    );

    // ── CompleteEncounter ───────────────────────────────────────────────────

    blocTest<EncounterBloc, EncounterState>(
      'CompleteEncounter adds id to completedIds',
      build: () => EncounterBloc(repository: mockRepository),
      seed: () => EncounterLoaded(index: [_fakeEntry()]),
      act: (bloc) => bloc.add(CompleteEncounter('test_001')),
      expect: () => [
        isA<EncounterLoaded>().having(
          (s) => s.isCompleted('test_001'),
          'is completed',
          true,
        ),
      ],
    );

    blocTest<EncounterBloc, EncounterState>(
      'CompleteEncounter fires only once per session',
      build: () => EncounterBloc(repository: mockRepository),
      seed: () => EncounterLoaded(index: [_fakeEntry()]),
      act: (bloc) async {
        bloc.add(CompleteEncounter('test_001'));
        await Future.delayed(const Duration(milliseconds: 10));
        // Second add — still only one encounter ID
        bloc.add(CompleteEncounter('test_001'));
      },
      expect: () => [
        isA<EncounterLoaded>().having(
          (s) => s.completedIds.length,
          'completed count',
          1,
        ),
        isA<EncounterLoaded>().having(
          (s) => s.completedIds.length,
          'completed count still 1',
          1,
        ),
      ],
    );
  });
}
