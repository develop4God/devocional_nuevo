// lib/services/startup_migration_service.dart
//
// Single entry point for all one-time startup fixes.
// Each fix is self-guarded by its own SharedPreferences flag,
// idempotent, and non-blocking — a failure never prevents app startup.
//
// To add a future fix: add a new private method and call it from runAll().
import 'dart:async' show unawaited;
import 'dart:developer' as developer;

import 'package:devocional_nuevo/models/devocional_model.dart';
import 'package:devocional_nuevo/services/i_analytics_service.dart';
import 'package:devocional_nuevo/services/i_spiritual_stats_service.dart';
import 'package:devocional_nuevo/services/i_startup_migration_service.dart';
import 'package:devocional_nuevo/services/service_locator.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

class StartupMigrationService implements IStartupMigrationService {
  const StartupMigrationService({required ISpiritualStatsService statsService})
      : _statsService = statsService;

  final ISpiritualStatsService _statsService;

  /// Run all registered fixes in order.
  /// Call once from AppInitializer._initAppData() on every cold start.
  /// Each fix is self-guarded and will no-op after its first run.
  @override
  Future<void> runAll(
    List<Devocional> devocionales,
    List<String> readDevocionalIds,
  ) async {
    await _applyReadGapFix(devocionales, readDevocionalIds);
    // Future fixes go here:
    // await _applyFutureFixName();
  }

  // ── Read Gap Fix ──────────────────────────────────────────────────────────
  //
  // One-time startup fix: Detects and fills single-entry gaps in the read list.
  // This prevents users from being stuck on an unread entry on every cold start.
  //
  // Detects two gap patterns:
  //   A) Leading gap  — index 0 unread, index 1 read (no prior neighbour).
  //      Fingerprint of a user who tapped "next" past the very first devotional.
  //   B) Interior gap — index N-1 read, N unread, N+1 read (both neighbours).
  //
  // Only that single entry is filled — no bulk writes.
  // Runs on EVERY startup (idempotent — safe to repeat).
  // Uses bulkMarkAsRead(), which is idempotent, so marking already-read entries
  // is a no-op. This allows QA and users to test multiple gap scenarios across
  // different app cold starts without data pollution.

  Future<void> _applyReadGapFix(
    List<Devocional> devocionales,
    List<String> readDevocionalIds,
  ) async {
    try {
      if (readDevocionalIds.isEmpty || devocionales.isEmpty) {
        developer.log(
          '🔧 [FIX] No read IDs — new user or clean state, skipping',
          name: 'ReadGapFix',
        );
        return;
      }

      final readSet = Set<String>.from(readDevocionalIds);

      String? singleGapId;
      int singleGapIndex = -1;

      // ── Pattern A: leading gap at index 0 ─────────────────────────────────
      // Checks the first entry explicitly since the interior loop requires
      // both prior and next entries to be read (which doesn't apply to index 0).
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
          '🔧 [FIX] No single-entry gap found — user state is clean',
          name: 'ReadGapFix',
        );
        unawaited(
          getService<IAnalyticsService>().logCustomEvent(
            eventName: 'read_gap_fix_clean',
          ),
        );
        return;
      }

      developer.log(
        '🔧 [FIX] Single gap found at index $singleGapIndex — filling silently',
        name: 'ReadGapFix',
      );

      await _statsService.bulkMarkAsRead([singleGapId]);

      developer.log(
        '✅ [FIX] Read gap fix complete: 1 entry marked as read (index $singleGapIndex)',
        name: 'ReadGapFix',
      );

      unawaited(
        getService<IAnalyticsService>().logCustomEvent(
          eventName: 'read_gap_fix_applied',
          parameters: {
            'gaps_filled': 1,
            'gap_index': singleGapIndex,
          },
        ),
      );
    } catch (e, stack) {
      // Fix is non-critical — log and continue. Never block app start.
      developer.log(
        '❌ [FIX] Error during read gap fix: $e',
        name: 'ReadGapFix',
        error: e,
      );
      FirebaseCrashlytics.instance.recordError(
        e,
        stack,
        fatal: false,
        reason: 'Read gap fix failed',
      );
    }
  }
}
