// lib/blocs/prayer_wall/prayer_wall_event.dart

abstract class PrayerWallEvent {}

/// Load the approved prayers for the wall.
class LoadPrayerWall extends PrayerWallEvent {
  final String userLanguage;
  LoadPrayerWall({required this.userLanguage});
}

/// Submit a new prayer request.
class SubmitPrayer extends PrayerWallEvent {
  final String text;
  final String language;
  final bool isAnonymous;
  final String authorHash;

  SubmitPrayer({
    required this.text,
    required this.language,
    required this.isAnonymous,
    required this.authorHash,
  });
}

/// Tap the 🙏 pray hand on a prayer card.
class TapPrayerHand extends PrayerWallEvent {
  final String prayerId;
  TapPrayerHand({required this.prayerId});
}

/// Report an inappropriate prayer.
class ReportPrayer extends PrayerWallEvent {
  final String prayerId;
  ReportPrayer({required this.prayerId});
}

/// Delete the user's own prayer.
class DeletePrayer extends PrayerWallEvent {
  final String prayerId;
  final String authorHash;
  DeletePrayer({required this.prayerId, required this.authorHash});
}

/// Internal event: update the prayer list from a Firestore stream snapshot.
class PrayerWallStreamUpdated extends PrayerWallEvent {
  final List<dynamic> prayers;
  PrayerWallStreamUpdated(this.prayers);
}
