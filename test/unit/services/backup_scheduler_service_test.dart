// test/unit/services/backup_scheduler_service_test.dart
import 'package:devocional_nuevo/services/backup_scheduler_service.dart';
import 'package:devocional_nuevo/services/connectivity_service.dart';
import 'package:devocional_nuevo/services/google_drive_backup_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

/// Mock class for GoogleDriveBackupService
class MockGoogleDriveBackupService extends Mock
    implements GoogleDriveBackupService {}

/// Mock class for ConnectivityService
class MockConnectivityService extends Mock implements ConnectivityService {}

void main() {
  group('BackupSchedulerService Tests', () {
    late BackupSchedulerService service;
    late MockGoogleDriveBackupService mockBackupService;
    late MockConnectivityService mockConnectivityService;

    setUp(() {
      // Initialize mocks
      mockBackupService = MockGoogleDriveBackupService();
      mockConnectivityService = MockConnectivityService();

      // Create service instance with mocked dependencies
      service = BackupSchedulerService(
        backupService: mockBackupService,
        connectivityService: mockConnectivityService,
      );
    });

    group('initialize', () {
      test('should complete initialization without errors', () async {
        // Act & Assert - Should complete without throwing
        await expectLater(
          BackupSchedulerService.initialize(),
          completes,
        );
      });

      test('should be called multiple times without issues', () async {
        // Act - Multiple initialization calls
        await BackupSchedulerService.initialize();
        await BackupSchedulerService.initialize();
        await BackupSchedulerService.initialize();

        // Assert - Should complete without errors
        expect(true, isTrue); // Test passes if no exceptions thrown
      });
    });

    group('scheduleAutomaticBackup', () {
      test('should complete scheduling without errors', () async {
        // Act & Assert - Should complete without throwing
        await expectLater(
          service.scheduleAutomaticBackup(),
          completes,
        );
      });

      test('should be idempotent when called multiple times', () async {
        // Act - Multiple scheduling calls
        await service.scheduleAutomaticBackup();
        await service.scheduleAutomaticBackup();
        await service.scheduleAutomaticBackup();

        // Assert - Should complete without errors
        expect(true, isTrue); // Test passes if no exceptions thrown
      });
    });

    group('cancelAutomaticBackup', () {
      test('should complete cancellation without errors', () async {
        // Act & Assert - Should complete without throwing
        await expectLater(
          service.cancelAutomaticBackup(),
          completes,
        );
      });

      test('should be safe to call without prior scheduling', () async {
        // Act - Cancel without scheduling first
        await service.cancelAutomaticBackup();

        // Assert - Should complete without errors
        expect(true, isTrue); // Test passes if no exceptions thrown
      });

      test('should be idempotent when called multiple times', () async {
        // Act - Multiple cancellation calls
        await service.cancelAutomaticBackup();
        await service.cancelAutomaticBackup();
        await service.cancelAutomaticBackup();

        // Assert - Should complete without errors
        expect(true, isTrue); // Test passes if no exceptions thrown
      });
    });

    group('shouldRunBackup', () {
      test('should return false when auto backup is disabled', () async {
        // Arrange
        when(() => mockBackupService.isAutoBackupEnabled())
            .thenAnswer((_) async => false);

        // Act
        final result = await service.shouldRunBackup();

        // Assert
        expect(result, isFalse);
        verify(() => mockBackupService.isAutoBackupEnabled()).called(1);
        verifyNever(() => mockBackupService.shouldCreateAutoBackup());
        verifyNever(() => mockBackupService.isWifiOnlyEnabled());
        verifyNever(
            () => mockConnectivityService.shouldProceedWithBackup(any()));
      });

      test(
          'should return false when auto backup is enabled but should not create backup',
          () async {
        // Arrange
        when(() => mockBackupService.isAutoBackupEnabled())
            .thenAnswer((_) async => true);
        when(() => mockBackupService.shouldCreateAutoBackup())
            .thenAnswer((_) async => false);

        // Act
        final result = await service.shouldRunBackup();

        // Assert
        expect(result, isFalse);
        verify(() => mockBackupService.isAutoBackupEnabled()).called(1);
        verify(() => mockBackupService.shouldCreateAutoBackup()).called(1);
        verifyNever(() => mockBackupService.isWifiOnlyEnabled());
        verifyNever(
            () => mockConnectivityService.shouldProceedWithBackup(any()));
      });

      test(
          'should return false when backup conditions met but connectivity check fails',
          () async {
        // Arrange
        when(() => mockBackupService.isAutoBackupEnabled())
            .thenAnswer((_) async => true);
        when(() => mockBackupService.shouldCreateAutoBackup())
            .thenAnswer((_) async => true);
        when(() => mockBackupService.isWifiOnlyEnabled())
            .thenAnswer((_) async => true);
        when(() => mockConnectivityService.shouldProceedWithBackup(true))
            .thenAnswer((_) async => false);

        // Act
        final result = await service.shouldRunBackup();

        // Assert
        expect(result, isFalse);
        verify(() => mockBackupService.isAutoBackupEnabled()).called(1);
        verify(() => mockBackupService.shouldCreateAutoBackup()).called(1);
        verify(() => mockBackupService.isWifiOnlyEnabled()).called(1);
        verify(() => mockConnectivityService.shouldProceedWithBackup(true))
            .called(1);
      });

      test(
          'should return true when all backup conditions are met with WiFi-only enabled',
          () async {
        // Arrange
        when(() => mockBackupService.isAutoBackupEnabled())
            .thenAnswer((_) async => true);
        when(() => mockBackupService.shouldCreateAutoBackup())
            .thenAnswer((_) async => true);
        when(() => mockBackupService.isWifiOnlyEnabled())
            .thenAnswer((_) async => true);
        when(() => mockConnectivityService.shouldProceedWithBackup(true))
            .thenAnswer((_) async => true);

        // Act
        final result = await service.shouldRunBackup();

        // Assert
        expect(result, isTrue);
        verify(() => mockBackupService.isAutoBackupEnabled()).called(1);
        verify(() => mockBackupService.shouldCreateAutoBackup()).called(1);
        verify(() => mockBackupService.isWifiOnlyEnabled()).called(1);
        verify(() => mockConnectivityService.shouldProceedWithBackup(true))
            .called(1);
      });

      test(
          'should return true when all backup conditions are met with WiFi-only disabled',
          () async {
        // Arrange
        when(() => mockBackupService.isAutoBackupEnabled())
            .thenAnswer((_) async => true);
        when(() => mockBackupService.shouldCreateAutoBackup())
            .thenAnswer((_) async => true);
        when(() => mockBackupService.isWifiOnlyEnabled())
            .thenAnswer((_) async => false);
        when(() => mockConnectivityService.shouldProceedWithBackup(false))
            .thenAnswer((_) async => true);

        // Act
        final result = await service.shouldRunBackup();

        // Assert
        expect(result, isTrue);
        verify(() => mockBackupService.isAutoBackupEnabled()).called(1);
        verify(() => mockBackupService.shouldCreateAutoBackup()).called(1);
        verify(() => mockBackupService.isWifiOnlyEnabled()).called(1);
        verify(() => mockConnectivityService.shouldProceedWithBackup(false))
            .called(1);
      });

      test('should pass correct WiFi-only setting to connectivity service',
          () async {
        // Test cases for different WiFi-only settings
        final testCases = [
          {'wifiOnly': true, 'description': 'WiFi-only enabled'},
          {'wifiOnly': false, 'description': 'WiFi-only disabled'},
        ];

        for (final testCase in testCases) {
          final wifiOnly = testCase['wifiOnly'] as bool;
          final description = testCase['description'] as String;

          // Arrange
          when(() => mockBackupService.isAutoBackupEnabled())
              .thenAnswer((_) async => true);
          when(() => mockBackupService.shouldCreateAutoBackup())
              .thenAnswer((_) async => true);
          when(() => mockBackupService.isWifiOnlyEnabled())
              .thenAnswer((_) async => wifiOnly);
          when(() => mockConnectivityService.shouldProceedWithBackup(wifiOnly))
              .thenAnswer((_) async => true);

          // Act
          await service.shouldRunBackup();

          // Assert
          verify(() =>
                  mockConnectivityService.shouldProceedWithBackup(wifiOnly))
              .called(1);

          // Reset mocks for next iteration
          reset(mockBackupService);
          reset(mockConnectivityService);
        }
      });
    });

    group('error handling', () {
      test(
          'should throw exception when backup service errors in shouldRunBackup',
          () async {
        // Arrange
        when(() => mockBackupService.isAutoBackupEnabled())
            .thenThrow(Exception('Backup service error'));

        // Act & Assert
        await expectLater(
          service.shouldRunBackup(),
          throwsA(isA<Exception>()),
        );
      });

      test('should throw exception when connectivity service errors', () async {
        // Arrange
        when(() => mockBackupService.isAutoBackupEnabled())
            .thenAnswer((_) async => true);
        when(() => mockBackupService.shouldCreateAutoBackup())
            .thenAnswer((_) async => true);
        when(() => mockBackupService.isWifiOnlyEnabled())
            .thenAnswer((_) async => true);
        when(() => mockConnectivityService.shouldProceedWithBackup(any()))
            .thenThrow(Exception('Connectivity error'));

        // Act & Assert
        await expectLater(
          service.shouldRunBackup(),
          throwsA(isA<Exception>()),
        );
      });

      test('should throw exception for individual service method errors',
          () async {
        // Test each service method error individually
        final errorScenarios = [
          {
            'description': 'shouldCreateAutoBackup throws error',
            'setup': () {
              when(() => mockBackupService.isAutoBackupEnabled())
                  .thenAnswer((_) async => true);
              when(() => mockBackupService.shouldCreateAutoBackup())
                  .thenThrow(Exception('Create backup error'));
            },
          },
          {
            'description': 'isWifiOnlyEnabled throws error',
            'setup': () {
              when(() => mockBackupService.isAutoBackupEnabled())
                  .thenAnswer((_) async => true);
              when(() => mockBackupService.shouldCreateAutoBackup())
                  .thenAnswer((_) async => true);
              when(() => mockBackupService.isWifiOnlyEnabled())
                  .thenThrow(Exception('WiFi setting error'));
            },
          },
        ];

        for (final scenario in errorScenarios) {
          final description = scenario['description'] as String;
          final setup = scenario['setup'] as Function();

          // Arrange
          setup();

          // Act & Assert
          await expectLater(
            service.shouldRunBackup(),
            throwsA(isA<Exception>()),
            reason: description,
          );

          // Reset for next test
          reset(mockBackupService);
          reset(mockConnectivityService);
        }
      });
    });

    group('backup decision logic combinations', () {
      test('should test all possible backup decision combinations', () async {
        // Test matrix: [autoEnabled, shouldCreate, wifiOnly, connectivityOk, expectedResult]
        final testMatrix = [
          [false, false, false, false, false], // Auto disabled
          [false, false, false, true, false], // Auto disabled
          [false, false, true, false, false], // Auto disabled
          [false, false, true, true, false], // Auto disabled
          [false, true, false, false, false], // Auto disabled
          [false, true, false, true, false], // Auto disabled
          [false, true, true, false, false], // Auto disabled
          [false, true, true, true, false], // Auto disabled
          [true, false, false, false, false], // Should not create
          [true, false, false, true, false], // Should not create
          [true, false, true, false, false], // Should not create
          [true, false, true, true, false], // Should not create
          [true, true, false, false, false], // No connectivity
          [true, true, false, true, true], // All conditions met
          [true, true, true, false, false], // WiFi required but no connectivity
          [true, true, true, true, true], // All conditions met with WiFi
        ];

        for (int i = 0; i < testMatrix.length; i++) {
          final testCase = testMatrix[i];
          final autoEnabled = testCase[0] as bool;
          final shouldCreate = testCase[1] as bool;
          final wifiOnly = testCase[2] as bool;
          final connectivityOk = testCase[3] as bool;
          final expectedResult = testCase[4] as bool;

          // Arrange
          when(() => mockBackupService.isAutoBackupEnabled())
              .thenAnswer((_) async => autoEnabled);
          when(() => mockBackupService.shouldCreateAutoBackup())
              .thenAnswer((_) async => shouldCreate);
          when(() => mockBackupService.isWifiOnlyEnabled())
              .thenAnswer((_) async => wifiOnly);
          when(() => mockConnectivityService.shouldProceedWithBackup(wifiOnly))
              .thenAnswer((_) async => connectivityOk);

          // Act
          final result = await service.shouldRunBackup();

          // Assert
          expect(result, equals(expectedResult),
              reason:
                  'Test case $i failed: auto=$autoEnabled, create=$shouldCreate, '
                  'wifiOnly=$wifiOnly, connectivity=$connectivityOk, expected=$expectedResult');

          // Reset for next iteration
          reset(mockBackupService);
          reset(mockConnectivityService);
        }
      });

      test('should handle rapid successive calls correctly', () async {
        // Arrange
        when(() => mockBackupService.isAutoBackupEnabled())
            .thenAnswer((_) async => true);
        when(() => mockBackupService.shouldCreateAutoBackup())
            .thenAnswer((_) async => true);
        when(() => mockBackupService.isWifiOnlyEnabled())
            .thenAnswer((_) async => false);
        when(() => mockConnectivityService.shouldProceedWithBackup(false))
            .thenAnswer((_) async => true);

        // Act - Multiple rapid calls
        final results = await Future.wait([
          service.shouldRunBackup(),
          service.shouldRunBackup(),
          service.shouldRunBackup(),
          service.shouldRunBackup(),
          service.shouldRunBackup(),
        ]);

        // Assert
        expect(results, everyElement(isTrue));

        // Verify all calls went through
        verify(() => mockBackupService.isAutoBackupEnabled()).called(5);
        verify(() => mockBackupService.shouldCreateAutoBackup()).called(5);
        verify(() => mockBackupService.isWifiOnlyEnabled()).called(5);
        verify(() => mockConnectivityService.shouldProceedWithBackup(false))
            .called(5);
      });
    });

    group('service lifecycle', () {
      test('should handle service method calls in various orders', () async {
        // Test different method call sequences
        final sequences = [
          ['schedule', 'cancel', 'shouldRun'],
          ['cancel', 'schedule', 'shouldRun'],
          ['shouldRun', 'schedule', 'cancel'],
          ['shouldRun', 'shouldRun', 'schedule'],
        ];

        for (final sequence in sequences) {
          // Setup mocks for shouldRunBackup
          when(() => mockBackupService.isAutoBackupEnabled())
              .thenAnswer((_) async => true);
          when(() => mockBackupService.shouldCreateAutoBackup())
              .thenAnswer((_) async => true);
          when(() => mockBackupService.isWifiOnlyEnabled())
              .thenAnswer((_) async => false);
          when(() => mockConnectivityService.shouldProceedWithBackup(false))
              .thenAnswer((_) async => true);

          // Act - Execute sequence
          for (final method in sequence) {
            switch (method) {
              case 'schedule':
                await service.scheduleAutomaticBackup();
                break;
              case 'cancel':
                await service.cancelAutomaticBackup();
                break;
              case 'shouldRun':
                await service.shouldRunBackup();
                break;
            }
          }

          // Assert - All operations should complete without errors
          expect(true, isTrue, reason: 'Sequence $sequence failed');

          // Reset for next sequence
          reset(mockBackupService);
          reset(mockConnectivityService);
        }
      });

      test('should be safe to call methods concurrently', () async {
        // Arrange
        when(() => mockBackupService.isAutoBackupEnabled())
            .thenAnswer((_) async => true);
        when(() => mockBackupService.shouldCreateAutoBackup())
            .thenAnswer((_) async => true);
        when(() => mockBackupService.isWifiOnlyEnabled())
            .thenAnswer((_) async => false);
        when(() => mockConnectivityService.shouldProceedWithBackup(false))
            .thenAnswer((_) async => true);

        // Act - Concurrent method calls
        final futures = <Future>[];
        for (int i = 0; i < 3; i++) {
          futures.add(service.scheduleAutomaticBackup());
          futures.add(service.cancelAutomaticBackup());
          futures.add(service.shouldRunBackup());
        }

        // Assert - All should complete without errors
        await expectLater(Future.wait(futures), completes);
      });
    });

    group('performance and reliability', () {
      test('should complete shouldRunBackup within reasonable time', () async {
        // Arrange
        when(() => mockBackupService.isAutoBackupEnabled())
            .thenAnswer((_) async => true);
        when(() => mockBackupService.shouldCreateAutoBackup())
            .thenAnswer((_) async => true);
        when(() => mockBackupService.isWifiOnlyEnabled())
            .thenAnswer((_) async => true);
        when(() => mockConnectivityService.shouldProceedWithBackup(true))
            .thenAnswer((_) async => true);

        // Act
        final stopwatch = Stopwatch()..start();
        final result = await service.shouldRunBackup();
        stopwatch.stop();

        // Assert
        expect(result, isTrue);
        expect(stopwatch.elapsedMilliseconds, lessThan(100),
            reason:
                'shouldRunBackup took too long: ${stopwatch.elapsedMilliseconds}ms');
      });

      test('should handle service delays gracefully', () async {
        // Arrange - Simulate slow services
        when(() => mockBackupService.isAutoBackupEnabled())
            .thenAnswer((_) async {
          await Future.delayed(const Duration(milliseconds: 50));
          return true;
        });
        when(() => mockBackupService.shouldCreateAutoBackup())
            .thenAnswer((_) async {
          await Future.delayed(const Duration(milliseconds: 50));
          return true;
        });
        when(() => mockBackupService.isWifiOnlyEnabled()).thenAnswer((_) async {
          await Future.delayed(const Duration(milliseconds: 50));
          return false;
        });
        when(() => mockConnectivityService.shouldProceedWithBackup(false))
            .thenAnswer((_) async {
          await Future.delayed(const Duration(milliseconds: 50));
          return true;
        });

        // Act
        final stopwatch = Stopwatch()..start();
        final result = await service.shouldRunBackup();
        stopwatch.stop();

        // Assert
        expect(result, isTrue);
        expect(stopwatch.elapsedMilliseconds, greaterThan(150),
            reason: 'Should account for all delays');
        expect(stopwatch.elapsedMilliseconds, lessThan(1000),
            reason: 'Should not take excessively long');
      });
    });
  });
}
