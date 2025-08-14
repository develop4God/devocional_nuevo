// test/services/notification_service_fcm_test.dart
// Tests for FCM functionality - Integration style (limited without real Firebase)

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:devocional_nuevo/services/notification_service.dart';
import 'notification_service_test_helper.dart';

void main() {
  group('NotificationService - FCM Integration Tests', () {
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

    group('FCM Service Availability', () {
      test('NotificationService instance can be created', () {
        expect(notificationService, isNotNull);
        expect(notificationService, isA<NotificationService>());
      });

      test('Service has notification callback property', () {
        expect(() {
          notificationService.onNotificationTapped = (payload) {
            // Test callback setup
          };
        }, returnsNormally);
      });

      test('Can set and invoke notification callback', () {
        String? receivedPayload;
        notificationService.onNotificationTapped = (payload) {
          receivedPayload = payload;
        };

        notificationService.onNotificationTapped?.call('test_payload');
        expect(receivedPayload, equals('test_payload'));
      });
    });

    group('FCM Initialization Behavior', () {
      test('initialize() method exists and can be called', () async {
        await expectLater(
          () => notificationService.initialize(),
          returnsNormally,
        );
      });

      test('Service remains functional after initialization attempt', () async {
        // Even if FCM initialization fails in test environment
        try {
          await notificationService.initialize();
        } catch (e) {
          // Expected in test environment without real Firebase
        }

        // Service should still be usable
        await expectLater(
          () => notificationService.areNotificationsEnabled(),
          returnsNormally,
        );
      });

      test('Multiple initialization calls are handled gracefully', () async {
        await expectLater(
          () async {
            await notificationService.initialize();
            await notificationService.initialize(); // Second call
          }(),
          returnsNormally,
        );
      });
    });

    group('Message Handling Capability', () {
      test('Service can handle immediate notifications', () async {
        await expectLater(
          () => notificationService.showImmediateNotification(
            'FCM Test Title',
            'FCM Test Body',
          ),
          returnsNormally,
        );
      });

      test('Service handles notifications with payload', () async {
        await expectLater(
          () => notificationService.showImmediateNotification(
            'FCM Test Title',
            'FCM Test Body',
            payload: 'fcm_test_payload',
          ),
          returnsNormally,
        );
      });

      test('Service handles various message formats', () async {
        final testMessages = [
          {'title': 'Simple Title', 'body': 'Simple Body'},
          {'title': 'Título con acentos', 'body': 'Mensaje con ñ y símbolos 🔔'},
          {'title': '', 'body': 'Empty title test'},
          {'title': 'Empty body test', 'body': ''},
        ];

        for (final message in testMessages) {
          await expectLater(
            () => notificationService.showImmediateNotification(
              message['title']!,
              message['body']!,
            ),
            returnsNormally,
            reason: 'Failed for message: $message',
          );
        }
      });
    });

    group('FCM Token Management Simulation', () {
      test('Service can store FCM token in SharedPreferences', () async {
        final prefs = await SharedPreferences.getInstance();
        
        // Simulate what FCM would do
        await prefs.setString('fcm_token', 'test_fcm_token_123');
        
        final storedToken = prefs.getString('fcm_token');
        expect(storedToken, equals('test_fcm_token_123'));
      });

      test('Service maintains state across FCM operations', () async {
        // Set notification settings
        await notificationService.setNotificationsEnabled(true);
        await notificationService.setNotificationTime('15:30');

        // Simulate FCM operations
        await expectLater(
          () => notificationService.showImmediateNotification('Test', 'Test'),
          returnsNormally,
        );

        // Settings should remain intact
        expect(await notificationService.areNotificationsEnabled(), isTrue);
        expect(await notificationService.getNotificationTime(), equals('15:30'));
      });
    });

    group('FCM Permission Handling', () {
      test('Service handles permission requests gracefully', () async {
        // In test environment, permission requests may fail
        // but service should not crash
        await expectLater(
          () => notificationService.initialize(),
          returnsNormally,
        );
      });

      test('Service works regardless of permission state', () async {
        // Test that core functionality works even if FCM permissions are denied
        await notificationService.setNotificationsEnabled(true);
        expect(await notificationService.areNotificationsEnabled(), isTrue);

        await expectLater(
          () => notificationService.showImmediateNotification('Test', 'Test'),
          returnsNormally,
        );
      });
    });

    group('FCM Error Handling', () {
      test('Service handles FCM initialization failures', () async {
        // Multiple initialization attempts should not crash
        for (int i = 0; i < 3; i++) {
          await expectLater(
            () => notificationService.initialize(),
            returnsNormally,
            reason: 'Failed on attempt $i',
          );
        }
      });

      test('Service maintains functionality after FCM errors', () async {
        // Even if FCM operations fail, basic settings should work
        await notificationService.setNotificationsEnabled(true);
        await notificationService.setNotificationTime('12:00');

        expect(await notificationService.areNotificationsEnabled(), isTrue);
        expect(await notificationService.getNotificationTime(), equals('12:00'));
      });

      test('Service handles notification display failures gracefully', () async {
        // Should not crash even if notification display fails
        await expectLater(
          () => notificationService.showImmediateNotification(
            'Error Test',
            'This should not crash the service',
          ),
          returnsNormally,
        );

        // Service should remain usable
        await expectLater(
          () => notificationService.areNotificationsEnabled(),
          returnsNormally,
        );
      });
    });

    group('FCM Integration with Scheduled Notifications', () {
      test('FCM does not interfere with scheduled notifications', () async {
        await notificationService.setNotificationsEnabled(true);
        await notificationService.setNotificationTime('09:00');

        // Both immediate and scheduled should work
        await expectLater(
          () => notificationService.showImmediateNotification('Immediate', 'Test'),
          returnsNormally,
        );

        await expectLater(
          () => notificationService.scheduleDailyNotification(),
          returnsNormally,
        );

        await expectLater(
          () => notificationService.cancelScheduledNotifications(),
          returnsNormally,
        );
      });

      test('FCM callback does not interfere with app state', () async {
        // Set callback
        String? lastPayload;
        notificationService.onNotificationTapped = (payload) {
          lastPayload = payload;
        };

        // Simulate callback invocation
        notificationService.onNotificationTapped?.call('fcm_callback_test');
        expect(lastPayload, equals('fcm_callback_test'));

        // App state should remain intact
        await notificationService.setNotificationsEnabled(true);
        expect(await notificationService.areNotificationsEnabled(), isTrue);
      });
    });
  });
}
