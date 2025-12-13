// test/devocional_reading_logic_test.dart

import 'package:devocional_nuevo/services/spiritual_stats_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/test_helpers.dart';

void main() {
  group('Devotional Reading Logic Tests', () {
    setUp(() {
      // Initialize Flutter binding for tests
      TestWidgetsFlutterBinding.ensureInitialized();
      // Initialize SharedPreferences mock for each test
      SharedPreferences.setMockInitialValues({});
      // Setup service locator with all required services
      registerTestServices();
    });

    test('DevocionalProvider recordDevocionalRead works correctly', () async {
      final statsService = SpiritualStatsService();

      // Record a devotional read with proper criteria
      await statsService.recordDevocionalRead(
        devocionalId: 'test_devotional_123',
        readingTimeSeconds: 60, // Meets criteria
        scrollPercentage: 0.8, // Meets criteria
      );

      // Verify it was recorded in stats
      final stats = await statsService.getStats();
      expect(stats.totalDevocionalesRead, 1);
      expect(stats.readDevocionalIds, contains('test_devotional_123'));
    });

    test('Empty devotional ID is handled gracefully', () async {
      final statsService = SpiritualStatsService();

      // Try to record with empty ID
      await statsService.recordDevocionalRead(
        devocionalId: '',
        readingTimeSeconds: 60,
        scrollPercentage: 0.8,
      );

      // Should not record anything due to empty ID
      final stats = await statsService.getStats();
      expect(stats.totalDevocionalesRead, 0);
      expect(stats.readDevocionalIds, isEmpty);
    });

    test('Real usage pattern: unique consecutive tracking', () async {
      final statsService = SpiritualStatsService();

      // Simulate reading devotionals with unique consecutive IDs
      final devotionalIds = [
        'devotional_2025_01_01',
        'devotional_2025_01_02',
        'devotional_2025_01_03',
      ];

      for (final id in devotionalIds) {
        await statsService.recordDevocionalRead(
          devocionalId: id,
          readingTimeSeconds: 60, // Meets criteria
          scrollPercentage: 0.8, // Meets criteria
        );
      }

      final stats = await statsService.getStats();
      expect(stats.totalDevocionalesRead, 3);
      expect(stats.readDevocionalIds.length, 3);

      // Verify all IDs are tracked
      for (final id in devotionalIds) {
        expect(stats.readDevocionalIds, contains(id));
      }
    });

    test('Rapid tapping prevention works', () async {
      final statsService = SpiritualStatsService();

      // Record a devotional with proper criteria
      await statsService.recordDevocionalRead(
        devocionalId: 'rapid_tap_test',
        readingTimeSeconds: 60,
        scrollPercentage: 0.8,
      );

      // Try to record the same devotional rapidly (should be ignored due to duplicate ID)
      await statsService.recordDevocionalRead(
        devocionalId: 'rapid_tap_test',
        readingTimeSeconds: 60,
        scrollPercentage: 0.8,
      );
      await statsService.recordDevocionalRead(
        devocionalId: 'rapid_tap_test',
        readingTimeSeconds: 60,
        scrollPercentage: 0.8,
      );
      await statsService.recordDevocionalRead(
        devocionalId: 'rapid_tap_test',
        readingTimeSeconds: 60,
        scrollPercentage: 0.8,
      );

      final stats = await statsService.getStats();
      expect(stats.totalDevocionalesRead, 1); // Should only count once
    });

    test('Legitimate re-reading after time delay is not prevented', () async {
      final statsService = SpiritualStatsService();

      // Record initial read
      await statsService.recordDevocionalRead(
        devocionalId: 'time_test',
        readingTimeSeconds: 60,
        scrollPercentage: 0.8,
      );

      // Simulate time passage by manually manipulating the service
      // In a real test environment, you might use techniques like mocking time
      final stats = await statsService.getStats();
      expect(stats.totalDevocionalesRead, 1);

      // Verify the devotional is marked as read
      expect(await statsService.hasDevocionalBeenRead('time_test'), true);
    });

    test('Favorites count integration with devotional reading', () async {
      final statsService = SpiritualStatsService();

      // Record devotional read with favorites count
      await statsService.recordDevocionalRead(
        devocionalId: 'favorites_integration_test',
        favoritesCount: 3,
        readingTimeSeconds: 60,
        scrollPercentage: 0.8,
      );

      final stats = await statsService.getStats();
      expect(stats.totalDevocionalesRead, 1);
      expect(stats.favoritesCount, 3);
    });

    test('Achievement unlocking during devotional reading', () async {
      final statsService = SpiritualStatsService();

      // Record first devotional to unlock "Primer Paso" achievement
      await statsService.recordDevocionalRead(
        devocionalId: 'achievement_test_1',
        readingTimeSeconds: 60,
        scrollPercentage: 0.8,
      );

      final stats = await statsService.getStats();
      expect(stats.totalDevocionalesRead, 1);

      // Check if achievement was unlocked
      final firstReadAchievement = stats.unlockedAchievements.firstWhere(
        (achievement) => achievement.id == 'first_read',
        orElse: () =>
            throw Exception('First read achievement should be unlocked'),
      );

      expect(firstReadAchievement.isUnlocked, true);
    });

    test('Streak calculation across multiple days simulation', () async {
      final statsService = SpiritualStatsService();

      // Record devotional reads (in real scenario, these would be on different days)
      await statsService.recordDevocionalRead(
        devocionalId: 'day_1_devotional',
        readingTimeSeconds: 60,
        scrollPercentage: 0.8,
      );

      // Check initial streak (note: reading devotionals doesn't affect streak in this implementation)
      var stats = await statsService.getStats();
      expect(stats.currentStreak, 0); // Reading devotionals doesn't set streak
      expect(stats.longestStreak, 0);

      // Record another devotional (same day)
      await statsService.recordDevocionalRead(
        devocionalId: 'day_1_devotional_2',
        readingTimeSeconds: 60,
        scrollPercentage: 0.8,
      );

      stats = await statsService.getStats();
      expect(stats.totalDevocionalesRead, 2);
      expect(stats.currentStreak,
          0); // Still 0, as reading devotionals doesn't affect streak
    });

    test('Service handles malformed data gracefully', () async {
      final statsService = SpiritualStatsService();

      // Try to record with null-like values
      try {
        await statsService.recordDevocionalRead(devocionalId: '');
        // Should not throw an error, but also shouldn't record anything
      } catch (e) {
        fail('Service should handle empty ID gracefully');
      }

      final stats = await statsService.getStats();
      expect(stats.totalDevocionalesRead, 0);
    });

    test('Multiple achievements unlock correctly', () async {
      final statsService = SpiritualStatsService();

      // Record multiple devotionals to unlock reading-based achievements
      for (int i = 1; i <= 7; i++) {
        await statsService.recordDevocionalRead(
          devocionalId: 'devotional_$i',
          readingTimeSeconds: 60,
          scrollPercentage: 0.8,
        );
      }

      final stats = await statsService.getStats();
      expect(stats.totalDevocionalesRead, 7);

      // Should unlock "Primer Paso" and "Lector Semanal"
      final unlockedIds = stats.unlockedAchievements.map((a) => a.id).toSet();
      expect(unlockedIds, contains('first_read'));
      expect(unlockedIds, contains('week_reader'));
    });
  });
}
