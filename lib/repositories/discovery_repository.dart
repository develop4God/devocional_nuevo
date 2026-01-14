// lib/repositories/discovery_repository.dart

import 'dart:convert';

import 'package:devocional_nuevo/models/discovery_devotional_model.dart';
import 'package:devocional_nuevo/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Repositorio para obtener devocionales Discovery desde GitHub.
class DiscoveryRepository {
  final http.Client httpClient;
  static const String _cacheKeyPrefix = 'discovery_cache_';
  static const String _indexCacheKey = 'discovery_index_cache';
  static const String _indexCacheTimestampKey = 'discovery_index_timestamp';
  static const Duration _indexCacheTTL = Duration(hours: 1);

  DiscoveryRepository({required this.httpClient});

  Future<DiscoveryDevotional> fetchDiscoveryStudy(
    String id,
    String languageCode,
  ) async {
    try {
      final index = await _fetchIndex();
      final studyInfo = index['studies']?.firstWhere(
        (s) => s['id'] == id,
        orElse: () => null,
      );

      final String expectedVersion = studyInfo?['version'] as String? ?? '1.0';

      final cacheKey = '${id}_$languageCode';
      final cached = await _loadFromCache(cacheKey, expectedVersion);
      if (cached != null) {
        return cached;
      }

      String filename;
      final files = studyInfo?['files'] as Map<String, dynamic>?;
      if (files != null) {
        filename = files[languageCode] ?? files['es'] ?? '${id}_es_001.json';
      } else {
        filename = '${id}_${languageCode}_001.json';
      }

      final url = Constants.getDiscoveryStudyFileUrl(filename);
      final response = await httpClient.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final study = DiscoveryDevotional.fromJson(json);
        await _saveToCache(cacheKey, json, expectedVersion);
        return study;
      } else {
        throw Exception(
            'Failed to load Discovery study: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<List<String>> fetchAvailableStudies(
      {bool forceRefresh = false}) async {
    try {
      final index = await _fetchIndex(forceRefresh: forceRefresh);
      final studies = index['studies'] as List<dynamic>?;
      if (studies != null && studies.isNotEmpty) {
        return studies.map((s) => s['id'] as String).toList();
      }
    } catch (e) {
      debugPrint('Error fetching index: $e');
    }
    return ['morning_star_001', 'morning_star_002', 'morning_star_003'];
  }

  Future<Map<String, dynamic>> _fetchIndex({bool forceRefresh = false}) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      if (!forceRefresh) {
        final cachedIndex = prefs.getString(_indexCacheKey);
        final cachedTimestamp = prefs.getInt(_indexCacheTimestampKey);

        if (cachedIndex != null && cachedTimestamp != null) {
          final cacheAge =
              DateTime.now().millisecondsSinceEpoch - cachedTimestamp;
          if (cacheAge < _indexCacheTTL.inMilliseconds) {
            debugPrint('Using cached Discovery index');
            return jsonDecode(cachedIndex) as Map<String, dynamic>;
          }
        }
      } else {
        debugPrint('Forcing Discovery index refresh...');
      }

      final url = Constants.discoveryIndexUrl;
      final response = await httpClient.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final index = jsonDecode(response.body) as Map<String, dynamic>;
        await prefs.setString(_indexCacheKey, response.body);
        await prefs.setInt(
            _indexCacheTimestampKey, DateTime.now().millisecondsSinceEpoch);
        return index;
      } else {
        throw Exception('Failed to load index: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<DiscoveryDevotional?> _loadFromCache(
      String id, String expectedVersion) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = '$_cacheKeyPrefix$id';
      final versionKey = '$_cacheKeyPrefix${id}_version';
      final cachedJson = prefs.getString(cacheKey);
      final cachedVersion = prefs.getString(versionKey);

      if (cachedJson != null && cachedVersion == expectedVersion) {
        return DiscoveryDevotional.fromJson(jsonDecode(cachedJson));
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<void> _saveToCache(
      String id, Map<String, dynamic> json, String version) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('$_cacheKeyPrefix$id', jsonEncode(json));
      await prefs.setString('$_cacheKeyPrefix${id}_version', version);
    } catch (e) {}
  }

  Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    for (final key in keys) {
      if (key.startsWith(_cacheKeyPrefix) || key == _indexCacheKey) {
        await prefs.remove(key);
      }
    }
  }

  Future<Map<String, dynamic>> fetchIndex({bool forceRefresh = false}) async {
    return await _fetchIndex(forceRefresh: forceRefresh);
  }
}
