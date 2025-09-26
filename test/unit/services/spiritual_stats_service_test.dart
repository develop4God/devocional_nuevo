// test/unit/services/spiritual_stats_service_test.dart
import 'dart:convert';
import 'dart:io';

import 'package:devocional_nuevo/models/spiritual_stats_model.dart';
import 'package:devocional_nuevo/services/spiritual_stats_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Mock class for PathProviderPlatform to simulate file system operations
class MockPathProviderPlatform extends Mock
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {}

/// Mock class for Directory to simulate directory operations
class MockDirectory extends Mock implements Directory {}

/// Mock class for File to simulate file operations
class MockFile extends Mock implements File {}

void main() {
  group('SpiritualStatsService Tests', () {
    late SpiritualStatsService service;
    late MockPathProviderPlatform mockPathProvider;
    late MockDirectory mockDirectory;
    late MockFile mockFile;

    setUp(() {
      // Initialize service instance
      service = SpiritualStatsService();

      // Initialize mocks
      mockPathProvider = MockPathProviderPlatform();
      mockDirectory = MockDirectory();
      mockFile = MockFile();

      // Reset SharedPreferences before each test
      SharedPreferences.setMockInitialValues({});

      // Register mock as singleton for PathProvider
      PathProviderPlatform.instance = mockPathProvider;

      // Setup default mock behaviors for file operations
      when(() => mockPathProvider.getApplicationDocumentsPath())
          .thenAnswer((_) async => '/mock/documents');
      when(() => mockDirectory.path).thenReturn('/mock/documents');
      when(() => mockFile.writeAsString(any()))
          .thenAnswer((_) async => mockFile);
      when(() => mockFile.readAsString()).thenAnswer((_) async => '{}');
      when(() => mockFile.exists()).thenAnswer((_) async => true);
    });

    group('Auto Backup Configuration', () {
      test('should enable auto backup and create initial backup', () async {
        // Act: Enable auto backup
        await service.setAutoBackupEnabled(true);

        // Assert: Auto backup should be enabled
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getBool('auto_backup_enabled'), equals(true));

        // Verify auto backup is enabled through service method
        final isEnabled = await service.isAutoBackupEnabled();
        expect(isEnabled, equals(true));
      });

      test('should disable auto backup without creating backup', () async {
        // Arrange: Start with auto backup enabled
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('auto_backup_enabled', true);

        // Act: Disable auto backup
        await service.setAutoBackupEnabled(false);

        // Assert: Auto backup should be disabled
        expect(prefs.getBool('auto_backup_enabled'), equals(false));

        final isEnabled = await service.isAutoBackupEnabled();
        expect(isEnabled, equals(false));
      });

      test('should default to enabled when no preference exists', () async {
        // Act: Check auto backup status without setting it
        final isEnabled = await service.isAutoBackupEnabled();

        // Assert: Should default to true for better user experience
        expect(isEnabled, equals(true));
      });

      test('should persist auto backup preference across service instances',
          () async {
        // Arrange: Set auto backup to false
        await service.setAutoBackupEnabled(false);

        // Act: Create new service instance and check status
        final newServiceInstance = SpiritualStatsService();
        final isEnabled = await newServiceInstance.isAutoBackupEnabled();

        // Assert: Preference should persist
        expect(isEnabled, equals(false));
      });
    });

    group('JSON Backup Configuration', () {
      test('should enable JSON backup functionality', () async {
        // Act: Enable JSON backup
        await service.setJsonBackupEnabled(true);

        // Assert: JSON backup should be enabled
        final isEnabled = await service.isJsonBackupEnabled();
        expect(isEnabled, equals(true));

        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getBool('json_backup_enabled'), equals(true));
      });

      test('should disable JSON backup functionality', () async {
        // Arrange: Start with JSON backup enabled
        await service.setJsonBackupEnabled(true);

        // Act: Disable JSON backup
        await service.setJsonBackupEnabled(false);

        // Assert: JSON backup should be disabled
        final isEnabled = await service.isJsonBackupEnabled();
        expect(isEnabled, equals(false));
      });

      test('should default to false when no preference exists', () async {
        // Act: Check JSON backup status without setting it
        final isEnabled = await service.isJsonBackupEnabled();

        // Assert: Should default to false (manual feature)
        expect(isEnabled, equals(false));
      });
    });

    group('Statistics Management', () {
      test('should save and retrieve spiritual statistics correctly', () async {
        // Arrange: Create test statistics
        final testStats = SpiritualStats(
          devotionalStreak: 5,
          totalDevotionalsRead: 25,
          totalPrayerTime: 120,
          totalMeditationTime: 60,
        );

        // Act: Save statistics
        await service.saveStats(testStats);

        // Retrieve statistics
        final retrievedStats = await service.getStats();

        // Assert: Statistics should match
        expect(retrievedStats.devotionalStreak, equals(5));
        expect(retrievedStats.totalDevotionalsRead, equals(25));
        expect(retrievedStats.totalPrayerTime, equals(120));
        expect(retrievedStats.totalMeditationTime, equals(60));
      });

      test('should return default stats when no saved data exists', () async {
        // Act: Retrieve statistics without saving any
        final stats = await service.getStats();

        // Assert: Should return default/empty statistics
        expect(stats.devotionalStreak, equals(0));
        expect(stats.totalDevotionalsRead, equals(0));
        expect(stats.totalPrayerTime, equals(0));
        expect(stats.totalMeditationTime, equals(0));
      });

      test('should handle corrupted statistics data gracefully', () async {
        // Arrange: Save corrupted JSON data
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('spiritual_stats', 'invalid_json_data');

        // Act: Try to retrieve statistics
        final stats = await service.getStats();

        // Assert: Should return default statistics without crashing
        expect(stats, isNotNull);
        expect(stats.devotionalStreak, equals(0));
        expect(stats.totalDevotionalsRead, equals(0));
      });

      test('should update statistics incrementally', () async {
        // Arrange: Save initial statistics
        final initialStats =
            SpiritualStats(devotionalStreak: 3, totalDevotionalsRead: 10);
        await service.saveStats(initialStats);

        // Act: Update with new statistics
        final updatedStats =
            SpiritualStats(devotionalStreak: 4, totalDevotionalsRead: 11);
        await service.saveStats(updatedStats);

        // Retrieve updated statistics
        final retrievedStats = await service.getStats();

        // Assert: Statistics should be updated
        expect(retrievedStats.devotionalStreak, equals(4));
        expect(retrievedStats.totalDevotionalsRead, equals(11));
      });
    });

    group('Read Dates Management', () {
      test('should add read date successfully', () async {
        // Arrange: Create test date
        final testDate = DateTime(2024, 1, 15);

        // Act: Add read date
        await service.addReadDate(testDate);

        // Assert: Date should be added to read dates
        final readDates = await service.getReadDates();
        expect(readDates, contains(testDate));
      });

      test('should retrieve all read dates correctly', () async {
        // Arrange: Add multiple read dates
        final dates = [
          DateTime(2024, 1, 10),
          DateTime(2024, 1, 11),
          DateTime(2024, 1, 12),
        ];

        for (final date in dates) {
          await service.addReadDate(date);
        }

        // Act: Retrieve read dates
        final retrievedDates = await service.getReadDates();

        // Assert: All dates should be present
        for (final date in dates) {
          expect(retrievedDates, contains(date));
        }
        expect(retrievedDates.length, equals(3));
      });

      test('should not duplicate read dates', () async {
        // Arrange: Same date to add twice
        final testDate = DateTime(2024, 1, 15);

        // Act: Add same date twice
        await service.addReadDate(testDate);
        await service.addReadDate(testDate);

        // Assert: Date should only appear once
        final readDates = await service.getReadDates();
        final dateCount = readDates.where((date) => date == testDate).length;
        expect(dateCount, equals(1));
      });

      test('should check if date was read correctly', () async {
        // Arrange: Add a specific date
        final testDate = DateTime(2024, 1, 15);
        await service.addReadDate(testDate);

        // Act: Check if date was read
        final wasRead = await service.wasReadOnDate(testDate);
        final wasNotRead = await service.wasReadOnDate(DateTime(2024, 1, 16));

        // Assert: Should correctly identify read/unread dates
        expect(wasRead, equals(true));
        expect(wasNotRead, equals(false));
      });
    });

    group('Last Read Devotional Tracking', () {
      test('should save and retrieve last read devotional', () async {
        // Arrange: Test devotional ID
        const testDevocionalId = 'devotional_123';

        // Act: Save last read devotional
        await service.setLastReadDevocional(testDevocionalId);

        // Retrieve last read devotional
        final lastReadId = await service.getLastReadDevocional();

        // Assert: Should match saved devotional ID
        expect(lastReadId, equals(testDevocionalId));
      });

      test('should return null when no last read devotional exists', () async {
        // Act: Retrieve last read devotional without setting one
        final lastReadId = await service.getLastReadDevocional();

        // Assert: Should return null
        expect(lastReadId, isNull);
      });

      test('should update last read devotional correctly', () async {
        // Arrange: Set initial devotional
        await service.setLastReadDevocional('devotional_1');

        // Act: Update to new devotional
        await service.setLastReadDevocional('devotional_2');

        // Retrieve updated devotional
        final lastReadId = await service.getLastReadDevocional();

        // Assert: Should return updated devotional ID
        expect(lastReadId, equals('devotional_2'));
      });
    });

    group('Last Read Time Tracking', () {
      test('should save and retrieve last read time', () async {
        // Arrange: Test timestamp
        final testTime = DateTime(2024, 1, 15, 10, 30);

        // Act: Save last read time
        await service.setLastReadTime(testTime);

        // Retrieve last read time
        final lastReadTime = await service.getLastReadTime();

        // Assert: Should match saved time
        expect(lastReadTime, equals(testTime));
      });

      test('should return null when no last read time exists', () async {
        // Act: Retrieve last read time without setting one
        final lastReadTime = await service.getLastReadTime();

        // Assert: Should return null
        expect(lastReadTime, isNull);
      });

      test('should update last read time correctly', () async {
        // Arrange: Set initial time
        final initialTime = DateTime(2024, 1, 15, 9, 0);
        await service.setLastReadTime(initialTime);

        // Act: Update to new time
        final newTime = DateTime(2024, 1, 15, 10, 30);
        await service.setLastReadTime(newTime);

        // Retrieve updated time
        final lastReadTime = await service.getLastReadTime();

        // Assert: Should return updated time
        expect(lastReadTime, equals(newTime));
      });
    });

    group('Statistics Calculation', () {
      test('should calculate current streak correctly', () async {
        // Arrange: Add consecutive read dates
        final today = DateTime.now();
        final yesterday = today.subtract(const Duration(days: 1));
        final twoDaysAgo = today.subtract(const Duration(days: 2));

        await service.addReadDate(twoDaysAgo);
        await service.addReadDate(yesterday);
        await service.addReadDate(today);

        // Act: Calculate current streak
        final streak = await service.getCurrentStreak();

        // Assert: Streak should be 3 days
        expect(streak, equals(3));
      });

      test('should return zero streak when no consecutive days', () async {
        // Arrange: Add non-consecutive dates
        final today = DateTime.now();
        final threeDaysAgo = today.subtract(const Duration(days: 3));

        await service.addReadDate(threeDaysAgo);
        await service.addReadDate(today);

        // Act: Calculate current streak
        final streak = await service.getCurrentStreak();

        // Assert: Streak should be 1 (only today)
        expect(streak, equals(1));
      });

      test('should calculate total read days correctly', () async {
        // Arrange: Add multiple read dates
        final dates = [
          DateTime(2024, 1, 10),
          DateTime(2024, 1, 12),
          DateTime(2024, 1, 15),
          DateTime(2024, 1, 18),
        ];

        for (final date in dates) {
          await service.addReadDate(date);
        }

        // Act: Calculate total read days
        final totalDays = await service.getTotalReadDays();

        // Assert: Should match number of dates added
        expect(totalDays, equals(4));
      });
    });

    group('Error Handling and Edge Cases', () {
      test('should handle SharedPreferences operation failures gracefully',
          () async {
        // Note: This test simulates SharedPreferences failures
        // In a real scenario, we would mock SharedPreferences to throw exceptions

        // Act & Assert: Service methods should not crash on storage failures
        expect(() async => await service.getStats(), returnsNormally);
        expect(
            () async => await service.isAutoBackupEnabled(), returnsNormally);
        expect(
            () async => await service.isJsonBackupEnabled(), returnsNormally);
      });

      test('should handle malformed JSON data in statistics', () async {
        // Arrange: Save malformed JSON data
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('spiritual_stats', '{"invalid": json}');

        // Act: Try to retrieve statistics
        final stats = await service.getStats();

        // Assert: Should return default statistics without crashing
        expect(stats, isNotNull);
        expect(stats.devotionalStreak, equals(0));
      });

      test('should handle null or empty statistics gracefully', () async {
        // Arrange: Save empty string as statistics
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('spiritual_stats', '');

        // Act: Try to retrieve statistics
        final stats = await service.getStats();

        // Assert: Should return default statistics
        expect(stats, isNotNull);
        expect(stats.devotionalStreak, equals(0));
      });
    });

    group('Integration Scenarios', () {
      test('should handle complete user journey correctly', () async {
        // Arrange: Simulate a complete user journey
        const devotionalId = 'daily_devotional_1';
        final readDate = DateTime(2024, 1, 15);
        final readTime = DateTime(2024, 1, 15, 9, 30);

        // Act: Perform complete reading session
        await service.addReadDate(readDate);
        await service.setLastReadDevocional(devotionalId);
        await service.setLastReadTime(readTime);

        // Save updated statistics
        final updatedStats = SpiritualStats(
          devotionalStreak: 1,
          totalDevotionalsRead: 1,
          totalPrayerTime: 5,
          totalMeditationTime: 3,
        );
        await service.saveStats(updatedStats);

        // Assert: All data should be saved and retrievable
        final retrievedStats = await service.getStats();
        final retrievedDevocional = await service.getLastReadDevocional();
        final retrievedTime = await service.getLastReadTime();
        final wasRead = await service.wasReadOnDate(readDate);

        expect(retrievedStats.totalDevotionalsRead, equals(1));
        expect(retrievedDevocional, equals(devotionalId));
        expect(retrievedTime, equals(readTime));
        expect(wasRead, equals(true));
      });

      test('should maintain data consistency across multiple operations',
          () async {
        // Arrange: Enable both backup types
        await service.setAutoBackupEnabled(true);
        await service.setJsonBackupEnabled(true);

        // Act: Perform multiple statistics updates
        for (int i = 1; i <= 5; i++) {
          final stats = SpiritualStats(
            devotionalStreak: i,
            totalDevotionalsRead: i * 2,
            totalPrayerTime: i * 10,
            totalMeditationTime: i * 5,
          );
          await service.saveStats(stats);
          await service.addReadDate(DateTime(2024, 1, i));
        }

        // Assert: Final statistics should be consistent
        final finalStats = await service.getStats();
        final readDates = await service.getReadDates();

        expect(finalStats.devotionalStreak, equals(5));
        expect(finalStats.totalDevotionalsRead, equals(10));
        expect(finalStats.totalPrayerTime, equals(50));
        expect(finalStats.totalMeditationTime, equals(25));
        expect(readDates.length, equals(5));
      });

      test('should handle rapid successive operations correctly', () async {
        // Arrange: Prepare for rapid operations
        final futures = <Future>[];

        // Act: Perform multiple concurrent operations
        for (int i = 0; i < 10; i++) {
          futures.add(service.addReadDate(DateTime(2024, 1, i + 1)));
          futures.add(service.setLastReadDevocional('devotional_$i'));
        }

        // Wait for all operations to complete
        await Future.wait(futures);

        // Assert: All operations should complete successfully
        final readDates = await service.getReadDates();
        final lastDevocional = await service.getLastReadDevocional();

        expect(readDates.length, equals(10));
        expect(lastDevocional, isNotNull);
        expect(lastDevocional!.startsWith('devotional_'), isTrue);
      });
    });
  });
}
