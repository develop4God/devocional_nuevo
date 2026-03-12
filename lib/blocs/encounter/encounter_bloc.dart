// lib/blocs/encounter/encounter_bloc.dart

import 'package:collection/collection.dart';
import 'package:devocional_nuevo/blocs/encounter/encounter_event.dart';
import 'package:devocional_nuevo/blocs/encounter/encounter_state.dart';
import 'package:devocional_nuevo/models/encounter_study.dart';
import 'package:devocional_nuevo/repositories/encounter_repository.dart';
import 'package:devocional_nuevo/services/i_encounter_progress_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class EncounterBloc extends Bloc<EncounterEvent, EncounterState> {
  final EncounterRepository repository;
  final IEncounterProgressService progressService;

  bool _disposed = false;

  EncounterBloc({
    required this.repository,
    required this.progressService,
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
    } catch (e) {
      debugPrint('❌ [EncounterBloc] Error loading index: $e');
      emit(EncounterError('Error loading encounters: $e'));
    }
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
