// lib/blocs/prayer_wall/prayer_wall_state.dart

import 'package:devocional_nuevo/models/prayer_wall_entry.dart';

abstract class PrayerWallState {}

/// Initial state before any load has been requested.
class PrayerWallInitial extends PrayerWallState {}

/// Prayers are being fetched for the first time.
class PrayerWallLoading extends PrayerWallState {}

/// Prayers loaded successfully.
class PrayerWallLoaded extends PrayerWallState {
  /// Same-language prayers (Section 1 — prominent display).
  final List<PrayerWallEntry> sameLanguagePrayers;

  /// Cross-language prayers (Section 2 — compact display with flag).
  final List<PrayerWallEntry> otherLanguagePrayers;

  /// The current user's pending prayer (shown only to the author, awaiting moderation).
  final PrayerWallEntry? myPendingPrayer;

  final String? errorMessage;

  PrayerWallLoaded({
    required this.sameLanguagePrayers,
    required this.otherLanguagePrayers,
    this.myPendingPrayer,
    this.errorMessage,
  });

  PrayerWallLoaded copyWith({
    List<PrayerWallEntry>? sameLanguagePrayers,
    List<PrayerWallEntry>? otherLanguagePrayers,
    PrayerWallEntry? myPendingPrayer,
    String? errorMessage,
    bool clearError = false,
    bool clearPending = false,
  }) {
    return PrayerWallLoaded(
      sameLanguagePrayers: sameLanguagePrayers ?? this.sameLanguagePrayers,
      otherLanguagePrayers: otherLanguagePrayers ?? this.otherLanguagePrayers,
      myPendingPrayer:
          clearPending ? null : (myPendingPrayer ?? this.myPendingPrayer),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

/// An error occurred while loading or operating on the wall.
class PrayerWallError extends PrayerWallState {
  final String message;
  PrayerWallError(this.message);
}

/// A prayer submission is in progress.
class PrayerSubmitting extends PrayerWallState {}

/// A prayer was submitted successfully (status: pending).
class PrayerSubmitted extends PrayerWallState {
  final String prayerId;
  PrayerSubmitted({required this.prayerId});
}

/// The submitted prayer was flagged for pastoral support (self-harm).
/// UI should show [PastoralSupportSheet] — never tell the user they were flagged.
class PastoralResponseTriggered extends PrayerWallState {}
