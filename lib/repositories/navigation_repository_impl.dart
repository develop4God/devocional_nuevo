// lib/repositories/navigation_repository_impl.dart

import 'package:shared_preferences/shared_preferences.dart';
import 'navigation_repository.dart';

/// Concrete implementation of NavigationRepository using SharedPreferences
class NavigationRepositoryImpl implements NavigationRepository {
  static const String _lastDevocionalIndexKey = 'lastDevocionalIndex';

  @override
  Future<void> saveCurrentIndex(int index) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_lastDevocionalIndexKey, index);
    } catch (e) {
      // Fail silently - navigation should continue to work even if persistence fails
      // Error is not logged to avoid console spam during tests
      // In production, consider integrating with your analytics/logging service
    }
  }

  @override
  Future<int> loadCurrentIndex() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(_lastDevocionalIndexKey) ?? 0;
    } catch (e) {
      return 0; // Default to first devotional
    }
  }
}
