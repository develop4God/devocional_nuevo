@Tags(['unit', 'utils'])
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Regression guard for the SpiritualStatsService concurrency fix.
///
/// Every mutating method on SpiritualStatsService wraps its own
/// getStats()+saveStats() cycle in a shared static Lock. A caller outside
/// the service that does its own getStats()+saveStats() (or a bare
/// saveStats()) bypasses that lock entirely and can silently drop a
/// concurrent update -- this is exactly the bug SupporterPage used to have
/// before it was migrated to call unlockAchievement() instead.
///
/// ISpiritualStatsService still exposes saveStats() publicly (a broader
/// interface change was deliberately deferred), so nothing in the type
/// system stops this from happening again. This test scans lib/ so a new
/// occurrence fails CI instead of shipping silently.
void main() {
  group('Migration Safety Tests - No External saveStats() Calls', () {
    test(
      'no file outside spiritual_stats_service.dart calls .saveStats(',
      () async {
        final libDir = Directory('lib');
        final offenders = <String>[];

        await for (final entity in libDir.list(recursive: true)) {
          if (entity is! File || !entity.path.endsWith('.dart')) continue;
          if (entity.path.endsWith('spiritual_stats_service.dart')) continue;

          final content = await entity.readAsString();
          if (content.contains('.saveStats(')) {
            offenders.add(entity.path);
          }
        }

        expect(
          offenders,
          isEmpty,
          reason:
              'saveStats() must only be called from within SpiritualStatsService\'s '
              'own locked methods -- found direct calls in: $offenders. '
              'Use one of the service\'s existing locked mutators (or add a new '
              'one) instead of reading/modifying/saving stats externally.',
        );
      },
    );
  });
}
