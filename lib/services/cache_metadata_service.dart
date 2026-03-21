// lib/services/cache_metadata_service.dart

import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';

/// Single responsibility: read/write sidecar `.meta.json` files that live
/// alongside the cached devotional JSON files.
///
/// Sidecar path = content file path with `.json` → `.meta.json`.
/// This automatically respects the es/RVR1960 backward-compat filename.
///
/// Sidecar schema:
/// ```json
/// {
///   "cached_at": "2026-03-03",
///   "manifest_date": "2026-03-03",
///   "schema_version": 1
/// }
/// ```
///
/// DI injected — NOT singleton.
class CacheMetadataService {
  static const int _schemaVersion = 1;

  /// Returns `manifest_date` string from the sidecar alongside
  /// [contentFilePath], or `null` if the sidecar is missing or unparseable.
  ///
  /// Never throws.
  Future<String?> readManifestDate(String contentFilePath) async {
    final sidecarPath = _sidecarPath(contentFilePath);
    final tag = _tag(contentFilePath);
    try {
      final file = File(sidecarPath);
      if (!await file.exists()) {
        developer.log(
          '⚠️ [SIDECAR] Not found: $tag — will re-fetch',
          name: 'CacheMetadata',
        );
        return null;
      }
      final content = await file.readAsString();
      final Map<String, dynamic> parsed =
          json.decode(content) as Map<String, dynamic>;
      final date = parsed['manifest_date'] as String?;
      developer.log(
        '🗂️ [SIDECAR] Read: $tag → manifest_date: $date',
        name: 'CacheMetadata',
      );
      return date;
    } catch (e) {
      developer.log(
        '⚠️ [SIDECAR] Not found: $tag — will re-fetch',
        name: 'CacheMetadata',
      );
      return null;
    }
  }

  /// Writes sidecar file alongside [contentFilePath].
  ///
  /// Silent failure — never throws — the JSON content is still usable without
  /// a sidecar.
  Future<void> writeMetadata(
    String contentFilePath,
    String manifestDate,
  ) async {
    final sidecarPath = _sidecarPath(contentFilePath);
    final tag = _tag(contentFilePath);
    try {
      final today = DateTime.now().toIso8601String().split('T').first;
      final Map<String, dynamic> meta = {
        'cached_at': today,
        'manifest_date': manifestDate,
        'schema_version': _schemaVersion,
      };
      await File(sidecarPath).writeAsString(json.encode(meta));
      developer.log(
        '📝 [SIDECAR] Written: $tag — manifest_date: $manifestDate',
        name: 'CacheMetadata',
      );
    } catch (e) {
      developer.log(
        '❌ [SIDECAR] Write failed: $tag — continuing safely',
        name: 'CacheMetadata',
      );
    }
  }

  /// Derives the sidecar path from the content file path.
  /// e.g. `.../devocional_2025_es.json` → `.../devocional_2025_es.meta.json`
  String _sidecarPath(String contentFilePath) {
    if (contentFilePath.endsWith('.json')) {
      return '${contentFilePath.substring(0, contentFilePath.length - 5)}.meta.json';
    }
    return '$contentFilePath.meta.json';
  }

  /// Short tag for log messages derived from file name.
  String _tag(String contentFilePath) {
    final name = contentFilePath.split('/').last;
    if (name.endsWith('.json')) {
      return name.substring(0, name.length - 5);
    }
    return name;
  }
}
