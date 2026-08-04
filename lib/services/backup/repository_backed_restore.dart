/// Restores a raw backup list into a repository, one entry at a time.
///
/// Each entry is decoded and persisted independently so a single malformed
/// entry (partial write, manual edit, future format drift) is skipped and
/// logged instead of corrupting the whole restore or being silently dropped
/// by an unvalidated raw-prefs write.
///
/// Domain-agnostic on purpose: pass the repository's own decode/persist
/// functions so this stays the single place that owns "restore one entry,
/// isolate its failure" — other backup domains can adopt it later by
/// supplying their own [decode]/[persist], without duplicating this logic.
class RepositoryBackedRestore {
  /// Restores [rawList] via [decode] + [persist], skipping and logging any
  /// entry that fails to decode or persist. Returns the count restored.
  static Future<int> run<T>({
    required List<dynamic> rawList,
    required T Function(Map<String, dynamic> json) decode,
    required Future<void> Function(T item) persist,
    required void Function(String message) onEntryError,
  }) async {
    var restoredCount = 0;
    for (final raw in rawList) {
      try {
        // `raw as Map` intentionally accepts any Map subtype (e.g. the
        // LinkedHashMap<dynamic, dynamic> that json.decode produces) — the
        // cast below normalizes it to Map<String, dynamic> for [decode].
        // A non-Map entry throws here and is caught below like any other
        // malformed entry.
        final item = decode(Map<String, dynamic>.from(raw as Map));
        await persist(item);
        restoredCount++;
      } catch (e) {
        onEntryError('Skipping corrupt entry: $e');
      }
    }
    return restoredCount;
  }
}
