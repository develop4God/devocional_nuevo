// test/unit/services/google_drive_backup_service_test.dart

import 'package:devocional_nuevo/services/connectivity_service.dart';
import 'package:devocional_nuevo/services/google_drive_auth_service.dart';
import 'package:devocional_nuevo/services/google_drive_backup_service.dart';
import 'package:devocional_nuevo/services/spiritual_stats_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Mock classes for dependencies
class MockGoogleDriveAuthService extends Mock
    implements GoogleDriveAuthService {}

class MockConnectivityService extends Mock implements ConnectivityService {}

class MockSpiritualStatsService extends Mock implements SpiritualStatsService {}

/// Comprehensive unit test suite for GoogleDriveBackupService
///
/// This test suite validates the core business logic of the GoogleDriveBackupService,
/// focusing on configuration management, backup scheduling, size estimation,
/// and error handling scenarios. Tests are isolated, fast, and independent of UI changes.
void main() {
  group('GoogleDriveBackupService Tests', () {
    late GoogleDriveBackupService service;
    late MockGoogleDriveAuthService mockAuthService;
    late MockConnectivityService mockConnectivityService;
    late MockSpiritualStatsService mockStatsService;

    /// Setup before each test - initializes mocks and service instance
    setUp(() {
      // Initialize mock dependencies
      mockAuthService = MockGoogleDriveAuthService();
      mockConnectivityService = MockConnectivityService();
      mockStatsService = MockSpiritualStatsService();

      // Create service instance with mocked dependencies
      service = GoogleDriveBackupService(
        authService: mockAuthService,
        connectivityService: mockConnectivityService,
        statsService: mockStatsService,
      );

      // Setup SharedPreferences for testing
      SharedPreferences.setMockInitialValues({});
    });

    group('Auto Backup Configuration', () {
      test('should return false for auto backup when not configured', () async {
        // Act
        final result = await service.isAutoBackupEnabled();

        // Assert
        expect(result, isFalse,
            reason: 'Auto backup should be disabled by default');
      });

      test('should enable auto backup successfully', () async {
        // Act
        await service.setAutoBackupEnabled(true);
        final result = await service.isAutoBackupEnabled();

        // Assert
        expect(result, isTrue,
            reason: 'Auto backup should be enabled after setting to true');
      });

      test('should disable auto backup successfully', () async {
        // Arrange - First enable auto backup
        await service.setAutoBackupEnabled(true);
        expect(await service.isAutoBackupEnabled(), isTrue);

        // Act
        await service.setAutoBackupEnabled(false);
        final result = await service.isAutoBackupEnabled();

        // Assert
        expect(result, isFalse,
            reason: 'Auto backup should be disabled after setting to false');
      });

      test('should persist auto backup setting across service instances',
          () async {
        // Arrange
        await service.setAutoBackupEnabled(true);

        // Act - Create new service instance
        final newService = GoogleDriveBackupService(
          authService: mockAuthService,
          connectivityService: mockConnectivityService,
          statsService: mockStatsService,
        );
        final result = await newService.isAutoBackupEnabled();

        // Assert
        expect(result, isTrue,
            reason:
                'Auto backup setting should persist across service instances');
      });
    });

    group('Backup Frequency Management', () {
      test('should return daily as default backup frequency', () async {
        // Act
        final result = await service.getBackupFrequency();

        // Assert
        expect(result, equals(GoogleDriveBackupService.frequencyDaily),
            reason: 'Default backup frequency should be daily');
      });

      test('should set manual backup frequency correctly', () async {
        // Act
        await service
            .setBackupFrequency(GoogleDriveBackupService.frequencyManual);
        final result = await service.getBackupFrequency();

        // Assert
        expect(result, equals(GoogleDriveBackupService.frequencyManual),
            reason: 'Backup frequency should be set to manual');
      });

      test('should set deactivated backup frequency correctly', () async {
        // Act
        await service.setBackupFrequency(
          GoogleDriveBackupService.frequencyDeactivated,
        );
        final result = await service.getBackupFrequency();

        // Assert
        expect(result, equals(GoogleDriveBackupService.frequencyDeactivated),
            reason: 'Backup frequency should be set to deactivated');
      });

      test('should handle frequency transitions correctly', () async {
        // Test daily -> manual -> deactivated -> daily

        // Start with daily (default)
        expect(await service.getBackupFrequency(),
            equals(GoogleDriveBackupService.frequencyDaily));

        // Change to manual
        await service
            .setBackupFrequency(GoogleDriveBackupService.frequencyManual);
        expect(await service.getBackupFrequency(),
            equals(GoogleDriveBackupService.frequencyManual));

        // Change to deactivated
        await service.setBackupFrequency(
          GoogleDriveBackupService.frequencyDeactivated,
        );
        expect(await service.getBackupFrequency(),
            equals(GoogleDriveBackupService.frequencyDeactivated));

        // Back to daily
        await service
            .setBackupFrequency(GoogleDriveBackupService.frequencyDaily);
        expect(await service.getBackupFrequency(),
            equals(GoogleDriveBackupService.frequencyDaily));
      });
    });

    group('WiFi-Only Settings', () {
      test('should default to WiFi-only enabled for data conservation',
          () async {
        // Act
        final result = await service.isWifiOnlyEnabled();

        // Assert
        expect(result, isTrue,
            reason:
                'WiFi-only should be enabled by default to save mobile data');
      });

      test('should allow disabling WiFi-only requirement', () async {
        // Act
        await service.setWifiOnlyEnabled(false);
        final result = await service.isWifiOnlyEnabled();

        // Assert
        expect(result, isFalse,
            reason: 'WiFi-only should be disabled when set to false');
      });

      test('should toggle WiFi-only setting correctly', () async {
        // Arrange - Verify default state
        expect(await service.isWifiOnlyEnabled(), isTrue);

        // Act - Disable WiFi-only
        await service.setWifiOnlyEnabled(false);
        expect(await service.isWifiOnlyEnabled(), isFalse);

        // Act - Re-enable WiFi-only
        await service.setWifiOnlyEnabled(true);
        final result = await service.isWifiOnlyEnabled();

        // Assert
        expect(result, isTrue,
            reason: 'WiFi-only should be re-enabled correctly');
      });
    });

    group('Data Compression Settings', () {
      test('should default to compression enabled for smaller backups',
          () async {
        // Act
        final result = await service.isCompressionEnabled();

        // Assert
        expect(result, isTrue,
            reason:
                'Compression should be enabled by default for smaller backups');
      });

      test('should allow disabling data compression', () async {
        // Act
        await service.setCompressionEnabled(false);
        final result = await service.isCompressionEnabled();

        // Assert
        expect(result, isFalse,
            reason: 'Compression should be disabled when set to false');
      });

      test('should handle compression toggle scenarios', () async {
        // Arrange - Verify default state
        expect(await service.isCompressionEnabled(), isTrue);

        // Act - Disable compression
        await service.setCompressionEnabled(false);
        expect(await service.isCompressionEnabled(), isFalse);

        // Act - Re-enable compression
        await service.setCompressionEnabled(true);
        final result = await service.isCompressionEnabled();

        // Assert
        expect(result, isTrue,
            reason: 'Compression should be re-enabled correctly');
      });
    });

    group('Backup Options Management', () {
      test('should provide sensible default backup options', () async {
        // Act
        final result = await service.getBackupOptions();

        // Assert
        expect(result, isA<Map<String, bool>>(),
            reason: 'Should return a map of backup options');
        expect(result.containsKey('spiritual_stats'), isTrue,
            reason: 'Should include spiritual stats option');
        expect(result.containsKey('favorite_devotionals'), isTrue,
            reason: 'Should include favorite devotionals option');
        expect(result.containsKey('saved_prayers'), isTrue,
            reason: 'Should include saved prayers option');
        expect(result['spiritual_stats'], isTrue,
            reason: 'Spiritual stats should be enabled by default');
        expect(result['favorite_devotionals'], isTrue,
            reason: 'Favorite devotionals should be enabled by default');
        expect(result['saved_prayers'], isTrue,
            reason: 'Saved prayers should be enabled by default');
      });

      test('should save and retrieve custom backup options', () async {
        // Arrange
        final customOptions = {
          'spiritual_stats': true,
          'favorite_devotionals': false,
          'saved_prayers': true,
          'custom_data': false,
        };

        // Act
        await service.setBackupOptions(customOptions);
        final result = await service.getBackupOptions();

        // Assert
        expect(result, equals(customOptions),
            reason:
                'Custom backup options should be saved and retrieved correctly');
      });

      test('should handle empty backup options', () async {
        // Arrange
        final emptyOptions = <String, bool>{};

        // Act
        await service.setBackupOptions(emptyOptions);
        final result = await service.getBackupOptions();

        // Assert
        expect(result, equals(emptyOptions),
            reason: 'Empty backup options should be handled correctly');
      });

      test('should update backup options incrementally', () async {
        // Arrange - Set initial options
        final initialOptions = {
          'spiritual_stats': true,
          'favorite_devotionals': true,
          'saved_prayers': true,
        };
        await service.setBackupOptions(initialOptions);

        // Act - Update to selective options
        final updatedOptions = {
          'spiritual_stats': false,
          'favorite_devotionals': true,
          'saved_prayers': false,
        };
        await service.setBackupOptions(updatedOptions);
        final result = await service.getBackupOptions();

        // Assert
        expect(result, equals(updatedOptions),
            reason: 'Backup options should be updated correctly');
        expect(result['spiritual_stats'], isFalse);
        expect(result['favorite_devotionals'], isTrue);
        expect(result['saved_prayers'], isFalse);
      });
    });

    group('Backup Time Management', () {
      test('should return null when no backup has been performed', () async {
        // Act
        final result = await service.getLastBackupTime();

        // Assert
        expect(result, isNull,
            reason:
                'Last backup time should be null when no backup has been performed');
      });

      test('should calculate next backup time for daily frequency correctly',
          () async {
        // Arrange
        await service.setAutoBackupEnabled(true);
        await service
            .setBackupFrequency(GoogleDriveBackupService.frequencyDaily);

        // Simulate a previous backup
        final yesterday = DateTime.now().subtract(const Duration(days: 1));
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt(
          'last_google_drive_backup_time',
          yesterday.millisecondsSinceEpoch,
        );

        // Act
        final result = await service.getNextBackupTime();

        // Assert - Test business logic, not implementation details
        expect(result, isNotNull,
            reason:
                'Next backup time should be calculated for daily frequency');
        expect(result, isA<DateTime>(),
            reason: 'Should return a valid DateTime object');

        // Verify it's a reasonable time (should be current time or later)
        final now = DateTime.now();
        expect(
            result!.millisecondsSinceEpoch >= now.millisecondsSinceEpoch - 1000,
            isTrue,
            reason: 'Next backup should be at current time or later');
      });

      test('should return null for next backup when auto backup is disabled',
          () async {
        // Arrange
        await service.setAutoBackupEnabled(false);
        await service
            .setBackupFrequency(GoogleDriveBackupService.frequencyDaily);

        // Act
        final result = await service.getNextBackupTime();

        // Assert
        expect(result, isNull,
            reason:
                'Next backup time should be null when auto backup is disabled');
      });

      test('should return null for next backup with manual frequency',
          () async {
        // Arrange
        await service.setAutoBackupEnabled(true);
        await service
            .setBackupFrequency(GoogleDriveBackupService.frequencyManual);

        // Act
        final result = await service.getNextBackupTime();

        // Assert
        expect(result, isNull,
            reason: 'Next backup time should be null for manual frequency');
      });

      test('should return null for next backup with deactivated frequency',
          () async {
        // Arrange
        await service.setAutoBackupEnabled(true);
        await service.setBackupFrequency(
          GoogleDriveBackupService.frequencyDeactivated,
        );

        // Act
        final result = await service.getNextBackupTime();

        // Assert
        expect(result, isNull,
            reason:
                'Next backup time should be null for deactivated frequency');
      });
    });

    group('Backup Size Estimation', () {
      test('should estimate reasonable size with default options', () async {
        // Act
        final result = await service.getEstimatedBackupSize(null);

        // Assert
        expect(result, greaterThan(0),
            reason: 'Estimated backup size should be greater than zero');
        expect(result, equals(20 * 1024),
            reason: 'Default size should be 20KB (5KB stats + 15KB prayers)');
      });

      test('should estimate size with selective backup options', () async {
        // Arrange - Only spiritual stats enabled
        final selectiveOptions = {
          'spiritual_stats': true,
          'favorite_devotionals': false,
          'saved_prayers': false,
        };
        await service.setBackupOptions(selectiveOptions);

        // Act
        final result = await service.getEstimatedBackupSize(null);

        // Assert
        expect(result, equals(5 * 1024),
            reason: 'Size should be 5KB when only spiritual stats is enabled');
      });

      test('should return zero size when all options are disabled', () async {
        // Arrange - All backup options disabled
        final disabledOptions = {
          'spiritual_stats': false,
          'favorite_devotionals': false,
          'saved_prayers': false,
        };
        await service.setBackupOptions(disabledOptions);

        // Act
        final result = await service.getEstimatedBackupSize(null);

        // Assert
        expect(result, equals(0),
            reason: 'Size should be zero when all backup options are disabled');
      });

      test('should calculate different combinations correctly', () async {
        // Test case 1: Only saved prayers
        await service.setBackupOptions({
          'spiritual_stats': false,
          'favorite_devotionals': false,
          'saved_prayers': true,
        });
        expect(await service.getEstimatedBackupSize(null), equals(15 * 1024));

        // Test case 2: Stats and prayers only
        await service.setBackupOptions({
          'spiritual_stats': true,
          'favorite_devotionals': false,
          'saved_prayers': true,
        });
        expect(await service.getEstimatedBackupSize(null), equals(20 * 1024));

        // Test case 3: All options
        await service.setBackupOptions({
          'spiritual_stats': true,
          'favorite_devotionals': true,
          'saved_prayers': true,
        });
        expect(await service.getEstimatedBackupSize(null),
            equals(20 * 1024)); // Base without provider
      });
    });

    group('Storage Information Handling', () {
      test('should handle authentication failure gracefully', () async {
        // Arrange
        when(() => mockAuthService.getDriveApi()).thenAnswer((_) async => null);

        // Act
        final result = await service.getStorageInfo();

        // Assert - Should not throw but return default values with error info
        expect(result, isA<Map<String, dynamic>>(),
            reason: 'Should return storage info map on authentication failure');
        expect(result['used_gb'], equals(0.0),
            reason: 'Should return 0.0 GB used on authentication failure');
        expect(result['total_gb'], equals(15.0),
            reason: 'Should return 15.0 GB total on authentication failure');
        expect(result['percentage'], equals(0.0),
            reason: 'Should return 0.0% usage on authentication failure');
        expect(result.containsKey('error'), isTrue,
            reason: 'Should include error information');
        expect(result['error'].toString(), contains('Not authenticated'),
            reason: 'Error should indicate authentication failure');
      });

      test('should return default storage info on API errors', () async {
        // Arrange - Mock API that throws an error
        when(() => mockAuthService.getDriveApi())
            .thenThrow(Exception('Network timeout'));

        // Act
        final result = await service.getStorageInfo();

        // Assert
        expect(result, isA<Map<String, dynamic>>(),
            reason: 'Should return storage info map on API errors');
        expect(result['used_gb'], equals(0.0),
            reason: 'Should return 0.0 GB used on error');
        expect(result['total_gb'], equals(15.0),
            reason: 'Should return 15.0 GB total (default free account size)');
        expect(result['percentage'], equals(0.0),
            reason: 'Should return 0.0% usage on error');
        expect(result['used_bytes'], equals(0),
            reason: 'Should return 0 bytes used on error');
        expect(result['total_bytes'], equals(15 * 1024 * 1024 * 1024),
            reason: 'Should return correct total bytes (15GB)');
      });
    });

    group('Error Handling and Edge Cases', () {
      test('should gracefully handle SharedPreferences operations', () async {
        // Act & Assert - All these should complete without throwing
        expect(() => service.isAutoBackupEnabled(), returnsNormally,
            reason: 'isAutoBackupEnabled should not throw exceptions');
        expect(() => service.getBackupFrequency(), returnsNormally,
            reason: 'getBackupFrequency should not throw exceptions');
        expect(() => service.isWifiOnlyEnabled(), returnsNormally,
            reason: 'isWifiOnlyEnabled should not throw exceptions');
        expect(() => service.isCompressionEnabled(), returnsNormally,
            reason: 'isCompressionEnabled should not throw exceptions');
        expect(() => service.getBackupOptions(), returnsNormally,
            reason: 'getBackupOptions should not throw exceptions');
      });

      test(
          'should handle malformed JSON in backup options by throwing exception',
          () async {
        // Arrange - Manually set invalid JSON in SharedPreferences
        SharedPreferences.setMockInitialValues(
            {'google_drive_backup_options': 'invalid_json_content{{'});

        // Act & Assert - Should throw FormatException for malformed JSON
        expect(
          () => service.getBackupOptions(),
          throwsA(isA<FormatException>()),
          reason: 'Should throw FormatException for malformed JSON',
        );
      });

      test('should handle null devotional provider gracefully', () async {
        // Act
        final result = await service.getEstimatedBackupSize(null);

        // Assert - Should not crash and return reasonable estimate
        expect(result, greaterThanOrEqualTo(0),
            reason: 'Should return non-negative size with null provider');
      });
    });

    group('Integration and Business Logic', () {
      test('should maintain settings consistency across operations', () async {
        // Arrange & Act - Configure multiple settings
        await service.setAutoBackupEnabled(true);
        await service
            .setBackupFrequency(GoogleDriveBackupService.frequencyDaily);
        await service.setWifiOnlyEnabled(false);
        await service.setCompressionEnabled(true);

        final customOptions = {
          'spiritual_stats': true,
          'favorite_devotionals': true,
          'saved_prayers': false,
        };
        await service.setBackupOptions(customOptions);

        // Assert - All settings should be consistent and retrievable
        expect(await service.isAutoBackupEnabled(), isTrue,
            reason: 'Auto backup should remain enabled');
        expect(await service.getBackupFrequency(),
            equals(GoogleDriveBackupService.frequencyDaily),
            reason: 'Frequency should remain daily');
        expect(await service.isWifiOnlyEnabled(), isFalse,
            reason: 'WiFi-only should remain disabled');
        expect(await service.isCompressionEnabled(), isTrue,
            reason: 'Compression should remain enabled');
        expect(await service.getBackupOptions(), equals(customOptions),
            reason: 'Custom options should remain consistent');
      });

      test('should validate complex configuration sequence', () async {
        // Test a realistic configuration flow

        // Step 1: Initial setup (user first time)
        expect(await service.isAutoBackupEnabled(), isFalse);
        expect(await service.getBackupFrequency(),
            equals(GoogleDriveBackupService.frequencyDaily));

        // Step 2: User enables backup
        await service.setAutoBackupEnabled(true);
        await service.setWifiOnlyEnabled(true);
        expect(await service.isAutoBackupEnabled(), isTrue);
        expect(await service.isWifiOnlyEnabled(), isTrue);

        // Step 3: User customizes options
        await service.setCompressionEnabled(false);
        final customOptions = {
          'spiritual_stats': true,
          'favorite_devotionals': false,
          'saved_prayers': true,
        };
        await service.setBackupOptions(customOptions);

        // Step 4: User changes to manual backup
        await service
            .setBackupFrequency(GoogleDriveBackupService.frequencyManual);

        // Final validation
        expect(await service.isAutoBackupEnabled(), isTrue);
        expect(await service.getBackupFrequency(),
            equals(GoogleDriveBackupService.frequencyManual));
        expect(await service.isWifiOnlyEnabled(), isTrue);
        expect(await service.isCompressionEnabled(), isFalse);
        expect(await service.getBackupOptions(), equals(customOptions));
      });

      test('should validate backup timing logic for daily frequency', () async {
        // Arrange - Set up daily backup with last backup time
        await service.setAutoBackupEnabled(true);
        await service
            .setBackupFrequency(GoogleDriveBackupService.frequencyDaily);

        // Simulate last backup was yesterday at 1:00 AM
        final lastBackup = DateTime.now()
            .subtract(const Duration(days: 1))
            .copyWith(hour: 1, minute: 0, second: 0, millisecond: 0);

        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt(
          'last_google_drive_backup_time',
          lastBackup.millisecondsSinceEpoch,
        );

        // Act
        final nextBackupTime = await service.getNextBackupTime();

        // Assert - Test business logic, not specific time implementation
        expect(nextBackupTime, isNotNull,
            reason: 'Next backup time should be calculated');
        expect(nextBackupTime, isA<DateTime>(),
            reason: 'Should return a valid DateTime object');

        // Verify it's a reasonable time (should be current time or later)
        final now = DateTime.now();
        expect(
            nextBackupTime!.millisecondsSinceEpoch >=
                now.millisecondsSinceEpoch - 1000,
            isTrue,
            reason: 'Next backup should be at current time or later');
      });

      test('should validate backup size calculations with different options',
          () async {
        // Test matrix of backup size calculations

        final testCases = [
          {
            'options': {
              'spiritual_stats': true,
              'favorite_devotionals': false,
              'saved_prayers': false,
            },
            'expectedSize': 5 * 1024, // 5KB
            'description': 'Only spiritual stats',
          },
          {
            'options': {
              'spiritual_stats': false,
              'favorite_devotionals': false,
              'saved_prayers': true,
            },
            'expectedSize': 15 * 1024, // 15KB
            'description': 'Only saved prayers',
          },
          {
            'options': {
              'spiritual_stats': true,
              'favorite_devotionals': false,
              'saved_prayers': true,
            },
            'expectedSize': 20 * 1024, // 20KB
            'description': 'Stats and prayers',
          },
          {
            'options': {
              'spiritual_stats': false,
              'favorite_devotionals': false,
              'saved_prayers': false,
            },
            'expectedSize': 0, // 0KB
            'description': 'Nothing selected',
          },
        ];

        for (final testCase in testCases) {
          // Arrange
          await service.setBackupOptions(
            Map<String, bool>.from(testCase['options'] as Map),
          );

          // Act
          final size = await service.getEstimatedBackupSize(null);

          // Assert
          expect(size, equals(testCase['expectedSize']),
              reason:
                  'Size calculation incorrect for: ${testCase['description']}');
        }
      });
    });
  });
}
