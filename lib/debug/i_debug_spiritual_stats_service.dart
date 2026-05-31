// lib/debug/i_debug_spiritual_stats_service.dart
//
// Segregated interface for debug-only spiritual stats capabilities.
// Extends [ISpiritualStatsService] so the concrete [SpiritualStatsService]
// satisfies both contracts through a single implementation.
//
// ISP — production code depends only on [ISpiritualStatsService].
//        Debug widgets depend on this narrower extension.
// OCP — future debug methods are added here, never to the production interface.

import '../models/spiritual_stats_model.dart';
import '../services/i_spiritual_stats_service.dart';

/// Debug-only extension of [ISpiritualStatsService].
///
/// Only [DebugStreakSection] (and other debug widgets) should depend on this
/// interface.  Production fakes implement [ISpiritualStatsService] only —
/// they never need to stub debug operations.
abstract class IDebugSpiritualStatsService implements ISpiritualStatsService {
  /// Add one synthetic read-date to extend the current streak by 1 day.
  ///
  /// Inserts the date immediately before the oldest date in the active streak,
  /// recalculates the streak value, and persists the updated [SpiritualStats].
  /// Idempotent per call — each invocation extends the streak by exactly 1.
  Future<SpiritualStats> addStreakDay();
}
