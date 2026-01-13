// lib/repositories/discovery_repository.dart

import 'dart:convert';
import 'package:devocional_nuevo/models/discovery_devotional_model.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Repositorio para obtener devocionales Discovery desde GitHub.
///
/// Sigue el patrón de repository con HTTP client injection y cache a SharedPreferences.
class DiscoveryRepository {
  final http.Client httpClient;
  static const String _cacheKeyPrefix = 'discovery_cache_';
  static const String _indexCacheKey = 'discovery_index_cache';
  static const String _indexCacheTimestampKey = 'discovery_index_timestamp';
  static const String _githubRawBaseUrl =
      'https://raw.githubusercontent.com/develop4God/Devocionales-json/refs/heads/main/discovery';
  static const Duration _indexCacheTTL = Duration(hours: 1);

  DiscoveryRepository({required this.httpClient});

  /// Obtiene un estudio Discovery por su ID y código de idioma.
  ///
  /// Primero intenta obtenerlo del cache, si no está disponible o ha expirado,
  /// lo descarga desde GitHub usando el nombre de archivo específico del idioma.
  Future<DiscoveryDevotional> fetchDiscoveryStudy(
    String id,
    String languageCode,
  ) async {
    try {
      // Intentar cargar desde cache primero
      final cacheKey = '${id}_$languageCode';
      final cached = await _loadFromCache(cacheKey);
      if (cached != null) {
        return cached;
      }

      // Obtener el índice para encontrar el nombre de archivo correcto
      final index = await _fetchIndex();
      final studyInfo = index['studies']?.firstWhere(
        (s) => s['id'] == id,
        orElse: () => null,
      );

      String filename;
      final files = studyInfo?['files'] as Map<String, dynamic>?;
      if (files != null) {
        filename = files[languageCode] ?? files['es'] ?? '${id}_es_001.json';
      } else {
        filename = '${id}_${languageCode}_001.json';
      }

      // Descargar desde GitHub
      final url = '$_githubRawBaseUrl/$filename';
      debugPrint('Fetching Discovery study from: $url');
      final response = await httpClient.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final study = DiscoveryDevotional.fromJson(json);

        // Guardar en cache
        await _saveToCache(cacheKey, json);

        return study;
      } else {
        throw Exception(
          'Failed to load Discovery study: ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('Error fetching Discovery study $id: $e');
      rethrow;
    }
  }

  /// Obtiene la lista de estudios Discovery disponibles desde GitHub index.
  ///
  /// Intenta cargar desde cache (TTL: 1 hora), si no está disponible o expiró,
  /// descarga desde GitHub. Si falla, retorna lista hardcoded como fallback.
  Future<List<String>> fetchAvailableStudies() async {
    try {
      final index = await _fetchIndex();
      final studies = index['studies'] as List<dynamic>?;
      if (studies != null && studies.isNotEmpty) {
        return studies.map((s) => s['id'] as String).toList();
      }
    } catch (e) {
      debugPrint('Error fetching index, using fallback list: $e');
    }

    // Fallback to hardcoded list if index fetch fails
    return [
      'morning_star_001',
      'morning_star_002',
      'morning_star_003',
    ];
  }

  /// Obtiene el índice de estudios desde GitHub con cache de 1 hora.
  Future<Map<String, dynamic>> _fetchIndex() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Check cache first
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

      // Fetch from GitHub
      final url = '$_githubRawBaseUrl/index.json';
      debugPrint('Fetching Discovery index from: $url');
      final response = await httpClient.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final index = jsonDecode(response.body) as Map<String, dynamic>;

        // Cache the index
        await prefs.setString(_indexCacheKey, response.body);
        await prefs.setInt(
          _indexCacheTimestampKey,
          DateTime.now().millisecondsSinceEpoch,
        );

        debugPrint('Discovery index cached successfully');
        return index;
      } else {
        throw Exception('Failed to load index: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching Discovery index: $e');
      rethrow;
    }
  }

  /// Carga un estudio desde el cache de SharedPreferences.
  Future<DiscoveryDevotional?> _loadFromCache(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = '$_cacheKeyPrefix$id';
      final cachedJson = prefs.getString(cacheKey);

      if (cachedJson != null && cachedJson.isNotEmpty) {
        final json = jsonDecode(cachedJson) as Map<String, dynamic>;
        return DiscoveryDevotional.fromJson(json);
      }
      return null;
    } catch (e) {
      debugPrint('Error loading from cache: $e');
      return null;
    }
  }

  /// Guarda un estudio en el cache de SharedPreferences.
  Future<void> _saveToCache(String id, Map<String, dynamic> json) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = '$_cacheKeyPrefix$id';
      await prefs.setString(cacheKey, jsonEncode(json));
    } catch (e) {
      debugPrint('Error saving to cache: $e');
      // No propagar el error, el cache es opcional
    }
  }

  /// Limpia el cache de estudios Discovery.
  Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      for (final key in keys) {
        if (key.startsWith(_cacheKeyPrefix)) {
          await prefs.remove(key);
        }
      }
    } catch (e) {
      debugPrint('Error clearing cache: $e');
    }
  }
}
