// lib/blocs/prayer_wall/prayer_wall_event.dart

import 'package:devocional_nuevo/models/prayer_wall_entry.dart';

abstract class PrayerWallEvent {}

/// Load the approved prayers for the wall.
class LoadPrayerWall extends PrayerWallEvent {
  final String userLanguage;

  /// Optional: author hash used to subscribe to the author's own pending prayer.
  /// When provided, [PrayerWallBloc] calls [IPrayerWallRepository.watchMyPendingPrayer]
  /// so status changes (approved, pastoral) are reflected in real time.
  final String? authorHash;

  LoadPrayerWall({required this.userLanguage, this.authorHash});
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

/// Internal event: author's pending prayer changed on the server.
class PrayerWallPendingUpdated extends PrayerWallEvent {
  final PrayerWallEntry? entry;
  PrayerWallPendingUpdated(this.entry);
}
