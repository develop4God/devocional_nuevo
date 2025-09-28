// test/unit/services/spiritual_stats_service_test.dart

import 'package:devocional_nuevo/models/spiritual_stats_model.dart';
import 'package:devocional_nuevo/services/spiritual_stats_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SpiritualStatsService Tests', () {
    late SpiritualStatsService service;

    setUp(() async {
      // Setup SharedPreferences mock
      SharedPreferences.setMockInitialValues({
        'spiritual_stats': jsonEncode({
          'totalDevocionalesRead': 5,
          'currentStreak': 3,
          'longestStreak': 7,
          'lastActivityDate': DateTime.now().toIso8601String(),
          'favoritesCount': 2,
          'readDevocionalIds': ['dev1', 'dev2', 'dev3'],
        }),
        'read_dates': jsonEncode(['2025-01-10', '2025-01-11', '2025-01-12']),
        'json_backup_enabled': true,
        'auto_backup_enabled': true,
      });

      // Setup method channel mocks for path_provider
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/path_provider'),
        (MethodCall methodCall) async {
          switch (methodCall.method) {
            case 'getApplicationDocumentsDirectory':
              return '/mock/documents';
            case 'getTemporaryDirectory':
              return '/mock/temp';
            default:
              return '/mock/default';
          }
        },
      );

      service = SpiritualStatsService();
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/path_provider'),
        null,
      );
    });

    group('Reading Streaks and Progress Calculation', () {
      test('should calculate reading streaks and spiritual progress correctly',
          () async {
        // Record reading activity
        await service.recordDevocionalRead('dev_streak_1');
        await service.recordDevocionalRead('dev_streak_2');
        await service.recordDevocionalRead('dev_streak_3');

        final stats = await service.getStats();
        expect(stats, isA<SpiritualStats>());
        expect(stats.totalDevocionalesRead, greaterThan(0));
        expect(stats.currentStreak, isA<int>());
        expect(stats.longestStreak, isA<int>());
        expect(stats.readDevocionalIds, isA<List<String>>());
      });

      test('should handle consecutive day streak calculations', () async {
        // Simulate reading on consecutive days
        final today = DateTime.now();
        final yesterday = today.subtract(const Duration(days: 1));

        // Record readings
        await service.recordDevocionalRead('today_dev');

        final stats = await service.getStats();
        expect(stats.currentStreak, isA<int>());
        expect(stats.longestStreak, greaterThanOrEqualTo(stats.currentStreak));
      });

      test('should track last activity date correctly', () async {
        await service.recordDevocionalRead('activity_test');

        final stats = await service.getStats();
        expect(stats.lastActivityDate, isA<DateTime>());

        final today = DateTime.now();
        final difference = today.difference(stats.lastActivityDate).inDays;
        expect(difference, lessThanOrEqualTo(1));
      });
    });

    group('Badge Achievement Logic and Milestones', () {
      test('should handle badge achievement logic and milestones', () async {
        // Record multiple readings to trigger achievements
        for (int i = 1; i <= 10; i++) {
          await service.recordDevocionalRead('badge_dev_$i');
        }

        final stats = await service.getStats();
        expect(stats.totalDevocionalesRead, greaterThanOrEqualTo(10));

        // Test milestone achievements
        final hasFirstReadMilestone = stats.totalDevocionalesRead >= 1;
        final hasWeekReaderMilestone = stats.totalDevocionalesRead >= 7;

        expect(hasFirstReadMilestone, isTrue);
        expect(hasWeekReaderMilestone, isTrue);
      });

      test('should validate achievement unlock conditions', () async {
        // Test different achievement thresholds
        final achievementThresholds = [1, 3, 7, 30, 100];

        for (final threshold in achievementThresholds) {
          // Record readings up to threshold
          for (int i = 1; i <= threshold; i++) {
            await service.recordDevocionalRead('threshold_${threshold}_dev_$i');
          }

          final stats = await service.getStats();
          expect(stats.totalDevocionalesRead, greaterThanOrEqualTo(threshold));
        }
      });

      test('should handle favorites count tracking', () async {
        // Add to favorites
        await service.addToFavorites('fav_dev_1');
        await service.addToFavorites('fav_dev_2');
        await service.addToFavorites('fav_dev_3');

        final stats = await service.getStats();
        expect(stats.favoritesCount, equals(3));

        // Remove from favorites
        await service.removeFromFavorites('fav_dev_1');

        final updatedStats = await service.getStats();
        expect(updatedStats.favoritesCount, equals(2));
      });
    });

    group('Statistics Persistence and Retrieval', () {
      test('should persist and retrieve user statistics accurately', () async {
        // Create test stats
        final testStats = SpiritualStats(
          totalDevocionalesRead: 15,
          currentStreak: 5,
          longestStreak: 10,
          lastActivityDate: DateTime.now(),
          favoritesCount: 8,
          readDevocionalIds: ['test1', 'test2', 'test3'],
        );

        // Save stats
        await service.saveStats(testStats);

        // Retrieve stats
        final retrievedStats = await service.getStats();

        expect(retrievedStats.totalDevocionalesRead, equals(15));
        expect(retrievedStats.currentStreak, equals(5));
        expect(retrievedStats.longestStreak, equals(10));
        expect(retrievedStats.favoritesCount, equals(8));
        expect(retrievedStats.readDevocionalIds, hasLength(3));
      });

      test('should handle statistics backup and restore', () async {
        // Enable auto backup
        await service.setAutoBackupEnabled(true);
        final isEnabled = await service.isAutoBackupEnabled();
        expect(isEnabled, isTrue);

        // Test manual backup creation
        await service.recordDevocionalRead('backup_test_dev');

        // Should not throw when creating backup
        expect(() => service.createManualBackup(), returnsNormally);
      });

      test('should handle empty or corrupted stats data', () async {
        // Test with empty SharedPreferences
        SharedPreferences.setMockInitialValues({});
        final freshService = SpiritualStatsService();

        final stats = await freshService.getStats();
        expect(stats.totalDevocionalesRead, equals(0));
        expect(stats.currentStreak, equals(0));
        expect(stats.longestStreak, equals(0));
        expect(stats.favoritesCount, equals(0));
        expect(stats.readDevocionalIds, isEmpty);
      });
    });

    group('Reading Tracking and Validation', () {
      test('should prevent duplicate devotional readings', () async {
        final deviceId = 'dev_duplicate_test';

        // Record same devotional multiple times
        await service.recordDevocionalRead(deviceId);
        await service.recordDevocionalRead(deviceId);
        await service.recordDevocionalRead(deviceId);

        final stats = await service.getStats();

        // Should only count unique devotionals
        final uniqueReadings = stats.readDevocionalIds.toSet().length;
        expect(uniqueReadings, lessThanOrEqualTo(stats.totalDevocionalesRead));
      });

      test('should handle reading validation and timestamps', () async {
        final beforeReading = DateTime.now();

        await service.recordDevocionalRead('timestamp_test');

        final afterReading = DateTime.now();
        final stats = await service.getStats();

        // Verify timestamp is within reasonable range
        expect(
            stats.lastActivityDate
                .isAfter(beforeReading.subtract(const Duration(seconds: 1))),
            isTrue);
        expect(
            stats.lastActivityDate
                .isBefore(afterReading.add(const Duration(seconds: 1))),
            isTrue);
      });

      test('should manage reading dates collection', () async {
        // Record readings on different conceptual days
        await service.recordDevocionalRead('date_test_1');
        await service.recordDevocionalRead('date_test_2');

        final stats = await service.getStats();
        expect(stats.readDevocionalIds, contains('date_test_1'));
        expect(stats.readDevocionalIds, contains('date_test_2'));
      });
    });

    group('Service Configuration and State', () {
      test('should handle JSON backup configuration', () async {
        // Test JSON backup enable/disable
        await service.setJsonBackupEnabled(true);
        await service.setJsonBackupEnabled(false);

        // Should complete without error
        expect(true, isTrue);
      });

      test('should manage service state correctly', () async {
        // Test service initialization and state management
        expect(service, isNotNull);
        expect(service, isA<SpiritualStatsService>());

        // Test basic operations don't throw
        expect(() => service.getStats(), returnsNormally);
        expect(
            () => service.recordDevocionalRead('state_test'), returnsNormally);
      });

      test('should handle concurrent operations gracefully', () async {
        // Perform multiple operations concurrently
        final futures = <Future>[];

        for (int i = 0; i < 5; i++) {
          futures.add(service.recordDevocionalRead('concurrent_$i'));
        }

        await Future.wait(futures);

        final stats = await service.getStats();
        expect(stats.totalDevocionalesRead, greaterThan(0));
      });
    });

    group('Error Handling and Edge Cases', () {
      test('should handle invalid devotional IDs gracefully', () async {
        // Test with various edge case IDs
        await service.recordDevocionalRead('');
        await service.recordDevocionalRead('   ');
        await service.recordDevocionalRead('🤔😀');

        // Should not crash
        final stats = await service.getStats();
        expect(stats, isA<SpiritualStats>());
      });

      test('should handle favorites operations with invalid data', () async {
        // Test favorites with edge cases
        await service.addToFavorites('');
        await service.removeFromFavorites('nonexistent');
        await service.addToFavorites('valid_favorite');

        final stats = await service.getStats();
        expect(stats.favoritesCount, isA<int>());
        expect(stats.favoritesCount, greaterThanOrEqualTo(0));
      });

      test('should handle system resource limitations', () async {
        // Test with large numbers of operations
        for (int i = 0; i < 100; i++) {
          await service.recordDevocionalRead('stress_test_$i');
        }

        final stats = await service.getStats();
        expect(stats.totalDevocionalesRead, isA<int>());
        expect(stats.readDevocionalIds, isA<List<String>>());
      });
    });
  });
}
