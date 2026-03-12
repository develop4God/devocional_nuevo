// lib/services/i_encounter_progress_service.dart

abstract class IEncounterProgressService {
  Future<Set<String>> loadCompletedIds();
  Future<void> markCompleted(String encounterId);
  Future<bool> isCompleted(String encounterId);
  Future<void> resetProgress(String encounterId);
  Future<void> clearAll();
}
