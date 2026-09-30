@Tags(['unit', 'providers'])
library;

// Startup must not block on a devotional year that is missing from disk when
// an earlier year is already cached: the missing year is downloaded after the
// first frame (prefetchDeferredYears) and only cached for the next launch.
// A fresh install / restored history (nothing cached) and any language or
// version switch keep the blocking behavior, so the reading position and the
// first-unread lookup are unaffected.

import 'dart:async';

import 'package:devocional_nuevo/models/devocional_model.dart';
import 'package:devocional_nuevo/providers/devocional_provider.dart';
import 'package:devocional_nuevo/repositories/devocional_repository.dart';
import 'package:devocional_nuevo/services/cache_metadata_service.dart';
import 'package:devocional_nuevo/services/devocional_index_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockIndexService extends Mock implements DevocionalIndexService {}

class _MockCacheService extends Mock implements CacheMetadataService {}

class _MockRepository extends Mock implements DevocionalRepository {}

Devocional _devocional(int year) => Devocional(
      id: 'dev_$year',
      date: DateTime(year, 1, 1),
      versiculo: 'Verse $year',
      reflexion: 'Reflection $year',
      paraMeditar: [],
      oracion: 'Prayer $year',
      version: 'RVR1960',
      language: 'es',
    );

CacheStatus _cached({bool stale = false}) =>
    CacheStatus(hasLocal: true, isStale: stale, indexReachable: true);

const CacheStatus _missing =
    CacheStatus(hasLocal: false, isStale: false, indexReachable: true);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _MockRepository repository;
  late Set<int> cachedYears;
  late Map<int, Completer<List<Devocional>>> pendingDownloads;

  DevocionalProvider buildProvider() => DevocionalProvider(
        enableAudio: false,
        devocionalIndexService: _MockIndexService(),
        cacheMetadataService: _MockCacheService(),
        devocionalRepository: repository,
      );

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'selectedLanguage': 'es',
      'selectedVersion': 'RVR1960',
    });
    repository = _MockRepository();
    cachedYears = {};
    pendingDownloads = {};

    when(() => repository.getAvailableYears())
        .thenAnswer((_) async => [2025, 2026, 2027]);
    when(() => repository.wasLastFetchOffline).thenReturn(false);
    when(() => repository.filterByVersion(any(), any())).thenAnswer(
      (invocation) => invocation.positionalArguments[0] as List<Devocional>,
    );
    when(() => repository.checkCacheStatus(any(), any(), any())).thenAnswer((
      invocation,
    ) async {
      final year = invocation.positionalArguments[0] as int;
      return cachedYears.contains(year) ? _cached() : _missing;
    });
    // A year not on disk "downloads" only when the test completes it.
    when(() => repository.fetchAll(any(), any(), any()))
        .thenAnswer((invocation) {
      final year = invocation.positionalArguments[0] as int;
      if (cachedYears.contains(year)) return Future.value([_devocional(year)]);
      final completer = pendingDownloads.putIfAbsent(
        year,
        () => Completer<List<Devocional>>(),
      );
      return completer.future;
    });
  });

  group('startup with an earlier year already cached', () {
    test(
      'does not wait for a missing later year, then caches it after the first frame',
      () async {
        cachedYears = {2025, 2026};
        final provider = buildProvider();

        // 2027 never completes on its own: if startup awaited it, this would hang.
        await provider.initializeData().timeout(
              const Duration(seconds: 2),
              onTimeout: () => fail('startup blocked on the uncached year'),
            );

        expect(
          provider.devocionales.map((d) => d.date.year),
          [2025, 2026],
          reason: 'only cached years are in memory, so the reading position '
              '(a list index) cannot shift',
        );
        verifyNever(() => repository.fetchAll(2027, any(), any()));

        // After the first frame the deferred year is downloaded (and cached
        // by the repository) without touching the in-memory list.
        final prefetch = provider.prefetchDeferredYears();
        await Future<void>.delayed(Duration.zero);
        verify(() => repository.fetchAll(2027, 'es', 'RVR1960')).called(1);
        pendingDownloads[2027]!.complete([_devocional(2027)]);
        await prefetch;

        expect(provider.devocionales.map((d) => d.date.year), [2025, 2026]);
      },
    );

    test('a failing deferred download is swallowed and not retried in-session',
        () async {
      cachedYears = {2025, 2026};
      final provider = buildProvider();
      await provider.initializeData();

      when(() => repository.fetchAll(2027, any(), any()))
          .thenThrow(Exception('network down'));
      await provider.prefetchDeferredYears();
      await provider.prefetchDeferredYears();

      verify(() => repository.fetchAll(2027, 'es', 'RVR1960')).called(1);
    });

    test('a stale cached year is still refreshed before startup completes',
        () async {
      cachedYears = {2025, 2026, 2027};
      when(() => repository.checkCacheStatus(2026, any(), any()))
          .thenAnswer((_) async => _cached(stale: true));
      final provider = buildProvider();

      await provider.initializeData();

      verify(() => repository.fetchAll(2026, 'es', 'RVR1960')).called(1);
      expect(provider.devocionales.map((d) => d.date.year), [2025, 2026, 2027]);
    });
  });

  group('startup keeps waiting when deferral could change the reading position',
      () {
    test('nothing cached (fresh install / restored history) awaits every year',
        () async {
      final provider = buildProvider();

      final init = provider.initializeData();
      for (final year in [2025, 2026, 2027]) {
        await Future<void>.delayed(Duration.zero);
        // Each year is requested in turn and startup waits for it.
        verify(() => repository.fetchAll(year, 'es', 'RVR1960')).called(1);
        pendingDownloads[year]!.complete([_devocional(year)]);
      }
      await init;

      expect(provider.devocionales.map((d) => d.date.year), [2025, 2026, 2027]);
      await provider.prefetchDeferredYears();
      verifyNever(() => repository.fetchAll(2027, any(), any()));
    });

    test('an earlier year missing while a later one is cached is still awaited',
        () async {
      cachedYears = {2026, 2027};
      final provider = buildProvider();

      final init = provider.initializeData();
      await Future<void>.delayed(Duration.zero);
      verify(() => repository.fetchAll(2025, 'es', 'RVR1960')).called(1);
      pendingDownloads[2025]!.complete([_devocional(2025)]);
      await init;

      expect(provider.devocionales.map((d) => d.date.year), [2025, 2026, 2027]);
    });

    test('a failed cache check falls back to the blocking path', () async {
      when(() => repository.checkCacheStatus(any(), any(), any()))
          .thenThrow(Exception('disk error'));
      cachedYears = {2025, 2026, 2027};
      final provider = buildProvider();

      await provider.initializeData();

      expect(provider.devocionales.map((d) => d.date.year), [2025, 2026, 2027]);
    });

    test('switching version never defers years', () async {
      cachedYears = {2025, 2026};
      final provider = buildProvider();
      await provider.initializeData();
      verifyNever(() => repository.fetchAll(2027, any(), any()));

      // 2027 downloads immediately for this switch.
      cachedYears = {2025, 2026, 2027};
      await provider.setSelectedVersion('NVI');

      verify(() => repository.fetchAll(2027, 'es', 'NVI')).called(1);
    });
  });
}
