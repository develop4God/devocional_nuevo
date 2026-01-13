// lib/blocs/discovery/discovery_bloc.dart

import 'package:devocional_nuevo/models/discovery_devotional_model.dart';
import 'package:devocional_nuevo/repositories/discovery_repository.dart';
import 'package:devocional_nuevo/services/discovery_progress_tracker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'discovery_event.dart';
import 'discovery_state.dart';

/// BLoC for managing Discovery studies.
///
/// Follows the pattern from prayer_bloc.dart with constructor injection
/// of repository and progress tracker.
class DiscoveryBloc extends Bloc<DiscoveryEvent, DiscoveryState> {
  final DiscoveryRepository repository;
  final DiscoveryProgressTracker progressTracker;

  DiscoveryBloc({
    required this.repository,
    required this.progressTracker,
  }) : super(DiscoveryInitial()) {
    on<LoadDiscoveryStudies>(_onLoadDiscoveryStudies);
    on<LoadDiscoveryStudy>(_onLoadDiscoveryStudy);
    on<MarkSectionCompleted>(_onMarkSectionCompleted);
    on<AnswerDiscoveryQuestion>(_onAnswerDiscoveryQuestion);
    on<CompleteDiscoveryStudy>(_onCompleteDiscoveryStudy);
    on<RefreshDiscoveryStudies>(_onRefreshDiscoveryStudies);
    on<ClearDiscoveryError>(_onClearDiscoveryError);
  }

  /// Handles loading all available Discovery studies
  Future<void> _onLoadDiscoveryStudies(
    LoadDiscoveryStudies event,
    Emitter<DiscoveryState> emit,
  ) async {
    emit(DiscoveryLoading());

    try {
      final studyIds = await repository.fetchAvailableStudies();
      // Fetch the index to get titles
      final index = await repository.fetchIndex();
      // Determine locale (default to 'es' if not available)
      String locale = 'es';
      try {
        // Try to get locale from context if possible
        // This is a workaround since BLoC doesn't have direct access to context
        // In production, pass locale as event or via repository/provider
        locale = WidgetsBinding.instance.platformDispatcher.locale.languageCode;
      } catch (_) {}
      // Build map of studyId -> localized title
      final Map<String, String> studyTitles = {};
      final studies = index['studies'] as List<dynamic>? ?? [];
      for (final s in studies) {
        final id = s['id'] as String?;
        final titles = s['titles'] as Map<String, dynamic>?;
        if (id != null && titles != null) {
          studyTitles[id] = titles[locale] ?? titles['es'] ?? id;
        }
      }
      emit(
        DiscoveryLoaded(
          availableStudyIds: studyIds,
          loadedStudies: {},
          studyTitles: studyTitles,
        ),
      );
    } catch (e) {
      debugPrint('Error loading Discovery studies: $e');
      emit(DiscoveryError('Error al cargar estudios Discovery: $e'));
    }
  }

  /// Handles loading a specific Discovery study
  Future<void> _onLoadDiscoveryStudy(
    LoadDiscoveryStudy event,
    Emitter<DiscoveryState> emit,
  ) async {
    final currentState = state;

    // Show loading state for this specific study
    emit(DiscoveryStudyLoading(event.studyId));

    try {
      // Default to Spanish if no language code provided
      final languageCode = event.languageCode ?? 'es';
      final study = await repository.fetchDiscoveryStudy(
        event.studyId,
        languageCode,
      );

      // Restore previous state if available, or create new loaded state
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
        // Create new loaded state if we don't have one
        emit(
          DiscoveryLoaded(
            availableStudyIds: [event.studyId],
            loadedStudies: {event.studyId: study},
            studyTitles: {}, // Fix: required argument
          ),
        );
      }
    } catch (e) {
      debugPrint('Error loading Discovery study ${event.studyId}: $e');

      // Restore previous state with error message
      if (currentState is DiscoveryLoaded) {
        emit(
          currentState.copyWith(
            errorMessage: 'Error al cargar estudio: $e',
          ),
        );
      } else {
        emit(DiscoveryError('Error al cargar estudio: $e'));
      }
    }
  }

  /// Handles marking a section as completed
  Future<void> _onMarkSectionCompleted(
    MarkSectionCompleted event,
    Emitter<DiscoveryState> emit,
  ) async {
    try {
      await progressTracker.markSectionCompleted(
        event.studyId,
        event.sectionIndex,
      );

      // Emit the same state to trigger UI refresh
      final currentState = state;
      if (currentState is DiscoveryLoaded) {
        emit(currentState.copyWith(
          clearError: true,
          lastUpdated: DateTime.now(),
        ));
      }
    } catch (e) {
      debugPrint('Error marking section completed: $e');
      final currentState = state;
      if (currentState is DiscoveryLoaded) {
        emit(
          currentState.copyWith(
            errorMessage: 'Error al marcar sección como completada: $e',
          ),
        );
      }
    }
  }

  /// Handles answering a discovery question
  Future<void> _onAnswerDiscoveryQuestion(
    AnswerDiscoveryQuestion event,
    Emitter<DiscoveryState> emit,
  ) async {
    try {
      await progressTracker.answerQuestion(
        event.studyId,
        event.questionIndex,
        event.answer,
      );

      // Emit the same state to trigger UI refresh
      final currentState = state;
      if (currentState is DiscoveryLoaded) {
        emit(currentState.copyWith(
          clearError: true,
          lastUpdated: DateTime.now(),
        ));
      }
    } catch (e) {
      debugPrint('Error saving answer: $e');
      final currentState = state;
      if (currentState is DiscoveryLoaded) {
        emit(
          currentState.copyWith(
            errorMessage: 'Error al guardar respuesta: $e',
          ),
        );
      }
    }
  }

  /// Handles completing a Discovery study
  Future<void> _onCompleteDiscoveryStudy(
    CompleteDiscoveryStudy event,
    Emitter<DiscoveryState> emit,
  ) async {
    try {
      await progressTracker.completeStudy(event.studyId);

      // Emit the same state to trigger UI refresh
      final currentState = state;
      if (currentState is DiscoveryLoaded) {
        emit(currentState.copyWith(
          clearError: true,
          lastUpdated: DateTime.now(),
        ));
      }
    } catch (e) {
      debugPrint('Error completing study: $e');
      final currentState = state;
      if (currentState is DiscoveryLoaded) {
        emit(
          currentState.copyWith(
            errorMessage: 'Error al completar estudio: $e',
          ),
        );
      }
    }
  }

  /// Handles refreshing Discovery studies
  Future<void> _onRefreshDiscoveryStudies(
    RefreshDiscoveryStudies event,
    Emitter<DiscoveryState> emit,
  ) async {
    try {
      final studyIds = await repository.fetchAvailableStudies();
      final currentState = state;

      if (currentState is DiscoveryLoaded) {
        emit(
          currentState.copyWith(
            availableStudyIds: studyIds,
            clearError: true,
          ),
        );
      } else {
        emit(
          DiscoveryLoaded(
            availableStudyIds: studyIds,
            loadedStudies: {},
            studyTitles: {}, // Fix: required argument
          ),
        );
      }
    } catch (e) {
      debugPrint('Error refreshing Discovery studies: $e');
    }
  }

  /// Handles clearing error messages
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
