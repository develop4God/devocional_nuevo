/// Constants for available devotional years
///
/// This class maintains the list of all years for which devotionals are available.
/// When new years are added, simply append to this list to make them accessible.
///
/// Example:
/// ```dart
/// // When 2027 devotionals are ready, update to:
/// static const availableYears = [2025, 2026, 2027];
/// ```
class DevocionalYears {
  /// List of all years for which devotionals are available
  ///
  /// This list should be updated when new years are added.
  /// All historical years remain accessible - no progressive data loss.
  static const List<int> availableYears = [2025, 2026];

  /// Private constructor to prevent instantiation
  DevocionalYears._();
}
