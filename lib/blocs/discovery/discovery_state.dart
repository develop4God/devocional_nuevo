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
  final Map<String, String> studyTitles; // study ID to localized title
  final Map<String, String> studyEmojis; // study ID to emoji
  final Map<String, bool> completedStudies; // NEW: study ID to completion status
  final String? errorMessage;
  final DateTime lastUpdated;

  DiscoveryLoaded({
    required this.availableStudyIds,
    required this.loadedStudies,
    required this.studyTitles,
    required this.studyEmojis,
    required this.completedStudies, // NEW
    this.errorMessage,
    DateTime? lastUpdated,
  }) : lastUpdated = lastUpdated ?? DateTime.now();

  DiscoveryDevotional? getStudy(String studyId) => loadedStudies[studyId];
  bool isStudyLoaded(String studyId) => loadedStudies.containsKey(studyId);
  bool isStudyCompleted(String studyId) => completedStudies[studyId] ?? false; // NEW
  int get availableStudiesCount => availableStudyIds.length;
  int get loadedStudiesCount => loadedStudies.length;

  DiscoveryLoaded copyWith({
    List<String>? availableStudyIds,
    Map<String, DiscoveryDevotional>? loadedStudies,
    Map<String, String>? studyTitles,
    Map<String, String>? studyEmojis,
    Map<String, bool>? completedStudies, // NEW
    String? errorMessage,
    bool clearError = false,
    DateTime? lastUpdated,
  }) {
    return DiscoveryLoaded(
      availableStudyIds: availableStudyIds ?? this.availableStudyIds,
      loadedStudies: loadedStudies ?? this.loadedStudies,
      studyTitles: studyTitles ?? this.studyTitles,
      studyEmojis: studyEmojis ?? this.studyEmojis,
      completedStudies: completedStudies ?? this.completedStudies, // NEW
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      lastUpdated: lastUpdated ?? DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [
        availableStudyIds,
        loadedStudies,
        studyTitles,
        studyEmojis,
        completedStudies, // NEW
        errorMessage,
        lastUpdated
      ];
}

class DiscoveryStudyLoading extends DiscoveryState {
  final String studyId;
  DiscoveryStudyLoading(this.studyId);
}

class DiscoveryError extends DiscoveryState {
  final String message;
  DiscoveryError(this.message);
}
