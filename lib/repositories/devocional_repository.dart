// lib/repositories/devocional_repository.dart

import 'package:devocional_nuevo/models/devocional_model.dart';

/// Abstract repository for managing devotional data access.
///
/// Extracted from DevocionalProvider following the EncounterRepository pattern.
abstract class DevocionalRepository {
  // ── EXISTING ─────────────────────────────────────────────────────────────

  /// Find the index of the first unread devotional.
  /// Returns 0 if all devotionals are read or list is empty.
  int findFirstUnreadDevocionalIndex(
    List<Devocional> devocionales,
    List<String> readDevocionalIds,
  );

  // ── DATA LOADING ─────────────────────────────────────────────────────────

  /// Fetches devotionals for one [year]/[language]/[version] combination.
  ///
  /// Handles cache freshness, API fetch, and local fallback internally.
  /// Returns empty list on total failure (no API, no cache).
  Future<List<Devocional>> fetchAll(int year, String language, String version);

  /// Filters [devocionales] to only those matching [version].
  ///
  /// Returns all when [version] is empty. Pure function — no side effects.
  List<Devocional> filterByVersion(
    List<Devocional> devocionales,
    String version,
  );

  // ── LOCAL STORAGE ─────────────────────────────────────────────────────────

  /// Returns true when a local cache file exists for [year]/[language]/[version].
  Future<bool> hasLocalData(int year, String language, String version);

  /// Downloads and stores devotionals for [year]/[language]/[version].
  ///
  /// Returns true on success, false on any failure. No UI state side effects.
  Future<bool> downloadAndStoreDevocionales(
    int year,
    String language,
    String version,
  );

  /// Deletes all cached devotional files from local storage.
  Future<void> clearOldFiles();

  // ── CACHE CONTROL ─────────────────────────────────────────────────────────

  /// True when the last index fetch failed (offline or server unreachable).
  bool get wasLastFetchOffline;

  // ── DOWNLOAD ORCHESTRATION ────────────────────────────────────────────────

  /// Downloads devotionals for all available years in [language]/[version].
  ///
  /// Tries version fallback if primary download fails for a year.
  /// Returns true when all years succeeded.
  Future<bool> downloadCurrentYearDevocionales(
    String language,
    String version,
  );

  /// Returns true when a local cache file exists for the current year.
  Future<bool> hasCurrentYearLocalData(String language, String version);

  /// Returns true when local cache files exist for all available years.
  Future<bool> hasTargetYearsLocalData(String language, String version);

  /// Returns all years for which devotionals are available.
  ///
  /// Derived from the remote index when online; falls back to the static
  /// [DevocionalYears.availableYears] constant when the index is unreachable
  /// or returns no years.  Always returns at least one year.
  Future<List<int>> getAvailableYears();
}
