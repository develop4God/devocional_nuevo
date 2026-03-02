// lib/blocs/encounter/encounter_event.dart

abstract class EncounterEvent {}

/// Load the encounters index.json
class LoadEncounterIndex extends EncounterEvent {
  final String? languageCode;
  LoadEncounterIndex({this.languageCode});
}

/// Load a specific encounter study by ID and language
class LoadEncounterStudy extends EncounterEvent {
  final String id;
  final String lang;
  LoadEncounterStudy(this.id, this.lang);
}

/// Mark an encounter as completed
class CompleteEncounter extends EncounterEvent {
  final String id;
  CompleteEncounter(this.id);
}
