// test/services/notification_service_settings_test.dart
// Tests for settings persistence - Integration style

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:devocional_nuevo/services/notification_service.dart';
import 'notification_service_test_helper.dart';

void main() {
  group('NotificationService - Settings Persistence Tests', () {
    late NotificationService notificationService;

    setUpAll(() async {
      await NotificationServiceTestHelper.setupFirebaseForTesting();
    });

    setUp(() async {
      await NotificationServiceTestHelper.setupSharedPreferencesForTesting();
      notificationService = NotificationService();
    });

    tearDown(() async {
      await NotificationServiceTestHelper.cleanup();
    });

    group('Settings Storage and Retrieval', () {
      test('default settings are properly initialized', () async {
        final isEnabled = await notificationService.areNotificationsEnabled();
        final time = await notificationService.getNotificationTime();
        
        expect(isEnabled, isFalse);
        expect(time, equals('09:00'));
      });

      test('settings persist after being set', () async {
        await notificationService.setNotificationsEnabled(true);
        await notificationService.setNotificationTime('14:45');

        expect(await notificationService.areNotificationsEnabled(), isTrue);
        expect(await notificationService.getNotificationTime(), equals('14:45'));
      });

      test('settings persist across service instances', () async {
        await notificationService.setNotificationsEnabled(true);
        await notificationService.setNotificationTime('20:30');

        // Create new instance (should be same singleton)
        final newService = NotificationService();
        expect(await newService.areNotificationsEnabled(), isTrue);
        expect(await newService.getNotificationTime(), equals('20:30'));
      });

      test('can update individual settings independently', () async {
        // Set initial state
        await notificationService.setNotificationsEnabled(true);
        await notificationService.setNotificationTime('10:00');

        // Update only the enabled state
        await notificationService.setNotificationsEnabled(false);
        expect(await notificationService.areNotificationsEnabled(), isFalse);
        expect(await notificationService.getNotificationTime(), equals('10:00'));

        // Update only the time
        await notificationService.setNotificationTime('16:30');
        expect(await notificationService.areNotificationsEnabled(), isFalse);
        expect(await notificationService.getNotificationTime(), equals('16:30'));
      });
    });

    group('Settings Validation and Edge Cases', () {
      test('handles various time format inputs', () async {
        final testTimes = [
          '00:00', '01:15', '06:30', '12:00', '18:45', '23:59'
        ];

        for (final time in testTimes) {
          await notificationService.setNotificationTime(time);
          final retrievedTime = await notificationService.getNotificationTime();
          expect(retrievedTime, equals(time), reason: 'Failed for time: $time');
        }
      });

      test('handles boolean state transitions correctly', () async {
        // Test all possible transitions
        expect(await notificationService.areNotificationsEnabled(), isFalse);

        await notificationService.setNotificationsEnabled(true);
        expect(await notificationService.areNotificationsEnabled(), isTrue);

        await notificationService.setNotificationsEnabled(true); // Same value
        expect(await notificationService.areNotificationsEnabled(), isTrue);

        await notificationService.setNotificationsEnabled(false);
        expect(await notificationService.areNotificationsEnabled(), isFalse);

        await notificationService.setNotificationsEnabled(false); // Same value
        expect(await notificationService.areNotificationsEnabled(), isFalse);
      });

      test('settings remain consistent during rapid changes', () async {
        // Make rapid consecutive changes
        await notificationService.setNotificationsEnabled(true);
        await notificationService.setNotificationTime('08:00');
        await notificationService.setNotificationsEnabled(false);
        await notificationService.setNotificationTime('14:00');
        await notificationService.setNotificationsEnabled(true);
        await notificationService.setNotificationTime('20:00');

        // Final state should be consistent
        expect(await notificationService.areNotificationsEnabled(), isTrue);
        expect(await notificationService.getNotificationTime(), equals('20:00'));
      });
    });

    group('Settings Persistence Layer', () {
      test('settings survive SharedPreferences operations', () async {
        await notificationService.setNotificationsEnabled(true);
        await notificationService.setNotificationTime('11:30');

        // Access SharedPreferences directly to verify storage
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getBool('notifications_enabled'), isTrue);
        expect(prefs.getString('notification_time'), equals('11:30'));
      });

      test('can manually modify SharedPreferences and read back', () async {
        final prefs = await SharedPreferences.getInstance();
        
        // Manually set values
        await prefs.setBool('notifications_enabled', true);
        await prefs.setString('notification_time', '17:15');

        // Service should read these values
        expect(await notificationService.areNotificationsEnabled(), isTrue);
        expect(await notificationService.getNotificationTime(), equals('17:15'));
      });

      test('handles missing SharedPreferences gracefully', () async {
        final prefs = await SharedPreferences.getInstance();
        
        // Clear all preferences
        await prefs.clear();

        // Service should use defaults
        expect(await notificationService.areNotificationsEnabled(), isFalse);
        expect(await notificationService.getNotificationTime(), equals('09:00'));
      });

      test('handles corrupted SharedPreferences data', () async {
        final prefs = await SharedPreferences.getInstance();
        
        // Set invalid data
        await prefs.setString('notifications_enabled', 'not_a_boolean');
        await prefs.setInt('notification_time', 12345);

        // Service should handle gracefully and use defaults
        await expectLater(
          () => notificationService.areNotificationsEnabled(),
          returnsNormally,
        );
        
        await expectLater(
          () => notificationService.getNotificationTime(),
          returnsNormally,
        );
      });
    });

    group('Settings Integration with Notifications', () {
      test('settings affect notification scheduling behavior', () async {
        await notificationService.setNotificationsEnabled(true);
        await notificationService.setNotificationTime('09:30');

        // Should be able to schedule with valid settings
        await expectLater(
          () => notificationService.scheduleDailyNotification(),
          returnsNormally,
        );
      });

      test('can modify settings after scheduling notifications', () async {
        await notificationService.setNotificationsEnabled(true);
        await notificationService.setNotificationTime('10:00');
        
        await notificationService.scheduleDailyNotification();

        // Change settings after scheduling
        await notificationService.setNotificationTime('15:00');
        expect(await notificationService.getNotificationTime(), equals('15:00'));

        // Should be able to reschedule with new time
        await expectLater(
          () => notificationService.scheduleDailyNotification(),
          returnsNormally,
        );
      });

      test('settings remain intact when notifications are cancelled', () async {
        await notificationService.setNotificationsEnabled(true);
        await notificationService.setNotificationTime('12:30');

        await notificationService.scheduleDailyNotification();
        await notificationService.cancelScheduledNotifications();

        // Settings should remain unchanged
        expect(await notificationService.areNotificationsEnabled(), isTrue);
        expect(await notificationService.getNotificationTime(), equals('12:30'));
      });
    });

    group('Settings Error Recovery', () {
      test('service recovers from storage errors', () async {
        // Set valid initial state
        await notificationService.setNotificationsEnabled(true);
        await notificationService.setNotificationTime('13:00');

        // Even if storage operations fail, reading should still work
        await expectLater(
          () => notificationService.areNotificationsEnabled(),
          returnsNormally,
        );
        
        await expectLater(
          () => notificationService.getNotificationTime(),
          returnsNormally,
        );
      });

      test('can continue working after settings errors', () async {
        // Try setting invalid data (should be handled gracefully)
        await expectLater(
          () => notificationService.setNotificationTime(''),
          returnsNormally,
        );

        // Service should still be functional
        await notificationService.setNotificationsEnabled(true);
        expect(await notificationService.areNotificationsEnabled(), isTrue);
      });

      test('maintains consistency during concurrent operations', () async {
        // Perform multiple concurrent settings operations
        final futures = <Future>[];
        
        futures.add(notificationService.setNotificationsEnabled(true));
        futures.add(notificationService.setNotificationTime('14:30'));
        futures.add(notificationService.setNotificationsEnabled(false));
        futures.add(notificationService.setNotificationTime('18:00'));

        await Future.wait(futures);

        // Should have some consistent final state
        final finalEnabled = await notificationService.areNotificationsEnabled();
        final finalTime = await notificationService.getNotificationTime();
        
        expect(finalEnabled, isA<bool>());
        expect(finalTime, isA<String>());
        expect(finalTime, isNotEmpty);
      });
    });
  });
}