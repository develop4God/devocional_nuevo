@Tags(['critical', 'unit', 'services'])
library;

import 'package:devocional_nuevo/services/spiritual_stats_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/test_helpers.dart';

void main() {
  group('SpiritualStatsService.restoreStats() — Backup Format Handling', () {
    late SpiritualStatsService statsService;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await registerTestServices();
      statsService = SpiritualStatsService();
    });

    test('should restore from FLAT backup format (no stats wrapper)', () async {
      // Simulate flat backup format: SpiritualStats.toJson() fields directly
      final flatBackupData = {
        'totalDevocionalesRead': 248,
        'currentStreak': 1,
        'longestStreak': 15,
        'lastActivityDate': '2026-05-23T15:30:00.000Z',
        'unlockedAchievements': [],
        'favoritesCount': 5,
        'readDevocionalIds': [
          'dev1',
          'dev2',
          'dev3',
          'dev4',
          'dev5',
        ].asMap().entries.map((e) => 'id-${e.value}').toList(),
        'read_dates': ['2026-05-23', '2026-05-22', '2026-05-21'],
      };

      // Restore from flat format
      await statsService.restoreStats(flatBackupData);

      // Verify stats were restored correctly
      final restoredStats = await statsService.getStats();
      expect(restoredStats.totalDevocionalesRead, equals(248));
      expect(restoredStats.currentStreak, equals(1));
      expect(restoredStats.longestStreak, equals(15));
      expect(restoredStats.favoritesCount, equals(5));
      expect(restoredStats.readDevocionalIds.length, equals(5));

      // Verify read dates were restored
      final readDates = await statsService.getReadDatesForVisualization();
      expect(readDates.length, equals(3));
    });

    test('should restore from LEGACY wrapped format (stats key)', () async {
      // Simulate legacy format: wrapped under 'stats' key
      final legacyBackupData = {
        'exported_at': '2026-05-23T15:30:00.000Z',
        'app_version': '1.0.0',
        'stats': {
          'totalDevocionalesRead': 100,
          'currentStreak': 7,
          'longestStreak': 30,
          'lastActivityDate': '2026-05-23T15:30:00.000Z',
          'unlockedAchievements': [],
          'favoritesCount': 12,
          'readDevocionalIds': List.generate(100, (i) => 'legacy-id-$i'),
        },
        'read_dates': [
          '2026-05-23',
          '2026-05-22',
          '2026-05-21',
          '2026-05-20',
          '2026-05-19',
          '2026-05-18',
          '2026-05-17',
        ],
      };

      // Restore from legacy format
      await statsService.restoreStats(legacyBackupData);

      // Verify stats were restored correctly
      final restoredStats = await statsService.getStats();
      expect(restoredStats.totalDevocionalesRead, equals(100));
      expect(restoredStats.currentStreak, equals(7));
      expect(restoredStats.longestStreak, equals(30));
      expect(restoredStats.favoritesCount, equals(12));
      expect(restoredStats.readDevocionalIds.length, equals(100));

      // Verify read dates were restored
      final readDates = await statsService.getReadDatesForVisualization();
      expect(readDates.length, equals(7));
    });

    test(
      'should skip stats if neither format is present (graceful no-op)',
      () async {
        // Save initial stats
        final initialStats = await statsService.getStats();
        expect(initialStats.totalDevocionalesRead, equals(0));

        // Try to restore from invalid backup (no stats, no totalDevocionalesRead)
        final invalidBackupData = {
          'random_field': 'value',
          'another_field': 123,
        };

        // Should not throw, just skip
        await statsService.restoreStats(invalidBackupData);

        // Stats should remain unchanged
        final stillEmpty = await statsService.getStats();
        expect(stillEmpty.totalDevocionalesRead, equals(0));
      },
    );

    test('should handle read_dates even if stats are missing', () async {
      final backupWithOnlyDates = {
        'read_dates': ['2026-05-20', '2026-05-19', '2026-05-18'],
      };

      // Restore (skip stats, but restore dates)
      await statsService.restoreStats(backupWithOnlyDates);

      // Verify read dates were restored even without stats
      final readDates = await statsService.getReadDatesForVisualization();
      expect(readDates.length, equals(3));
    });

    test(
      'should call saveStats() so JSON backup side-effect is preserved',
      () async {
        // Enable JSON backup
        await statsService.setJsonBackupEnabled(true);

        final flatBackupData = {
          'totalDevocionalesRead': 50,
          'currentStreak': 5,
          'longestStreak': 10,
          'lastActivityDate': '2026-05-23T15:30:00.000Z',
          'unlockedAchievements': [],
          'favoritesCount': 3,
          'readDevocionalIds': List.generate(50, (i) => 'id-$i'),
          'read_dates': ['2026-05-23', '2026-05-22'],
        };

        // Restore from backup — this should call saveStats() internally
        await statsService.restoreStats(flatBackupData);

        // Verify stats were persisted (backup JSON is created by saveStats())
        final restoredStats = await statsService.getStats();
        expect(restoredStats.totalDevocionalesRead, equals(50));

        // Verify that JSON backup was created (side-effect of saveStats())
        final backupPath = await statsService.getBackupFilePath();
        expect(backupPath, isNotNull);
      },
    );

    test('should rethrow exceptions after logging', () async {
      final invalidData = {
        'stats': 'not-a-map', // Invalid: string instead of map
      };

      expect(
        () => statsService.restoreStats(invalidData),
        throwsA(isA<TypeError>()),
      );
    });

    test('should restore full backup with all fields populated', () async {
      final completeBackup = {
        'totalDevocionalesRead': 248,
        'currentStreak': 1,
        'longestStreak': 15,
        'lastActivityDate': '2026-05-23T10:00:00.000Z',
        'unlockedAchievements': [],
        'favoritesCount': 8,
        'readDevocionalIds': List.generate(248, (i) => 'devocional-$i'),
        'read_dates': List.generate(
          20,
          (i) => DateTime(2026, 5, 24 - i).toIso8601String().split('T').first,
        ),
      };

      await statsService.restoreStats(completeBackup);

      final restored = await statsService.getStats();
      expect(restored.totalDevocionalesRead, equals(248));
      expect(restored.readDevocionalIds.length, equals(248));
      expect(restored.currentStreak, equals(1));
      expect(restored.longestStreak, equals(15));
      expect(restored.favoritesCount, equals(8));

      final readDates = await statsService.getReadDatesForVisualization();
      expect(readDates.length, equals(20));
    });
  });
}
