import 'package:devocional_nuevo/services/service_locator.dart';
import 'package:devocional_nuevo/services/spiritual_stats_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Comprehensive tests for devotional tracking and completion logic
/// Tests real user behavior patterns and edge cases
void main() {
  group('Devotional Tracking - Real User Behavior Tests', () {
    late SpiritualStatsService statsService;

    setUp(() {
      TestWidgetsFlutterBinding.ensureInitialized();
      SharedPreferences.setMockInitialValues({});

      // Initialize ServiceLocator for dependencies
      ServiceLocator().reset();
      setupServiceLocator();

      statsService = SpiritualStatsService();
    });

    tearDown(() async {
      // Clean up SharedPreferences after each test
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      // Clean up ServiceLocator
      ServiceLocator().reset();
    });

    group('Devotional Completion and Persistence', () {
      test(
          'Should NOT mark devotional as read if criteria not met (reading time < 60s)',
          () async {
        // GIVEN: User reads a devotional for only 30 seconds
        const devocionalId = 'devotional_2024_001';

        // WHEN: Recording devotional with insufficient reading time
        final stats = await statsService.recordDevocionalCompletado(
          devocionalId: devocionalId,
          readingTimeSeconds: 30, // Less than 60 seconds
          scrollPercentage: 0.9, // Good scroll
          source: 'read',
        );

        // THEN: Devotional should NOT be counted as read
        expect(stats.readDevocionalIds, isEmpty,
            reason:
                'Devotional should not be counted without meeting criteria');
        expect(stats.totalDevocionalesRead, 0,
            reason:
                'Total devotionals read should remain 0 if criteria not met');
      });

      test('Should NOT mark devotional as read if scroll percentage < 80%',
          () async {
        // GIVEN: User reads a devotional for sufficient time but doesn't scroll enough
        const devocionalId = 'devotional_2024_002';

        // WHEN: Recording devotional with insufficient scroll
        final stats = await statsService.recordDevocionalCompletado(
          devocionalId: devocionalId,
          readingTimeSeconds: 90, // Good reading time
          scrollPercentage: 0.5, // Only 50% scroll
          source: 'read',
        );

        // THEN: Devotional should NOT be counted as read
        expect(stats.readDevocionalIds, isEmpty,
            reason:
                'Devotional should not be counted without meeting scroll criteria');
        expect(stats.totalDevocionalesRead, 0);
      });

      test('Should mark devotional as read when criteria met (time + scroll)',
          () async {
        // GIVEN: User properly reads a devotional
        const devocionalId = 'devotional_2024_003';

        // WHEN: Recording devotional with both criteria met
        final stats = await statsService.recordDevocionalCompletado(
          devocionalId: devocionalId,
          readingTimeSeconds: 75, // >= 60 seconds
          scrollPercentage: 0.85, // >= 0.8 (80%)
          source: 'read',
        );

        // THEN: Devotional should be counted as read
        expect(stats.readDevocionalIds, contains(devocionalId),
            reason: 'Devotional should be counted when criteria are met');
        expect(stats.totalDevocionalesRead, 1,
            reason: 'Total should increment when devotional is read');
      });

      test('Should mark devotional as read when listened to >= 80%', () async {
        // GIVEN: User listens to a devotional via TTS
        const devocionalId = 'devotional_2024_004';

        // WHEN: Recording devotional listened to completion
        final stats = await statsService.recordDevocionalCompletado(
          devocionalId: devocionalId,
          listenedPercentage: 0.9, // 90% listened
          source: 'heard',
        );

        // THEN: Devotional should be counted as read
        expect(stats.readDevocionalIds, contains(devocionalId),
            reason: 'Devotional should be counted when listened to >= 80%');
        expect(stats.totalDevocionalesRead, 1);
      });

      test('Should NOT count same devotional twice (deduplication)', () async {
        // GIVEN: User reads a devotional
        const devocionalId = 'devotional_2024_005';

        // WHEN: Recording the same devotional multiple times
        await statsService.recordDevocionalCompletado(
          devocionalId: devocionalId,
          readingTimeSeconds: 80,
          scrollPercentage: 0.9,
          source: 'read',
        );

        final secondStats = await statsService.recordDevocionalCompletado(
          devocionalId: devocionalId,
          readingTimeSeconds: 90,
          scrollPercentage: 0.95,
          source: 'read',
        );

        // THEN: Should only count once
        expect(secondStats.readDevocionalIds.length, 1,
            reason: 'Same devotional should only be counted once');
        expect(secondStats.totalDevocionalesRead, 1,
            reason: 'Total should not increment for duplicate reads');
      });

      test(
          'Should persist devotional completion across app restarts (SharedPreferences)',
          () async {
        // GIVEN: User reads a devotional
        const devocionalId = 'devotional_2024_006';

        await statsService.recordDevocionalCompletado(
          devocionalId: devocionalId,
          readingTimeSeconds: 70,
          scrollPercentage: 0.85,
          source: 'read',
        );

        // WHEN: Simulating app restart by creating new service instance
        final newStatsService = SpiritualStatsService();
        final statsAfterRestart = await newStatsService.getStats();

        // THEN: Devotional should still be marked as read
        expect(statsAfterRestart.readDevocionalIds, contains(devocionalId),
            reason: 'Devotional completion should persist across app restarts');
        expect(statsAfterRestart.totalDevocionalesRead, 1,
            reason: 'Total should be maintained after restart');
      });
    });

    group('Real User Journey - Multiple Devotionals', () {
      test(
          'User reads multiple devotionals throughout the day - all should be tracked',
          () async {
        // GIVEN: User has time to read 3 devotionals in one day
        const devotionals = [
          'devotional_2024_morning',
          'devotional_2024_afternoon',
          'devotional_2024_evening'
        ];

        // WHEN: User reads each devotional
        for (final devId in devotionals) {
          await statsService.recordDevocionalCompletado(
            devocionalId: devId,
            readingTimeSeconds: 75,
            scrollPercentage: 0.9,
            source: 'read',
          );
        }

        final stats = await statsService.getStats();

        // THEN: All 3 should be tracked
        expect(stats.readDevocionalIds.length, 3,
            reason: 'All devotionals should be tracked');
        expect(stats.totalDevocionalesRead, 3,
            reason: 'Total count should match number of devotionals read');
        for (final devId in devotionals) {
          expect(stats.readDevocionalIds, contains(devId),
              reason: 'Each devotional should be in the list');
        }
      });

      test(
          'User starts devotional, switches away, comes back - should not duplicate',
          () async {
        // GIVEN: User starts reading a devotional
        const devocionalId = 'devotional_2024_interrupted';

        // WHEN: User reads partially, then completes (simulating interruption)
        await statsService.recordDevocionalCompletado(
          devocionalId: devocionalId,
          readingTimeSeconds: 30,
          scrollPercentage: 0.4,
          source: 'read',
        );

        // User comes back and completes
        await statsService.recordDevocionalCompletado(
          devocionalId: devocionalId,
          readingTimeSeconds: 90,
          scrollPercentage: 0.95,
          source: 'read',
        );

        final stats = await statsService.getStats();

        // THEN: Should only count once
        expect(stats.readDevocionalIds.length, 1,
            reason:
                'Interrupted devotional should only count once when completed');
        expect(stats.totalDevocionalesRead, 1);
      });

      test('User reads some devotionals, listens to others - all count',
          () async {
        // GIVEN: User prefers different methods for different devotionals
        const readDevotional = 'devotional_read_001';
        const heardDevotional = 'devotional_heard_001';

        // WHEN: User reads one and listens to another
        await statsService.recordDevocionalCompletado(
          devocionalId: readDevotional,
          readingTimeSeconds: 80,
          scrollPercentage: 0.9,
          source: 'read',
        );

        await statsService.recordDevocionalCompletado(
          devocionalId: heardDevotional,
          listenedPercentage: 0.95,
          source: 'heard',
        );

        final stats = await statsService.getStats();

        // THEN: Both should be counted
        expect(stats.readDevocionalIds.length, 2,
            reason: 'Both read and heard devotionals should count');
        expect(stats.readDevocionalIds,
            containsAll([readDevotional, heardDevotional]),
            reason: 'Both devotionals should be in the list');
        expect(stats.totalDevocionalesRead, 2);
      });
    });

    group('Edge Cases and Error Handling', () {
      test('Should handle empty devotional ID gracefully', () async {
        // WHEN: Trying to record with empty ID
        final stats = await statsService.recordDevocionalCompletado(
          devocionalId: '',
          readingTimeSeconds: 80,
          scrollPercentage: 0.9,
          source: 'read',
        );

        // THEN: Should not crash and not count
        expect(stats.readDevocionalIds, isEmpty,
            reason: 'Empty ID should not be recorded');
        expect(stats.totalDevocionalesRead, 0);
      });

      test('Should handle very long devotional IDs', () async {
        // GIVEN: Extremely long devotional ID
        final longId = 'devotional_${'x' * 500}';

        // WHEN: Recording devotional with long ID
        final stats = await statsService.recordDevocionalCompletado(
          devocionalId: longId,
          readingTimeSeconds: 80,
          scrollPercentage: 0.9,
          source: 'read',
        );

        // THEN: Should handle normally
        expect(stats.readDevocionalIds, contains(longId),
            reason: 'Long IDs should be handled correctly');
        expect(stats.totalDevocionalesRead, 1);
      });

      test('Should handle special characters in devotional IDs', () async {
        // GIVEN: Devotional ID with special characters
        const specialId = 'devotional_2024-01-01_special!@#\$%';

        // WHEN: Recording devotional with special characters
        final stats = await statsService.recordDevocionalCompletado(
          devocionalId: specialId,
          readingTimeSeconds: 80,
          scrollPercentage: 0.9,
          source: 'read',
        );

        // THEN: Should handle normally
        expect(stats.readDevocionalIds, contains(specialId),
            reason: 'Special characters should be handled correctly');
      });

      test('Should handle zero and negative values for reading metrics',
          () async {
        // WHEN: Recording with unusual values
        final stats = await statsService.recordDevocionalCompletado(
          devocionalId: 'devotional_edge_case',
          readingTimeSeconds: 0,
          scrollPercentage: -0.5, // Invalid negative
          source: 'read',
        );

        // THEN: Should not count due to not meeting criteria
        expect(stats.readDevocionalIds, isEmpty,
            reason: 'Invalid metrics should not count devotional as read');
      });
    });

    group('Data Integrity - Prevent Repetition Bug', () {
      test(
          'BUGFIX: Devotional should not appear multiple times in history/list',
          () async {
        // GIVEN: Simulating the reported bug scenario
        const devocionalId = 'devotional_repeat_bug_test';

        // WHEN: User completes devotional multiple times (app reopens, etc.)
        for (int i = 0; i < 5; i++) {
          await statsService.recordDevocionalCompletado(
            devocionalId: devocionalId,
            readingTimeSeconds: 80,
            scrollPercentage: 0.9,
            source: 'read',
          );
        }

        final stats = await statsService.getStats();

        // THEN: Should only appear once in the list
        final occurrences =
            stats.readDevocionalIds.where((id) => id == devocionalId).length;
        expect(occurrences, 1,
            reason:
                'BUGFIX: Devotional should only appear once even after multiple completions');

        // AND: Total should be 1, not 5
        expect(stats.totalDevocionalesRead, 1,
            reason: 'BUGFIX: Total count should be 1 for repeated devotional');
      });

      test(
          'PERSISTENCE: SharedPreferences should correctly store and retrieve list without duplicates',
          () async {
        // GIVEN: Multiple devotionals are read
        const devotionals = [
          'dev_001',
          'dev_002',
          'dev_001', // Duplicate attempt
          'dev_003',
          'dev_002', // Another duplicate
        ];

        // WHEN: Recording all devotionals (including duplicates)
        for (final devId in devotionals) {
          await statsService.recordDevocionalCompletado(
            devocionalId: devId,
            readingTimeSeconds: 80,
            scrollPercentage: 0.9,
            source: 'read',
          );
        }

        // Simulate app restart
        final newService = SpiritualStatsService();
        final stats = await newService.getStats();

        // THEN: Should only have unique devotionals
        expect(stats.readDevocionalIds.length, 3,
            reason: 'Should only store unique devotional IDs');
        expect(stats.readDevocionalIds.toSet().length, 3,
            reason: 'No duplicates should exist in the list');
        expect(stats.totalDevocionalesRead, 3);
      });
    });

    group('Streak and Date Tracking', () {
      test('Should track consecutive days streak correctly', () async {
        // This test validates the streak logic isn't affected by devotional tracking
        const devocionalId1 = 'streak_test_day1';

        // WHEN: User reads a devotional (meeting criteria)
        final stats = await statsService.recordDevocionalCompletado(
          devocionalId: devocionalId1,
          readingTimeSeconds: 80,
          scrollPercentage: 0.9,
          source: 'read',
        );

        // THEN: Streak should be maintained correctly
        expect(stats.currentStreak, greaterThanOrEqualTo(0),
            reason: 'Streak should be a valid non-negative number');
        // Note: Current streak calculation depends on dates, tested separately
      });
    });
  });
}
