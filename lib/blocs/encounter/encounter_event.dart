// lib/blocs/encounter/encounter_event.dart

abstract class EncounterEvent {}

/// Load the encounters index.json
class LoadEncounterIndex extends EncounterEvent {
  final String? languageCode;
  final bool forceRefresh;

  LoadEncounterIndex({this.languageCode, this.forceRefresh = false});
}

/// Load a specific encounter study by ID and language
class LoadEncounterStudy extends EncounterEvent {
  final String id;
  final String lang;

  /// Optional: resolved filename from the index entry's [files] map.
  /// When provided, used directly in the URL so the real GitHub filename
  /// (e.g. peter_water_001_es.json) is used instead of deriving it from [id].
  final String? filename;

  LoadEncounterStudy(this.id, this.lang, {this.filename});
}

/// Mark an encounter as completed
class CompleteEncounter extends EncounterEvent {
  final String id;

  CompleteEncounter(this.id);
}
