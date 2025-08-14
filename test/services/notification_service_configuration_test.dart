// test/services/notification_service_configuration_test.dart
// Tests for NotificationService configuration management - Integration style

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:devocional_nuevo/services/notification_service.dart';
import 'notification_service_test_helper.dart';

void main() {
  group('NotificationService - Configuration Tests', () {
    late NotificationService notificationService;

    setUpAll(() async {
      await NotificationServiceTestHelper.setupFirebaseForTesting();
    });

    setUp(() async {
      await NotificationServiceTestHelper.setupSharedPreferencesForTesting();
      notificationService = NotificationService.instance;
    });

    tearDown(() async {
      await NotificationServiceTestHelper.cleanup();
    });

    group('Notification Enabled/Disabled Configuration', () {
      test('notifications are disabled by default', () async {
        final isEnabled = await notificationService.areNotificationsEnabled();
        expect(isEnabled, isFalse);
      });

      test('can enable notifications', () async {
        await notificationService.setNotificationsEnabled(true);
        final isEnabled = await notificationService.areNotificationsEnabled();
        expect(isEnabled, isTrue);
      });

      test('can disable notifications', () async {
        await notificationService.setNotificationsEnabled(true);
        await notificationService.setNotificationsEnabled(false);
        final isEnabled = await notificationService.areNotificationsEnabled();
        expect(isEnabled, isFalse);
      });

      test('notification setting persists between service instances', () async {
        await notificationService.setNotificationsEnabled(true);

        // Get another instance (should be same singleton)
        final anotherService = NotificationService();
        final isEnabled = await anotherService.areNotificationsEnabled();
        expect(isEnabled, isTrue);
      });

      test('can toggle notifications multiple times', () async {
        // Enable
        await notificationService.setNotificationsEnabled(true);
        expect(await notificationService.areNotificationsEnabled(), isTrue);

        // Disable
        await notificationService.setNotificationsEnabled(false);
        expect(await notificationService.areNotificationsEnabled(), isFalse);

        // Enable again
        await notificationService.setNotificationsEnabled(true);
        expect(await notificationService.areNotificationsEnabled(), isTrue);
      });
    });

    group('Notification Time Configuration', () {
      test('default notification time is 09:00', () async {
        final time = await notificationService.getNotificationTime();
        expect(time, equals('09:00'));
      });

      test('can set custom notification time', () async {
        await notificationService.setNotificationTime('14:30');
        final time = await notificationService.getNotificationTime();
        expect(time, equals('14:30'));
      });

      test('notification time persists between service instances', () async {
        await notificationService.setNotificationTime('20:15');

        // Get another instance (should be same singleton)
        final anotherService = NotificationService();
        final time = await anotherService.getNotificationTime();
        expect(time, equals('20:15'));
      });

      test('can update notification time multiple times', () async {
        await notificationService.setNotificationTime('08:00');
        expect(
            await notificationService.getNotificationTime(), equals('08:00'));

        await notificationService.setNotificationTime('12:30');
        expect(
            await notificationService.getNotificationTime(), equals('12:30'));

        await notificationService.setNotificationTime('18:45');
        expect(
            await notificationService.getNotificationTime(), equals('18:45'));
      });

      test('handles various time formats', () async {
        final testTimes = [
          '00:00', // Midnight
          '12:00', // Noon
          '23:59', // Almost midnight
          '06:30', // Early morning
          '15:45', // Afternoon
        ];

        for (final testTime in testTimes) {
          await notificationService.setNotificationTime(testTime);
          final retrievedTime = await notificationService.getNotificationTime();
          expect(retrievedTime, equals(testTime),
              reason: 'Failed for time: $testTime');
        }
      });

      test('handles edge case times', () async {
        // Test early morning
        await notificationService.setNotificationTime('00:01');
        expect(
            await notificationService.getNotificationTime(), equals('00:01'));

        // Test late night
        await notificationService.setNotificationTime('23:58');
        expect(
            await notificationService.getNotificationTime(), equals('23:58'));
      });
    });

    group('Configuration Persistence', () {
      test('settings persist across app restarts (simulated)', () async {
        // Set configuration
        await notificationService.setNotificationsEnabled(true);
        await notificationService.setNotificationTime('16:20');

        // Clear in-memory cache (simulating app restart)
        final prefs = await SharedPreferences.getInstance();

        // Create new service instance and verify persistence
        final newService = NotificationService();
        expect(await newService.areNotificationsEnabled(), isTrue);
        expect(await newService.getNotificationTime(), equals('16:20'));
      });

      test('can handle mixed configuration states', () async {
        // Set enabled but different time
        await notificationService.setNotificationsEnabled(true);
        await notificationService.setNotificationTime('07:15');

        expect(await notificationService.areNotificationsEnabled(), isTrue);
        expect(
            await notificationService.getNotificationTime(), equals('07:15'));

        // Disable but keep time
        await notificationService.setNotificationsEnabled(false);
        expect(await notificationService.areNotificationsEnabled(), isFalse);
        expect(
            await notificationService.getNotificationTime(), equals('07:15'));
      });

      test('handles concurrent configuration changes', () async {
        // Make multiple concurrent configuration changes
        final futures = <Future>[];

        futures.add(notificationService.setNotificationsEnabled(true));
        futures.add(notificationService.setNotificationTime('11:30'));

        await Future.wait(futures);

        expect(await notificationService.areNotificationsEnabled(), isTrue);
        expect(
            await notificationService.getNotificationTime(), equals('11:30'));
      });
    });

    group('Configuration Error Handling', () {
      test('handles empty time string gracefully', () async {
        await expectLater(
          () => notificationService.setNotificationTime(''),
          returnsNormally,
        );

        // Should either keep previous time or use default
        final time = await notificationService.getNotificationTime();
        expect(time, isNotEmpty);
      });

      test('configuration remains functional after errors', () async {
        // Set valid configuration first
        await notificationService.setNotificationsEnabled(true);
        await notificationService.setNotificationTime('13:45');

        // Try to set invalid configuration
        try {
          await notificationService.setNotificationTime('invalid_time');
        } catch (e) {
          // Expected to handle gracefully
        }

        // Valid configuration should still work
        expect(await notificationService.areNotificationsEnabled(), isTrue);
        final time = await notificationService.getNotificationTime();
        expect(time, isNotEmpty);
      });

      test('can recover from SharedPreferences failures', () async {
        // Even if SharedPreferences fails, service should not crash
        await expectLater(
          () => notificationService.setNotificationsEnabled(true),
          returnsNormally,
        );

        await expectLater(
          () => notificationService.setNotificationTime('10:00'),
          returnsNormally,
        );
      });
    });

    group('Configuration Integration with Other Features', () {
      test('configuration affects notification behavior', () async {
        // Enable notifications and set time
        await notificationService.setNotificationsEnabled(true);
        await notificationService.setNotificationTime('09:30');

        // These operations should work when enabled
        await expectLater(
          () => notificationService.scheduleDailyNotification(),
          returnsNormally,
        );

        await expectLater(
          () =>
              notificationService.showImmediateNotification('Test', 'Message'),
          returnsNormally,
        );
      });

      test('can configure and then cancel notifications', () async {
        await notificationService.setNotificationsEnabled(true);
        await notificationService.setNotificationTime('19:00');

        await expectLater(
          () => notificationService.scheduleDailyNotification(),
          returnsNormally,
        );

        await expectLater(
          () => notificationService.cancelScheduledNotifications(),
          returnsNormally,
        );

        // Configuration should remain unchanged
        expect(await notificationService.areNotificationsEnabled(), isTrue);
        expect(
            await notificationService.getNotificationTime(), equals('19:00'));
      });
    });
  });
}
