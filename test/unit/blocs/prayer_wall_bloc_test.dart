@Tags(['critical', 'unit', 'blocs'])
library;

// test/unit/blocs/prayer_wall_bloc_test.dart

import 'package:bloc_test/bloc_test.dart';
import 'package:devocional_nuevo/blocs/prayer_wall/prayer_wall_bloc.dart';
import 'package:devocional_nuevo/blocs/prayer_wall/prayer_wall_event.dart';
import 'package:devocional_nuevo/blocs/prayer_wall/prayer_wall_state.dart';
import 'package:devocional_nuevo/models/prayer_wall_entry.dart';
import 'package:devocional_nuevo/repositories/i_prayer_wall_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockPrayerWallRepository extends Mock
    implements IPrayerWallRepository {}

PrayerWallEntry _makeEntry({
  String id = 'prayer1',
  String language = 'en',
  PrayerWallStatus status = PrayerWallStatus.approved,
  int prayCount = 0,
}) {
  return PrayerWallEntry(
    id: id,
    maskedText: 'Please pray for [name]',
    language: language,
    status: status,
    isAnonymous: true,
    prayCount: prayCount,
    createdAt: DateTime(2026, 1, 1),
    expiresAt: DateTime(2026, 2, 1),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PrayerWallBloc', () {
    late MockPrayerWallRepository repo;

    setUp(() {
      repo = MockPrayerWallRepository();
    });

    test('initial state is PrayerWallInitial', () {
      final bloc = PrayerWallBloc(repository: repo);
      expect(bloc.state, isA<PrayerWallInitial>());
      bloc.close();
    });

    blocTest<PrayerWallBloc, PrayerWallState>(
      'LoadPrayerWall emits Loading then Loaded with same/other language split',
      build: () {
        final en1 = _makeEntry(id: 'en1', language: 'en');
        final en2 = _makeEntry(id: 'en2', language: 'en');
        final es1 = _makeEntry(id: 'es1', language: 'es');

        when(() => repo.fetchApprovedPrayers(
              userLanguage: 'en',
              limit: any(named: 'limit'),
            )).thenAnswer((_) async => [en1, en2, es1]);

        return PrayerWallBloc(repository: repo);
      },
      act: (bloc) => bloc.add(LoadPrayerWall(userLanguage: 'en')),
      wait: const Duration(milliseconds: 100),
      expect: () => [
        isA<PrayerWallLoading>(),
        isA<PrayerWallLoaded>()
            .having((s) => s.sameLanguagePrayers.length, 'same count', 2)
            .having((s) => s.otherLanguagePrayers.length, 'other count', 1),
      ],
    );

    blocTest<PrayerWallBloc, PrayerWallState>(
      'RefreshPrayerWall re-fetches prayers and updates loaded state',
      build: () {
        final en1 = _makeEntry(id: 'en1', language: 'en');
        final en2 = _makeEntry(id: 'en2', language: 'en');

        when(() => repo.fetchApprovedPrayers(
              userLanguage: 'en',
              limit: any(named: 'limit'),
            )).thenAnswer((_) async => [en1, en2]);

        return PrayerWallBloc(repository: repo);
      },
      seed: () => PrayerWallLoaded(
        sameLanguagePrayers: [_makeEntry(id: 'old1', language: 'en')],
        otherLanguagePrayers: const [],
      ),
      act: (bloc) => bloc.add(RefreshPrayerWall(userLanguage: 'en')),
      wait: const Duration(milliseconds: 100),
      expect: () => [
        isA<PrayerWallLoaded>()
            .having((s) => s.sameLanguagePrayers.length, 'refreshed count', 2)
            .having((s) => s.sameLanguagePrayers.first.id, 'first id', 'en1'),
      ],
    );

    blocTest<PrayerWallBloc, PrayerWallState>(
      'SubmitPrayer emits PrayerSubmitting then PrayerSubmitted',
      build: () {
        when(() => repo.submitPrayer(
              originalText: any(named: 'originalText'),
              language: any(named: 'language'),
              isAnonymous: any(named: 'isAnonymous'),
              authorHash: any(named: 'authorHash'),
            )).thenAnswer((_) async => 'new_prayer_id');
        return PrayerWallBloc(repository: repo);
      },
      seed: () => PrayerWallLoaded(
        sameLanguagePrayers: const [],
        otherLanguagePrayers: const [],
      ),
      act: (bloc) => bloc.add(SubmitPrayer(
        text: 'Please pray for my family',
        language: 'en',
        isAnonymous: true,
        authorHash: 'hash123',
      )),
      wait: const Duration(milliseconds: 100),
      expect: () => [
        isA<PrayerSubmitting>(),
        isA<PrayerSubmitted>()
            .having((s) => s.prayerId, 'prayerId', 'new_prayer_id'),
        isA<PrayerWallLoaded>()
            .having((s) => s.myPendingPrayer, 'has pending', isNotNull),
      ],
    );

    blocTest<PrayerWallBloc, PrayerWallState>(
      'SubmitPrayer ignores empty text',
      build: () {
        return PrayerWallBloc(repository: repo);
      },
      seed: () => PrayerWallLoaded(
        sameLanguagePrayers: const [],
        otherLanguagePrayers: const [],
      ),
      act: (bloc) => bloc.add(SubmitPrayer(
        text: '   ',
        language: 'en',
        isAnonymous: true,
        authorHash: 'hash123',
      )),
      expect: () => [],
    );

    blocTest<PrayerWallBloc, PrayerWallState>(
      'TapPrayerHand optimistically increments prayCount',
      build: () {
        when(() => repo.tapPrayHand(prayerId: any(named: 'prayerId')))
            .thenAnswer((_) async {});
        return PrayerWallBloc(repository: repo);
      },
      seed: () => PrayerWallLoaded(
        sameLanguagePrayers: [_makeEntry(id: 'p1', prayCount: 3)],
        otherLanguagePrayers: const [],
      ),
      act: (bloc) => bloc.add(TapPrayerHand(prayerId: 'p1')),
      wait: const Duration(milliseconds: 100),
      expect: () => [
        isA<PrayerWallLoaded>().having(
          (s) => s.sameLanguagePrayers.first.prayCount,
          'prayCount',
          4,
        ),
      ],
    );

    blocTest<PrayerWallBloc, PrayerWallState>(
      'ReportPrayer calls repository without changing state',
      build: () {
        when(() => repo.reportPrayer(prayerId: any(named: 'prayerId')))
            .thenAnswer((_) async {});
        return PrayerWallBloc(repository: repo);
      },
      seed: () => PrayerWallLoaded(
        sameLanguagePrayers: const [],
        otherLanguagePrayers: const [],
      ),
      act: (bloc) => bloc.add(ReportPrayer(prayerId: 'p1')),
      wait: const Duration(milliseconds: 100),
      expect: () => [],
      verify: (_) {
        verify(() => repo.reportPrayer(prayerId: 'p1')).called(1);
      },
    );

    blocTest<PrayerWallBloc, PrayerWallState>(
      'DeletePrayer clears myPendingPrayer in state',
      build: () {
        when(() => repo.deletePrayer(
              prayerId: any(named: 'prayerId'),
              authorHash: any(named: 'authorHash'),
            )).thenAnswer((_) async {});
        return PrayerWallBloc(repository: repo);
      },
      seed: () => PrayerWallLoaded(
        sameLanguagePrayers: const [],
        otherLanguagePrayers: const [],
        myPendingPrayer: _makeEntry(status: PrayerWallStatus.pending),
      ),
      act: (bloc) => bloc.add(DeletePrayer(prayerId: 'prayer1', authorHash: 'h')),
      wait: const Duration(milliseconds: 100),
      expect: () => [
        isA<PrayerWallLoaded>()
            .having((s) => s.myPendingPrayer, 'no pending', isNull),
      ],
    );

    blocTest<PrayerWallBloc, PrayerWallState>(
      'SubmitPrayer emits PrayerWallError on repository failure',
      build: () {
        when(() => repo.submitPrayer(
              originalText: any(named: 'originalText'),
              language: any(named: 'language'),
              isAnonymous: any(named: 'isAnonymous'),
              authorHash: any(named: 'authorHash'),
            )).thenThrow(Exception('Firestore error'));
        return PrayerWallBloc(repository: repo);
      },
      seed: () => PrayerWallLoaded(
        sameLanguagePrayers: const [],
        otherLanguagePrayers: const [],
      ),
      act: (bloc) => bloc.add(SubmitPrayer(
        text: 'Please pray for me',
        language: 'en',
        isAnonymous: true,
        authorHash: 'hash123',
      )),
      wait: const Duration(milliseconds: 100),
      expect: () => [
        isA<PrayerSubmitting>(),
        isA<PrayerWallError>(),
      ],
    );

    blocTest<PrayerWallBloc, PrayerWallState>(
      'PrayerWallPendingUpdated with pastoral status emits PastoralResponseTriggered',
      build: () {
        return PrayerWallBloc(repository: repo);
      },
      seed: () => PrayerWallLoaded(
        sameLanguagePrayers: const [],
        otherLanguagePrayers: const [],
      ),
      act: (bloc) => bloc.add(PrayerWallPendingUpdated(
        _makeEntry(status: PrayerWallStatus.pastoral),
      )),
      wait: const Duration(milliseconds: 100),
      expect: () => [
        isA<PastoralResponseTriggered>(),
        isA<PrayerWallLoaded>()
            .having((s) => s.myPendingPrayer, 'cleared pending', isNull),
      ],
    );

    blocTest<PrayerWallBloc, PrayerWallState>(
      'PrayerWallPendingUpdated with null entry clears pending',
      build: () {
        return PrayerWallBloc(repository: repo);
      },
      seed: () => PrayerWallLoaded(
        sameLanguagePrayers: const [],
        otherLanguagePrayers: const [],
        myPendingPrayer: _makeEntry(status: PrayerWallStatus.pending),
      ),
      act: (bloc) => bloc.add(PrayerWallPendingUpdated(null)),
      wait: const Duration(milliseconds: 100),
      expect: () => [
        isA<PrayerWallLoaded>()
            .having((s) => s.myPendingPrayer, 'cleared', isNull),
      ],
    );

    blocTest<PrayerWallBloc, PrayerWallState>(
      'PrayerWallPendingUpdated with approved status updates myPendingPrayer',
      build: () {
        return PrayerWallBloc(repository: repo);
      },
      seed: () => PrayerWallLoaded(
        sameLanguagePrayers: const [],
        otherLanguagePrayers: const [],
      ),
      act: (bloc) => bloc.add(PrayerWallPendingUpdated(
        _makeEntry(id: 'approved1', status: PrayerWallStatus.approved),
      )),
      wait: const Duration(milliseconds: 100),
      expect: () => [
        isA<PrayerWallLoaded>()
            .having((s) => s.myPendingPrayer, 'updated', isNotNull)
            .having((s) => s.myPendingPrayer?.id, 'correct id', 'approved1')
            .having((s) => s.myPendingPrayer?.status, 'status', PrayerWallStatus.approved),
      ],
    );
  });

  group('PrayerWallEntry model', () {
    test('fromJson correctly parses approved prayer', () {
      final json = {
        'prayerId': 'abc123',
        'maskedText': 'Pray for [name]',
        'language': 'es',
        'status': 'approved',
        'isAnonymous': true,
        'prayCount': 7,
        'createdAt': '2026-01-01T00:00:00.000',
        'expiresAt': '2026-01-31T00:00:00.000',
      };

      final entry = PrayerWallEntry.fromJson(json);

      expect(entry.id, 'abc123');
      expect(entry.maskedText, 'Pray for [name]');
      expect(entry.language, 'es');
      expect(entry.status, PrayerWallStatus.approved);
      expect(entry.prayCount, 7);
    });

    test('fromJson defaults status to pending for unknown status', () {
      final json = {
        'prayerId': 'x',
        'maskedText': 'test',
        'language': 'en',
        'status': 'unknown_status',
        'isAnonymous': false,
        'prayCount': 0,
        'createdAt': '2026-01-01T00:00:00.000',
        'expiresAt': '2026-01-31T00:00:00.000',
      };
      final entry = PrayerWallEntry.fromJson(json);
      expect(entry.status, PrayerWallStatus.pending);
    });

    test('copyWith updates prayCount', () {
      final original = _makeEntry(prayCount: 5);
      final updated = original.copyWith(prayCount: 6);
      expect(updated.prayCount, 6);
      expect(updated.id, original.id);
    });
  });
}
