// test/unit/services/notification_service_test.dart

import 'package:devocional_nuevo/services/notification_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('NotificationService', () {
    late NotificationService notificationService;

    setUp(() {
      // Initialize SharedPreferences with mock data
      SharedPreferences.setMockInitialValues({});

      // Get singleton instance
      notificationService = NotificationService();
    });

    group('Notification Settings Management', () {
      test('should enable notifications and save to preferences', () async {
        // Arrange
        final prefs = await SharedPreferences.getInstance();

        // Act
        await notificationService.setNotificationsEnabled(true);

        // Assert
        expect(prefs.getBool('notifications_enabled'), isTrue);
      });

      test('should disable notifications and save to preferences', () async {
        // Arrange
        final prefs = await SharedPreferences.getInstance();

        // Act
        await notificationService.setNotificationsEnabled(false);

        // Assert
        expect(prefs.getBool('notifications_enabled'), isFalse);
      });

      test('should return default enabled state when no preference exists',
          () async {
        // Arrange - no preferences set

        // Act
        final isEnabled = await notificationService.areNotificationsEnabled();

        // Assert - default should be true
        expect(isEnabled, isTrue);
      });

      test('should return stored notification state from preferences',
          () async {
        // Arrange
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('notifications_enabled', false);

        // Act
        final isEnabled = await notificationService.areNotificationsEnabled();

        // Assert
        expect(isEnabled, isFalse);
      });

      test('should handle rapid state changes correctly', () async {
        // Arrange & Act - rapid state changes
        await notificationService.setNotificationsEnabled(true);
        await notificationService.setNotificationsEnabled(false);
        await notificationService.setNotificationsEnabled(true);

        // Assert - final state should be correct
        expect(await notificationService.areNotificationsEnabled(), isTrue);
      });
    });

    group('Notification Time Management', () {
      test('should set notification time and save to preferences', () async {
        // Arrange
        const testTime = '14:30';
        final prefs = await SharedPreferences.getInstance();

        // Act
        await notificationService.setNotificationTime(testTime);

        // Assert
        expect(prefs.getString('notification_time'), equals(testTime));
      });

      test('should return default time when no time is set', () async {
        // Arrange - no time preference set

        // Act
        final time = await notificationService.getNotificationTime();

        // Assert - should return default time
        expect(time, equals('09:00'));
      });

      test('should return stored notification time from preferences', () async {
        // Arrange
        const testTime = '20:15';
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('notification_time', testTime);

        // Act
        final time = await notificationService.getNotificationTime();

        // Assert
        expect(time, equals(testTime));
      });

      test('should handle invalid time formats gracefully', () async {
        // Arrange
        const invalidTime = 'invalid-time';
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('notification_time', invalidTime);

        // Act
        final time = await notificationService.getNotificationTime();

        // Assert - should return the stored value even if invalid
        expect(time, equals(invalidTime));
      });

      test('should validate notification time boundaries', () async {
        // Arrange - test edge case times
        const edgeCases = ['00:00', '23:59', '12:00', '01:30'];

        // Act & Assert - should handle all valid times
        for (final time in edgeCases) {
          await notificationService.setNotificationTime(time);
          expect(await notificationService.getNotificationTime(), equals(time));
        }
      });
    });

    group('Service Initialization', () {
      test('should initialize service without throwing exceptions', () async {
        // Act & Assert - initialization should not throw
        expect(
          () => notificationService.initialize(),
          returnsNormally,
        );
      });

      test('should handle multiple initializations gracefully', () async {
        // Act - multiple initializations
        await notificationService.initialize();
        await notificationService.initialize();

        // Assert - should not throw on subsequent calls
        expect(
          () => notificationService.initialize(),
          returnsNormally,
        );
      });
    });

    group('Daily Notification Scheduling', () {
      test('should schedule daily notification without parameters', () async {
        // Act - should not throw
        expect(
          () => notificationService.scheduleDailyNotification(),
          returnsNormally,
        );
      });

      test('should handle scheduling operations gracefully', () async {
        // Act & Assert - should handle gracefully without throwing
        expect(
          () => notificationService.scheduleDailyNotification(),
          returnsNormally,
        );
      });

      test('should handle scheduling after time changes', () async {
        // Arrange
        const firstTime = '08:00';
        const secondTime = '20:00';

        // Act - change time and reschedule
        await notificationService.setNotificationTime(firstTime);
        await notificationService.scheduleDailyNotification();

        await notificationService.setNotificationTime(secondTime);
        await notificationService.scheduleDailyNotification();

        // Assert - should complete without errors
        expect(await notificationService.getNotificationTime(),
            equals(secondTime));
      });
    });

    group('Immediate Notification Display', () {
      test('should show immediate notification with title and body', () async {
        // Arrange
        const title = 'Test Notification';
        const body = 'Test notification body';

        // Act & Assert - should not throw
        expect(
          () => notificationService.showImmediateNotification(title, body),
          returnsNormally,
        );
      });

      test('should show notification with custom payload', () async {
        // Arrange
        const title = 'Custom Title';
        const body = 'Custom Body';
        const payload = 'custom-payload';

        // Act & Assert - should not throw
        expect(
          () => notificationService.showImmediateNotification(title, body,
              payload: payload),
          returnsNormally,
        );
      });

      test('should handle empty or null notification content', () async {
        // Arrange
        const emptyTitle = '';
        const emptyBody = '';

        // Act & Assert - should handle gracefully
        expect(
          () => notificationService.showImmediateNotification(
              emptyTitle, emptyBody),
          returnsNormally,
        );
      });

      test('should handle special characters in notifications', () async {
        // Arrange
        const specialTitle = 'Título con acentos: ñáéíóú 🙏';
        const specialBody = 'Contenido con símbolos especiales: @#\$%^&*()';

        // Act & Assert - should handle special characters
        expect(
          () => notificationService.showImmediateNotification(
              specialTitle, specialBody),
          returnsNormally,
        );
      });
    });

    group('Notification State Integration', () {
      test('should handle complete notification setup flow', () async {
        // Arrange
        const notificationTime = '08:00';

        // Act - complete setup flow should not throw
        await notificationService.setNotificationsEnabled(true);
        await notificationService.setNotificationTime(notificationTime);

        // Assert - verify state is properly saved
        expect(await notificationService.areNotificationsEnabled(), isTrue);
        expect(await notificationService.getNotificationTime(),
            equals(notificationTime));
      });

      test('should handle notification disabling correctly', () async {
        // Act
        await notificationService.setNotificationsEnabled(false);

        // Assert
        expect(await notificationService.areNotificationsEnabled(), isFalse);
      });

      test('should maintain consistent state across operations', () async {
        // Arrange
        const testTime = '15:45';

        // Act - perform multiple operations
        await notificationService.setNotificationsEnabled(true);
        await notificationService.setNotificationTime(testTime);

        // Assert - state should be consistent
        expect(await notificationService.areNotificationsEnabled(), isTrue);
        expect(
            await notificationService.getNotificationTime(), equals(testTime));
      });

      test('should handle configuration changes during active notifications',
          () async {
        // Arrange
        const initialTime = '09:00';
        const updatedTime = '21:00';

        // Act - setup and then change configuration
        await notificationService.setNotificationsEnabled(true);
        await notificationService.setNotificationTime(initialTime);

        // Simulate schedule and then update
        await notificationService.scheduleDailyNotification();
        await notificationService.setNotificationTime(updatedTime);
        await notificationService.scheduleDailyNotification();

        // Assert - final state should reflect changes
        expect(await notificationService.getNotificationTime(),
            equals(updatedTime));
        expect(await notificationService.areNotificationsEnabled(), isTrue);
      });
    });

    group('Error Handling & Edge Cases', () {
      test('should handle SharedPreferences operations gracefully', () async {
        // Act & Assert - operations should complete normally
        expect(() => notificationService.setNotificationsEnabled(true),
            returnsNormally);
        expect(() => notificationService.areNotificationsEnabled(),
            returnsNormally);
        expect(() => notificationService.setNotificationTime('10:00'),
            returnsNormally);
        expect(
            () => notificationService.getNotificationTime(), returnsNormally);
      });

      test('should handle notification callback setup', () async {
        // Arrange
        String? receivedPayload;
        notificationService.onNotificationTapped = (payload) {
          receivedPayload = payload;
        };

        // Act
        notificationService.onNotificationTapped?.call('test-payload');

        // Assert
        expect(receivedPayload, equals('test-payload'));
      });

      test('should handle null callback gracefully', () async {
        // Arrange
        notificationService.onNotificationTapped = null;

        // Act & Assert - should not throw when callback is null
        expect(
          () => notificationService.onNotificationTapped?.call('payload'),
          returnsNormally,
        );
      });

      test('should handle service operations in sequence', () async {
        // Act - perform operations in sequence
        await notificationService.initialize();
        await notificationService.setNotificationsEnabled(true);
        await notificationService.setNotificationTime('12:00');
        await notificationService.scheduleDailyNotification();

        // Assert - all operations should complete successfully
        expect(await notificationService.areNotificationsEnabled(), isTrue);
        expect(
            await notificationService.getNotificationTime(), equals('12:00'));
      });
    });

    group('Business Logic Validation', () {
      test('should preserve notification settings after service restart',
          () async {
        // Arrange
        const testTime = '16:30';
        const testEnabled = true;

        // Act - set preferences
        await notificationService.setNotificationsEnabled(testEnabled);
        await notificationService.setNotificationTime(testTime);

        // Create new service instance (simulate restart)
        final newService = NotificationService();

        // Assert - settings should be preserved
        expect(await newService.areNotificationsEnabled(), equals(testEnabled));
        expect(await newService.getNotificationTime(), equals(testTime));
      });

      test('should handle concurrent notification operations', () async {
        // Arrange
        const times = ['08:00', '12:00', '18:00', '22:00'];

        // Act - perform concurrent operations
        final futures = times.map((time) async {
          await notificationService.setNotificationTime(time);
          return notificationService.getNotificationTime();
        });

        final results = await Future.wait(futures);

        // Assert - all operations should complete
        expect(results, hasLength(4));
        // Final state should be one of the set times
        expect(
            times, contains(await notificationService.getNotificationTime()));
      });

      test('should maintain notification state consistency', () async {
        // Arrange & Act - perform various state changes
        await notificationService.setNotificationsEnabled(false);
        await notificationService.setNotificationTime('05:30');
        await notificationService.setNotificationsEnabled(true);

        // Assert - final state should be consistent
        expect(await notificationService.areNotificationsEnabled(), isTrue);
        expect(
            await notificationService.getNotificationTime(), equals('05:30'));
      });

      test('should handle extreme notification time values', () async {
        // Arrange - test boundary values
        const extremeTimes = ['00:00', '23:59', '24:00', '-01:00'];

        // Act & Assert - should handle all values without crashing
        for (final time in extremeTimes) {
          await notificationService.setNotificationTime(time);
          final retrievedTime = await notificationService.getNotificationTime();
          expect(retrievedTime, equals(time));
        }
      });
    });
  });
}
