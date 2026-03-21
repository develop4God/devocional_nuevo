// lib/blocs/encounter/encounter_bloc.dart

import 'package:collection/collection.dart';
import 'package:devocional_nuevo/blocs/encounter/encounter_event.dart';
import 'package:devocional_nuevo/blocs/encounter/encounter_state.dart';
import 'package:devocional_nuevo/models/encounter_index_entry.dart';
import 'package:devocional_nuevo/models/encounter_study.dart';
import 'package:devocional_nuevo/repositories/encounter_repository.dart';
import 'package:devocional_nuevo/services/i_encounter_progress_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class EncounterBloc extends Bloc<EncounterEvent, EncounterState> {
  final EncounterRepository repository;
  final IEncounterProgressService progressService;
  final BaseCacheManager cacheManager;

  bool _disposed = false;

  EncounterBloc({
    required this.repository,
    required this.progressService,
    required this.cacheManager,
  }) : super(EncounterInitial()) {
    on<LoadEncounterIndex>(_onLoadEncounterIndex);
    on<LoadEncounterStudy>(_onLoadEncounterStudy);
    on<CompleteEncounter>(_onCompleteEncounter);
  }

  @override
  Future<void> close() {
    _disposed = true;
    return super.close();
  }

  Future<void> _onLoadEncounterIndex(
    LoadEncounterIndex event,
    Emitter<EncounterState> emit,
  ) async {
    emit(EncounterLoading());

    try {
      final index =
          await repository.fetchIndex(forceRefresh: event.forceRefresh);
      debugPrint('🔵 [EncounterBloc] Index loaded: ${index.length} entries');

      // Load persisted completed IDs from SharedPreferences
      final completedIds = await progressService.loadCompletedIds();
      debugPrint(
          '✅ [EncounterBloc] Restored ${completedIds.length} completed encounter(s) from storage');

      emit(EncounterLoaded(index: index, completedIds: completedIds));

      // Background: warm image cache for first published encounter
      // so images are ready when the user opens the reader.
      _preloadFirstEncounterImages(index, event.languageCode ?? 'es');
    } catch (e) {
      debugPrint('❌ [EncounterBloc] Error loading index: $e');
      emit(EncounterError('Error loading encounters: $e'));
    }
  }

  /// Downloads card images for the first published encounter into the
  /// disk cache ([DefaultCacheManager]) so they are served instantly from
  /// cache when [CachedNetworkImage] first renders them.
  ///
  /// Runs entirely in the background — never emits a state.
  void _preloadFirstEncounterImages(
    List<EncounterIndexEntry> index,
    String lang,
  ) {
    if (index.isEmpty) return;

    Future.microtask(() async {
      if (_disposed) return;
      try {
        final first = index.firstWhere(
          (e) => e.status == 'published',
          orElse: () => index.first,
        );

        debugPrint(
            '🖼️ [EncounterBloc] BG: preloading images for ${first.id} [$lang]…');

        final filename =
            first.files[lang] ?? first.files['en'] ?? '${first.id}_$lang.json';

        // Fetch study (also warms the SharedPrefs JSON cache as a side-effect)
        final EncounterStudy study = await repository.fetchStudy(
          first.id,
          lang,
          filename: filename,
          entry: first,
        );

        if (_disposed) return;

        final imageUrls = study.cards
            .map((c) => c.imageUrl)
            .whereType<String>()
            .where((url) => url.isNotEmpty)
            .toSet();

        debugPrint(
            '🖼️ [EncounterBloc] BG: warming disk cache for ${imageUrls.length} images…');

        int cached = 0;
        for (final url in imageUrls) {
          if (_disposed) return;
          try {
            await cacheManager.downloadFile(url);
            cached++;
          } catch (_) {
            // Individual image failure is non-fatal
          }
        }

        debugPrint(
            '✅ [EncounterBloc] BG: pre-cached $cached/${imageUrls.length} images for ${first.id}');
      } catch (e) {
        // Background preload is non-critical — log and swallow
        debugPrint('⚠️ [EncounterBloc] BG image preload failed: $e');
      }
    });
  }

  Future<void> _onLoadEncounterStudy(
    LoadEncounterStudy event,
    Emitter<EncounterState> emit,
  ) async {
    final currentState = state;

    // If state is EncounterLoaded, keep index while loading study
    // Check cache in the map before fetching
    if (currentState is EncounterLoaded) {
      if (currentState.isStudyLoaded(event.id)) {
        debugPrint(
            '✅ [EncounterBloc] Cache hit for ${event.id} — skipping fetch');
        return; // Already loaded, do nothing
      }
    }

    try {
      // Entry is already in state — pass it for version-aware cache.
      // No extra network call: index was fetched when state became EncounterLoaded.
      final entry = currentState is EncounterLoaded
          ? currentState.index.firstWhereOrNull((e) => e.id == event.id)
          : null;

      debugPrint(
        '🔵 [EncounterBloc] Fetching study ${event.id} (${event.lang}) '
        'entry v${entry?.version ?? "unknown — entry not in state"}',
      );

      final study = await repository.fetchStudy(
        event.id,
        event.lang,
        filename: event.filename ?? entry?.fileFor(event.lang),
        entry: entry, // version signal, no extra network call
      );

      if (_disposed) return;

      final newState = state;
      if (newState is EncounterLoaded) {
        final updatedStudies =
            Map<String, EncounterStudy>.from(newState.loadedStudies);
        updatedStudies[event.id] = study;
        emit(
            newState.copyWith(loadedStudies: updatedStudies, clearError: true));
      } else {
        // Fallback if state changed
        emit(
          EncounterLoaded(
            index: currentState is EncounterLoaded ? currentState.index : [],
            loadedStudies: {event.id: study},
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ [EncounterBloc] Error loading study ${event.id}: $e');
      final newState = state;
      if (newState is EncounterLoaded) {
        emit(newState.copyWith(errorMessage: 'Error loading encounter: $e'));
      } else {
        emit(EncounterError('Error loading encounter: $e'));
      }
    }
  }

  Future<void> _onCompleteEncounter(
    CompleteEncounter event,
    Emitter<EncounterState> emit,
  ) async {
    final currentState = state;
    if (currentState is EncounterLoaded) {
      // Persist to SharedPreferences first
      await progressService.markCompleted(event.id);

      final updated = Set<String>.from(currentState.completedIds);
      updated.add(event.id);
      emit(currentState.copyWith(completedIds: updated));
      debugPrint(
          '✅ [EncounterBloc] Encounter completed and saved: ${event.id}');
    }
  }
}
