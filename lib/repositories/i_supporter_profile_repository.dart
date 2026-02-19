// lib/repositories/i_supporter_profile_repository.dart
//
// Interface for Gold supporter display-name persistence.
// Extracted so that [SupporterBloc] depends on an abstraction (DIP),
// not on the concrete [SupporterProfileRepository].

/// Contract for persisting and loading the Gold supporter display name.
abstract class ISupporterProfileRepository {
  /// Returns the stored Gold supporter display name, or null if not set.
  Future<String?> loadGoldSupporterName();

  /// Persists the Gold supporter display name.
  Future<void> saveGoldSupporterName(String name);
}
