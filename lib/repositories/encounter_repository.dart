// lib/repositories/encounter_repository.dart

import 'dart:convert';
import 'dart:developer' as developer;

import 'package:devocional_nuevo/models/encounter_index_entry.dart';
import 'package:devocional_nuevo/models/encounter_study.dart';
import 'package:devocional_nuevo/utils/constants/constants.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Repository for fetching Encounters content from remote JSON via GitHub Pages.
///
/// Strategy: Network-first with fallback to SharedPreferences cache.
class EncounterRepository {
  final http.Client httpClient;

  static const String _indexCacheKey = 'encounter_index_cache';
  static const String _studyCacheKeyPrefix = 'encounter_cache_';
  static const String _studyVersionSuffix = '_version'; // NEW

  /// Fetched at most once per app session — reset on every cold start.
  static bool _indexFetchedThisSession = false; // NEW

  static const Duration _networkTimeout = Duration(seconds: 10);

  EncounterRepository({required this.httpClient});

  // ---------------------------------------------------------------------------
  // Index
  // ---------------------------------------------------------------------------

  /// Fetches the encounter index. Cache-first within session → network → SharedPreferences cache.
  Future<List<EncounterIndexEntry>> fetchIndex({
    bool forceRefresh = false,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    // ── Cache-First: serve from cache within the same app session ──
    if (!forceRefresh && _indexFetchedThisSession) {
      final cachedIndex = prefs.getString(_indexCacheKey);
      if (cachedIndex != null) {
        final entries =
            _parseIndex(jsonDecode(cachedIndex) as Map<String, dynamic>);
        debugPrint(
            '✅ Encounter: Index cache hit (same session, skipping network)');
        debugPrint('📚 Encounter: Cached index has ${entries.length} entries');
        return entries;
      }
    }

    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final url = Constants.getEncounterIndexUrl();
      final cacheBusterUrl = '$url?cb=$timestamp';

      debugPrint(
          '🌐 Encounter: Fetching index — session flag was ${_indexFetchedThisSession ? "true but no cache" : "false"}');
      debugPrint('📍 Encounter: URL = $cacheBusterUrl');
      final response = await httpClient
          .get(Uri.parse(cacheBusterUrl))
          .timeout(_networkTimeout);

      debugPrint(
          '📡 Encounter: Index response status = ${response.statusCode}');

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final entries = _parseIndex(json);
        await prefs.setString(_indexCacheKey, response.body);
        _indexFetchedThisSession = true; // NEW
        debugPrint('💾 Encounter: Index cached — ${entries.length} entries');
        return entries;
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('⚠️ Encounter: Network error fetching index: $e');

      if (!Constants.enableEncounterFallback) {
        debugPrint('🚫 Encounter: Fallback disabled — rethrowing error');
        rethrow;
      }

      // Try SharedPreferences cache
      final cached = prefs.getString(_indexCacheKey);
      if (cached != null) {
        try {
          final entries =
              _parseIndex(jsonDecode(cached) as Map<String, dynamic>);
          debugPrint(
              '📦 Encounter: Using cached index after network failure — ${entries.length} entries');
          return entries;
        } catch (_) {
          debugPrint(
              '💥 Encounter: Cached index corrupt — no fallback available');
        }
      }

      rethrow;
    }
  }

  List<EncounterIndexEntry> _parseIndex(Map<String, dynamic> json) {
    final entries = json['encounters'] ?? json['studies'] ?? json['entries'];
    if (entries is List) {
      return entries
          .whereType<Map<String, dynamic>>()
          .map(EncounterIndexEntry.fromJson)
          .toList();
    }
    return [];
  }

  // ---------------------------------------------------------------------------
  // Study
  // ---------------------------------------------------------------------------

  /// Fetches an individual encounter study. Checks cache first, then network.
  ///
  /// [filename] — the exact filename from the index `files` map
  ///   (e.g. `peter_water_001_es.json`). Preferred over constructing it from [id].
  /// [entry] — index entry carrying the expected version.
  /// Callers that have the index in state should always pass this.
  /// When null, cache is served without version validation (legacy safe path).
  Future<EncounterStudy> fetchStudy(
    String id,
    String lang, {
    String? filename,
    EncounterIndexEntry? entry, // NEW — version signal
  }) async {
    // 1. Check SharedPreferences cache (skipped when fallback is disabled)
    if (Constants.enableEncounterFallback) {
      final cached = await _loadStudyFromCache(
          id, lang, entry?.version, entry?.imageVersion);
      if (cached != null) return cached;
    }

    // 2. Fetch from network (non-recursive — try lang, then 'en' directly)
    try {
      final study = await _fetchStudyFromNetwork(
        id,
        lang,
        filename: filename,
        version: entry?.version, // NEW — passed to save
        imageVersion:
            entry?.imageVersion, // NEW — for EncounterCard image cache
      );
      return study;
    } catch (e) {
      debugPrint('❌ Encounter: Error fetching study $id ($lang): $e');
      rethrow;
    }
  }

  /// Non-recursive network fetch: tries [lang], then 'en' if different.
  ///
  /// [filename] — when provided, used directly; otherwise falls back to
  ///   the `{id}_{lang}.json` convention.
  /// [version] — passed from fetchStudy via entry, saved to cache.
  Future<EncounterStudy> _fetchStudyFromNetwork(
    String id,
    String lang, {
    String? filename,
    String? version, // NEW — passed from fetchStudy, used for cache staleness
    String?
        imageVersion, // NEW — passed from entry.imageVersion for card image cache
  }) async {
    final url = Constants.getEncounterStudyUrl(id, lang, filename: filename);
    debugPrint('🌐 Encounter: Fetching study $id ($lang) from $url');
    final response =
        await httpClient.get(Uri.parse(url)).timeout(_networkTimeout);

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final study = EncounterStudy.fromJson(json, imageVersion: imageVersion);
      await _saveStudyToCache(id, lang, response.body, version); // NEW
      return study;
    }

    // Try English fallback once (no recursion)
    if (lang != 'en') {
      debugPrint(
          '⚠️ Encounter: $lang not found for $id, trying English fallback');
      // Derive the English filename by replacing the lang segment.
      // Handles both peter_water_es_001.json → peter_water_en_001.json
      // and the legacy {id}_{lang}.json → {id}_en.json patterns.
      String? enFilename;
      if (filename != null) {
        enFilename = filename.contains('_${lang}_')
            ? filename.replaceFirst('_${lang}_', '_en_')
            : filename.replaceAll('_$lang.json', '_en.json');
      }
      final enUrl =
          Constants.getEncounterStudyUrl(id, 'en', filename: enFilename);
      final enResponse =
          await httpClient.get(Uri.parse(enUrl)).timeout(_networkTimeout);
      if (enResponse.statusCode == 200) {
        final json = jsonDecode(enResponse.body) as Map<String, dynamic>;
        final study = EncounterStudy.fromJson(json, imageVersion: imageVersion);
        await _saveStudyToCache(id, 'en', enResponse.body, version); // NEW
        return study;
      }
    }

    throw Exception(
        'Failed to load encounter study $id: ${response.statusCode}');
  }

  Future<EncounterStudy?> _loadStudyFromCache(
    String id,
    String lang, [
    String? expectedVersion,
    String?
        imageVersion, // NEW — driven by entry.imageVersion, not content version
  ]) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final contentKey = '$_studyCacheKeyPrefix${id}_$lang';
      final cached = prefs.getString(contentKey);

      if (cached == null) {
        debugPrint(
            '📭 Encounter: No cache for $id ($lang) — first install or cleared');
        return null;
      }

      // Version check — only when expectedVersion is provided
      if (expectedVersion != null) {
        final cachedVersion =
            prefs.getString('$contentKey$_studyVersionSuffix');
        if (cachedVersion != expectedVersion) {
          debugPrint(
            '🔄 Encounter: Stale cache for $id ($lang) '
            '— cached: $cachedVersion, expected: $expectedVersion',
          );
          return null; // stale → trigger network re-fetch
        }
      }

      debugPrint('✅ Encounter: Cache hit $id ($lang) v$expectedVersion');
      return EncounterStudy.fromJson(
        jsonDecode(cached) as Map<String, dynamic>,
        imageVersion:
            imageVersion, // keyed on image_version, not content version
      );
    } catch (e) {
      developer.log('Failed to load encounter study from cache: $e',
          name: 'EncounterRepository._loadStudyFromCache');
    }
    return null;
  }

  Future<void> _saveStudyToCache(
    String id,
    String lang,
    String body, [
    String? version,
  ]) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final contentKey = '$_studyCacheKeyPrefix${id}_$lang';
      await prefs.setString(contentKey, body);
      if (version != null) {
        await prefs.setString('$contentKey$_studyVersionSuffix', version);
      }
      debugPrint('💾 Encounter: Saved $id ($lang) v$version to cache');
    } catch (e) {
      developer.log('Failed to save encounter study to cache: $e',
          name: 'EncounterRepository._saveStudyToCache');
    }
  }
}
