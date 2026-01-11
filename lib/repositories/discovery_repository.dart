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
  static const String _githubRawBaseUrl =
      'https://raw.githubusercontent.com/develop4God/Devocionales-json/main/discovery';

  DiscoveryRepository({required this.httpClient});

  /// Obtiene un estudio Discovery por su ID.
  ///
  /// Primero intenta obtenerlo del cache, si no está disponible o ha expirado,
  /// lo descarga desde GitHub.
  Future<DiscoveryDevotional> fetchDiscoveryStudy(String id) async {
    try {
      // Intentar cargar desde cache primero
      final cached = await _loadFromCache(id);
      if (cached != null) {
        return cached;
      }

      // Si no está en cache, descargar desde GitHub
      final url = '$_githubRawBaseUrl/$id.json';
      final response = await httpClient.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final study = DiscoveryDevotional.fromJson(json);

        // Guardar en cache
        await _saveToCache(id, json);

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

  /// Obtiene la lista de estudios Discovery disponibles.
  ///
  /// Por ahora retorna una lista hardcoded, pero podría extenderse
  /// para obtener el índice desde GitHub.
  Future<List<String>> fetchAvailableStudies() async {
    // TODO: En una implementación completa, esto vendría de un index.json en GitHub
    return [
      'estrella-manana-001',
      'estrella-manana-002',
      'estrella-manana-003',
    ];
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
