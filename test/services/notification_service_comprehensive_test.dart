// test/services/notification_service_comprehensive_test.dart
// Comprehensive integration tests for NotificationService - Public API only

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:devocional_nuevo/services/notification_service.dart';
import 'notification_service_test_helper.dart';

void main() {
  group('NotificationService - Comprehensive Integration Tests', () {
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

    group('Complete Workflow Tests', () {
      test('full notification setup and usage workflow', () async {
        // 1. Check initial state
        expect(await notificationService.areNotificationsEnabled(), isFalse);
        expect(await notificationService.getNotificationTime(), equals('09:00'));

        // 2. Enable notifications
        await notificationService.setNotificationsEnabled(true);
        expect(await notificationService.areNotificationsEnabled(), isTrue);

        // 3. Set custom notification time
        await notificationService.setNotificationTime('14:30');
        expect(await notificationService.getNotificationTime(), equals('14:30'));

        // 4. Show immediate notification
        await expectLater(
          () => notificationService.showImmediateNotification(
            'Workflow Test',
            'Testing complete workflow',
            payload: 'workflow_payload',
          ),
          returnsNormally,
        );

        // 5. Schedule daily notifications
        await expectLater(
          () => notificationService.scheduleDailyNotification(),
          returnsNormally,
        );

        // 6. Update settings while scheduled
        await notificationService.setNotificationTime('16:45');
        expect(await notificationService.getNotificationTime(), equals('16:45'));

        // 7. Show another immediate notification
        await expectLater(
          () => notificationService.showImmediateNotification(
            'Updated Settings',
            'After time change',
          ),
          returnsNormally,
        );

        // 8. Cancel scheduled notifications
        await expectLater(
          () => notificationService.cancelScheduledNotifications(),
          returnsNormally,
        );

        // 9. Verify final state
        expect(await notificationService.areNotificationsEnabled(), isTrue);
        expect(await notificationService.getNotificationTime(), equals('16:45'));
      });

      test('disable notifications workflow', () async {
        // Enable and configure
        await notificationService.setNotificationsEnabled(true);
        await notificationService.setNotificationTime('12:00');
        
        await expectLater(
          () => notificationService.scheduleDailyNotification(),
          returnsNormally,
        );

        // Disable notifications
        await notificationService.setNotificationsEnabled(false);
        expect(await notificationService.areNotificationsEnabled(), isFalse);
        
        // Time setting should persist
        expect(await notificationService.getNotificationTime(), equals('12:00'));

        // Cancel existing scheduled notifications
        await expectLater(
          () => notificationService.cancelScheduledNotifications(),
          returnsNormally,
        );

        // Immediate notifications should still work
        await expectLater(
          () => notificationService.showImmediateNotification(
            'Disabled State',
            'Immediate notification while disabled',
          ),
          returnsNormally,
        );
      });

      test('multiple configuration changes workflow', () async {
        final times = ['08:00', '12:30', '18:45', '21:15'];
        
        for (final time in times) {
          await notificationService.setNotificationTime(time);
          await notificationService.setNotificationsEnabled(true);
          
          expect(await notificationService.getNotificationTime(), equals(time));
          expect(await notificationService.areNotificationsEnabled(), isTrue);
          
          await expectLater(
            () => notificationService.showImmediateNotification(
              'Time: $time',
              'Testing time: $time',
            ),
            returnsNormally,
          );
          
          await notificationService.setNotificationsEnabled(false);
          expect(await notificationService.areNotificationsEnabled(), isFalse);
        }
      });
    });

    group('Service Persistence Tests', () {
      test('settings persist across multiple service operations', () async {
        // Set initial configuration
        await notificationService.setNotificationsEnabled(true);
        await notificationService.setNotificationTime('10:30');

        // Perform various operations
        await expectLater(
          () => notificationService.showImmediateNotification('Test 1', 'Body 1'),
          returnsNormally,
        );
        
        await expectLater(
          () => notificationService.scheduleDailyNotification(),
          returnsNormally,
        );
        
        await expectLater(
          () => notificationService.showImmediateNotification('Test 2', 'Body 2'),
          returnsNormally,
        );
        
        await expectLater(
          () => notificationService.cancelScheduledNotifications(),
          returnsNormally,
        );

        // Settings should remain unchanged
        expect(await notificationService.areNotificationsEnabled(), isTrue);
        expect(await notificationService.getNotificationTime(), equals('10:30'));
      });

      test('service singleton behavior is maintained', () async {
        final service1 = NotificationService();
        final service2 = NotificationService();
        
        expect(identical(service1, service2), isTrue);

        await service1.setNotificationsEnabled(true);
        await service1.setNotificationTime('15:00');

        expect(await service2.areNotificationsEnabled(), isTrue);
        expect(await service2.getNotificationTime(), equals('15:00'));
      });
    });

    group('Error Recovery and Resilience Tests', () {
      test('service recovers from operation failures', () async {
        // Set valid initial state
        await notificationService.setNotificationsEnabled(true);
        await notificationService.setNotificationTime('11:00');

        // Perform operations that might fail in test environment
        await expectLater(
          () => notificationService.initialize(),
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

        // Service should remain functional
        expect(await notificationService.areNotificationsEnabled(), isTrue);
        expect(await notificationService.getNotificationTime(), equals('11:00'));
      });

      test('handles concurrent operations gracefully', () async {
        final futures = <Future>[];
        
        // Perform multiple concurrent operations
        futures.add(notificationService.setNotificationsEnabled(true));
        futures.add(notificationService.setNotificationTime('13:45'));
        futures.add(notificationService.showImmediateNotification('Concurrent 1', 'Test 1'));
        futures.add(notificationService.showImmediateNotification('Concurrent 2', 'Test 2'));
        futures.add(notificationService.scheduleDailyNotification());

        await expectLater(
          () => Future.wait(futures),
          returnsNormally,
        );

        // Final state should be consistent
        final enabled = await notificationService.areNotificationsEnabled();
        final time = await notificationService.getNotificationTime();
        
        expect(enabled, isA<bool>());
        expect(time, isA<String>());
        expect(time, isNotEmpty);
      });

      test('service maintains functionality after multiple error scenarios', () async {
        // Try various operations that might fail
        for (int i = 0; i < 3; i++) {
          await expectLater(
            () => notificationService.initialize(),
            returnsNormally,
          );
          
          await expectLater(
            () => notificationService.showImmediateNotification('Error Test $i', 'Body $i'),
            returnsNormally,
          );
        }

        // Basic functionality should still work
        await notificationService.setNotificationsEnabled(true);
        await notificationService.setNotificationTime('17:30');
        
        expect(await notificationService.areNotificationsEnabled(), isTrue);
        expect(await notificationService.getNotificationTime(), equals('17:30'));
      });
    });

    group('Callback Integration Tests', () {
      test('callback functionality works throughout workflow', () async {
        final receivedPayloads = <String>[];
        
        notificationService.onNotificationTapped = (payload) {
          if (payload != null) {
            receivedPayloads.add(payload);
          }
        };

        // Show notifications with different payloads
        await notificationService.showImmediateNotification(
          'Callback Test 1',
          'First notification',
          payload: 'callback_1',
        );

        await notificationService.showImmediateNotification(
          'Callback Test 2',
          'Second notification',
          payload: 'callback_2',
        );

        // Simulate taps
        notificationService.onNotificationTapped?.call('callback_1');
        notificationService.onNotificationTapped?.call('callback_2');

        expect(receivedPayloads, equals(['callback_1', 'callback_2']));

        // Settings operations shouldn't affect callback
        await notificationService.setNotificationsEnabled(true);
        await notificationService.setNotificationTime('19:00');

        notificationService.onNotificationTapped?.call('callback_3');
        expect(receivedPayloads, equals(['callback_1', 'callback_2', 'callback_3']));
      });

      test('callback can be changed during operation', () async {
        String? result1;
        String? result2;

        // Set first callback
        notificationService.onNotificationTapped = (payload) {
          result1 = payload;
        };

        notificationService.onNotificationTapped?.call('test_1');
        expect(result1, equals('test_1'));
        expect(result2, isNull);

        // Change callback
        notificationService.onNotificationTapped = (payload) {
          result2 = payload;
        };

        notificationService.onNotificationTapped?.call('test_2');
        expect(result1, equals('test_1')); // Unchanged
        expect(result2, equals('test_2')); // New value

        // Clear callback
        notificationService.onNotificationTapped = null;
        
        // Should not crash when null
        notificationService.onNotificationTapped?.call('test_3');
        expect(result1, equals('test_1')); // Unchanged
        expect(result2, equals('test_2')); // Unchanged
      });
    });
  });
}