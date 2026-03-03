// lib/repositories/discovery_repository.dart

import 'dart:convert';
import 'dart:developer' as developer;

import 'package:devocional_nuevo/models/discovery_devotional_model.dart';
import 'package:devocional_nuevo/utils/constants.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Repositorio para obtener devocionales Discovery desde GitHub con cache inteligente.
class DiscoveryRepository {
  final http.Client httpClient;
  static const String _cacheKeyPrefix = 'discovery_cache_';
  static const String _indexCacheKey = 'discovery_index_cache';

  /// How long an index cache entry is considered fresh before a background
  /// revalidation is triggered (same sidecar-date pattern used by devocional cache).
  static const Duration _indexCacheTtl = Duration(hours: 24);

  DiscoveryRepository({required this.httpClient});

  /// Obtiene un estudio Discovery comparando versiones del índice.
  ///
  /// [prefetchedIndex] — pass the already-fetched index map (e.g. from the
  /// BLoC) to avoid a redundant 43 KB network round-trip.  When null, the
  /// index is fetched from cache (or network if cache is stale/absent).
  Future<DiscoveryDevotional> fetchDiscoveryStudy(
    String id,
    String languageCode, {
    Map<String, dynamic>? prefetchedIndex,
  }) async {
    try {
      // Get current branch (debug mode can switch, production always 'main')
      final branch = kDebugMode ? Constants.debugBranch : 'main';

      // 1. Obtener el índice — reutilizar el ya obtenido si está disponible,
      //    de lo contrario cargar desde cache (o red si la cache está vacía).
      final index = prefetchedIndex ?? await _fetchIndex(forceRefresh: false);
      final studyInfo = index['studies']?.firstWhere(
        (s) => s['id'] == id,
        orElse: () => null,
      );

      final String expectedVersion = studyInfo?['version'] as String? ?? '1.0';

      // 2. Intentar cargar desde cache (CRITICAL: include branch in cache key)
      final cacheKey = '${id}_${languageCode}_$branch';
      final cached = await _loadFromCache(cacheKey, expectedVersion);

      if (cached != null) {
        debugPrint(
            '✅ Discovery: Usando cache para $id (v$expectedVersion) [branch: $branch]');
        return cached;
      }

      // 3. Si no hay cache o versión difiere, descargar
      debugPrint(
          '🚀 Discovery: Descargando nueva versión para $id (v$expectedVersion) [branch: $branch]');
      String filename;
      final files = studyInfo?['files'] as Map<String, dynamic>?;
      if (files != null) {
        filename = files[languageCode] ?? files['es'] ?? '${id}_es_001.json';
      } else {
        filename = '${id}_${languageCode}_001.json';
      }

      final url = Constants.getDiscoveryStudyFileUrl(filename, languageCode);
      final response = await httpClient.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final study = DiscoveryDevotional.fromJson(json);

        // Guardar en cache con la nueva versión
        await _saveToCache(cacheKey, json, expectedVersion);
        return study;
      } else {
        throw Exception('Failed to load study: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Discovery Error: $e');
      rethrow;
    }
  }

  /// Obtiene la lista de IDs de estudios disponibles.
  Future<List<String>> fetchAvailableStudies(
      {bool forceRefresh = false}) async {
    try {
      final index = await _fetchIndex(forceRefresh: forceRefresh);
      final studies = index['studies'] as List<dynamic>?;
      if (studies != null) {
        return studies.map((s) => s['id'] as String).toList();
      }
    } catch (e) {
      debugPrint('Error fetching available studies: $e');
    }
    return [];
  }

  /// Obtiene el índice de estudios.
  ///
  /// Estrategia:
  ///  • forceRefresh=false → Cache-First: devuelve cache si existe, evita red.
  ///  • forceRefresh=true  → Network-First: ignora cache, hit de red con
  ///    cache-buster, cae a cache si la red falla.
  Future<Map<String, dynamic>> _fetchIndex({bool forceRefresh = false}) async {
    final prefs = await SharedPreferences.getInstance();
    // Get current branch (debug mode can switch, production always 'main')
    final branch = kDebugMode ? Constants.debugBranch : 'main';
    final indexCacheKey = '${_indexCacheKey}_$branch';

    // ── Cache-First: serve from cache when fresh and caller did not force ──
    if (!forceRefresh) {
      final cachedIndex = prefs.getString(indexCacheKey);
      final cachedDateStr = prefs.getString('${indexCacheKey}_date');
      final cachedDate =
          cachedDateStr != null ? DateTime.tryParse(cachedDateStr) : null;
      final isFresh = cachedDate != null &&
          DateTime.now().difference(cachedDate) < _indexCacheTtl;

      if (cachedIndex != null && isFresh) {
        debugPrint(
            '✅ Discovery: Index cache hit [branch: $branch] age: ${DateTime.now().difference(cachedDate).inMinutes}m (skipping network)');
        final index = jsonDecode(cachedIndex) as Map<String, dynamic>;
        final studiesCount = (index['studies'] as List?)?.length ?? 0;
        debugPrint(
            '📚 Discovery: Cached index has $studiesCount studies [branch: $branch]');
        return index;
      }

      if (cachedIndex != null && !isFresh) {
        debugPrint(
            '⏰ Discovery: Index cache stale (age: ${cachedDate == null ? '?' : DateTime.now().difference(cachedDate).inHours}h) — revalidating from network');
      } else {
        debugPrint(
            '⚠️ Discovery: No cache for branch $branch — fetching from network');
      }
    }

    try {
      // Agregar cache-buster (timestamp) para ignorar CDNs de GitHub y proxies locales
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final indexUrl = Constants.getDiscoveryIndexUrl();
      final cacheBusterUrl = indexUrl.contains('?')
          ? '$indexUrl&cb=$timestamp'
          : '$indexUrl?cb=$timestamp';

      debugPrint(
          '🌐 Discovery: Buscando índice en la red [branch: $branch] (buster: $timestamp)...');
      debugPrint('📍 Discovery: URL = $cacheBusterUrl');

      final response = await httpClient.get(Uri.parse(cacheBusterUrl));
      debugPrint('📡 Discovery: Response status = ${response.statusCode}');

      if (response.statusCode == 200) {
        debugPrint(
            '✅ Discovery: Response body length = ${response.body.length}');
        debugPrint(
            '🔍 Discovery: First 500 chars of response: ${response.body.substring(0, response.body.length < 500 ? response.body.length : 500)}');

        final index = jsonDecode(response.body) as Map<String, dynamic>;
        debugPrint('🔍 Discovery: Index keys = ${index.keys.toList()}');

        final studiesCount = (index['studies'] as List?)?.length ?? 0;
        debugPrint(
            '📚 Discovery: Parsed $studiesCount studies from index [branch: $branch]');

        if (studiesCount == 0) {
          debugPrint(
              '⚠️ Discovery: index["studies"] type = ${index['studies'].runtimeType}');
          debugPrint('⚠️ Discovery: Full index = $index');
        }

        // CRITICAL: Guardar en cache con branch incluido en la key
        await prefs.setString(indexCacheKey, response.body);
        // Store fetch date for TTL check (inline sidecar pattern)
        await prefs.setString(
            '${indexCacheKey}_date', DateTime.now().toIso8601String());
        debugPrint(
            '💾 Discovery: Index cached successfully for branch: $branch');
        return index;
      } else {
        debugPrint('❌ Discovery: Server error ${response.statusCode}');
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint(
          '⚠️ Discovery: Error de red al buscar índice [branch: $branch], usando cache: $e');
      // CRITICAL: Buscar cache con branch incluido en la key
      final cachedIndex = prefs.getString(indexCacheKey);
      if (cachedIndex != null) {
        debugPrint(
            '📦 Discovery: Cache encontrado para branch: $branch, parseando...');
        final index = jsonDecode(cachedIndex) as Map<String, dynamic>;
        final studiesCount = (index['studies'] as List?)?.length ?? 0;
        debugPrint(
            '📚 Discovery: Cached index has $studiesCount studies [branch: $branch]');
        return index;
      }
      debugPrint(
          '🚫 Discovery: No cache disponible para branch: $branch, relanzando error');
      rethrow;
    }
  }

  Future<DiscoveryDevotional?> _loadFromCache(
      String id, String expectedVersion) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedJson = prefs.getString('$_cacheKeyPrefix$id');
      final cachedVersion = prefs.getString('$_cacheKeyPrefix${id}_version');

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
    } catch (e) {
      // Cache write failure is non-critical, app continues with network data
      developer.log('Failed to save discovery cache: $e',
          name: 'DiscoveryRepository._saveToCache', error: e);
    }
  }

  Future<Map<String, dynamic>> fetchIndex({bool forceRefresh = false}) async {
    return await _fetchIndex(forceRefresh: forceRefresh);
  }
}
