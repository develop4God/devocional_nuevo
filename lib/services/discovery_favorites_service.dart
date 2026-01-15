// lib/services/discovery_favorites_service.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service to manage favorite Discovery studies using ID-based persistence.
class DiscoveryFavoritesService {
  static const String _favoritesKey = 'discovery_favorite_ids';

  /// Load favorited study IDs from SharedPreferences
  Future<Set<String>> loadFavoriteIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? jsonString = prefs.getString(_favoritesKey);
      
      if (jsonString != null && jsonString.isNotEmpty) {
        final List<dynamic> decoded = json.decode(jsonString);
        return decoded.cast<String>().toSet();
      }
    } catch (e) {
      debugPrint('Error loading discovery favorites: $e');
    }
    return {};
  }

  /// Toggle favorite status and persist to storage
  Future<bool> toggleFavorite(String studyId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ids = await loadFavoriteIds();
      
      bool wasAdded;
      if (ids.contains(studyId)) {
        ids.remove(studyId);
        wasAdded = false;
      } else {
        ids.add(studyId);
        wasAdded = true;
      }
      
      await prefs.setString(_favoritesKey, json.encode(ids.toList()));
      debugPrint('⭐ Discovery Favorite toggled for $studyId: $wasAdded');
      return wasAdded;
    } catch (e) {
      debugPrint('Error toggling discovery favorite: $e');
      return false;
    }
  }
}
