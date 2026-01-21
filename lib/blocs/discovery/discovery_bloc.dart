// lib/blocs/discovery/discovery_bloc.dart

import 'package:devocional_nuevo/models/discovery_devotional_model.dart';
import 'package:devocional_nuevo/repositories/discovery_repository.dart';
import 'package:devocional_nuevo/services/discovery_favorites_service.dart';
import 'package:devocional_nuevo/services/discovery_progress_tracker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'discovery_event.dart';
import 'discovery_state.dart';

class DiscoveryBloc extends Bloc<DiscoveryEvent, DiscoveryState> {
  final DiscoveryRepository repository;
  final DiscoveryProgressTracker progressTracker;
  final DiscoveryFavoritesService favoritesService;

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
      final index = await repository.fetchIndex(forceRefresh: forceRefresh);
      final favoriteIds = await favoritesService.loadFavoriteIds();

      String locale = languageCode ?? 'es';
      if (languageCode == null) {
        try {
          locale =
              WidgetsBinding.instance.platformDispatcher.locale.languageCode;
        } catch (_) {}
      }

      final List<String> filteredStudyIds = [];
      final Map<String, String> studyTitles = {};
      final Map<String, String> studySubtitles = {};
      final Map<String, String> studyEmojis = {};
      final Map<String, int> studyReadingMinutes = {};
      final Map<String, bool> completedStudies = {};

      final studiesData = index['studies'];
      final List studies = studiesData is List ? studiesData : [];

      for (final s in studies) {
        if (s is! Map<String, dynamic>) continue;

        final id = s['id'] as String?;
        if (id == null) continue;

        final files = s['files'];
        final filesMap = files is Map ? files : null;

        if (filesMap != null && filesMap.containsKey(locale)) {
          filteredStudyIds.add(id);

          // Safe Title extraction
          final titles = s['titles'];
          if (titles is Map) {
            studyTitles[id] =
                titles[locale]?.toString() ?? titles['es']?.toString() ?? id;
          } else {
            studyTitles[id] = s['title']?.toString() ?? id;
          }

          // Safe Subtitle extraction
          final subtitles = s['subtitles'];
          if (subtitles is Map) {
            studySubtitles[id] = subtitles[locale]?.toString() ??
                subtitles['es']?.toString() ??
                '';
          } else {
            studySubtitles[id] = s['subtitle']?.toString() ?? '';
          }

          studyEmojis[id] = s['emoji']?.toString() ?? '📖';

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

          final progress = await progressTracker.getProgress(id);
          completedStudies[id] = progress.isCompleted;
        }
      }

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
        ),
      );
    } catch (e) {
      debugPrint('Error loading Discovery index: $e');
      emit(DiscoveryError('Error: $e'));
    }
  }

  Future<void> _onLoadDiscoveryStudy(
    LoadDiscoveryStudy event,
    Emitter<DiscoveryState> emit,
  ) async {
    final currentState = state;
    emit(DiscoveryStudyLoading(event.studyId));

    try {
      final languageCode = event.languageCode ?? 'es';
      final study = await repository.fetchDiscoveryStudy(
        event.studyId,
        languageCode,
      );

      if (currentState is DiscoveryLoaded) {
        final updatedStudies =
            Map<String, DiscoveryDevotional>.from(currentState.loadedStudies);
        updatedStudies[event.studyId] = study;

        emit(
          currentState.copyWith(
            loadedStudies: updatedStudies,
            clearError: true,
          ),
        );
      } else {
        final progress = await progressTracker.getProgress(event.studyId);
        final favoriteIds = await favoritesService.loadFavoriteIds();
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
          ),
        );
      }
    } catch (e) {
      if (currentState is DiscoveryLoaded) {
        emit(currentState.copyWith(
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
      await progressTracker.markSectionCompleted(
          event.studyId, event.sectionIndex);
      final currentState = state;
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
      await progressTracker.answerQuestion(
          event.studyId, event.questionIndex, event.answer);
      final currentState = state;
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
      await progressTracker.completeStudy(event.studyId);
      final currentState = state;
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
      await favoritesService.toggleFavorite(event.studyId);
      final updatedIds = await favoritesService.loadFavoriteIds();

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
      await progressTracker.resetStudyProgress(event.studyId);
      final currentState = state;
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
