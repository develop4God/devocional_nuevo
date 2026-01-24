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
  final Map<String, String> studySubtitles; // NEW: localized subtitle
  final Map<String, String> studyEmojis; // study ID to emoji
  final Map<String, int> studyReadingMinutes; // NEW: localized minutes
  final Map<String, bool> completedStudies; // study ID to completion status
  final Set<String> favoriteStudyIds; // NEW: Set of favorited study IDs
  final Set<String> downloadingStudyIds; // NEW: Track background downloads
  final String? errorMessage;
  final DateTime lastUpdated;
  final String languageCode; // NEW: Track current language

  DiscoveryLoaded({
    required this.availableStudyIds,
    required this.loadedStudies,
    required this.studyTitles,
    required this.studySubtitles,
    required this.studyEmojis,
    required this.studyReadingMinutes,
    required this.completedStudies,
    required this.favoriteStudyIds,
    this.downloadingStudyIds = const {},
    this.errorMessage,
    DateTime? lastUpdated,
    required this.languageCode,
  }) : lastUpdated = lastUpdated ?? DateTime.now();

  DiscoveryDevotional? getStudy(String studyId) => loadedStudies[studyId];
  bool isStudyLoaded(String studyId) => loadedStudies.containsKey(studyId);
  bool isStudyCompleted(String studyId) => completedStudies[studyId] ?? false;
  bool isStudyFavorite(String studyId) => favoriteStudyIds.contains(studyId);
  bool isStudyDownloading(String studyId) =>
      downloadingStudyIds.contains(studyId);

  int get availableStudiesCount => availableStudyIds.length;
  int get loadedStudiesCount => loadedStudies.length;

  DiscoveryLoaded copyWith({
    List<String>? availableStudyIds,
    Map<String, DiscoveryDevotional>? loadedStudies,
    Map<String, String>? studyTitles,
    Map<String, String>? studySubtitles,
    Map<String, String>? studyEmojis,
    Map<String, int>? studyReadingMinutes,
    Map<String, bool>? completedStudies,
    Set<String>? favoriteStudyIds,
    Set<String>? downloadingStudyIds,
    String? errorMessage,
    bool clearError = false,
    DateTime? lastUpdated,
    String? languageCode,
  }) {
    return DiscoveryLoaded(
      availableStudyIds: availableStudyIds ?? this.availableStudyIds,
      loadedStudies: loadedStudies ?? this.loadedStudies,
      studyTitles: studyTitles ?? this.studyTitles,
      studySubtitles: studySubtitles ?? this.studySubtitles,
      studyEmojis: studyEmojis ?? this.studyEmojis,
      studyReadingMinutes: studyReadingMinutes ?? this.studyReadingMinutes,
      completedStudies: completedStudies ?? this.completedStudies,
      favoriteStudyIds: favoriteStudyIds ?? this.favoriteStudyIds,
      downloadingStudyIds: downloadingStudyIds ?? this.downloadingStudyIds,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      lastUpdated: lastUpdated ?? DateTime.now(),
      languageCode: languageCode ?? this.languageCode,
    );
  }

  @override
  List<Object?> get props => [
        availableStudyIds,
        loadedStudies,
        studyTitles,
        studySubtitles,
        studyEmojis,
        studyReadingMinutes,
        completedStudies,
        favoriteStudyIds,
        downloadingStudyIds,
        errorMessage,
        lastUpdated,
        languageCode,
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
