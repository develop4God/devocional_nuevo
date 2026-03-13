// lib/blocs/encounter/encounter_state.dart

import 'package:devocional_nuevo/models/encounter_index_entry.dart';
import 'package:devocional_nuevo/models/encounter_study.dart';
import 'package:equatable/equatable.dart';

abstract class EncounterState {}

/// Initial state when the bloc is created
class EncounterInitial extends EncounterState {}

/// State while the index or a study is loading
class EncounterLoading extends EncounterState {}

/// State when the index is successfully loaded
class EncounterLoaded extends EncounterState with EquatableMixin {
  final List<EncounterIndexEntry> index;
  final Map<String, EncounterStudy> loadedStudies;
  final Set<String> completedIds;
  final String? errorMessage;
  final DateTime lastUpdated;

  EncounterLoaded({
    required this.index,
    this.loadedStudies = const {},
    this.completedIds = const {},
    this.errorMessage,
    DateTime? lastUpdated,
  }) : lastUpdated = lastUpdated ?? DateTime.now();

  EncounterStudy? getStudy(String id) => loadedStudies[id];
  bool isStudyLoaded(String id) => loadedStudies.containsKey(id);
  bool isCompleted(String id) => completedIds.contains(id);

  /// Returns true if the encounter with [encounterId] is unlocked.
  ///
  /// Rules:
  /// - The first published encounter is always unlocked.
  /// - Every subsequent published encounter is unlocked only when the
  ///   immediately preceding published encounter is completed.
  /// - Non-published (coming_soon) encounters are treated as unlocked
  ///   (their own overlay handles the "not tappable" state).
  bool isUnlocked(String encounterId) {
    final published = index.where((e) => e.status == 'published').toList();
    final position = published.indexWhere((e) => e.id == encounterId);
    if (position <= 0) return true; // first or not in published list
    final previous = published[position - 1];
    return completedIds.contains(previous.id);
  }

  EncounterLoaded copyWith({
    List<EncounterIndexEntry>? index,
    Map<String, EncounterStudy>? loadedStudies,
    Set<String>? completedIds,
    String? errorMessage,
    bool clearError = false,
    DateTime? lastUpdated,
  }) {
    return EncounterLoaded(
      index: index ?? this.index,
      loadedStudies: loadedStudies ?? this.loadedStudies,
      completedIds: completedIds ?? this.completedIds,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      lastUpdated: lastUpdated ?? DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [index, loadedStudies, completedIds, errorMessage];
}

/// State when an error occurs
class EncounterError extends EncounterState {
  final String message;
  EncounterError(this.message);
}
