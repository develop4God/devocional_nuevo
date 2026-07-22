/// Shared engagement thresholds used across independent features so a
/// change to one doesn't silently drift out of sync with the other.
class EngagementThresholds {
  /// Devotionals read at which a user is considered "engaged" — used both
  /// to gate the first-time app review prompt ([InAppReviewService]) and
  /// as the proxy for classifying pre-existing users during the
  /// onboarding backfill ([OnboardingService]).
  static const int engagedUserDevocionalThreshold = 5;
}
