// lib/repositories/supporter_profile_repository.dart

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'i_supporter_profile_repository.dart';

/// Persists and retrieves the Gold supporter's chosen display name.
///
/// Extracted from [IapService] so that name-management concerns are
/// separate from the purchase lifecycle (Single Responsibility).
///
/// Implements [ISupporterProfileRepository] for Dependency Inversion —
/// callers (e.g. [SupporterBloc]) depend on the interface, not this class.
class SupporterProfileRepository implements ISupporterProfileRepository {
  static const String _goldNameKey = 'iap_gold_supporter_name';

  final Future<SharedPreferences> Function() _prefsFactory;

  SupporterProfileRepository({
    Future<SharedPreferences> Function()? prefsFactory,
  }) : _prefsFactory = prefsFactory ?? SharedPreferences.getInstance;

  /// Load the stored Gold supporter display name (may be null).
  @override
  Future<String?> loadGoldSupporterName() async {
    try {
      final prefs = await _prefsFactory();
      return prefs.getString(_goldNameKey);
    } catch (e) {
      debugPrint('❌ [SupporterProfileRepository] Error loading name: $e');
      return null;
    }
  }

  /// Persist the Gold supporter display name.
  @override
  Future<void> saveGoldSupporterName(String name) async {
    try {
      final prefs = await _prefsFactory();
      await prefs.setString(_goldNameKey, name);
      debugPrint('✅ [SupporterProfileRepository] Saved name: $name');
    } catch (e) {
      debugPrint('❌ [SupporterProfileRepository] Error saving name: $e');
    }
  }
}
