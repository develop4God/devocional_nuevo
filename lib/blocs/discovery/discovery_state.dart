// lib/blocs/discovery/discovery_state.dart

import 'package:devocional_nuevo/models/discovery_devotional_model.dart';
import 'package:equatable/equatable.dart';

abstract class DiscoveryState {}

/// Initial state when the bloc is created
class DiscoveryInitial extends DiscoveryState {}

/// State when Discovery studies are being loaded
class DiscoveryLoading extends DiscoveryState {}

/// State when Discovery studies are successfully loaded
class DiscoveryLoaded extends DiscoveryState with EquatableMixin {
  final List<String> availableStudyIds;
  final Map<String, DiscoveryDevotional> loadedStudies;
  final Map<String, String> studyTitles; // New: study ID to localized title
  final String? errorMessage;
  final DateTime lastUpdated;

  DiscoveryLoaded({
    required this.availableStudyIds,
    required this.loadedStudies,
    required this.studyTitles, // New
    this.errorMessage,
    DateTime? lastUpdated,
  }) : lastUpdated = lastUpdated ?? DateTime.now();

  /// Get a specific study by ID
  DiscoveryDevotional? getStudy(String studyId) {
    return loadedStudies[studyId];
  }

  /// Check if a study is loaded
  bool isStudyLoaded(String studyId) {
    return loadedStudies.containsKey(studyId);
  }

  /// Get count of available studies
  int get availableStudiesCount => availableStudyIds.length;

  /// Get count of loaded studies
  int get loadedStudiesCount => loadedStudies.length;

  /// Create a copy of this state with updated values
  DiscoveryLoaded copyWith({
    List<String>? availableStudyIds,
    Map<String, DiscoveryDevotional>? loadedStudies,
    Map<String, String>? studyTitles, // New
    String? errorMessage,
    bool clearError = false,
    DateTime? lastUpdated,
  }) {
    return DiscoveryLoaded(
      availableStudyIds: availableStudyIds ?? this.availableStudyIds,
      loadedStudies: loadedStudies ?? this.loadedStudies,
      studyTitles: studyTitles ?? this.studyTitles,
      // New
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      lastUpdated: lastUpdated ?? DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [
        availableStudyIds,
        loadedStudies,
        studyTitles,
        errorMessage,
        lastUpdated
      ];
}

/// State when a specific study is being loaded
class DiscoveryStudyLoading extends DiscoveryState {
  final String studyId;

  DiscoveryStudyLoading(this.studyId);
}

/// State when there's an error with Discovery studies
class DiscoveryError extends DiscoveryState {
  final String message;

  DiscoveryError(this.message);
}
