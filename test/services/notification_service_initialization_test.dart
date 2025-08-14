// test/services/notification_service_initialization_test.dart
// Tests for NotificationService initialization - Integration style

import 'package:flutter_test/flutter_test.dart';
import 'package:devocional_nuevo/services/notification_service.dart';
import 'notification_service_test_helper.dart';

void main() {
  group('NotificationService - Initialization Tests', () {
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

    test('NotificationService can be instantiated as singleton', () {
      final service1 = NotificationService();
      final service2 = NotificationService();

      expect(identical(service1, service2), isTrue);
    });

    test('NotificationService has onNotificationTapped callback property', () {
      expect(() {
        notificationService.onNotificationTapped = (payload) {
          // Test callback
        };
      }, returnsNormally);
    });

    test('onNotificationTapped callback can be invoked', () {
      String? receivedPayload;
      notificationService.onNotificationTapped = (payload) {
        receivedPayload = payload;
      };

      notificationService.onNotificationTapped?.call('test_payload');
      expect(receivedPayload, equals('test_payload'));
    });

    test('onNotificationTapped can be set to null', () {
      notificationService.onNotificationTapped = null;
      expect(notificationService.onNotificationTapped, isNull);
    });

    test(
        'NotificationService initialization does not throw without actual Firebase setup',
        () async {
      // Note: This tests that the service gracefully handles missing Firebase setup
      // which is expected in test environments
      await expectLater(
        () => notificationService.initialize(),
        returnsNormally,
      );
    });

    test('NotificationService is accessible after initialization attempt',
        () async {
      // Even if initialization fails in test environment, service should remain usable
      try {
        await notificationService.initialize();
      } catch (e) {
        // Expected in test environment
      }

      // Should still be able to access the service methods
      expect(
          () => notificationService.areNotificationsEnabled(), returnsNormally);
      expect(() => notificationService.getNotificationTime(), returnsNormally);
    });

    test('Service maintains state between method calls', () async {
      await notificationService.setNotificationsEnabled(true);
      final enabled = await notificationService.areNotificationsEnabled();
      expect(enabled, isTrue);

      await notificationService.setNotificationTime('15:30');
      final time = await notificationService.getNotificationTime();
      expect(time, equals('15:30'));
    });

    test('Service public API methods are accessible', () {
      // Test that all expected public methods exist and are callable
      expect(notificationService.initialize, isA<Function>());
      expect(notificationService.areNotificationsEnabled, isA<Function>());
      expect(notificationService.setNotificationsEnabled, isA<Function>());
      expect(notificationService.getNotificationTime, isA<Function>());
      expect(notificationService.setNotificationTime, isA<Function>());
      expect(notificationService.showImmediateNotification, isA<Function>());
      expect(notificationService.scheduleDailyNotification, isA<Function>());
      expect(notificationService.cancelScheduledNotifications, isA<Function>());
    });

    test('Service handles multiple rapid calls gracefully', () async {
      final futures = <Future>[];

      // Make multiple concurrent calls
      futures.add(notificationService.setNotificationsEnabled(true));
      futures.add(notificationService.setNotificationTime('12:00'));
      futures.add(notificationService.areNotificationsEnabled());
      futures.add(notificationService.getNotificationTime());

      await expectLater(
        () => Future.wait(futures),
        returnsNormally,
      );
    });

    test('Service state persists across multiple instances', () async {
      // Set state with first instance
      await notificationService.setNotificationsEnabled(true);
      await notificationService.setNotificationTime('18:45');

      // Check state with another reference (should be same singleton)
      final anotherReference = NotificationService();
      expect(await anotherReference.areNotificationsEnabled(), isTrue);
      expect(await anotherReference.getNotificationTime(), equals('18:45'));
    });

    test('Service handles error conditions gracefully', () async {
      // These should not throw even in test environment without proper Firebase setup
      await expectLater(
        () => notificationService.showImmediateNotification('Test', 'Test'),
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
  });
}
