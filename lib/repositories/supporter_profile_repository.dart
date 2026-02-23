// lib/repositories/supporter_profile_repository.dart

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'i_supporter_profile_repository.dart';

/// Persists and retrieves the Gold supporter's profile name.
///
/// Implements [ISupporterProfileRepository] for Dependency Inversion.
class SupporterProfileRepository implements ISupporterProfileRepository {
  // Current preferred key
  static const String _profileNameKey = 'profile_display_name';

  // Legacy key used by older releases (kept for migration)
  static const String _legacyGoldNameKey = 'iap_gold_supporter_name';

  final Future<SharedPreferences> Function() _prefsFactory;

  SupporterProfileRepository({
    Future<SharedPreferences> Function()? prefsFactory,
  }) : _prefsFactory = prefsFactory ?? SharedPreferences.getInstance;

  /// Load the stored profile display name (may be null).
  ///
  /// This method will attempt to read the current key first. If nothing is
  /// present, it will look for the legacy key and migrate the value to the
  /// new key (removing the legacy entry) so migration happens once.
  @override
  Future<String?> loadProfileName() async {
    try {
      final prefs = await _prefsFactory();

      // Prefer the new key
      final current = prefs.getString(_profileNameKey);
      if (current != null) return current;

      // Attempt migration from legacy key
      final legacy = prefs.getString(_legacyGoldNameKey);
      if (legacy != null) {
        // Migrate to the new key and remove legacy entry
        await prefs.setString(_profileNameKey, legacy);
        await prefs.remove(_legacyGoldNameKey);
        debugPrint('🔁 [SupporterProfileRepository] Migrated legacy gold name');
        return legacy;
      }

      return null;
    } catch (e) {
      debugPrint('❌ [SupporterProfileRepository] Error loading name: $e');
      return null;
    }
  }

  /// Persist the profile display name.
  @override
  Future<void> saveProfileName(String name) async {
    try {
      final prefs = await _prefsFactory();
      await prefs.setString(_profileNameKey, name);
      debugPrint('✅ [SupporterProfileRepository] Saved profile name: $name');
    } catch (e) {
      debugPrint('❌ [SupporterProfileRepository] Error saving name: $e');
    }
  }
}
