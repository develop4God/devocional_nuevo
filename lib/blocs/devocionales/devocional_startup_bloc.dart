// lib/blocs/devocionales/devocional_startup_bloc.dart

import 'package:devocional_nuevo/models/devocional_model.dart';
import 'package:devocional_nuevo/repositories/devocional_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'devocional_startup_event.dart';
import 'devocional_startup_state.dart';

/// BLoC sequencing devotional startup as explicit phases.
///
/// Every transition is caused by a prior phase producing its output — resolving
/// the index, reading the cache, or a year file landing — never by a wall-clock
/// timer. Timeouts live only on the individual HTTP calls inside the
/// repository, as dead-socket escape hatches.
class DevocionalStartupBloc
    extends Bloc<DevocionalStartupEvent, DevocionalStartupState> {
  final DevocionalRepository _repository;

  /// Retained so [StartupRetryRequested] can re-run the last request.
  String? _language;
  String? _version;

  DevocionalStartupBloc({required DevocionalRepository repository})
      : _repository = repository,
        super(const StartupIdle()) {
    on<StartupRequested>(_onStartupRequested);
    on<StartupRetryRequested>(_onStartupRetryRequested);
  }

  Future<void> _onStartupRequested(
    StartupRequested event,
    Emitter<DevocionalStartupState> emit,
  ) async {
    _language = event.language;
    _version = event.version;
    await _runStartup(event.language, event.version, emit);
  }

  Future<void> _onStartupRetryRequested(
    StartupRetryRequested event,
    Emitter<DevocionalStartupState> emit,
  ) async {
    final language = _language;
    final version = _version;
    if (language == null || version == null) {
      // Retry before any StartupRequested — nothing to re-run.
      return;
    }

    // A retry means the remote state may have changed since the failed
    // attempt, so the memoized index must not be reused.
    _repository.resetCache();
    await _runStartup(language, version, emit);
  }

  Future<void> _runStartup(
    String language,
    String version,
    Emitter<DevocionalStartupState> emit,
  ) async {
    try {
      emit(const StartupResolvingIndex());
      final List<int> years = await _repository.getAvailableYears();

      emit(const StartupCheckingCache());
      final List<CacheStatus> statuses = [];
      for (final year in years) {
        statuses.add(
          await _repository.checkCacheStatus(year, language, version),
        );
      }

      // Any local file is servable immediately, fresh or not — staleness only
      // decides whether to also refresh in the background (below).
      final bool anyServableFromCache = statuses.any((s) => s.hasLocal);
      final bool anyStale = statuses.any((s) => s.isStale);

      if (anyServableFromCache) {
        // Serve what is on disk immediately — no network wait. If anything is
        // stale, refresh in the background and re-emit with fresher content.
        final List<Devocional> cached = await _readAllLocal(
          years,
          statuses,
          language,
          version,
        );
        emit(
          StartupServingCache(devocionales: cached, refreshing: anyStale),
        );

        if (!anyStale) return;

        final List<Devocional> refreshed = await _fetchYears(
          years,
          language,
          version,
          emit,
          emitProgress: false,
        );
        // Keep serving the cache if the refresh produced nothing usable.
        if (refreshed.isNotEmpty) emit(StartupReady(refreshed));
        return;
      }

      // Nothing usable on disk — the one phase with an unavoidable
      // foreground network wait.
      final List<Devocional> fetched = await _fetchYears(
        years,
        language,
        version,
        emit,
        emitProgress: true,
      );

      if (fetched.isNotEmpty) {
        emit(StartupReady(fetched));
      } else {
        final bool indexReachable = statuses.any((s) => s.indexReachable);
        emit(
          StartupUnavailable(
            indexReachable
                ? StartupUnavailableReason.serverContent
                : StartupUnavailableReason.network,
          ),
        );
      }
    } catch (e) {
      // A phase failure is a state the UI renders, never an escaped exception.
      debugPrint('[STARTUP_BLOC] Startup failed: $e');
      emit(const StartupUnavailable(StartupUnavailableReason.network));
    }
  }

  /// Reads every year that has a usable local file.
  Future<List<Devocional>> _readAllLocal(
    List<int> years,
    List<CacheStatus> statuses,
    String language,
    String version,
  ) async {
    final List<Devocional> all = [];
    for (int i = 0; i < years.length; i++) {
      if (!statuses[i].hasLocal) continue;
      all.addAll(await _repository.readLocal(years[i], language, version));
    }
    return all;
  }

  /// Fetches each year, tolerating per-year failure.
  ///
  /// Emits [StartupFetching] progress when [emitProgress] is true — that is,
  /// when the user is waiting on this with nothing else to look at.
  Future<List<Devocional>> _fetchYears(
    List<int> years,
    String language,
    String version,
    Emitter<DevocionalStartupState> emit, {
    required bool emitProgress,
  }) async {
    final List<Devocional> all = [];
    for (int i = 0; i < years.length; i++) {
      if (emitProgress) {
        emit(StartupFetching(yearsDone: i, yearsTotal: years.length));
      }
      try {
        all.addAll(await _repository.fetchAll(years[i], language, version));
      } catch (e) {
        // Partial success is not an error — a later year may still land.
        debugPrint('[STARTUP_BLOC] Year ${years[i]} failed: $e');
      }
    }
    return all;
  }
}
