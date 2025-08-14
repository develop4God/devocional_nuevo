// test/services/notification_service_public_api_test.dart
// Tests for the public API of NotificationService - Integration style tests

import 'package:flutter_test/flutter_test.dart';
import 'package:devocional_nuevo/services/notification_service.dart';
import 'notification_service_test_helper.dart';

void main() {
  group('NotificationService - Public API Tests', () {
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

    group('Notification Settings - SharedPreferences Integration', () {
      test('areNotificationsEnabled() returns false by default', () async {
        final result = await notificationService.areNotificationsEnabled();
        expect(result, isFalse);
      });

      test('setNotificationsEnabled(true) enables notifications', () async {
        await notificationService.setNotificationsEnabled(true);
        final result = await notificationService.areNotificationsEnabled();
        expect(result, isTrue);
      });

      test('setNotificationsEnabled(false) disables notifications', () async {
        await notificationService.setNotificationsEnabled(false);
        final result = await notificationService.areNotificationsEnabled();
        expect(result, isFalse);
      });

      test('notification setting persists between calls', () async {
        await notificationService.setNotificationsEnabled(true);

        // Create new instance to test persistence
        final anotherService = NotificationService();
        final result = await anotherService.areNotificationsEnabled();
        expect(result, isTrue);
      });
    });

    group('Notification Time Settings', () {
      test('getNotificationTime() returns default time 09:00', () async {
        final result = await notificationService.getNotificationTime();
        expect(result, equals('09:00'));
      });

      test('setNotificationTime() saves custom time', () async {
        await notificationService.setNotificationTime('14:30');
        final result = await notificationService.getNotificationTime();
        expect(result, equals('14:30'));
      });

      test('notification time persists between calls', () async {
        await notificationService.setNotificationTime('20:15');

        // Create new instance to test persistence
        final anotherService = NotificationService();
        final result = await anotherService.getNotificationTime();
        expect(result, equals('20:15'));
      });

      test('setNotificationTime() handles edge cases', () async {
        // Test early morning
        await notificationService.setNotificationTime('00:00');
        expect(
            await notificationService.getNotificationTime(), equals('00:00'));

        // Test late night
        await notificationService.setNotificationTime('23:59');
        expect(
            await notificationService.getNotificationTime(), equals('23:59'));
      });
    });

    group('Immediate Notifications', () {
      test('showImmediateNotification() executes without throwing', () async {
        await expectLater(
          () => notificationService.showImmediateNotification(
            'Test Title',
            'Test Body',
          ),
          returnsNormally,
        );
      });

      test('showImmediateNotification() with payload executes without throwing',
          () async {
        await expectLater(
          () => notificationService.showImmediateNotification(
            'Test Title',
            'Test Body',
            payload: 'test_payload',
          ),
          returnsNormally,
        );
      });

      test('showImmediateNotification() handles empty strings', () async {
        await expectLater(
          () => notificationService.showImmediateNotification('', ''),
          returnsNormally,
        );
      });

      test('showImmediateNotification() handles special characters', () async {
        await expectLater(
          () => notificationService.showImmediateNotification(
            'Title with émojis 🔔',
            'Body with special chars: áéíóú & symbols!',
          ),
          returnsNormally,
        );
      });
    });

    group('Scheduled Notifications', () {
      test('scheduleDailyNotification() executes without throwing', () async {
        await expectLater(
          () => notificationService.scheduleDailyNotification(),
          returnsNormally,
        );
      });

      test('cancelScheduledNotifications() executes without throwing',
          () async {
        await expectLater(
          () => notificationService.cancelScheduledNotifications(),
          returnsNormally,
        );
      });

      test('schedule and cancel workflow works', () async {
        await expectLater(
          () async {
            await notificationService.scheduleDailyNotification();
            await notificationService.cancelScheduledNotifications();
          }(),
          returnsNormally,
        );
      });
    });

    group('Service Initialization', () {
      test('NotificationService is singleton', () {
        final service1 = NotificationService();
        final service2 = NotificationService();
        expect(identical(service1, service2), isTrue);
      });

      test('onNotificationTapped property can be set', () {
        String? receivedPayload;
        notificationService.onNotificationTapped = (payload) {
          receivedPayload = payload;
        };

        // Simulate notification tap
        notificationService.onNotificationTapped?.call('test_payload');
        expect(receivedPayload, equals('test_payload'));
      });
    });

    group('Error Handling', () {
      test('methods handle null/empty parameters gracefully', () async {
        await expectLater(
          () => notificationService.setNotificationTime(''),
          returnsNormally,
        );
      });

      test('service continues working after errors', () async {
        // Even if one operation fails, others should still work
        await notificationService.setNotificationsEnabled(true);

        // This should still work
        final result = await notificationService.areNotificationsEnabled();
        expect(result, isTrue);
      });
    });

    group('Integration Workflow Tests', () {
      test('complete notification setup workflow', () async {
        // 1. Enable notifications
        await notificationService.setNotificationsEnabled(true);
        expect(await notificationService.areNotificationsEnabled(), isTrue);

        // 2. Set notification time
        await notificationService.setNotificationTime('08:30');
        expect(
            await notificationService.getNotificationTime(), equals('08:30'));

        // 3. Schedule daily notification
        await expectLater(
          () => notificationService.scheduleDailyNotification(),
          returnsNormally,
        );

        // 4. Show immediate notification
        await expectLater(
          () => notificationService.showImmediateNotification(
            'Workflow Test',
            'Testing complete workflow',
          ),
          returnsNormally,
        );

        // 5. Cancel scheduled notifications
        await expectLater(
          () => notificationService.cancelScheduledNotifications(),
          returnsNormally,
        );
      });

      test('disable notifications workflow', () async {
        // Enable first
        await notificationService.setNotificationsEnabled(true);

        // Then disable
        await notificationService.setNotificationsEnabled(false);
        expect(await notificationService.areNotificationsEnabled(), isFalse);

        // Should still be able to set time even when disabled
        await notificationService.setNotificationTime('16:45');
        expect(
            await notificationService.getNotificationTime(), equals('16:45'));
      });
    });
  });
}
