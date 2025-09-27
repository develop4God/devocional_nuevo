@TestOn('vm')
import 'dart:io';

import 'package:devocional_nuevo/models/spiritual_stats_model.dart';
import 'package:devocional_nuevo/services/spiritual_stats_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Mock classes for dependencies using mocktail
class MockSharedPreferences extends Mock implements SharedPreferences {}

class MockDirectory extends Mock implements Directory {}

class MockFile extends Mock implements File {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SpiritualStatsService Comprehensive Tests', () {
    late SpiritualStatsService service;

    setUp(() {
      // Initialize service
      service = SpiritualStatsService();

      // Setup SharedPreferences mock
      SharedPreferences.setMockInitialValues({});
    });

    group('Backup Configuration Management', () {
      test('should enable auto backup and verify configuration', () async {
        // Act
        await service.setAutoBackupEnabled(true);
        final isEnabled = await service.isAutoBackupEnabled();

        // Assert
        expect(isEnabled, isTrue);
      });

      test('should disable auto backup and verify configuration', () async {
        // Act
        await service.setAutoBackupEnabled(false);
        final isEnabled = await service.isAutoBackupEnabled();

        // Assert
        expect(isEnabled, isFalse);
      });

      test('should enable JSON backup and verify configuration', () async {
        // Act
        await service.setJsonBackupEnabled(true);
        final isEnabled = await service.isJsonBackupEnabled();

        // Assert
        expect(isEnabled, isTrue);
      });

      test('should handle rapid backup configuration changes', () async {
        // Act - Rapid successive changes
        await service.setAutoBackupEnabled(true);
        await service.setAutoBackupEnabled(false);
        await service.setJsonBackupEnabled(true);
        await service.setJsonBackupEnabled(false);

        // Assert - Final state should be consistent
        final autoEnabled = await service.isAutoBackupEnabled();
        final jsonEnabled = await service.isJsonBackupEnabled();

        expect(autoEnabled, isFalse);
        expect(jsonEnabled, isFalse);
      });
    });

    group('Spiritual Statistics Management', () {
      test('should return default stats when no data exists', () async {
        // Act
        final stats = await service.getStats();

        // Assert
        expect(stats, isA<SpiritualStats>());
        expect(stats.readDevocionalIds, isEmpty);
      });

      test('should save and retrieve spiritual statistics', () async {
        // Arrange
        final testStats = SpiritualStats(
          readDevocionalIds: ['dev_1', 'dev_2', 'dev_3'],
        );

        // Act
        await service.saveStats(testStats);
        final retrievedStats = await service.getStats();

        // Assert
        expect(retrievedStats.readDevocionalIds,
            equals(testStats.readDevocionalIds));
        expect(retrievedStats.readDevocionalIds, hasLength(3));
      });

      test('should handle corrupted stats data gracefully', () async {
        // Arrange - Simulate corrupted JSON data
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('spiritual_stats', 'invalid_json_data');

        // Act
        final stats = await service.getStats();

        // Assert - Should return default stats without throwing
        expect(stats, isA<SpiritualStats>());
        expect(stats.readDevocionalIds, isEmpty);
      });

      test('should preserve stats data integrity across multiple operations',
          () async {
        // Arrange
        final originalStats = SpiritualStats(
          readDevocionalIds: ['original_1', 'original_2'],
        );

        // Act
        await service.saveStats(originalStats);

        // Multiple retrievals should return consistent data
        final stats1 = await service.getStats();
        final stats2 = await service.getStats();
        final stats3 = await service.getStats();

        // Assert
        expect(stats1.readDevocionalIds, equals(stats2.readDevocionalIds));
        expect(stats2.readDevocionalIds, equals(stats3.readDevocionalIds));
        expect(
            stats1.readDevocionalIds, equals(originalStats.readDevocionalIds));
      });
    });

    group('Devotional Reading Tracking', () {
      test('should record devotional read with sufficient criteria', () async {
        // Arrange
        const devocionalId = 'devotional_123';
        const readingTime = 90; // seconds
        const scrollPercentage = 0.85;

        // Act
        final updatedStats = await service.recordDevocionalRead(
          devocionalId: devocionalId,
          readingTimeSeconds: readingTime,
          scrollPercentage: scrollPercentage,
        );

        // Assert
        expect(updatedStats.readDevocionalIds, contains(devocionalId));
      });

      test('should not record devotional read with insufficient reading time',
          () async {
        // Arrange
        const devocionalId = 'devotional_short_read';
        const readingTime = 30; // seconds - below threshold
        const scrollPercentage = 0.90;

        // Act
        final updatedStats = await service.recordDevocionalRead(
          devocionalId: devocionalId,
          readingTimeSeconds: readingTime,
          scrollPercentage: scrollPercentage,
        );

        // Assert
        expect(updatedStats.readDevocionalIds, isNot(contains(devocionalId)));
      });

      test(
          'should not record devotional read with insufficient scroll percentage',
          () async {
        // Arrange
        const devocionalId = 'devotional_short_scroll';
        const readingTime = 120; // seconds - above threshold
        const scrollPercentage = 0.5; // below threshold

        // Act
        final updatedStats = await service.recordDevocionalRead(
          devocionalId: devocionalId,
          readingTimeSeconds: readingTime,
          scrollPercentage: scrollPercentage,
        );

        // Assert
        expect(updatedStats.readDevocionalIds, isNot(contains(devocionalId)));
      });

      test('should not duplicate devotional reads', () async {
        // Arrange
        const devocionalId = 'devotional_duplicate_test';
        const readingTime = 90;
        const scrollPercentage = 0.85;

        // Act - Record same devotional multiple times
        await service.recordDevocionalRead(
          devocionalId: devocionalId,
          readingTimeSeconds: readingTime,
          scrollPercentage: scrollPercentage,
        );

        await service.recordDevocionalRead(
          devocionalId: devocionalId,
          readingTimeSeconds: readingTime,
          scrollPercentage: scrollPercentage,
        );

        final finalStats = await service.getStats();

        // Assert
        final occurrences = finalStats.readDevocionalIds
            .where((id) => id == devocionalId)
            .length;
        expect(occurrences, equals(1));
      });

      test('should handle empty devotional ID gracefully', () async {
        // Arrange
        const emptyId = '';
        const readingTime = 120;
        const scrollPercentage = 0.90;

        // Act
        final stats = await service.recordDevocionalRead(
          devocionalId: emptyId,
          readingTimeSeconds: readingTime,
          scrollPercentage: scrollPercentage,
        );

        // Assert - Should not add empty ID
        expect(stats.readDevocionalIds, isNot(contains(emptyId)));
      });
    });

    group('Devotional Heard Tracking', () {
      test(
          'should record devotional heard with sufficient listening percentage',
          () async {
        // Arrange
        const devocionalId = 'devotional_audio_123';
        const listenedPercentage = 0.85;

        // Act
        final updatedStats = await service.recordDevotionalHeard(
          devocionalId: devocionalId,
          listenedPercentage: listenedPercentage,
        );

        // Assert
        expect(updatedStats.readDevocionalIds, contains(devocionalId));
      });

      test(
          'should not record devotional heard with insufficient listening percentage',
          () async {
        // Arrange
        const devocionalId = 'devotional_audio_short';
        const listenedPercentage = 0.50; // below threshold

        // Act
        final updatedStats = await service.recordDevotionalHeard(
          devocionalId: devocionalId,
          listenedPercentage: listenedPercentage,
        );

        // Assert
        expect(updatedStats.readDevocionalIds, isNot(contains(devocionalId)));
      });

      test('should handle audio tracking with various completion percentages',
          () async {
        // Arrange - Test different completion thresholds
        const baseId = 'audio_completion_test';

        // Act & Assert
        final stats1 = await service.recordDevotionalHeard(
          devocionalId: '${baseId}_high',
          listenedPercentage: 0.95, // High completion
        );

        final stats2 = await service.recordDevotionalHeard(
          devocionalId: '${baseId}_low',
          listenedPercentage: 0.50, // Low completion
        );

        expect(stats1.readDevocionalIds, contains('${baseId}_high'));
        expect(stats2.readDevocionalIds, isNot(contains('${baseId}_low')));
      });
    });

    group('Favorites Count Management', () {
      test('should update favorites count successfully', () async {
        // Arrange
        const newFavoritesCount = 15;

        // Act
        final updatedStats =
            await service.updateFavoritesCount(newFavoritesCount);

        // Assert
        expect(updatedStats, isA<SpiritualStats>());
        // The favorites count should be processed by the service
      });

      test('should handle negative favorites count', () async {
        // Arrange
        const negativeFavorites = -5;

        // Act & Assert - Should complete without throwing
        expect(
          () => service.updateFavoritesCount(negativeFavorites),
          returnsNormally,
        );
      });

      test('should handle extremely large favorites count', () async {
        // Arrange
        const largeFavorites = 999999;

        // Act & Assert - Should complete without throwing
        expect(
          () => service.updateFavoritesCount(largeFavorites),
          returnsNormally,
        );
      });
    });

    group('Daily App Visit Tracking', () {
      test('should record daily app visit', () async {
        // Act & Assert - Should complete without throwing
        expect(() => service.recordDailyAppVisit(), returnsNormally);
      });

      test('should handle multiple daily visits correctly', () async {
        // Act - Multiple visits in same test run
        await service.recordDailyAppVisit();
        await service.recordDailyAppVisit();
        await service.recordDailyAppVisit();

        // Assert - Should complete without errors
        final stats = await service.getStats();
        expect(stats, isA<SpiritualStats>());
      });
    });

    group('Performance and Concurrency', () {
      test('should handle concurrent operations without data corruption',
          () async {
        // Arrange
        final futures = <Future<void>>[];

        // Act - Perform concurrent operations
        for (int i = 0; i < 10; i++) {
          futures.add(service.recordDevocionalRead(
            devocionalId: 'concurrent_$i',
            readingTimeSeconds: 90,
            scrollPercentage: 0.85,
          ));
        }

        // Wait for all operations to complete
        await Future.wait(futures);

        // Assert
        final finalStats = await service.getStats();
        expect(finalStats.readDevocionalIds.length, greaterThanOrEqualTo(5));
      });

      test('should complete operations within performance limits', () async {
        // Arrange
        final stopwatch = Stopwatch()..start();
        const devocionalId = 'performance_test';

        // Act
        await service.recordDevocionalRead(
          devocionalId: devocionalId,
          readingTimeSeconds: 90,
          scrollPercentage: 0.85,
        );

        await service.getStats();
        await service.recordDailyAppVisit();

        stopwatch.stop();

        // Assert - Should complete within reasonable time
        expect(stopwatch.elapsedMilliseconds, lessThan(1000));
      });

      test('should handle rapid successive stat updates', () async {
        // Arrange
        const iterations = 20;

        // Act - Rapid updates
        for (int i = 0; i < iterations; i++) {
          final stats = SpiritualStats(
            readDevocionalIds: ['rapid_$i'],
          );
          await service.saveStats(stats);
        }

        // Assert - Final state should be consistent
        final finalStats = await service.getStats();
        expect(finalStats, isA<SpiritualStats>());
        expect(finalStats.readDevocionalIds, isNotEmpty);
      });
    });

    group('Error Handling and Edge Cases', () {
      test('should handle SharedPreferences errors gracefully', () async {
        // Act & Assert - Operations should complete without throwing
        expect(() => service.getStats(), returnsNormally);
        expect(() => service.isAutoBackupEnabled(), returnsNormally);
        expect(() => service.isJsonBackupEnabled(), returnsNormally);
      });

      test('should handle devotional IDs with special characters', () async {
        // Arrange
        const specialId =
            'devotional_with_special_chars_!@#\$%^&*()_+{}[]|\\:";\'<>?,./<>àáâãäåæçèéêë';

        // Act
        final stats = await service.recordDevocionalRead(
          devocionalId: specialId,
          readingTimeSeconds: 90,
          scrollPercentage: 0.85,
        );

        // Assert
        expect(stats.readDevocionalIds, contains(specialId));
      });

      test('should handle very long devotional IDs', () async {
        // Arrange
        final longId = 'very_long_devotional_id_${'x' * 1000}';

        // Act & Assert - Should handle without throwing
        expect(
          () => service.recordDevocionalRead(
            devocionalId: longId,
            readingTimeSeconds: 90,
            scrollPercentage: 0.85,
          ),
          returnsNormally,
        );
      });

      test('should handle extreme parameter values', () async {
        // Arrange
        const devocionalId = 'extreme_params_test';

        // Act & Assert - Should handle edge cases gracefully
        expect(
          () => service.recordDevocionalRead(
            devocionalId: devocionalId,
            readingTimeSeconds: 0,
            scrollPercentage: 0.0,
          ),
          returnsNormally,
        );

        expect(
          () => service.recordDevocionalRead(
            devocionalId: devocionalId,
            readingTimeSeconds: 999999,
            scrollPercentage: 1.0,
          ),
          returnsNormally,
        );
      });

      test('should maintain data consistency after error recovery', () async {
        // Arrange - Save initial valid state
        final initialStats = SpiritualStats(
          readDevocionalIds: ['initial_data'],
        );
        await service.saveStats(initialStats);

        // Act - Attempt operations that might cause issues
        await service.recordDevocionalRead(
          devocionalId: '',
          readingTimeSeconds: -100,
          scrollPercentage: -1.0,
        );

        // Assert - Data should remain consistent
        final finalStats = await service.getStats();
        expect(finalStats.readDevocionalIds, contains('initial_data'));
      });
    });

    group('Business Logic Validation', () {
      test('should enforce reading criteria consistently', () async {
        // Test various combinations of reading time and scroll percentage
        final testCases = [
          {
            'time': 60,
            'scroll': 0.8,
            'shouldRecord': true
          }, // Both criteria met
          {'time': 60, 'scroll': 0.7, 'shouldRecord': false}, // Scroll too low
          {'time': 30, 'scroll': 0.9, 'shouldRecord': false}, // Time too low
          {
            'time': 120,
            'scroll': 1.0,
            'shouldRecord': true
          }, // Both exceed minimum
        ];

        for (int i = 0; i < testCases.length; i++) {
          final testCase = testCases[i];
          final devocionalId = 'criteria_test_$i';

          final stats = await service.recordDevocionalRead(
            devocionalId: devocionalId,
            readingTimeSeconds: testCase['time'] as int,
            scrollPercentage: testCase['scroll'] as double,
          );

          if (testCase['shouldRecord'] as bool) {
            expect(stats.readDevocionalIds, contains(devocionalId),
                reason: 'Should record for case $i: $testCase');
          } else {
            expect(stats.readDevocionalIds, isNot(contains(devocionalId)),
                reason: 'Should NOT record for case $i: $testCase');
          }
        }
      });

      test('should prioritize data integrity over performance', () async {
        // Arrange - Create scenario that tests data integrity
        const criticalId = 'data_integrity_test';

        // Act - Perform operations that could cause race conditions
        final future1 = service.recordDevocionalRead(
          devocionalId: criticalId,
          readingTimeSeconds: 90,
          scrollPercentage: 0.85,
        );

        final future2 = service.recordDevocionalRead(
          devocionalId: criticalId,
          readingTimeSeconds: 120,
          scrollPercentage: 0.90,
        );

        await Future.wait([future1, future2]);

        // Assert - Should not have duplicates
        final stats = await service.getStats();
        final occurrences =
            stats.readDevocionalIds.where((id) => id == criticalId).length;
        expect(occurrences, equals(1));
      });
    });
  });
}
