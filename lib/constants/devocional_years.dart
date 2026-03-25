/// Offline fallback for available devotional years.
///
/// **This constant is NOT the primary source of truth.**
/// At runtime, [DevocionalRepositoryImpl.getAvailableYears()] derives the year
/// list from `index.json` (the remote index).  This list is used **only** when
/// the index is unreachable (network offline, server error, parse failure).
///
/// When new years are added to the remote index, they are automatically
/// discovered.  Only update this list when you also need the app to load that
/// year while fully offline (e.g., before the first successful index fetch).
///
/// Example — adding 2027 offline support:
/// ```dart
/// static const availableYears = [2025, 2026, 2027];
/// ```
class DevocionalYears {
  /// Offline-fallback list of years for which devotionals are available.
  ///
  /// Keep this list in sync with the remote index so offline installs
  /// can still load all years.  Must remain sorted ascending.
  static const List<int> availableYears = [2025, 2026];

  /// Private constructor to prevent instantiation
  DevocionalYears._();
}
