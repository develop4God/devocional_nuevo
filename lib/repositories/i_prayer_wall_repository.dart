// lib/repositories/i_prayer_wall_repository.dart

import 'package:devocional_nuevo/models/prayer_wall_entry.dart';

/// Abstract interface for the Prayer Wall data source.
///
/// Follows Interface Segregation and Dependency Inversion principles:
/// BLoC depends on this abstraction, never on the concrete Firestore implementation.
abstract class IPrayerWallRepository {
  /// Returns a stream of approved prayer entries ordered by language affinity.
  /// [userLanguage] is used to sort same-language prayers first.
  Stream<List<PrayerWallEntry>> watchApprovedPrayers({
    required String userLanguage,
  });

  /// Returns a stream for the current user's own pending prayer (if any).
  /// Shows the author their own prayer while it awaits moderation.
  Stream<PrayerWallEntry?> watchMyPendingPrayer({required String authorHash});

  /// Submits a new prayer to the wall.
  ///
  /// The prayer is stored with [status: pending]. PII masking and moderation
  /// are handled server-side by Cloud Functions.
  ///
  /// [originalText] is the raw user input — stored encrypted, never shown.
  /// [language] is the BCP-47 code for the author's current app language.
  /// [isAnonymous] controls whether any author identifier is shown.
  /// [authorHash] is a one-way hash of the Firebase UID (never raw UID).
  Future<String> submitPrayer({
    required String originalText,
    required String language,
    required bool isAnonymous,
    required String authorHash,
  });

  /// Increments the 🙏 pray count for a prayer (optimistic update supported).
  Future<void> tapPrayHand({required String prayerId});

  /// Reports a prayer. After 3 reports it moves to `needs_review` automatically.
  Future<void> reportPrayer({required String prayerId});

  /// Hard-deletes the user's own prayer from Firestore.
  Future<void> deletePrayer({
    required String prayerId,
    required String authorHash,
  });
}
