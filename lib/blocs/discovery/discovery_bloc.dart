// lib/blocs/discovery/discovery_bloc.dart

import 'package:devocional_nuevo/models/discovery_devotional_model.dart';
import 'package:devocional_nuevo/repositories/discovery_repository.dart';
import 'package:devocional_nuevo/services/discovery_favorites_service.dart';
import 'package:devocional_nuevo/services/discovery_progress_tracker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'discovery_event.dart';
import 'discovery_state.dart';

class DiscoveryBloc extends Bloc<DiscoveryEvent, DiscoveryState> {
  static const String _firstDownloadKeyPrefix = 'discovery_first_downloaded_';

  final DiscoveryRepository repository;
  final DiscoveryProgressTracker progressTracker;
  final DiscoveryFavoritesService favoritesService;

  bool _disposed = false;
  SharedPreferences? _prefs;

  Future<SharedPreferences> get prefs async {
    return _prefs ??= await SharedPreferences.getInstance();
  }

  DiscoveryBloc({
    required this.repository,
    required this.progressTracker,
    required this.favoritesService,
  }) : super(DiscoveryInitial()) {
    on<LoadDiscoveryStudies>(_onLoadDiscoveryStudies);
    on<LoadDiscoveryStudy>(_onLoadDiscoveryStudy);
    on<MarkSectionCompleted>(_onMarkSectionCompleted);
    on<AnswerDiscoveryQuestion>(_onAnswerDiscoveryQuestion);
    on<CompleteDiscoveryStudy>(_onCompleteDiscoveryStudy);
    on<ToggleDiscoveryFavorite>(_onToggleDiscoveryFavorite);
    on<ResetDiscoveryStudy>(_onResetDiscoveryStudy);
    on<RefreshDiscoveryStudies>(_onRefreshDiscoveryStudies);
    on<ClearDiscoveryError>(_onClearDiscoveryError);
  }

  @override
  Future<void> close() {
    _disposed = true;
    return super.close();
  }

  Future<void> _onLoadDiscoveryStudies(
    LoadDiscoveryStudies event,
    Emitter<DiscoveryState> emit,
  ) async {
    emit(DiscoveryLoading());
    await _fetchAndEmitIndex(emit, languageCode: event.languageCode);
  }

  Future<void> _fetchAndEmitIndex(Emitter<DiscoveryState> emit,
      {bool forceRefresh = false, String? languageCode}) async {
    try {
      debugPrint(
          '🔵 [BLOC] _fetchAndEmitIndex START (languageCode: $languageCode, forceRefresh: $forceRefresh)');

      final index = await repository.fetchIndex(forceRefresh: forceRefresh);
      debugPrint('🔵 [BLOC] Index fetched successfully');

      String locale = languageCode ?? 'es';
      if (languageCode == null) {
        try {
          locale =
              WidgetsBinding.instance.platformDispatcher.locale.languageCode;
          debugPrint('🔵 [BLOC] Detected platform locale: $locale');
        } catch (_) {
          debugPrint('🔵 [BLOC] Failed to detect locale, using default: es');
        }
      } else {
        debugPrint('🔵 [BLOC] Using provided locale: $locale');
      }

      final favoriteIds = await favoritesService.loadFavoriteIds(locale);
      debugPrint('🔵 [BLOC] Favorites loaded: ${favoriteIds.length} items');

      final List<String> filteredStudyIds = [];
      final Map<String, String> studyTitles = {};
      final Map<String, String> studySubtitles = {};
      final Map<String, String> studyEmojis = {};
      final Map<String, int> studyReadingMinutes = {};
      final Map<String, bool> completedStudies = {};

      final studiesData = index['studies'];
      final List studies = studiesData is List ? studiesData : [];
      debugPrint('🔵 [BLOC] Processing ${studies.length} studies from index');

      for (final s in studies) {
        if (s is! Map<String, dynamic>) {
          debugPrint('⚠️ [BLOC] Skipping non-map study entry');
          continue;
        }

        final id = s['id'] as String?;
        if (id == null) {
          debugPrint('⚠️ [BLOC] Skipping study with null ID');
          continue;
        }

        debugPrint('🔍 [BLOC] Processing study: $id');

        final files = s['files'];
        final filesMap = files is Map ? files : null;

        if (filesMap != null) {
          debugPrint('  📁 Files available: ${filesMap.keys.toList()}');
        } else {
          debugPrint('  ❌ No files map found for $id');
        }

        // Check if study has files for current locale OR fallback locales
        final hasValidFile = filesMap != null &&
            (filesMap.containsKey(locale) ||
                filesMap.containsKey('es') ||
                filesMap.containsKey('en'));

        debugPrint(
            '  ✓ hasValidFile: $hasValidFile (locale: $locale, has es: ${filesMap?.containsKey('es')}, has en: ${filesMap?.containsKey('en')})');

        if (hasValidFile) {
          filteredStudyIds.add(id);
          debugPrint('  ✅ Study $id ADDED to filtered list');

          // Safe Title extraction
          final titles = s['titles'];
          if (titles is Map) {
            studyTitles[id] =
                titles[locale]?.toString() ?? titles['es']?.toString() ?? id;
            debugPrint('  📝 Title: ${studyTitles[id]}');
          } else {
            studyTitles[id] = s['title']?.toString() ?? id;
            debugPrint('  📝 Title (legacy): ${studyTitles[id]}');
          }

          // Safe Subtitle extraction
          final subtitles = s['subtitles'];
          if (subtitles is Map) {
            studySubtitles[id] = subtitles[locale]?.toString() ??
                subtitles['es']?.toString() ??
                '';
            debugPrint('  📋 Subtitle: ${studySubtitles[id]}');
          } else {
            studySubtitles[id] = s['subtitle']?.toString() ?? '';
            debugPrint('  📋 Subtitle (legacy): ${studySubtitles[id]}');
          }

          studyEmojis[id] = s['emoji']?.toString() ?? '📖';
          debugPrint('  😀 Emoji: ${studyEmojis[id]}');

          // Safe Reading Minutes extraction
          final readingMinutes = s['estimated_reading_minutes'];
          if (readingMinutes is Map) {
            final val = readingMinutes[locale] ?? readingMinutes['es'] ?? 5;
            studyReadingMinutes[id] = int.tryParse(val.toString()) ?? 5;
          } else if (readingMinutes is int) {
            studyReadingMinutes[id] = readingMinutes;
          } else {
            studyReadingMinutes[id] = 5;
          }
          debugPrint('  ⏱️ Reading minutes: ${studyReadingMinutes[id]}');

          final progress = await progressTracker.getProgress(id, locale);
          completedStudies[id] = progress.isCompleted;
          debugPrint('  🎯 Completed: ${completedStudies[id]}');
        } else {
          debugPrint('  ❌ Study $id SKIPPED (no valid files)');
        }
      }

      debugPrint(
          '🔵 [BLOC] Filtering complete: ${filteredStudyIds.length} studies passed filter');
      debugPrint('🔵 [BLOC] Filtered IDs: $filteredStudyIds');
      debugPrint('🔵 [BLOC] Titles: ${studyTitles.keys.toList()}');
      debugPrint('🔵 [BLOC] Subtitles: ${studySubtitles.keys.toList()}');

      emit(
        DiscoveryLoaded(
          availableStudyIds: filteredStudyIds,
          loadedStudies: {},
          studyTitles: studyTitles,
          studySubtitles: studySubtitles,
          // Ensure required parameter is passed
          studyEmojis: studyEmojis,
          studyReadingMinutes: studyReadingMinutes,
          // Ensure required parameter is passed
          completedStudies: completedStudies,
          favoriteStudyIds: favoriteIds,
          languageCode: locale,
        ),
      );

      debugPrint(
          '🔵 [BLOC] DiscoveryLoaded state emitted with ${filteredStudyIds.length} studies');

      // Background download of first study for offline access
      if (filteredStudyIds.isNotEmpty) {
        _downloadFirstStudyForOffline(filteredStudyIds.first, locale);
      }
    } catch (e) {
      debugPrint('❌ [BLOC] Error loading Discovery index: $e');
      debugPrint('❌ [BLOC] Stack trace: ${StackTrace.current}');
      emit(DiscoveryError('Error: $e'));
    }
  }

  /// Download first study in background for offline access
  void _downloadFirstStudyForOffline(String studyId, String languageCode) {
    // Run in background without awaiting
    Future.microtask(() async {
      if (_disposed) return;

      try {
        final prefsInstance = await prefs;
        final downloadKey = '$_firstDownloadKeyPrefix$languageCode';

        // Check if we've already downloaded a study for this language
        final alreadyDownloaded = prefsInstance.getBool(downloadKey) ?? false;

        if (!alreadyDownloaded) {
          debugPrint('📥 [BLOC] Downloading first study for offline: $studyId');
          await repository.fetchDiscoveryStudy(studyId, languageCode);
          await prefsInstance.setBool(downloadKey, true);
          debugPrint('✅ [BLOC] First study downloaded for offline access');
        } else {
          debugPrint(
              '✓ [BLOC] First study already downloaded for this language');
        }
      } catch (e) {
        debugPrint('⚠️ [BLOC] Failed to download first study for offline: $e');
      }
    });
  }

  Future<void> _onLoadDiscoveryStudy(
    LoadDiscoveryStudy event,
    Emitter<DiscoveryState> emit,
  ) async {
    final currentState = state;
    
    // If we're already in DiscoveryLoaded, we track downloading state per study
    if (currentState is DiscoveryLoaded) {
      final updatedDownloading = Set<String>.from(currentState.downloadingStudyIds);
      updatedDownloading.add(event.studyId);
      
      emit(currentState.copyWith(
        downloadingStudyIds: updatedDownloading,
        clearError: true,
      ));
    } else {
      // Fallback for initial load
      emit(DiscoveryStudyLoading(event.studyId));
    }

    try {
      final languageCode = event.languageCode ?? 'es';
      final study = await repository.fetchDiscoveryStudy(
        event.studyId,
        languageCode,
      );

      final newState = state; // Get current state after async work
      if (newState is DiscoveryLoaded) {
        final updatedStudies =
            Map<String, DiscoveryDevotional>.from(newState.loadedStudies);
        updatedStudies[event.studyId] = study;
        
        final updatedDownloading = Set<String>.from(newState.downloadingStudyIds);
        updatedDownloading.remove(event.studyId);

        emit(
          newState.copyWith(
            loadedStudies: updatedStudies,
            downloadingStudyIds: updatedDownloading,
            clearError: true,
          ),
        );
      } else {
        // Fallback if state changed drastically (shouldn't happen often)
        final progress =
            await progressTracker.getProgress(event.studyId, languageCode);
        final favoriteIds =
            await favoritesService.loadFavoriteIds(languageCode);
        emit(
          DiscoveryLoaded(
            availableStudyIds: [event.studyId],
            loadedStudies: {event.studyId: study},
            studyTitles: {},
            studySubtitles: {},
            studyEmojis: {},
            studyReadingMinutes: {},
            completedStudies: {event.studyId: progress.isCompleted},
            favoriteStudyIds: favoriteIds,
            languageCode: languageCode,
            downloadingStudyIds: {},
          ),
        );
      }
    } catch (e) {
      final newState = state;
      if (newState is DiscoveryLoaded) {
        final updatedDownloading = Set<String>.from(newState.downloadingStudyIds);
        updatedDownloading.remove(event.studyId);
        
        emit(newState.copyWith(
            downloadingStudyIds: updatedDownloading,
            errorMessage: 'Error al cargar contenido del estudio: $e'));
      } else {
        emit(DiscoveryError('Error al cargar estudio: $e'));
      }
    }
  }

  Future<void> _onMarkSectionCompleted(
    MarkSectionCompleted event,
    Emitter<DiscoveryState> emit,
  ) async {
    try {
      final currentState = state;
      final languageCode =
          currentState is DiscoveryLoaded ? currentState.languageCode : null;
      await progressTracker.markSectionCompleted(
          event.studyId, event.sectionIndex, languageCode);
      if (currentState is DiscoveryLoaded) {
        emit(currentState.copyWith(
            clearError: true, lastUpdated: DateTime.now()));
      }
    } catch (e) {
      debugPrint('Error marking section completed: $e');
    }
  }

  Future<void> _onAnswerDiscoveryQuestion(
    AnswerDiscoveryQuestion event,
    Emitter<DiscoveryState> emit,
  ) async {
    try {
      final currentState = state;
      final languageCode =
          currentState is DiscoveryLoaded ? currentState.languageCode : null;
      await progressTracker.answerQuestion(
          event.studyId, event.questionIndex, event.answer, languageCode);
      if (currentState is DiscoveryLoaded) {
        emit(currentState.copyWith(
            clearError: true, lastUpdated: DateTime.now()));
      }
    } catch (e) {
      debugPrint('Error saving answer: $e');
    }
  }

  Future<void> _onCompleteDiscoveryStudy(
    CompleteDiscoveryStudy event,
    Emitter<DiscoveryState> emit,
  ) async {
    try {
      final currentState = state;
      final languageCode =
          currentState is DiscoveryLoaded ? currentState.languageCode : null;
      await progressTracker.completeStudy(event.studyId, languageCode);
      if (currentState is DiscoveryLoaded) {
        final updatedCompletion =
            Map<String, bool>.from(currentState.completedStudies);
        updatedCompletion[event.studyId] = true;

        emit(currentState.copyWith(
          completedStudies: updatedCompletion,
          clearError: true,
          lastUpdated: DateTime.now(),
        ));
      }
    } catch (e) {
      debugPrint('Error completing study: $e');
    }
  }

  Future<void> _onToggleDiscoveryFavorite(
    ToggleDiscoveryFavorite event,
    Emitter<DiscoveryState> emit,
  ) async {
    final currentState = state;
    if (currentState is DiscoveryLoaded) {
      await favoritesService.toggleFavorite(
          event.studyId, currentState.languageCode);
      final updatedIds =
          await favoritesService.loadFavoriteIds(currentState.languageCode);

      emit(currentState.copyWith(
        favoriteStudyIds: updatedIds,
        lastUpdated: DateTime.now(),
      ));
    }
  }

  Future<void> _onResetDiscoveryStudy(
    ResetDiscoveryStudy event,
    Emitter<DiscoveryState> emit,
  ) async {
    try {
      final currentState = state;
      final languageCode =
          currentState is DiscoveryLoaded ? currentState.languageCode : null;
      await progressTracker.resetStudyProgress(event.studyId, languageCode);
      if (currentState is DiscoveryLoaded) {
        final updatedCompletion =
            Map<String, bool>.from(currentState.completedStudies);
        updatedCompletion[event.studyId] = false;

        emit(currentState.copyWith(
          completedStudies: updatedCompletion,
          clearError: true,
          lastUpdated: DateTime.now(),
        ));
      }
    } catch (e) {
      debugPrint('Error resetting study progress: $e');
    }
  }

  Future<void> _onRefreshDiscoveryStudies(
    RefreshDiscoveryStudies event,
    Emitter<DiscoveryState> emit,
  ) async {
    await _fetchAndEmitIndex(emit,
        forceRefresh: true, languageCode: event.languageCode);
  }

  void _onClearDiscoveryError(
    ClearDiscoveryError event,
    Emitter<DiscoveryState> emit,
  ) {
    final currentState = state;
    if (currentState is DiscoveryLoaded) {
      emit(currentState.copyWith(clearError: true));
    }
  }
}
