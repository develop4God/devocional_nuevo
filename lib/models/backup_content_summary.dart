// lib/models/backup_content_summary.dart
//
// Pure value object representing item counts in a backup payload.
// Single Responsibility: holds backup content statistics for display.
// Open/Closed: extend by adding fields; existing consumers use null-safe access.

import 'package:equatable/equatable.dart';

/// Immutable summary of item counts included in a backup file.
///
/// Each field maps to a [BackupKeys] category. A count of 0 means the
/// category is either empty or was not included in the backup.
class BackupContentSummary extends Equatable {
  /// Number of saved prayers (`backup.saved_prayers`).
  final int prayersCount;

  /// Number of saved thanksgivings (`thanksgiving.thanksgivings`).
  final int thanksgivingsCount;

  /// Number of testimonies (`testimony.testimonies`).
  final int testimoniesCount;

  /// Number of favourite devotionals (`backup.favorite_devotionals`).
  final int favoritesCount;

  /// Number of completed encounter entries (`encounters.section_title`).
  final int encountersCount;

  /// Number of discovery study progress entries (`discovery.discovery_studies`).
  final int discoveryCount;

  /// Number of marked Bible verses (`backup.saved_verses`).
  final int versesCount;

  /// Number of read devotional IDs (`backup.read_devotionals`).
  final int readDevocionalesCount;

  /// Number of answered prayers (derived from spiritual stats).
  final int answeredPrayersCount;

  const BackupContentSummary({
    required this.prayersCount,
    required this.thanksgivingsCount,
    required this.testimoniesCount,
    required this.favoritesCount,
    required this.encountersCount,
    required this.discoveryCount,
    required this.versesCount,
    this.readDevocionalesCount = 0,
    this.answeredPrayersCount = 0,
  });

  /// Returns `true` when every counter is zero (nothing in the backup).
  bool get isEmpty =>
      prayersCount == 0 &&
      thanksgivingsCount == 0 &&
      testimoniesCount == 0 &&
      favoritesCount == 0 &&
      encountersCount == 0 &&
      discoveryCount == 0 &&
      versesCount == 0 &&
      readDevocionalesCount == 0 &&
      answeredPrayersCount == 0;

  /// Total number of content items across all categories.
  int get totalItems =>
      prayersCount +
      thanksgivingsCount +
      testimoniesCount +
      favoritesCount +
      encountersCount +
      discoveryCount +
      versesCount +
      readDevocionalesCount +
      answeredPrayersCount;

  @override
  List<Object?> get props => [
        prayersCount,
        thanksgivingsCount,
        testimoniesCount,
        favoritesCount,
        encountersCount,
        discoveryCount,
        versesCount,
        readDevocionalesCount,
        answeredPrayersCount,
      ];
}
