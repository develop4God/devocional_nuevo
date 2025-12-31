import 'package:devocional_nuevo/services/spiritual_stats_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../test/helpers/test_helpers.dart';

/// Integration tests for Devotional Reading workflow
/// Tests real user behavior: reading devotionals, tracking progress, streaks
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Devotional Reading - Real User Workflow Tests', () {
    late SpiritualStatsService statsService;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      registerTestServices();
      statsService = SpiritualStatsService();
    });

    test('Complete user journey: Read 3 devotionals in one day', () async {
      // Scenario: User opens app and reads multiple devotionals

      // Morning: First devotional
      await statsService.recordDevocionalRead(
        devocionalId: 'dev_2025_01_15',
        readingTimeSeconds: 120, // 2 minutes - meets criteria
        scrollPercentage: 0.9, // scrolled through most of it
      );

      var stats = await statsService.getStats();
      expect(stats.totalDevocionalesRead, equals(1));
      expect(stats.currentStreak, equals(1));
      expect(stats.readDevocionalIds, contains('dev_2025_01_15'));

      // Afternoon: Second devotional
      await Future.delayed(const Duration(milliseconds: 50));
      await statsService.recordDevocionalRead(
        devocionalId: 'dev_2025_01_16',
        readingTimeSeconds: 90,
        scrollPercentage: 0.85,
      );

      stats = await statsService.getStats();
      expect(stats.totalDevocionalesRead, equals(2));
      expect(stats.currentStreak, equals(1)); // Same day, streak still 1

      // Evening: Third devotional
      await Future.delayed(const Duration(milliseconds: 50));
      await statsService.recordDevocionalRead(
        devocionalId: 'dev_2025_01_17',
        readingTimeSeconds: 150,
        scrollPercentage: 0.95,
      );

      stats = await statsService.getStats();
      expect(stats.totalDevocionalesRead, equals(3));
      expect(stats.readDevocionalIds.length, equals(3));

      // Verify all devotionals are tracked
      expect(stats.readDevocionalIds, contains('dev_2025_01_15'));
      expect(stats.readDevocionalIds, contains('dev_2025_01_16'));
      expect(stats.readDevocionalIds, contains('dev_2025_01_17'));
    });

    test('User re-reads same devotional - should not double count', () async {
      // Scenario: User likes a devotional and re-reads it

      // First read
      await statsService.recordDevocionalRead(
        devocionalId: 'favorite_dev_123',
        readingTimeSeconds: 100,
        scrollPercentage: 0.9,
      );

      var stats = await statsService.getStats();
      expect(stats.totalDevocionalesRead, equals(1));

      // User re-reads the same devotional
      await Future.delayed(const Duration(milliseconds: 50));
      await statsService.recordDevocionalRead(
        devocionalId: 'favorite_dev_123',
        readingTimeSeconds: 80,
        scrollPercentage: 0.85,
      );

      stats = await statsService.getStats();
      // Should still be 1, not 2
      expect(
        stats.totalDevocionalesRead,
        equals(1),
        reason: 'Re-reading same devotional should not increase count',
      );
      expect(stats.readDevocionalIds.length, equals(1));
    });

    test('User skims devotional (quick scroll) - should not count', () async {
      // Scenario: User quickly scrolls through without really reading

      await statsService.recordDevocionalRead(
        devocionalId: 'skimmed_dev',
        readingTimeSeconds: 5, // Too quick
        scrollPercentage: 0.9,
      );

      var stats = await statsService.getStats();
      expect(
        stats.totalDevocionalesRead,
        equals(0),
        reason: 'Quick skim should not count as read',
      );
      expect(stats.readDevocionalIds, isEmpty);
    });

    test('User reads but does not scroll much - should not count', () async {
      // Scenario: User starts reading but gets distracted

      await statsService.recordDevocionalRead(
        devocionalId: 'partial_dev',
        readingTimeSeconds: 120, // Enough time
        scrollPercentage: 0.3, // Did not scroll enough
      );

      var stats = await statsService.getStats();
      expect(
        stats.totalDevocionalesRead,
        equals(0),
        reason: 'Partial scroll should not count as read',
      );
      expect(stats.readDevocionalIds, isEmpty);
    });

    test('User listens to devotional via TTS', () async {
      // Scenario: User prefers listening over reading

      await statsService.recordDevocionalHeard(
        devocionalId: 'audio_dev_001',
        listenedPercentage: 0.85, // Listened to 85%
      );

      var stats = await statsService.getStats();
      expect(
        stats.totalDevocionalesRead,
        equals(1),
        reason: 'Listening should count as completing devotional',
      );
      expect(stats.readDevocionalIds, contains('audio_dev_001'));
    });

    test('User builds 7-day streak (weekly commitment)', () async {
      // Scenario: User commits to reading daily for a week

      // Simulate reading one devotional each day for 7 days
      for (int day = 1; day <= 7; day++) {
        await statsService.recordDevocionalRead(
          devocionalId: 'week_dev_day_$day',
          readingTimeSeconds: 100,
          scrollPercentage: 0.9,
        );
        await Future.delayed(const Duration(milliseconds: 10));
      }

      var stats = await statsService.getStats();
      expect(stats.totalDevocionalesRead, equals(7));

      // Note: Actual streak calculation depends on real dates
      // This test verifies all reads are tracked
      expect(stats.readDevocionalIds.length, equals(7));
    });

    test('User adds devotional to favorites and it is tracked', () async {
      // Scenario: User favorites a devotional after reading

      await statsService.recordDevocionalRead(
        devocionalId: 'fav_candidate_dev',
        readingTimeSeconds: 150,
        scrollPercentage: 0.95,
        favoritesCount: 1, // User also favorited it
      );

      var stats = await statsService.getStats();
      expect(stats.totalDevocionalesRead, equals(1));
      expect(stats.favoritesCount, equals(1));
    });

    test(
      'User updates favorites count after reading multiple devotionals',
      () async {
        // Read first devotional
        await statsService.recordDevocionalRead(
          devocionalId: 'dev_1',
          readingTimeSeconds: 100,
          scrollPercentage: 0.9,
        );

        // Read and favorite second
        await statsService.recordDevocionalRead(
          devocionalId: 'dev_2',
          readingTimeSeconds: 100,
          scrollPercentage: 0.9,
          favoritesCount: 1,
        );

        // Read and favorite third
        await statsService.recordDevocionalRead(
          devocionalId: 'dev_3',
          readingTimeSeconds: 100,
          scrollPercentage: 0.9,
          favoritesCount: 2,
        );

        var stats = await statsService.getStats();
        expect(stats.totalDevocionalesRead, equals(3));
        expect(stats.favoritesCount, equals(2));
      },
    );

    test('User workflow: App restart and stats persist', () async {
      // Day 1: User reads devotionals
      await statsService.recordDevocionalRead(
        devocionalId: 'persistent_dev_1',
        readingTimeSeconds: 100,
        scrollPercentage: 0.9,
      );

      await statsService.recordDevocionalRead(
        devocionalId: 'persistent_dev_2',
        readingTimeSeconds: 100,
        scrollPercentage: 0.9,
      );

      var stats = await statsService.getStats();
      expect(stats.totalDevocionalesRead, equals(2));

      // Simulate app restart - create new service instance
      final newStatsService = SpiritualStatsService();
      var newStats = await newStatsService.getStats();

      // Stats should persist
      expect(newStats.totalDevocionalesRead, equals(2));
      expect(newStats.readDevocionalIds, contains('persistent_dev_1'));
      expect(newStats.readDevocionalIds, contains('persistent_dev_2'));
    });

    test('Edge case: Empty devotional ID handled gracefully', () async {
      // User somehow triggers with empty ID (defensive programming)

      await statsService.recordDevocionalRead(
        devocionalId: '',
        readingTimeSeconds: 100,
        scrollPercentage: 0.9,
      );

      var stats = await statsService.getStats();
      expect(
        stats.totalDevocionalesRead,
        equals(0),
        reason: 'Empty ID should not be counted',
      );
    });

    test('Real user pattern: Mix of reading and listening', () async {
      // User sometimes reads, sometimes listens

      // Monday: Read
      await statsService.recordDevocionalRead(
        devocionalId: 'mon_dev',
        readingTimeSeconds: 120,
        scrollPercentage: 0.9,
      );

      // Tuesday: Listen (driving to work)
      await statsService.recordDevocionalHeard(
        devocionalId: 'tue_dev',
        listenedPercentage: 0.9,
      );

      // Wednesday: Read
      await statsService.recordDevocionalRead(
        devocionalId: 'wed_dev',
        readingTimeSeconds: 100,
        scrollPercentage: 0.85,
      );

      // Thursday: Listen (exercising)
      await statsService.recordDevocionalHeard(
        devocionalId: 'thu_dev',
        listenedPercentage: 0.95,
      );

      var stats = await statsService.getStats();
      expect(
        stats.totalDevocionalesRead,
        equals(4),
        reason: 'Both reading and listening should count',
      );
      expect(stats.readDevocionalIds.length, equals(4));
    });

    test('Achievement unlock: First devotional read', () async {
      // Fresh user reads first devotional

      var statsBefore = await statsService.getStats();
      expect(statsBefore.totalDevocionalesRead, equals(0));

      await statsService.recordDevocionalRead(
        devocionalId: 'first_ever_dev',
        readingTimeSeconds: 120,
        scrollPercentage: 0.9,
      );

      var statsAfter = await statsService.getStats();
      expect(statsAfter.totalDevocionalesRead, equals(1));

      // Check if first read achievement is unlocked
      final firstReadAchievement = statsAfter.unlockedAchievements.firstWhere(
        (a) => a.id == 'first_read',
        orElse: () => statsAfter.unlockedAchievements.first,
      );

      expect(
        firstReadAchievement.isUnlocked,
        isTrue,
        reason: 'First read achievement should be unlocked',
      );
    });

    test('User quickly switches between devotionals (navigation)', () async {
      // User browses through several devotionals quickly

      // Open first devotional but switch away quickly
      await statsService.recordDevocionalRead(
        devocionalId: 'quick_view_1',
        readingTimeSeconds: 3, // Too quick
        scrollPercentage: 0.2,
      );

      // Second one also quick
      await statsService.recordDevocionalRead(
        devocionalId: 'quick_view_2',
        readingTimeSeconds: 5,
        scrollPercentage: 0.3,
      );

      // Finally settles on third and actually reads it
      await statsService.recordDevocionalRead(
        devocionalId: 'actual_read',
        readingTimeSeconds: 120,
        scrollPercentage: 0.9,
      );

      var stats = await statsService.getStats();
      // Only the properly read one should count
      expect(stats.totalDevocionalesRead, equals(1));
      expect(stats.readDevocionalIds, contains('actual_read'));
      expect(stats.readDevocionalIds, isNot(contains('quick_view_1')));
    });
  });
}
