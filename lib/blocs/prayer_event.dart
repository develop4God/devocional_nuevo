// lib/blocs/prayer_event.dart

abstract class PrayerEvent {}

/// Event to load all prayers from storage
class LoadPrayers extends PrayerEvent {}

/// Event to add a new prayer
class AddPrayer extends PrayerEvent {
  final String text;

  AddPrayer(this.text);
}

/// Event to edit an existing prayer
class EditPrayer extends PrayerEvent {
  final String prayerId;
  final String newText;

  EditPrayer(this.prayerId, this.newText);
}

/// Event to delete a prayer
class DeletePrayer extends PrayerEvent {
  final String prayerId;

  DeletePrayer(this.prayerId);
}

/// Event to mark a prayer as answered
class MarkPrayerAsAnswered extends PrayerEvent {
  final String prayerId;

  MarkPrayerAsAnswered(this.prayerId);
}

/// Event to mark a prayer as active (undo answered status)
class MarkPrayerAsActive extends PrayerEvent {
  final String prayerId;

  MarkPrayerAsActive(this.prayerId);
}

/// Event to refresh prayers from storage
class RefreshPrayers extends PrayerEvent {}

/// Event to clear error messages
class ClearPrayerError extends PrayerEvent {}
