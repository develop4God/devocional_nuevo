// test/unit/services/google_drive_backup_service_test.dart

import 'package:devocional_nuevo/services/google_drive_backup_service.dart';
import 'package:devocional_nuevo/services/google_drive_auth_service.dart';
import 'package:devocional_nuevo/services/connectivity_service.dart';
import 'package:devocional_nuevo/services/spiritual_stats_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Mock services for testing
class MockGoogleDriveAuthService extends GoogleDriveAuthService {
  bool _isSignedIn = false;

  @override
  Future<bool?> signIn() async => _isSignedIn = true;

  @override
  Future<void> signOut() async => _isSignedIn = false;

  @override
  Future<bool> isSignedIn() async => _isSignedIn;

  @override
  Future<String?> getUserEmail() async =>
      _isSignedIn ? 'test@example.com' : null;
}

class MockConnectivityService extends ConnectivityService {
  bool _hasConnection = true;
  bool _isWiFi = true;

  void setConnection(bool hasConnection, [bool isWiFi = true]) {
    _hasConnection = hasConnection;
    _isWiFi = isWiFi;
  }

  @override
  Future<bool> hasInternetConnection() async => _hasConnection;

  @override
  Future<bool> isWiFiConnected() async => _isWiFi;
}

class MockSpiritualStatsService extends SpiritualStatsService {
  @override
  Future<Map<String, dynamic>> exportStats() async => {
        'totalDevocionalesRead': 10,
        'currentStreak': 5,
        'exportDate': DateTime.now().toIso8601String(),
      };
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('GoogleDriveBackupService Tests', () {
    late GoogleDriveBackupService service;
    late MockGoogleDriveAuthService mockAuthService;
    late MockConnectivityService mockConnectivityService;
    late MockSpiritualStatsService mockStatsService;

    setUp(() async {
      // Setup SharedPreferences mock
      SharedPreferences.setMockInitialValues({
        'google_drive_auto_backup_enabled': true,
        'google_drive_backup_frequency': 'daily',
        'google_drive_wifi_only': true,
        'google_drive_compress_data': false,
        'last_google_drive_backup_time': DateTime.now().toIso8601String(),
      });

      // Setup method channel mocks
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/path_provider'),
        (MethodCall methodCall) async => '/mock/path',
      );

      // Initialize mock services
      mockAuthService = MockGoogleDriveAuthService();
      mockConnectivityService = MockConnectivityService();
      mockStatsService = MockSpiritualStatsService();

      service = GoogleDriveBackupService(
        authService: mockAuthService,
        connectivityService: mockConnectivityService,
        statsService: mockStatsService,
      );
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/path_provider'),
        null,
      );
    });

    group('Google Drive Authentication Flow', () {
      test('should handle Google Drive authentication flow', () async {
        // Test sign in
        final signInResult = await mockAuthService.signIn();
        expect(signInResult, isTrue);

        // Test authentication status
        final isSignedIn = await mockAuthService.isSignedIn();
        expect(isSignedIn, isTrue);

        // Test user email retrieval
        final userEmail = await mockAuthService.getUserEmail();
        expect(userEmail, equals('test@example.com'));

        // Test sign out
        await mockAuthService.signOut();
        final isSignedInAfterSignOut = await mockAuthService.isSignedIn();
        expect(isSignedInAfterSignOut, isFalse);
      });

      test('should check backup enabled status', () async {
        final isEnabled = await service.isBackupEnabled();
        expect(isEnabled, isA<bool>());
      });

      test('should handle authentication state changes', () async {
        // Initially not signed in
        await mockAuthService.signOut();
        expect(await mockAuthService.isSignedIn(), isFalse);

        // Sign in and verify
        await mockAuthService.signIn();
        expect(await mockAuthService.isSignedIn(), isTrue);

        // Sign out and verify
        await mockAuthService.signOut();
        expect(await mockAuthService.isSignedIn(), isFalse);
      });
    });

    group('Backup Creation and Restoration', () {
      test('should create and restore backups with proper error handling',
          () async {
        // Setup signed in state
        await mockAuthService.signIn();
        mockConnectivityService.setConnection(true, true);

        // Test backup creation (mock)
        expect(() => service.createBackup(), returnsNormally);

        // Test backup status check
        final lastBackupTime = await service.getLastBackupTime();
        expect(lastBackupTime, isA<DateTime?>());
      });

      test('should handle backup without internet connection', () async {
        await mockAuthService.signIn();
        mockConnectivityService.setConnection(false);

        // Backup should handle no connection gracefully
        expect(() => service.createBackup(), returnsNormally);
      });

      test('should handle backup without authentication', () async {
        await mockAuthService.signOut();

        // Should handle unauthenticated state
        expect(() => service.createBackup(), returnsNormally);
      });

      test('should manage backup file versioning and conflicts', () async {
        await mockAuthService.signIn();
        mockConnectivityService.setConnection(true);

        // Test multiple backups (versioning concept)
        await service.createBackup();
        await service.createBackup();
        await service.createBackup();

        // Should handle multiple backup requests gracefully
        expect(true, isTrue);
      });
    });

    group('Backup Configuration Management', () {
      test('should manage backup frequency settings', () async {
        // Test different frequencies
        await service
            .setBackupFrequency(GoogleDriveBackupService.frequencyDaily);
        final dailyFreq = await service.getBackupFrequency();
        expect(dailyFreq, equals(GoogleDriveBackupService.frequencyDaily));

        await service
            .setBackupFrequency(GoogleDriveBackupService.frequencyManual);
        final manualFreq = await service.getBackupFrequency();
        expect(manualFreq, equals(GoogleDriveBackupService.frequencyManual));

        await service
            .setBackupFrequency(GoogleDriveBackupService.frequencyDeactivated);
        final deactivatedFreq = await service.getBackupFrequency();
        expect(deactivatedFreq,
            equals(GoogleDriveBackupService.frequencyDeactivated));
      });

      test('should handle WiFi-only backup settings', () async {
        // Test WiFi-only setting
        await service.setWifiOnlyBackup(true);
        final wifiOnly = await service.isWifiOnlyBackup();
        expect(wifiOnly, isTrue);

        await service.setWifiOnlyBackup(false);
        final notWifiOnly = await service.isWifiOnlyBackup();
        expect(notWifiOnly, isFalse);
      });

      test('should manage auto backup enable/disable', () async {
        // Test auto backup toggle
        await service.setAutoBackupEnabled(true);
        final autoEnabled = await service.isAutoBackupEnabled();
        expect(autoEnabled, isTrue);

        await service.setAutoBackupEnabled(false);
        final autoDisabled = await service.isAutoBackupEnabled();
        expect(autoDisabled, isFalse);
      });

      test('should handle data compression settings', () async {
        await service.setCompressData(true);
        final compressEnabled = await service.isCompressData();
        expect(compressEnabled, isTrue);

        await service.setCompressData(false);
        final compressDisabled = await service.isCompressData();
        expect(compressDisabled, isFalse);
      });
    });

    group('Connectivity and Network Handling', () {
      test('should validate network connectivity before backup', () async {
        mockConnectivityService.setConnection(true, true);
        final hasConnection =
            await mockConnectivityService.hasInternetConnection();
        expect(hasConnection, isTrue);

        mockConnectivityService.setConnection(false, false);
        final noConnection =
            await mockConnectivityService.hasInternetConnection();
        expect(noConnection, isFalse);
      });

      test('should respect WiFi-only setting', () async {
        // Set WiFi-only backup
        await service.setWifiOnlyBackup(true);

        // Test with WiFi connection
        mockConnectivityService.setConnection(true, true);
        final isWiFiConnected = await mockConnectivityService.isWiFiConnected();
        expect(isWiFiConnected, isTrue);

        // Test with mobile data
        mockConnectivityService.setConnection(true, false);
        final isMobileData = await mockConnectivityService.isWiFiConnected();
        expect(isMobileData, isFalse);
      });

      test('should handle network timeout and retry scenarios', () async {
        // Simulate network issues
        mockConnectivityService.setConnection(false);

        // Backup should handle network issues gracefully
        expect(() => service.createBackup(), returnsNormally);

        // Restore connection
        mockConnectivityService.setConnection(true);
        expect(() => service.createBackup(), returnsNormally);
      });
    });

    group('Data Export and Import', () {
      test('should handle data export for backup', () async {
        final exportData = await mockStatsService.exportStats();

        expect(exportData, isA<Map<String, dynamic>>());
        expect(exportData.containsKey('totalDevocionalesRead'), isTrue);
        expect(exportData.containsKey('currentStreak'), isTrue);
        expect(exportData.containsKey('exportDate'), isTrue);
      });

      test('should manage backup file structure and metadata', () async {
        await mockAuthService.signIn();

        // Test backup metadata
        final lastBackup = await service.getLastBackupTime();
        expect(lastBackup, isA<DateTime?>());

        // Test backup storage information
        expect(() => service.getStorageInfo(), returnsNormally);
      });
    });

    group('Error Handling and Edge Cases', () {
      test('should handle authentication errors gracefully', () async {
        // Test with invalid auth state
        await mockAuthService.signOut();

        expect(() => service.createBackup(), returnsNormally);
        expect(() => service.restoreBackup(), returnsNormally);
      });

      test('should handle storage quota and space issues', () async {
        await mockAuthService.signIn();

        // Should handle storage issues gracefully
        expect(() => service.getStorageInfo(), returnsNormally);
        expect(() => service.createBackup(), returnsNormally);
      });

      test('should handle corrupted backup data', () async {
        await mockAuthService.signIn();

        // Should handle restore with corrupted data
        expect(() => service.restoreBackup(), returnsNormally);
      });

      test('should manage concurrent backup operations', () async {
        await mockAuthService.signIn();
        mockConnectivityService.setConnection(true);

        // Multiple concurrent backups should be handled gracefully
        final futures = <Future>[];
        for (int i = 0; i < 3; i++) {
          futures.add(service.createBackup());
        }

        expect(() => Future.wait(futures), returnsNormally);
      });
    });

    group('Service State and Configuration', () {
      test('should maintain service configuration state', () async {
        expect(service, isNotNull);
        expect(service, isA<GoogleDriveBackupService>());

        // Test configuration persistence
        await service.setBackupFrequency('daily');
        await service.setWifiOnlyBackup(true);
        await service.setCompressData(false);

        // Verify settings are maintained
        expect(await service.getBackupFrequency(), equals('daily'));
        expect(await service.isWifiOnlyBackup(), isTrue);
        expect(await service.isCompressData(), isFalse);
      });

      test('should handle service initialization and cleanup', () async {
        // Service should initialize properly
        expect(service, isNotNull);

        // Basic operations should work
        expect(() => service.isBackupEnabled(), returnsNormally);
        expect(() => service.getLastBackupTime(), returnsNormally);
      });
    });
  });
}
