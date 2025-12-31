// lib/repositories/navigation_repository.dart

/// Abstract repository for managing navigation-related data persistence
abstract class NavigationRepository {
  /// Save the current devotional index
  Future<void> saveCurrentIndex(int index);

  /// Load the last saved devotional index
  /// Returns 0 if no saved index is found
  Future<int> loadCurrentIndex();
}
