// lib/services/i_spiritual_stats_service.dart
//
// Abstract interface for [SpiritualStatsService].
// Depend on this interface (not the concrete class) for
// Dependency Inversion and easy test mocking.

import '../models/spiritual_stats_model.dart';

/// Abstract interface defining spiritual statistics service capabilities.
abstract class ISpiritualStatsService {
  /// Get current spiritual statistics.
  Future<SpiritualStats> getStats();

  /// Save spiritual statistics.
  Future<void> saveStats(SpiritualStats stats);

  /// Record that a devotional was read.
  Future<SpiritualStats> recordDevocionalRead({
    required String devocionalId,
    int? favoritesCount,
    int readingTimeSeconds = 0,
    double scrollPercentage = 0.0,
  });

  /// Record that a devotional was heard (TTS).
  Future<SpiritualStats> recordDevocionalHeard({
    required String devocionalId,
    required double listenedPercentage,
    int? favoritesCount,
  });

  /// Record a full devotional completion event.
  Future<SpiritualStats> recordDevocionalCompletado({
    required String devocionalId,
    int readingTimeSeconds = 0,
    double scrollPercentage = 0.0,
    double listenedPercentage = 0.0,
    int? favoritesCount,
    String source = 'unknown',
  });

  /// Get all stats as a map for backup purposes.
  Future<Map<String, dynamic>> getAllStats();

  /// Restore stats from backup data.
  Future<void> restoreStats(Map<String, dynamic> backupData);

  /// Check if auto-backup is enabled.
  Future<bool> isAutoBackupEnabled();

  /// Enable/disable auto-backup.
  Future<void> setAutoBackupEnabled(bool enabled);

  /// Check if JSON backup is enabled.
  Future<bool> isJsonBackupEnabled();

  /// Enable/disable JSON backup.
  Future<void> setJsonBackupEnabled(bool enabled);

  /// Check if a devotional has been read.
  Future<bool> hasDevocionalBeenRead(String devocionalId);

  /// Get read dates for visualization.
  Future<List<DateTime>> getReadDatesForVisualization();

  /// Reset all stats.
  Future<void> resetStats();

  /// Export stats as JSON string.
  Future<String?> exportStatsAsJson();

  /// Import stats from JSON string.
  Future<bool> importStatsFromJson(String jsonString);

  /// Get backup file path.
  Future<String?> getBackupFilePath();

  /// Update favorites count.
  Future<SpiritualStats> updateFavoritesCount(int favoritesCount);

  /// Force creation of a manual backup.
  Future<bool> createManualBackup();
}
