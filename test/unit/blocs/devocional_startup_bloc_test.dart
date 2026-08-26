@Tags(['critical', 'unit', 'blocs'])
library;

import 'dart:async';

import 'package:devocional_nuevo/blocs/devocionales/devocional_startup_bloc.dart';
import 'package:devocional_nuevo/blocs/devocionales/devocional_startup_event.dart';
import 'package:devocional_nuevo/blocs/devocionales/devocional_startup_state.dart';
import 'package:devocional_nuevo/models/devocional_model.dart';
import 'package:devocional_nuevo/repositories/devocional_repository.dart';
import 'package:flutter_test/flutter_test.dart';

/// Hand-written fake implementing the full repository contract, so the tests
/// exercise real bloc sequencing rather than only asserting mock returns.
class _FakeDevocionalRepository implements DevocionalRepository {
  _FakeDevocionalRepository({
    this.years = const [2025, 2026],
    Map<int, CacheStatus>? statuses,
    Map<int, List<Devocional>>? local,
    Map<int, List<Devocional>>? remote,
  })  : statuses = statuses ?? {},
        local = local ?? {},
        remote = remote ?? {};

  List<int> years;
  final Map<int, CacheStatus> statuses;
  final Map<int, List<Devocional>> local;
  final Map<int, List<Devocional>> remote;

  /// Years whose fetchAll should throw instead of returning.
  final Set<int> failingYears = {};

  /// When set, fetchAll waits on this before returning — lets a test prove a
  /// state is emitted before the network resolves, without using delays.
  Completer<void>? fetchGate;

  final List<int> fetchedYears = [];
  int resetCacheCount = 0;

  @override
  Future<List<int>> getAvailableYears() async => years;

  @override
  Future<CacheStatus> checkCacheStatus(
    int year,
    String language,
    String version,
  ) async =>
      statuses[year] ??
      const CacheStatus(hasLocal: false, isStale: false, indexReachable: true);

  @override
  Future<List<Devocional>> readLocal(
    int year,
    String language,
    String version,
  ) async =>
      local[year] ?? [];

  @override
  Future<List<Devocional>> fetchAll(
    int year,
    String language,
    String version,
  ) async {
    fetchedYears.add(year);
    if (fetchGate != null) await fetchGate!.future;
    if (failingYears.contains(year)) throw Exception('year $year failed');
    return remote[year] ?? [];
  }

  @override
  void resetCache() => resetCacheCount++;

  // ── Unused by the startup bloc ──────────────────────────────────────────

  @override
  int findFirstUnreadDevocionalIndex(
    List<Devocional> devocionales,
    List<String> readDevocionalIds,
  ) =>
      0;

  @override
  List<Devocional> filterByVersion(
    List<Devocional> devocionales,
    String version,
  ) =>
      devocionales;

  @override
  Future<bool> hasLocalData(int year, String language, String version) async =>
      false;

  @override
  Future<bool> downloadAndStoreDevocionales(
    int year,
    String language,
    String version,
  ) async =>
      true;

  @override
  Future<void> clearOldFiles() async {}

  @override
  bool get wasLastFetchOffline => false;

  @override
  Future<bool> downloadCurrentYearDevocionales(
    String language,
    String version,
  ) async =>
      true;

  @override
  Future<bool> hasCurrentYearLocalData(String language, String version) async =>
      false;

  @override
  Future<bool> hasTargetYearsLocalData(String language, String version) async =>
      false;
}

Devocional _devocional(String id) => Devocional(
      id: id,
      versiculo: 'verse',
      reflexion: 'reflection',
      paraMeditar: const [],
      oracion: 'prayer',
      date: DateTime(2025, 1, 1),
      version: 'RVR1960',
    );

const _fresh = CacheStatus(
  hasLocal: true,
  isStale: false,
  indexReachable: true,
);
const _stale = CacheStatus(hasLocal: true, isStale: true, indexReachable: true);
const _missing = CacheStatus(
  hasLocal: false,
  isStale: false,
  indexReachable: true,
);
const _missingOffline = CacheStatus(
  hasLocal: false,
  isStale: false,
  indexReachable: false,
);

void main() {
  late _FakeDevocionalRepository repository;
  late DevocionalStartupBloc bloc;

  void buildBloc() {
    bloc = DevocionalStartupBloc(repository: repository);
    addTearDown(bloc.close);
  }

  group('fresh cache', () {
    test(
      'serves cache without making any year-file network call',
      () async {
        repository = _FakeDevocionalRepository(
          years: [2025, 2026],
          statuses: {2025: _fresh, 2026: _fresh},
          local: {
            2025: [_devocional('a')],
            2026: [_devocional('b')],
          },
        );
        buildBloc();

        final states = <DevocionalStartupState>[];
        final sub = bloc.stream.listen(states.add);

        bloc.add(const StartupRequested(language: 'es', version: 'RVR1960'));
        await bloc.stream.firstWhere((s) => s.isServableOrTerminal);
        await sub.cancel();

        expect(states[0], isA<StartupResolvingIndex>());
        expect(states[1], isA<StartupCheckingCache>());
        expect(states[2], isA<StartupServingCache>());

        final serving = states[2] as StartupServingCache;
        expect(serving.refreshing, isFalse);
        expect(serving.devocionales.length, 2);

        // The whole point of the fresh-cache path: no network at all.
        expect(repository.fetchedYears, isEmpty);
      },
    );
  });

  group('stale cache', () {
    test(
      'emits ServingCache before the network resolves, then Ready',
      () async {
        final gate = Completer<void>();
        repository = _FakeDevocionalRepository(
          years: [2025],
          statuses: {2025: _stale},
          local: {
            2025: [_devocional('cached')],
          },
          remote: {
            2025: [_devocional('fresh1'), _devocional('fresh2')],
          },
        )..fetchGate = gate;
        buildBloc();
        // Subscribe to both phases up front — bloc.stream is a broadcast
        // stream, so a listener attached after an emission would miss it.
        final servingFuture = bloc.stream.firstWhere(
          (s) => s is StartupServingCache,
        );
        final readyFuture = bloc.stream.firstWhere((s) => s is StartupReady);

        bloc.add(const StartupRequested(language: 'es', version: 'RVR1960'));

        // ServingCache must arrive while the fetch is still outstanding —
        // this is what proves the transition is completion-driven and not
        // waiting on the network.
        final serving = await servingFuture as StartupServingCache;

        expect(gate.isCompleted, isFalse);
        expect(serving.refreshing, isTrue);
        expect(serving.devocionales.single.id, 'cached');

        // Now let the refresh land.
        gate.complete();
        final ready = await readyFuture as StartupReady;

        expect(ready.devocionales.length, 2);
      },
    );
  });

  group('no cache', () {
    test(
      'emits Unavailable with no exception escaping when the network fails',
      () async {
        repository = _FakeDevocionalRepository(
          years: [2025],
          statuses: {2025: _missingOffline},
        )..failingYears.add(2025);
        buildBloc();

        final errors = <Object>[];
        final sub = bloc.stream.handleError(errors.add).listen((_) {});

        bloc.add(const StartupRequested(language: 'es', version: 'RVR1960'));
        final terminal = await bloc.stream.firstWhere(
          (s) => s.isServableOrTerminal,
        );
        await sub.cancel();

        expect(terminal, isA<StartupUnavailable>());
        expect(
          (terminal as StartupUnavailable).reason,
          StartupUnavailableReason.network,
        );
        expect(errors, isEmpty);
      },
    );

    test('emits Ready when one year succeeds and another fails', () async {
      repository = _FakeDevocionalRepository(
        years: [2025, 2026],
        statuses: {2025: _missing, 2026: _missing},
        remote: {
          2025: [_devocional('y1')],
        },
      )..failingYears.add(2026);
      buildBloc();

      bloc.add(const StartupRequested(language: 'es', version: 'RVR1960'));
      final terminal =
          await bloc.stream.firstWhere((s) => s.isServableOrTerminal);

      expect(terminal, isA<StartupReady>());
      expect((terminal as StartupReady).devocionales.single.id, 'y1');
    });

    test('emits fetching progress while downloading', () async {
      repository = _FakeDevocionalRepository(
        years: [2025, 2026],
        statuses: {2025: _missing, 2026: _missing},
        remote: {
          2025: [_devocional('y1')],
          2026: [_devocional('y2')],
        },
      );
      buildBloc();

      final states = <DevocionalStartupState>[];
      final sub = bloc.stream.listen(states.add);

      bloc.add(const StartupRequested(language: 'es', version: 'RVR1960'));
      await bloc.stream.firstWhere((s) => s.isServableOrTerminal);
      await sub.cancel();

      final fetching = states.whereType<StartupFetching>().toList();
      expect(fetching, isNotEmpty);
      expect(fetching.first.yearsTotal, 2);
    });
  });

  group('retry', () {
    test('re-enters ResolvingIndex from Unavailable', () async {
      repository = _FakeDevocionalRepository(
        years: [2025],
        statuses: {2025: _missingOffline},
      )..failingYears.add(2025);
      buildBloc();

      bloc.add(const StartupRequested(language: 'es', version: 'RVR1960'));
      await bloc.stream.firstWhere((s) => s is StartupUnavailable);

      // The retry succeeds this time.
      repository.failingYears.clear();
      repository.remote[2025] = [_devocional('retried')];
      repository.statuses[2025] = _missing;

      final afterRetry = <DevocionalStartupState>[];
      final sub = bloc.stream.listen(afterRetry.add);

      bloc.add(const StartupRetryRequested());
      final terminal =
          await bloc.stream.firstWhere((s) => s.isServableOrTerminal);
      await sub.cancel();

      expect(afterRetry.first, isA<StartupResolvingIndex>());
      expect(terminal, isA<StartupReady>());
      expect((terminal as StartupReady).devocionales.single.id, 'retried');

      // A retry must not reuse the memoized index from the failed attempt.
      expect(repository.resetCacheCount, 1);
    });

    test('is a no-op before any StartupRequested', () async {
      repository = _FakeDevocionalRepository();
      buildBloc();

      bloc.add(const StartupRetryRequested());
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state, isA<StartupIdle>());
      expect(repository.fetchedYears, isEmpty);
    });
  });
}
