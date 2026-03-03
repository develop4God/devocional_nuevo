// lib/repositories/encounter_repository.dart

import 'dart:convert';
import 'dart:developer' as developer;

import 'package:devocional_nuevo/models/encounter_index_entry.dart';
import 'package:devocional_nuevo/models/encounter_study.dart';
import 'package:devocional_nuevo/utils/constants.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Repository for fetching Encounters content from remote JSON via GitHub Pages.
///
/// Strategy: Network-first with fallback to SharedPreferences cache.
/// On complete failure for the index, falls back to the bundled asset.
class EncounterRepository {
  final http.Client httpClient;

  static const String _indexCacheKey = 'encounter_index_cache';
  static const String _studyCacheKeyPrefix = 'encounter_cache_';

  /// Bundled fallback assets for peter_water_001, keyed by language code.
  /// Files live at assets/encounters/peter_water_{lang}_001.json.
  static const Map<String, String> _fallbackAssets = {
    'es': 'assets/encounters/peter_water_es_001.json',
    'en': 'assets/encounters/peter_water_en_001.json',
    'pt': 'assets/encounters/peter_water_pt_001.json',
    'fr': 'assets/encounters/peter_water_fr_001.json',
    'zh': 'assets/encounters/peter_water_zh_001.json',
    'hi': 'assets/encounters/peter_water_hi_001.json',
    'ja': 'assets/encounters/peter_water_ja_001.json',
  };

  static const Duration _networkTimeout = Duration(seconds: 10);

  EncounterRepository({required this.httpClient});

  // ---------------------------------------------------------------------------
  // Index
  // ---------------------------------------------------------------------------

  /// Fetches the encounter index. Network-first → cache → fallback asset.
  Future<List<EncounterIndexEntry>> fetchIndex({
    bool forceRefresh = false,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final url = Constants.getEncounterIndexUrl();
      final cacheBusterUrl = '$url?cb=$timestamp';

      debugPrint('🌐 Encounter: Fetching index from $cacheBusterUrl');
      final response = await httpClient
          .get(Uri.parse(cacheBusterUrl))
          .timeout(_networkTimeout);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        await prefs.setString(_indexCacheKey, response.body);
        return _parseIndex(json);
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
          final json = jsonDecode(cached) as Map<String, dynamic>;
          debugPrint('📦 Encounter: Using cached index');
          return _parseIndex(json);
        } catch (_) {
          // Cache is corrupt — fall through to asset
        }
      }

      // Fall back to bundled asset
      debugPrint('📂 Encounter: Falling back to bundled asset');
      return _loadFallbackAsIndex();
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

  /// Loads the fallback asset as a single-entry index.
  Future<List<EncounterIndexEntry>> _loadFallbackAsIndex() async {
    try {
      // Build bilingual entry directly from known fallback content
      return [
        EncounterIndexEntry(
          id: 'peter_water_001',
          version: '1.0',
          emoji: '🌊',
          status: 'published',
          moodPrimary: 'storm',
          accentColor: '#1e3a5f',
          testament: 'new',
          character: 'Peter',
          files: const {
            'en': 'peter_water_en_001.json',
            'es': 'peter_water_es_001.json',
            'pt': 'peter_water_pt_001.json',
            'fr': 'peter_water_fr_001.json',
            'zh': 'peter_water_zh_001.json',
            'hi': 'peter_water_hi_001.json',
            'ja': 'peter_water_ja_001.json',
          },
          titles: const {
            'en': 'Peter Walks on Water',
            'es': 'Pedro Camina sobre el Agua',
          },
          subtitles: const {
            'en': 'Faith Beyond the Storm',
            'es': 'Fe Más Allá de la Tormenta',
          },
          scriptureReference: const {
            'en': 'Matthew 14:22-33',
            'es': 'Mateo 14:22-33',
          },
          estimatedReadingMinutes: const {'en': 8, 'es': 8},
        ),
      ];
    } catch (e) {
      developer.log('Failed to build fallback encounter index: $e',
          name: 'EncounterRepository._loadFallbackAsIndex');
      return [];
    }
  }

  // ---------------------------------------------------------------------------
  // Study
  // ---------------------------------------------------------------------------

  /// Fetches an individual encounter study. Checks cache first, then network.
  /// Falls back to the bundled fallback asset for 'peter_water_001'.
  ///
  /// [filename] — the exact filename from the index `files` map
  ///   (e.g. `peter_water_001_es.json`). Preferred over constructing it from [id].
  Future<EncounterStudy> fetchStudy(String id, String lang,
      {String? filename}) async {
    // 1. Check SharedPreferences cache (skipped when fallback is disabled)
    if (Constants.enableEncounterFallback) {
      final cached = await _loadStudyFromCache(id, lang);
      if (cached != null) {
        debugPrint('✅ Encounter: Cache hit for $id ($lang)');
        return cached;
      }
    }

    // 2. Fetch from network (non-recursive — try lang, then 'en' directly)
    try {
      final study = await _fetchStudyFromNetwork(id, lang, filename: filename);
      return study;
    } catch (e) {
      debugPrint('❌ Encounter: Error fetching study $id ($lang): $e');
      // Fallback to bundled asset only when fallback is enabled
      if (Constants.enableEncounterFallback && id == 'peter_water_001') {
        return _loadFallbackStudy(lang);
      }
      rethrow;
    }
  }

  /// Non-recursive network fetch: tries [lang], then 'en' if different.
  ///
  /// [filename] — when provided, used directly; otherwise falls back to
  ///   the `{id}_{lang}.json` convention.
  Future<EncounterStudy> _fetchStudyFromNetwork(String id, String lang,
      {String? filename}) async {
    final url = Constants.getEncounterStudyUrl(id, lang, filename: filename);
    debugPrint('🌐 Encounter: Fetching study $id ($lang) from $url');
    final response =
        await httpClient.get(Uri.parse(url)).timeout(_networkTimeout);

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final study = EncounterStudy.fromJson(json);
      await _saveStudyToCache(id, lang, response.body);
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
        final study = EncounterStudy.fromJson(json);
        await _saveStudyToCache(id, 'en', enResponse.body);
        return study;
      }
    }

    throw Exception(
        'Failed to load encounter study $id: ${response.statusCode}');
  }

  Future<EncounterStudy?> _loadStudyFromCache(String id, String lang) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString('$_studyCacheKeyPrefix${id}_$lang');
      if (cached != null) {
        return EncounterStudy.fromJson(
            jsonDecode(cached) as Map<String, dynamic>);
      }
    } catch (e) {
      developer.log('Failed to load encounter study from cache: $e',
          name: 'EncounterRepository._loadStudyFromCache');
    }
    return null;
  }

  Future<void> _saveStudyToCache(String id, String lang, String body) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('$_studyCacheKeyPrefix${id}_$lang', body);
    } catch (e) {
      developer.log('Failed to save encounter study to cache: $e',
          name: 'EncounterRepository._saveStudyToCache');
    }
  }

  Future<EncounterStudy> _loadFallbackStudy(String lang) async {
    // Pick language-appropriate bundled asset; default to 'en' for unsupported langs.
    final assetPath = _fallbackAssets[lang] ?? _fallbackAssets['en']!;
    try {
      final raw = await rootBundle.loadString(assetPath);
      final json = jsonDecode(raw) as Map<String, dynamic>;
      debugPrint(
          '📂 Encounter: Using bundled fallback study ($lang) → $assetPath');
      return EncounterStudy.fromJson(json);
    } catch (e) {
      throw Exception('Failed to load fallback encounter: $e');
    }
  }
}
