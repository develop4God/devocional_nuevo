// lib/services/i_user_recency_service.dart
//
// Abstract interface for [UserRecencyService].
// Depend on this interface (not the concrete class) for
// Dependency Inversion and easy test mocking.

/// Abstract interface for classifying a user as new or existing, so
/// features that must behave differently for each (e.g. onboarding,
/// one-time migration notices) share a single source of truth instead of
/// each re-deriving the classification independently.
abstract class IUserRecencyService {
  /// True if this device has no meaningful engagement history yet (i.e.
  /// should be treated as a fresh install), false if it already has
  /// enough reading history to be considered an existing user.
  Future<bool> isNewUser();
}
