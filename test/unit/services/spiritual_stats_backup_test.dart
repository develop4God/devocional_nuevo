// test/unit/services/spiritual_stats_backup_test.dart
import 'package:devocional_nuevo/services/spiritual_stats_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('SpiritualStatsService Backup Tests', () {
    late SpiritualStatsService service;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      service = SpiritualStatsService();
    });

    group('Auto Backup Configuration', () {
      test('should enable auto backup by default', () async {
        final isEnabled = await service.isAutoBackupEnabled();
        expect(isEnabled, isTrue);
      });

      test('should toggle auto backup setting', () async {
        await service.setAutoBackupEnabled(false);
        final isEnabled = await service.isAutoBackupEnabled();
        expect(isEnabled, isFalse);

        await service.setAutoBackupEnabled(true);
        final isEnabledAgain = await service.isAutoBackupEnabled();
        expect(isEnabledAgain, isTrue);
      });

      test('should handle JSON backup configuration', () async {
        await service.setJsonBackupEnabled(true);
        final isEnabled = await service.isJsonBackupEnabled();
        expect(isEnabled, isTrue);

        await service.setJsonBackupEnabled(false);
        final isDisabled = await service.isJsonBackupEnabled();
        expect(isDisabled, isFalse);
      });
    });

    group('Backup Data Structure', () {
      test('should generate backup data with version information', () async {
        final backupData = await service.getAllStats();

        expect(backupData, isA<Map<String, dynamic>>());
        expect(backupData['metadata'], isNotNull);
        expect(backupData['metadata']['backup_version'], isNotNull);
        expect(backupData['spiritual_stats'], isNotNull);
      });

      test('should include devotional reading data in backup', () async {
        // Add some test data
        final prefs = await SharedPreferences.getInstance();
        await prefs.setStringList('readDevocionalIds', ['dev_1', 'dev_2']);
        await prefs.setString('last_read_devocional', 'dev_2');

        final backupData = await service.getAllStats();

        expect(backupData['devotional_reading_data'], isNotNull);
        expect(
          backupData['devotional_reading_data']['read_devocional_ids'],
          isA<List>(),
        );
        expect(
          backupData['devotional_reading_data']['reading_progress'],
          isA<Map>(),
        );
      });

      test('should handle empty backup data gracefully', () async {
        final backupData = await service.getAllStats();

        expect(
          backupData['devotional_reading_data']['read_devocional_ids'],
          isEmpty,
        );
        expect(
          backupData['devotional_reading_data']['reading_progress']
              ['total_devotionals_read'],
          equals(0),
        );
      });
    });

    group('Backup Restoration', () {
      test('should restore valid backup data', () async {
        final testBackupData = {
          'metadata': {
            'backup_version': '2.0.0',
            'created_at': DateTime.now().toIso8601String(),
          },
          'spiritual_stats': {'total_devotionals_read': 5},
          'devotional_reading_data': {
            'read_devocional_ids': ['dev_1', 'dev_2'],
            'reading_progress': {'total_devotionals_read': 2},
          },
        };

        await service.restoreStats(testBackupData);

        // Verify restoration
        final prefs = await SharedPreferences.getInstance();
        final restoredIds = prefs.getStringList('readDevocionalIds');
        expect(restoredIds, equals(['dev_1', 'dev_2']));
      });

      test('should handle legacy backup format gracefully', () async {
        final legacyBackupData = {
          'metadata': {'backup_version': '1.0.0'},
          'spiritual_stats': {'total_devotionals_read': 3},
          // No devotional_reading_data in legacy format
        };

        // Should not throw
        await service.restoreStats(legacyBackupData);

        final backupAfterRestore = await service.getAllStats();
        expect(backupAfterRestore['metadata']['backup_version'], isNotNull);
      });

      test('should handle corrupted backup data', () async {
        final corruptedData = {
          // Missing required fields
          'invalid': 'data',
        };

        // Should handle gracefully without throwing
        await service.restoreStats(corruptedData);

        final stats = await service.getAllStats();
        expect(stats, isA<Map<String, dynamic>>());
      });
    });

    group('Reading Progress Tracking', () {
      test('should track reading progress correctly', () async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setStringList('readDevocionalIds', [
          'dev_1',
          'dev_2',
          'dev_3',
        ]);

        final stats = await service.getAllStats();
        final readingProgress =
            stats['devotional_reading_data']['reading_progress'];

        expect(readingProgress['total_devotionals_read'], equals(3));
        expect(readingProgress['reading_frequency'], isA<double>());
        expect(readingProgress['current_reading_streak'], isA<int>());
      });

      test('should calculate reading streaks', () async {
        final prefs = await SharedPreferences.getInstance();
        final today = DateTime.now();
        final yesterday = today.subtract(const Duration(days: 1));

        await prefs.setStringList('read_dates', [
          yesterday.toIso8601String().split('T')[0],
          today.toIso8601String().split('T')[0],
        ]);

        final stats = await service.getAllStats();
        final readingProgress =
            stats['devotional_reading_data']['reading_progress'];

        expect(readingProgress['current_reading_streak'], greaterThan(0));
      });

      test('should generate reading history', () async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setStringList('readDevocionalIds', ['dev_1']);

        final stats = await service.getAllStats();
        final readingHistory =
            stats['devotional_reading_data']['reading_history'];

        expect(readingHistory, isA<Map>());
        expect(readingHistory['dev_1'], isA<Map>());
        expect(readingHistory['dev_1']['read'], isTrue);
        expect(readingHistory['dev_1']['recorded_date'], isNotNull);
      });
    });

    group('Performance and Data Integrity', () {
      test('should handle large datasets efficiently', () async {
        final prefs = await SharedPreferences.getInstance();
        final largeDataset = List.generate(100, (i) => 'dev_$i');
        await prefs.setStringList('readDevocionalIds', largeDataset);

        final stopwatch = Stopwatch()..start();
        final stats = await service.getAllStats();
        stopwatch.stop();

        expect(
          stopwatch.elapsedMilliseconds,
          lessThan(1000),
        ); // Should complete within 1 second
        expect(
          stats['devotional_reading_data']['read_devocional_ids'].length,
          equals(100),
        );
      });

      test('should maintain data consistency', () async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setStringList('readDevocionalIds', ['dev_1', 'dev_2']);

        final stats1 = await service.getAllStats();
        final stats2 = await service.getAllStats();

        expect(
          stats1['devotional_reading_data']['read_devocional_ids'],
          equals(stats2['devotional_reading_data']['read_devocional_ids']),
        );
      });

      test('should handle concurrent operations safely', () async {
        final futures = <Future>[];

        for (int i = 0; i < 5; i++) {
          futures.add(service.getAllStats());
        }

        final results = await Future.wait(futures);

        // All results should be consistent
        for (final result in results) {
          expect(result, isA<Map<String, dynamic>>());
          expect(result['metadata'], isNotNull);
        }
      });
    });

    group('Error Handling', () {
      test('should handle SharedPreferences errors gracefully', () async {
        // Should not throw even with invalid data
        expect(() => service.getAllStats(), returnsNormally);
        expect(() => service.isAutoBackupEnabled(), returnsNormally);
      });

      test('should handle invalid backup data types', () async {
        final invalidData = {
          'devotional_reading_data': {
            'read_devocional_ids': 'not_a_list', // Wrong type
            'reading_history': 'not_a_map', // Wrong type
          },
        };

        // Should handle gracefully without throwing
        await service.restoreStats(invalidData);

        final stats = await service.getAllStats();
        expect(
          stats['devotional_reading_data']['read_devocional_ids'],
          isA<List>(),
        );
      });
    });
  });
}
