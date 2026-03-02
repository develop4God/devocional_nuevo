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
  static const String _fallbackAsset =
      'assets/encounters/fallback_peter_en.json';

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
      final response = await httpClient.get(Uri.parse(cacheBusterUrl));

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
      final raw = await rootBundle.loadString(_fallbackAsset);
      final json = jsonDecode(raw) as Map<String, dynamic>;
      // Wrap the single encounter in an entry
      final id = json['id'] as String? ?? 'peter_water_001';
      return [
        EncounterIndexEntry(
          id: id,
          version: json['version'] as String? ?? '1.0',
          emoji: '🌊',
          status: 'published',
          moodPrimary: 'tense',
          accentColor: '#0f1828',
          testament: 'new',
          character: 'Peter',
          files: {'en': '$id.json'},
          titles: {'en': 'Peter Walks on Water'},
          subtitles: {'en': 'Faith Beyond the Storm'},
          scriptureReference: {'en': 'Matthew 14:22-33'},
          estimatedReadingMinutes: {'en': 10},
        ),
      ];
    } catch (e) {
      developer.log('Failed to load fallback encounter asset: $e',
          name: 'EncounterRepository._loadFallbackAsIndex');
      return [];
    }
  }

  // ---------------------------------------------------------------------------
  // Study
  // ---------------------------------------------------------------------------

  /// Fetches an individual encounter study. Checks cache first, then network.
  /// Falls back to the bundled fallback asset for 'peter_water_001'.
  Future<EncounterStudy> fetchStudy(String id, String lang) async {
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
      final study = await _fetchStudyFromNetwork(id, lang);
      return study;
    } catch (e) {
      debugPrint('❌ Encounter: Error fetching study $id ($lang): $e');
      // Fallback to bundled asset only when fallback is enabled
      if (Constants.enableEncounterFallback && id == 'peter_water_001') {
        return _loadFallbackStudy();
      }
      rethrow;
    }
  }

  /// Non-recursive network fetch: tries [lang], then 'en' if different.
  Future<EncounterStudy> _fetchStudyFromNetwork(String id, String lang) async {
    final url = Constants.getEncounterStudyUrl(id, lang);
    debugPrint('🌐 Encounter: Fetching study $id ($lang) from $url');
    final response = await httpClient.get(Uri.parse(url));

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
      final enUrl = Constants.getEncounterStudyUrl(id, 'en');
      final enResponse = await httpClient.get(Uri.parse(enUrl));
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

  Future<EncounterStudy> _loadFallbackStudy() async {
    try {
      final raw = await rootBundle.loadString(_fallbackAsset);
      final json = jsonDecode(raw) as Map<String, dynamic>;
      debugPrint('📂 Encounter: Using bundled fallback study');
      return EncounterStudy.fromJson(json);
    } catch (e) {
      throw Exception('Failed to load fallback encounter: $e');
    }
  }
}
