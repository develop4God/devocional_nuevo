// lib/services/remote_badge_service.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/badge_model.dart' as badge_model;

class RemoteBadgeService {
  static const String _configUrl =
      'https://raw.githubusercontent.com/develop4God/Devocionales-json/refs/heads/main/badges/badge_config.json';

  static const String _cacheKey = 'cached_badge_config';
  static const String _cacheTimeKey = 'badge_config_cache_time';
  static const Duration _cacheExpiry = Duration(hours: 1);

  // Singleton
  static final RemoteBadgeService _instance = RemoteBadgeService._internal();

  factory RemoteBadgeService() => _instance;

  RemoteBadgeService._internal();

  List<badge_model.Badge>? _cachedBadges;

  /// Get all available badges
  Future<List<badge_model.Badge>> getAvailableBadges({
    bool forceRefresh = false,
  }) async {
    try {
      debugPrint('🏅 Fetching available badges...');

      if (!forceRefresh && _cachedBadges != null) {
        debugPrint('✅ Returning cached badges: ${_cachedBadges!.length}');
        return _cachedBadges!;
      }

      final config = await _fetchBadgeConfig(forceRefresh: forceRefresh);
      _cachedBadges = config?.badges ?? [];

      debugPrint('✅ Loaded ${_cachedBadges!.length} badges from remote');
      return _cachedBadges!;
    } catch (e) {
      debugPrint('❌ Error fetching badges: $e');

      // Try to return cached badges as fallback
      if (_cachedBadges != null) {
        debugPrint('🔄 Returning cached badges as fallback');
        return _cachedBadges!;
      }

      return [];
    }
  }

  /// Get a specific badge by ID
  Future<badge_model.Badge?> getBadgeById(String id) async {
    try {
      final badges = await getAvailableBadges();
      return badges.cast<badge_model.Badge?>().firstWhere(
            (badge) => badge?.id == id,
            orElse: () => null,
          );
    } catch (e) {
      debugPrint('❌ Error getting badge by ID: $e');
      return null;
    }
  }

  /// Check if badges need update
  Future<bool> hasUpdates() async {
    try {
      final cachedConfig = await _getCachedConfig();
      if (cachedConfig == null) return true;

      final remoteConfig = await _fetchBadgeConfig(forceRefresh: true);
      if (remoteConfig == null) return false;

      return cachedConfig.version != remoteConfig.version ||
          cachedConfig.lastUpdated != remoteConfig.lastUpdated;
    } catch (e) {
      debugPrint('❌ Error checking for updates: $e');
      return false;
    }
  }

  /// Refresh badges cache
  Future<void> refreshBadges() async {
    debugPrint('🔄 Refreshing badges cache...');
    _cachedBadges = null;
    await getAvailableBadges(forceRefresh: true);
  }

  /// Fetch badge configuration from remote
  Future<badge_model.BadgeConfig?> _fetchBadgeConfig({
    bool forceRefresh = false,
  }) async {
    try {
      // Check cache first
      if (!forceRefresh) {
        final cachedConfig = await _getCachedConfig();
        if (cachedConfig != null) {
          return cachedConfig;
        }
      }

      debugPrint('🌐 Fetching badge config from: $_configUrl');

      final response = await http.get(
        Uri.parse(_configUrl),
        headers: {
          'Accept': 'application/json',
          'Cache-Control': 'no-cache',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body) as Map<String, dynamic>;
        final config = badge_model.BadgeConfig.fromJson(jsonData);

        // Cache the successful response
        await _cacheConfig(config);

        debugPrint(
          '✅ Badge config loaded successfully. Version: ${config.version}',
        );
        return config;
      } else {
        debugPrint('❌ HTTP Error: ${response.statusCode}');
        throw HttpException(
          'Failed to load badge config: ${response.statusCode}',
        );
      }
    } on TimeoutException {
      debugPrint('❌ Timeout fetching badge config');
      return await _getCachedConfig(); // Return cached as fallback
    } on SocketException {
      debugPrint('❌ Network error fetching badge config');
      return await _getCachedConfig(); // Return cached as fallback
    } catch (e) {
      debugPrint('❌ Unexpected error fetching badge config: $e');
      return await _getCachedConfig(); // Return cached as fallback
    }
  }

  /// Cache badge configuration
  Future<void> _cacheConfig(badge_model.BadgeConfig config) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final configJson = json.encode(config.toJson());

      await prefs.setString(_cacheKey, configJson);
      await prefs.setInt(_cacheTimeKey, DateTime.now().millisecondsSinceEpoch);

      debugPrint('💾 Badge config cached successfully');
    } catch (e) {
      debugPrint('❌ Error caching badge config: $e');
    }
  }

  /// Get cached badge configuration
  Future<badge_model.BadgeConfig?> _getCachedConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Check if cache exists
      final configJson = prefs.getString(_cacheKey);
      if (configJson == null) {
        debugPrint('📭 No cached badge config found');
        return null;
      }

      // Check if cache is expired
      final cacheTime = prefs.getInt(_cacheTimeKey) ?? 0;
      final cacheAge = DateTime.now().millisecondsSinceEpoch - cacheTime;
      final cacheExpired = cacheAge > _cacheExpiry.inMilliseconds;

      if (cacheExpired) {
        debugPrint('⏰ Badge config cache expired');
        return null;
      }

      // Parse cached config
      final jsonData = json.decode(configJson) as Map<String, dynamic>;
      final config = badge_model.BadgeConfig.fromJson(jsonData);

      debugPrint('📦 Using cached badge config. Version: ${config.version}');
      return config;
    } catch (e) {
      debugPrint('❌ Error reading cached badge config: $e');
      return null;
    }
  }

  /// Clear cache (for debugging/testing)
  Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cacheKey);
      await prefs.remove(_cacheTimeKey);

      _cachedBadges = null;

      debugPrint('🗑️ Badge cache cleared');
    } catch (e) {
      debugPrint('❌ Error clearing badge cache: $e');
    }
  }
}
