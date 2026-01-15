// lib/blocs/discovery/discovery_bloc.dart

import 'package:devocional_nuevo/models/discovery_devotional_model.dart';
import 'package:devocional_nuevo/repositories/discovery_repository.dart';
import 'package:devocional_nuevo/services/discovery_favorites_service.dart';
import 'package:devocional_nuevo/services/discovery_progress_tracker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'discovery_event.dart';
import 'discovery_state.dart';

/// BLoC for managing Discovery studies with intelligent version-based fetching.
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

  /// Handles loading all available Discovery studies on page entry.
  Future<void> _onLoadDiscoveryStudies(
    LoadDiscoveryStudies event,
    Emitter<DiscoveryState> emit,
  ) async {
    emit(DiscoveryLoading());
    await _fetchAndEmitIndex(emit, languageCode: event.languageCode);
  }

  /// Shared logic to fetch index and emit loaded state
  Future<void> _fetchAndEmitIndex(Emitter<DiscoveryState> emit, {bool forceRefresh = false, String? languageCode}) async {
    try {
      final studyIds = await repository.fetchAvailableStudies(forceRefresh: forceRefresh);
      final index = await repository.fetchIndex(forceRefresh: forceRefresh);
      final favoriteIds = await favoritesService.loadFavoriteIds();
      
      // ✅ PRIORITY: Use provided languageCode, then platform locale, then fallback 'es'
      String locale = languageCode ?? 'es';
      if (languageCode == null) {
        try {
          locale = WidgetsBinding.instance.platformDispatcher.locale.languageCode;
        } catch (_) {}
      }

      debugPrint('🌐 Discovery: Building index for language: $locale');

      final Map<String, String> studyTitles = {};
      final Map<String, String> studyEmojis = {};
      final Map<String, bool> completedStudies = {};
      
      final studies = index['studies'] as List<dynamic>? ?? [];
      for (final s in studies) {
        final id = s['id'] as String?;
        if (id != null) {
          final titles = s['titles'] as Map<String, dynamic>?;
          final emoji = s['emoji'] as String?;

          if (titles != null) {
            studyTitles[id] = titles[locale] ?? titles['es'] ?? id;
          }
          if (emoji != null) {
            studyEmojis[id] = emoji;
          }
          
          final progress = await progressTracker.getProgress(id);
          completedStudies[id] = progress.isCompleted;
        }
      }
      
      emit(
        DiscoveryLoaded(
          availableStudyIds: studyIds,
          loadedStudies: {},
          studyTitles: studyTitles,
          studyEmojis: studyEmojis,
          completedStudies: completedStudies,
          favoriteStudyIds: favoriteIds,
        ),
      );
    } catch (e) {
      debugPrint('Error loading Discovery studies index: $e');
      emit(DiscoveryError('Error al cargar índice de estudios: $e'));
    }
  }

  /// Handles loading a specific Discovery study content.
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
        final updatedStudies = Map<String, DiscoveryDevotional>.from(currentState.loadedStudies);
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
            studyEmojis: {},
            completedStudies: {event.studyId: progress.isCompleted},
            favoriteStudyIds: favoriteIds,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error loading Discovery study ${event.studyId}: $e');
      if (currentState is DiscoveryLoaded) {
        emit(currentState.copyWith(errorMessage: 'Error al cargar contenido del estudio: $e'));
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
      await progressTracker.markSectionCompleted(event.studyId, event.sectionIndex);
      final currentState = state;
      if (currentState is DiscoveryLoaded) {
        emit(currentState.copyWith(clearError: true, lastUpdated: DateTime.now()));
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
      await progressTracker.answerQuestion(event.studyId, event.questionIndex, event.answer);
      final currentState = state;
      if (currentState is DiscoveryLoaded) {
        emit(currentState.copyWith(clearError: true, lastUpdated: DateTime.now()));
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
        final updatedCompletion = Map<String, bool>.from(currentState.completedStudies);
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

  /// Handles toggling favorite status
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
        final updatedCompletion = Map<String, bool>.from(currentState.completedStudies);
        updatedCompletion[event.studyId] = false; // Mark as incomplete
        
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
    // ✅ PASS THE LANGUAGE CODE FROM EVENT
    await _fetchAndEmitIndex(emit, forceRefresh: true, languageCode: event.languageCode);
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
