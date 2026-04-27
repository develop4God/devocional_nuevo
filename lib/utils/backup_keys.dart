// lib/utils/backup_keys.dart

/// Canonical keys for Google Drive backup payload.
/// Single source of truth for all backup/restore field names.
abstract class BackupKeys {
  // Existing fields
  static const String spiritualStats = 'spiritual_stats';
  static const String favoriteDevotionals = 'favorite_devotionals';
  static const String savedPrayers = 'saved_prayers';
  static const String savedThanksgivings = 'saved_thanksgivings';

  // New fields
  static const String completedEncounters = 'completed_encounters';
  static const String discoveryProgress = 'discovery_progress';
  static const String discoveryFavorites = 'discovery_favorites';
  static const String testimonies = 'testimonies';
}
