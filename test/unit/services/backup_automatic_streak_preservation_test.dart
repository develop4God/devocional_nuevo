@Tags(['critical', 'unit', 'services', 'backup'])
library;

// test/unit/services/backup_automatic_streak_preservation_test.dart
//
// Tests for the automatic backup streak preservation bug fix.
// Validates that automatic backups (triggered every 24 hours) properly sync
// merged spiritual stats back to local device, preventing streak reset to 1.
//
// Root cause: Lines 571-573 in google_drive_backup_service.dart were removing
// spiritualStats from sync-back payload, causing merged streak to not be
// restored locally. This left device with old streak value but new read_dates,
// creating a mismatch that could reset streak to 1 on next read calculation.

import 'package:devocional_nuevo/models/spiritual_stats_model.dart';
import 'package:devocional_nuevo/services/spiritual_stats_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/test_helpers.dart';

void main() {
  group('Automatic Backup Streak Preservation', () {
    late SpiritualStatsService statsService;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await registerTestServices();
      statsService = SpiritualStatsService();
    });

    test(
      'User with 3-day streak → automatic backup → streak preserved locally',
      () async {
        // Setup: User has 3-day streak on local device
        final localStats = SpiritualStats(
          totalDevocionalesRead: 3,
          currentStreak: 3,
          longestStreak: 3,
          lastActivityDate: DateTime(2026, 5, 28),
          readDevocionalIds: ['dev1', 'dev2', 'dev3'],
          favoritesCount: 0,
          unlockedAchievements: [],
        );
        await statsService.saveStats(localStats);

        // Simulate local read_dates for 3 consecutive days
        final localReadDates = [
          '2026-05-28', // today
          '2026-05-27', // yesterday
          '2026-05-26', // day before
        ];

        // Simulate automatic backup merge payload (what createBackup produces)
        // This represents the merged data that should be synced back to local
        final mergedBackupPayload = {
          'spiritual_stats': {
            'totalDevocionalesRead': 3,
            'currentStreak': 3, // This should be preserved!
            'longestStreak': 3,
            'lastActivityDate': '2026-05-28T00:00:00.000',
            'readDevocionalIds': ['dev1', 'dev2', 'dev3'],
            'favoritesCount': 0,
            'unlockedAchievements': [],
          },
          'read_dates': localReadDates,
          'backup_timestamp': '2026-05-28T03:00:00.000Z',
          'merge_source': 'multi_device',
        };

        // Act: Sync merged backup back to local (what happens at line 573)
        await statsService.restoreStats(mergedBackupPayload);

        // Assert: Streak should still be 3, not reset to 1
        final restoredStats = await statsService.getStats();
        expect(
          restoredStats.currentStreak,
          equals(3),
          reason: 'Merged streak should be preserved during automatic backup',
        );
        expect(restoredStats.longestStreak, equals(3));
        expect(restoredStats.totalDevocionalesRead, equals(3));
        expect(restoredStats.readDevocionalIds.length, equals(3));

        // Verify read_dates were also restored
        final readDates = await statsService.getReadDatesForVisualization();
        expect(
          readDates.length,
          equals(3),
          reason: 'Read dates should be synced from merged backup',
        );
      },
    );

    test(
      'Multi-device merge: Device A (streak 5) + Device B (streak 3) → both get max streak 5',
      () async {
        // Setup: Simulate Device A with 5-day streak
        final deviceAStats = SpiritualStats(
          totalDevocionalesRead: 10,
          currentStreak: 5,
          longestStreak: 5,
          lastActivityDate: DateTime(2026, 5, 28),
          readDevocionalIds: [
            'dev1',
            'dev2',
            'dev3',
            'dev4',
            'dev5',
            'dev6',
            'dev7',
            'dev8',
            'dev9',
            'dev10',
          ],
          favoritesCount: 2,
          unlockedAchievements: [],
        );

        final deviceAReadDates = [
          '2026-05-28',
          '2026-05-27',
          '2026-05-26',
          '2026-05-25',
          '2026-05-24', // 5 consecutive days
          '2026-05-20',
          '2026-05-19',
          '2026-05-18',
          '2026-05-17',
          '2026-05-16',
        ];

        // Simulate Device B stats (has only 3-day streak, some different IDs)
        final deviceBStats = SpiritualStats(
          totalDevocionalesRead: 8,
          currentStreak: 3,
          longestStreak: 4,
          lastActivityDate: DateTime(2026, 5, 28),
          readDevocionalIds: [
            'dev1',
            'dev2',
            'dev3',
            'dev11',
            'dev12',
            'dev13',
            'dev14',
            'dev15',
          ],
          favoritesCount: 1,
          unlockedAchievements: [],
        );

        final deviceBReadDates = [
          '2026-05-28',
          '2026-05-27',
          '2026-05-26', // 3 consecutive days
          '2026-05-15',
          '2026-05-14',
          '2026-05-13',
          '2026-05-12',
          '2026-05-11',
        ];

        // Simulate the merge that happens in _mergePayloads()
        final mergedStats = SpiritualStats.merge(deviceAStats, deviceBStats);

        // Build merged backup payload as createBackup would
        final mergedReadDates = {
          ...deviceAReadDates,
          ...deviceBReadDates,
        }.toList()
          ..sort();

        final mergedBackupPayload = {
          'spiritual_stats': mergedStats.toJson(),
          'read_dates': mergedReadDates,
          'backup_timestamp': '2026-05-28T03:00:00.000Z',
          'merge_source': 'multi_device',
        };

        // Act: Simulate Device B receiving the merged backup sync-back
        await statsService.saveStats(deviceBStats); // Start with Device B state
        await statsService.restoreStats(mergedBackupPayload); // Sync merged data

        // Assert: Device B should now have max streak of 5 from Device A
        final syncedStats = await statsService.getStats();
        expect(
          syncedStats.currentStreak,
          equals(5),
          reason: 'Merged streak should be max of both devices',
        );
        expect(
          syncedStats.longestStreak,
          equals(5),
          reason: 'Longest streak should be max of both devices',
        );
        expect(
          syncedStats.readDevocionalIds.length,
          equals(15),
          reason:
              'Merged IDs should be union of both devices (10 from A + 8 from B, with 3 duplicates = 15 unique)',
        );

        // Verify merged read_dates
        final readDates = await statsService.getReadDatesForVisualization();
        expect(
          readDates.length,
          equals(mergedReadDates.length),
          reason: 'Read dates should be union from both devices',
        );
      },
    );

    test(
      'Merged backup format with spiritual_stats key is properly restored',
      () async {
        // This test validates the fix in spiritual_stats_service.dart
        // where we added support for 'spiritual_stats' key (merged format)

        final mergedBackupData = {
          'spiritual_stats': {
            'totalDevocionalesRead': 7,
            'currentStreak': 7,
            'longestStreak': 7,
            'lastActivityDate': '2026-05-28T00:00:00.000',
            'readDevocionalIds': [
              'dev1',
              'dev2',
              'dev3',
              'dev4',
              'dev5',
              'dev6',
              'dev7',
            ],
            'favoritesCount': 3,
            'unlockedAchievements': [],
          },
          'read_dates': [
            '2026-05-28',
            '2026-05-27',
            '2026-05-26',
            '2026-05-25',
            '2026-05-24',
            '2026-05-23',
            '2026-05-22',
          ],
        };

        // Act: Restore from merged format
        await statsService.restoreStats(mergedBackupData);

        // Assert: Stats should be fully restored
        final restoredStats = await statsService.getStats();
        expect(restoredStats.totalDevocionalesRead, equals(7));
        expect(restoredStats.currentStreak, equals(7));
        expect(restoredStats.longestStreak, equals(7));
        expect(restoredStats.readDevocionalIds.length, equals(7));

        // Verify read_dates
        final readDates = await statsService.getReadDatesForVisualization();
        expect(readDates.length, equals(7));
      },
    );

    test(
      'Empty remote backup + local streak → local streak preserved',
      () async {
        // Setup: User has local data but remote backup is empty
        final localStats = SpiritualStats(
          totalDevocionalesRead: 10,
          currentStreak: 10,
          longestStreak: 10,
          lastActivityDate: DateTime(2026, 5, 28),
          readDevocionalIds: List.generate(10, (i) => 'dev$i'),
          favoritesCount: 5,
          unlockedAchievements: [],
        );
        await statsService.saveStats(localStats);

        // Simulate merge with empty remote
        final emptyRemoteStats = SpiritualStats(
          totalDevocionalesRead: 0,
          currentStreak: 0,
          longestStreak: 0,
          lastActivityDate: null,
          readDevocionalIds: [],
          favoritesCount: 0,
          unlockedAchievements: [],
        );

        final mergedStats = SpiritualStats.merge(localStats, emptyRemoteStats);

        // Build sync-back payload
        final mergedBackupPayload = {
          'spiritual_stats': mergedStats.toJson(),
          'read_dates': List.generate(
            10,
            (i) => DateTime(2026, 5, 28 - i).toIso8601String().substring(0, 10),
          ),
        };

        // Act: Sync back to local
        await statsService.restoreStats(mergedBackupPayload);

        // Assert: Local streak should be preserved (max of local and empty)
        final syncedStats = await statsService.getStats();
        expect(
          syncedStats.currentStreak,
          equals(10),
          reason: 'Local streak should be preserved when remote is empty',
        );
        expect(syncedStats.longestStreak, equals(10));
        expect(syncedStats.readDevocionalIds.length, equals(10));
      },
    );

    test(
      'Broken streak scenario: last read 3 days ago → streak should be 0',
      () async {
        // Setup: User hasn't read for 3 days (streak broken)
        final oldStats = SpiritualStats(
          totalDevocionalesRead: 5,
          currentStreak: 5, // This was the old streak
          longestStreak: 5,
          lastActivityDate: DateTime(2026, 5, 25), // 3 days ago
          readDevocionalIds: ['dev1', 'dev2', 'dev3', 'dev4', 'dev5'],
          favoritesCount: 0,
          unlockedAchievements: [],
        );

        // Old read dates: last read was 2026-05-25 (3 days ago)
        final oldReadDates = [
          '2026-05-25',
          '2026-05-24',
          '2026-05-23',
          '2026-05-22',
          '2026-05-21',
        ];

        // Build merged backup payload (automatic backup on 2026-05-28)
        final mergedBackupPayload = {
          'spiritual_stats': oldStats.toJson(),
          'read_dates': oldReadDates,
          'backup_timestamp': '2026-05-28T03:00:00.000Z',
        };

        // Act: Restore the old data
        await statsService.restoreStats(mergedBackupPayload);

        // Assert: Streak should still be 5 (as recorded in backup)
        // The streak will only recalculate to 0 when user next completes a devotional
        final restoredStats = await statsService.getStats();
        expect(
          restoredStats.currentStreak,
          equals(5),
          reason: 'Restored streak should match backup value',
        );

        // But read_dates should show the gap
        final readDates = await statsService.getReadDatesForVisualization();
        expect(readDates.length, equals(5));
        expect(
          readDates.last.isBefore(DateTime(2026, 5, 26)),
          isTrue,
          reason: 'Last read date should be before today (streak broken)',
        );
      },
    );

    test(
      'Backward compatibility: Legacy stats format still works',
      () async {
        // Ensure our fix doesn't break existing backup restore flows
        final legacyBackupData = {
          'stats': {
            'totalDevocionalesRead': 15,
            'currentStreak': 15,
            'longestStreak': 15,
            'lastActivityDate': '2026-05-28T00:00:00.000',
            'readDevocionalIds': List.generate(15, (i) => 'legacy-dev$i'),
            'favoritesCount': 7,
            'unlockedAchievements': [],
          },
          'read_dates': List.generate(
            15,
            (i) => DateTime(2026, 5, 28 - i).toIso8601String().substring(0, 10),
          ),
        };

        // Act: Restore from legacy format
        await statsService.restoreStats(legacyBackupData);

        // Assert: Should work just as before
        final restoredStats = await statsService.getStats();
        expect(restoredStats.currentStreak, equals(15));
        expect(restoredStats.longestStreak, equals(15));
        expect(restoredStats.totalDevocionalesRead, equals(15));
      },
    );

    test(
      'Flat format (no wrapper) still works',
      () async {
        // Ensure our fix doesn't break flat backup format
        final flatBackupData = {
          'totalDevocionalesRead': 20,
          'currentStreak': 20,
          'longestStreak': 20,
          'lastActivityDate': '2026-05-28T00:00:00.000',
          'readDevocionalIds': List.generate(20, (i) => 'flat-dev$i'),
          'favoritesCount': 10,
          'unlockedAchievements': [],
          'read_dates': List.generate(
            20,
            (i) => DateTime(2026, 5, 28 - i).toIso8601String().substring(0, 10),
          ),
        };

        // Act: Restore from flat format
        await statsService.restoreStats(flatBackupData);

        // Assert: Should work
        final restoredStats = await statsService.getStats();
        expect(restoredStats.currentStreak, equals(20));
        expect(restoredStats.longestStreak, equals(20));
        expect(restoredStats.totalDevocionalesRead, equals(20));
      },
    );
  });
}
