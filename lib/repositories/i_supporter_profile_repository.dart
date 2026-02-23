// lib/repositories/i_supporter_profile_repository.dart

/// Interface for persisting and retrieving supporter profile data.
///
/// Following the Dependency Inversion Principle, this allows callers
/// to depend on an abstraction, not a concrete implementation.
abstract class ISupporterProfileRepository {
  /// Load the stored profile display name (may be null).
  Future<String?> loadProfileName();

  /// Persist the profile display name.
  Future<void> saveProfileName(String name);
}
