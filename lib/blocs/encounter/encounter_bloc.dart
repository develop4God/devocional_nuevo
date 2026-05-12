// lib/blocs/encounter/encounter_bloc.dart

import 'package:collection/collection.dart';
import 'package:devocional_nuevo/blocs/encounter/encounter_event.dart';
import 'package:devocional_nuevo/blocs/encounter/encounter_state.dart';
import 'package:devocional_nuevo/models/encounter_index_entry.dart';
import 'package:devocional_nuevo/models/encounter_study.dart';
import 'package:devocional_nuevo/repositories/encounter_repository.dart';
import 'package:devocional_nuevo/services/i_encounter_progress_service.dart';
import 'package:devocional_nuevo/utils/constants/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

const Duration _kPrefetchDelay = Duration(seconds: 3);

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
      final index = await repository.fetchIndex(
        forceRefresh: event.forceRefresh,
      );
      debugPrint('🔵 [EncounterBloc] Index loaded: ${index.length} entries');

      // Load persisted completed IDs from SharedPreferences
      final completedIds = await progressService.loadCompletedIds();
      debugPrint(
        '✅ [EncounterBloc] Restored ${completedIds.length} completed encounter(s) from storage',
      );

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
          '🖼️ [EncounterBloc] BG: preloading images for ${first.id} [$lang]…',
        );

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
          '🖼️ [EncounterBloc] BG: warming disk cache for ${imageUrls.length} images…',
        );

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
          '✅ [EncounterBloc] BG: pre-cached $cached/${imageUrls.length} images for ${first.id}',
        );
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
          '✅ [EncounterBloc] Cache hit for ${event.id} — skipping fetch',
        );
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
        final updatedStudies = Map<String, EncounterStudy>.from(
          newState.loadedStudies,
        );
        updatedStudies[event.id] = study;
        emit(
          newState.copyWith(loadedStudies: updatedStudies, clearError: true),
        );
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
        '✅ [EncounterBloc] Encounter completed and saved: ${event.id}',
      );

      // Background: prefetch next encounter in the user's language.
      // Fail fast if language is unknown — don't silently default to 'es'.
      final completedStudy = currentState.loadedStudies[event.id];
      final lang = completedStudy?.language;
      if (lang == null) {
        debugPrint(
          '⚠️ [EncounterBloc] BG: No language found for ${event.id} — skipping prefetch',
        );
        return;
      }
      _prefetchNextEncounterImages(
        currentState.index,
        currentState.completedIds,
        lang,
      );
    }
  }

  /// Finds the next available encounter (respects sequential unlock chain)
  /// and fires off background fetch + image preload in the user's [lang].
  /// Never emits state — entirely background work.
  void _prefetchNextEncounterImages(
    List<EncounterIndexEntry> index,
    Set<String> completedIds,
    String lang,
  ) {
    if (index.isEmpty) return;

    Future.delayed(_kPrefetchDelay, () async {
      if (_disposed) return;
      try {
        // Find next published encounter that user hasn't completed yet
        final nextEntry = index.firstWhereOrNull((e) {
          if (e.status != 'published') return false;
          // Only prefetch if not already completed
          if (completedIds.contains(e.id)) return false;
          // Check if previous encounter is completed (sequential unlock chain)
          final entryIndex = index.indexOf(e);
          if (entryIndex > 0) {
            final previousEntry = index[entryIndex - 1];
            if (previousEntry.status == 'published' &&
                !completedIds.contains(previousEntry.id)) {
              return false; // Previous not done yet, this is locked
            }
          }
          return true;
        });

        if (nextEntry == null) {
          debugPrint(
            '📭 [EncounterBloc] BG: No next encounter to prefetch (all completed or locked)',
          );
          return;
        }

        debugPrint(
          '🎯 [EncounterBloc] BG: Prefetching next encounter ${nextEntry.id}…',
        );

        // Fetch the study JSON (also cached to disk via repository)
        final study = await repository.fetchStudy(
          nextEntry.id,
          lang,
          filename: nextEntry.files[lang] ??
              nextEntry.files['en'] ??
              '${nextEntry.id}_$lang.json',
          entry: nextEntry,
        );

        if (_disposed) return;

        // Warm the disk cache using the same AVIF-first resolution
        // that EncounterImageWidget uses — respecting SharedPrefs fallback flags
        // and version-scoped cache keys (SRP: resolution logic stays in one place).
        final prefs = await SharedPreferences.getInstance();
        final bases = study.cards
            .map((c) => c.imageUrl)
            .whereType<String>()
            .where((b) => b.isNotEmpty)
            .toSet();

        // Format resolution is per-encounter, not per-image (loop-invariant)
        final flagKey =
            'img_fallback_${nextEntry.id}_${nextEntry.imageVersion}';
        final usePng = prefs.getBool(flagKey) ?? false;
        final format = usePng ? 'png' : 'avif';

        int cached = 0;
        for (final base in bases) {
          if (_disposed) return;
          try {
            final url = Constants.getEncounterImageUrl(
              base,
              encounterId: nextEntry.id,
              format: format,
            );
            final cacheKey =
                '${nextEntry.id}_${base}_${nextEntry.imageVersion}_$format';
            await cacheManager.downloadFile(url, key: cacheKey);
            cached++;
          } catch (_) {
            // Individual image failure is non-fatal
          }
        }

        debugPrint(
          '✅ [EncounterBloc] BG: Prefetched ${nextEntry.id} — cached $cached/${bases.length} images',
        );
      } catch (e) {
        // Background prefetch is non-critical — log and swallow
        debugPrint('⚠️ [EncounterBloc] BG: Prefetch failed — $e');
      }
    });
  }
}
