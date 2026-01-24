// lib/services/discovery_favorites_service.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service to manage favorite Discovery studies using ID-based persistence.
class DiscoveryFavoritesService {
  static const String _favoritesKeyPrefix = 'discovery_favorite_ids_';
  static const String _defaultLanguage = 'en';

  SharedPreferences? _prefs;

  Future<SharedPreferences> get prefs async {
    return _prefs ??= await SharedPreferences.getInstance();
  }

  /// Load favorited study IDs from SharedPreferences for a specific language
  Future<Set<String>> loadFavoriteIds([String? languageCode]) async {
    try {
      final prefsInstance = await prefs;
      final key = _getFavoritesKey(languageCode);
      final String? jsonString = prefsInstance.getString(key);

      if (jsonString != null && jsonString.isNotEmpty) {
        final List<dynamic> decoded = json.decode(jsonString);
        return decoded.cast<String>().toSet();
      }
    } catch (e) {
      debugPrint('Error loading discovery favorites: $e');
    }
    return {};
  }

  /// Toggle favorite status and persist to storage for a specific language
  Future<bool> toggleFavorite(String studyId, [String? languageCode]) async {
    try {
      final prefsInstance = await prefs;
      final ids = await loadFavoriteIds(languageCode);

      bool wasAdded;
      if (ids.contains(studyId)) {
        ids.remove(studyId);
        wasAdded = false;
      } else {
        ids.add(studyId);
        wasAdded = true;
      }

      final key = _getFavoritesKey(languageCode);
      await prefsInstance.setString(key, json.encode(ids.toList()));
      debugPrint(
          '⭐ Discovery Favorite toggled for $studyId ($languageCode): $wasAdded');
      return wasAdded;
    } catch (e) {
      debugPrint('Error toggling discovery favorite: $e');
      return false;
    }
  }

  String _getFavoritesKey(String? languageCode) {
    // Normalize language code to base language (e.g., 'en-US' -> 'en')
    final normalized =
        languageCode?.split('-').first.toLowerCase() ?? _defaultLanguage;
    return '$_favoritesKeyPrefix$normalized';
  }
}
