// lib/blocs/discovery/discovery_event.dart

abstract class DiscoveryEvent {}

/// Event to load all available Discovery studies
class LoadDiscoveryStudies extends DiscoveryEvent {
  final String? languageCode;

  LoadDiscoveryStudies({this.languageCode});
}

/// Event to load a specific Discovery study by ID
class LoadDiscoveryStudy extends DiscoveryEvent {
  final String studyId;
  final String? languageCode;

  LoadDiscoveryStudy(this.studyId, {this.languageCode});
}

/// Event to mark a section as completed
class MarkSectionCompleted extends DiscoveryEvent {
  final String studyId;
  final int sectionIndex;

  MarkSectionCompleted(this.studyId, this.sectionIndex);
}

/// Event to answer a discovery question
class AnswerDiscoveryQuestion extends DiscoveryEvent {
  final String studyId;
  final int questionIndex;
  final String answer;

  AnswerDiscoveryQuestion(this.studyId, this.questionIndex, this.answer);
}

/// Event to complete a study
class CompleteDiscoveryStudy extends DiscoveryEvent {
  final String studyId;

  CompleteDiscoveryStudy(this.studyId);
}

/// Event to toggle favorite status for a study
class ToggleDiscoveryFavorite extends DiscoveryEvent {
  final String studyId;

  ToggleDiscoveryFavorite(this.studyId);
}

/// Event to reset a study progress (do it again)
class ResetDiscoveryStudy extends DiscoveryEvent {
  final String studyId;

  ResetDiscoveryStudy(this.studyId);
}

/// Event to refresh Discovery studies
class RefreshDiscoveryStudies extends DiscoveryEvent {
  final String? languageCode;

  RefreshDiscoveryStudies({this.languageCode});
}

/// Event to clear error messages
class ClearDiscoveryError extends DiscoveryEvent {}
