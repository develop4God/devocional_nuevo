// lib/blocs/thanksgiving_event.dart

abstract class ThanksgivingEvent {}

/// Event to load all thanksgivings from storage
class LoadThanksgivings extends ThanksgivingEvent {}

/// Event to add a new thanksgiving
class AddThanksgiving extends ThanksgivingEvent {
  final String text;

  AddThanksgiving(this.text);
}

/// Event to edit an existing thanksgiving
class EditThanksgiving extends ThanksgivingEvent {
  final String thanksgivingId;
  final String newText;

  EditThanksgiving(this.thanksgivingId, this.newText);
}

/// Event to delete a thanksgiving
class DeleteThanksgiving extends ThanksgivingEvent {
  final String thanksgivingId;

  DeleteThanksgiving(this.thanksgivingId);
}

/// Event to refresh thanksgivings from storage
class RefreshThanksgivings extends ThanksgivingEvent {}

/// Event to clear error messages
class ClearThanksgivingError extends ThanksgivingEvent {}
