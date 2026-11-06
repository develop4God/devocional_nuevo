/// Result of a forced refresh of the remote Bible versions index.
class BibleIndexRefreshResult {
  /// Version names listed in the index (bundled ones included), by language.
  final Map<String, List<String>> versionsByLanguage;

  /// True when the network fetch failed and the cached index was used.
  final bool servedFromCache;

  const BibleIndexRefreshResult({
    required this.versionsByLanguage,
    required this.servedFromCache,
  });
}

/// Debug-only controls over the remote Bible versions index. Kept apart from
/// `IBibleVersionRepository` so production consumers never see them.
abstract class IBibleIndexDebugControls {
  /// Re-fetches the index of the selected debug branch unconditionally (the
  /// cached ETag is dropped so a 304 cannot hide changes). The cached body
  /// is kept as the offline fallback, reported via
  /// [BibleIndexRefreshResult.servedFromCache].
  Future<BibleIndexRefreshResult> refreshIndex();
}
