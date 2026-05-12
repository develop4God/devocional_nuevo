// lib/services/startup_migration_service.dart
//
// Single entry point for all one-time startup data migrations.
// Each migration is self-guarded by its own SharedPreferences flag,
// idempotent, and non-blocking — a failure never prevents app startup.
//
// To add a future migration: add a new private method and call it from runAll().
import 'dart:async' show unawaited;
import 'dart:developer' as developer;

import 'package:devocional_nuevo/models/devocional_model.dart';
import 'package:devocional_nuevo/services/i_analytics_service.dart';
import 'package:devocional_nuevo/services/i_spiritual_stats_service.dart';
import 'package:devocional_nuevo/services/i_startup_migration_service.dart';
import 'package:devocional_nuevo/services/service_locator.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:devocional_nuevo/utils/constants/storage_keys.dart';

class StartupMigrationService implements IStartupMigrationService {
  const StartupMigrationService({required ISpiritualStatsService statsService})
      : _statsService = statsService;

  final ISpiritualStatsService _statsService;

  /// Run all registered migrations in order.
  /// Call once from AppInitializer._initAppData() on every cold start.
  /// Each migration is self-guarded and will no-op after its first run.
  @override
  Future<void> runAll(
    List<Devocional> devocionales,
    List<String> readDevocionalIds,
  ) async {
    await _migrationV3SingleGapFix(devocionales, readDevocionalIds);
    // Future migrations go here:
    // await _migrationV3SomethingElse();
  }

  // ── Migration V2 — Single-entry gap fix ───────────────────────────────────
  //
  // One-time migration for users affected by the legacy unread-state bug.
  //
  // The bug caused exactly one devotional entry to not be saved as read,
  // leaving the user stuck on that entry on every cold start.
  //
  // Detects two gap patterns:
  //   A) Leading gap  — index 0 unread, index 1 read (no prior neighbour).
  //      Fingerprint of a user who tapped "next" past the very first devotional.
  //   B) Interior gap — index N-1 read, N unread, N+1 read (both neighbours).
  //
  // Only that single entry is filled — no bulk writes.
  // Runs once per install. The flag below prevents re-runs.

  Future<void> _migrationV3SingleGapFix(
    List<Devocional> devocionales,
    List<String> readDevocionalIds,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final alreadyRan = prefs.getBool(MigrationKeys.singleGapFix) ?? false;
      if (alreadyRan) return;

      // Mark migration as done immediately — even if we find nothing to fix.
      // This prevents repeated prefs reads on every cold start.
      await prefs.setBool(MigrationKeys.singleGapFix, true);

      if (readDevocionalIds.isEmpty || devocionales.isEmpty) {
        developer.log(
          '🔧 [MIGRATION] No read IDs — new user or clean state, skipping',
          name: 'GapMigration',
        );
        return;
      }

      final readSet = Set<String>.from(readDevocionalIds);

      String? singleGapId;
      int singleGapIndex = -1;

      // ── Pattern A: leading gap at index 0 ─────────────────────────────────
      // The original loop started at i=1 (requires both neighbours) so index 0
      // was structurally excluded. Check it explicitly first.
      if (devocionales.length >= 2) {
        final firstUnread = !readSet.contains(devocionales[0].id);
        final secondRead = readSet.contains(devocionales[1].id);
        if (firstUnread && secondRead && devocionales[0].id.isNotEmpty) {
          singleGapId = devocionales[0].id;
          singleGapIndex = 0;
        }
      }

      // ── Pattern B: interior gap (N-1 read, N unread, N+1 read) ───────────
      if (singleGapId == null) {
        for (int i = 1; i < devocionales.length - 1; i++) {
          final prevRead = readSet.contains(devocionales[i - 1].id);
          final currUnread = !readSet.contains(devocionales[i].id);
          final nextRead = readSet.contains(devocionales[i + 1].id);

          if (prevRead && currUnread && nextRead) {
            final id = devocionales[i].id;
            if (id.isNotEmpty) {
              singleGapId = id;
              singleGapIndex = i;
            }
            break; // exactly one — stop immediately
          }
        }
      }

      if (singleGapId == null) {
        developer.log(
          '🔧 [MIGRATION] No single-entry gap found — user state is clean',
          name: 'GapMigration',
        );
        unawaited(
          getService<IAnalyticsService>().logCustomEvent(
            eventName: 'legacy_gap_migration_clean',
          ),
        );
        return;
      }

      developer.log(
        '🔧 [MIGRATION] Single gap found at index $singleGapIndex — filling silently',
        name: 'GapMigration',
      );

      await _statsService.bulkMarkAsRead([singleGapId]);

      developer.log(
        '✅ [MIGRATION] Legacy gap migration complete: 1 entry marked as read (index $singleGapIndex)',
        name: 'GapMigration',
      );

      unawaited(
        getService<IAnalyticsService>().logCustomEvent(
          eventName: 'legacy_gap_migration_applied',
          parameters: {
            'gaps_filled': 1,
            'gap_index': singleGapIndex,
          },
        ),
      );
    } catch (e, stack) {
      // Migration is non-critical — log and continue. Never block app start.
      developer.log(
        '❌ [MIGRATION] Error during gap migration: $e',
        name: 'GapMigration',
        error: e,
      );
      FirebaseCrashlytics.instance.recordError(
        e,
        stack,
        fatal: false,
        reason: 'Legacy gap migration V2 failed',
      );
    }
  }
}
