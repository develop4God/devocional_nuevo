// lib/blocs/testimony_event.dart

abstract class TestimonyEvent {}

/// Event to load all testimonies from storage
class LoadTestimonies extends TestimonyEvent {}

/// Event to add a new testimony
class AddTestimony extends TestimonyEvent {
  final String text;

  AddTestimony(this.text);
}

/// Event to edit an existing testimony
class EditTestimony extends TestimonyEvent {
  final String testimonyId;
  final String newText;

  EditTestimony(this.testimonyId, this.newText);
}

/// Event to delete a testimony
class DeleteTestimony extends TestimonyEvent {
  final String testimonyId;

  DeleteTestimony(this.testimonyId);
}

/// Event to refresh testimonies from storage
class RefreshTestimonies extends TestimonyEvent {}

/// Event to clear error messages
class ClearTestimonyError extends TestimonyEvent {}
