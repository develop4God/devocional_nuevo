// lib/services/encounter_progress_service.dart
//
// Persists completed encounter IDs to SharedPreferences,
// mirroring the pattern used by DiscoveryProgressTracker.

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service to persist completed encounter study IDs.
class EncounterProgressService {
  static const String _completedKey = 'encounter_completed_ids';

  /// Returns the full set of completed encounter IDs.
  Future<Set<String>> loadCompletedIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_completedKey) ?? [];
      debugPrint(
          '✅ [EncounterProgress] Loaded ${list.length} completed encounter(s)');
      return list.toSet();
    } catch (e) {
      debugPrint('❌ [EncounterProgress] Error loading completed IDs: $e');
      return {};
    }
  }

  /// Marks an encounter as completed and persists the updated set.
  Future<void> markCompleted(String encounterId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existing = (prefs.getStringList(_completedKey) ?? []).toSet();
      if (existing.contains(encounterId)) return; // already saved
      existing.add(encounterId);
      await prefs.setStringList(_completedKey, existing.toList());
      debugPrint(
          '✅ [EncounterProgress] Encounter marked as completed: $encounterId');
    } catch (e) {
      debugPrint('❌ [EncounterProgress] Error saving completion: $e');
    }
  }

  /// Returns true if the given encounter ID is completed.
  Future<bool> isCompleted(String encounterId) async {
    final ids = await loadCompletedIds();
    return ids.contains(encounterId);
  }

  /// Resets progress for a specific encounter (removes from persisted set).
  Future<void> resetProgress(String encounterId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existing = (prefs.getStringList(_completedKey) ?? []).toSet();
      existing.remove(encounterId);
      await prefs.setStringList(_completedKey, existing.toList());
      debugPrint(
          '♻️ [EncounterProgress] Progress reset for encounter: $encounterId');
    } catch (e) {
      debugPrint('❌ [EncounterProgress] Error resetting progress: $e');
    }
  }

  /// Clears all persisted completion data (useful for testing/reset).
  Future<void> clearAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_completedKey);
      debugPrint('♻️ [EncounterProgress] All encounter progress cleared');
    } catch (e) {
      debugPrint('❌ [EncounterProgress] Error clearing all progress: $e');
    }
  }
}
