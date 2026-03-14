// lib/services/i_encounter_progress_service.dart

abstract class IEncounterProgressService {
  /// Storage key for completed encounter IDs in SharedPreferences
  static const String completedIdsKey = 'encounter_completed_ids';

  Future<Set<String>> loadCompletedIds();
  Future<void> markCompleted(String encounterId);
  Future<bool> isCompleted(String encounterId);
  Future<void> resetProgress(String encounterId);
}
