// test/services/notification_service_immediate_test.dart
// Tests for immediate notification functionality - Integration style

import 'package:flutter_test/flutter_test.dart';
import 'package:devocional_nuevo/services/notification_service.dart';
import 'notification_service_test_helper.dart';

void main() {
  group('NotificationService - Immediate Notifications Tests', () {
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

    group('Basic Immediate Notification Tests', () {
      test('showImmediateNotification method exists and can be called',
          () async {
        await expectLater(
          () => notificationService.showImmediateNotification(
            'Test Title',
            'Test Body',
          ),
          returnsNormally,
        );
      });

      test('showImmediateNotification with payload works', () async {
        await expectLater(
          () => notificationService.showImmediateNotification(
            'Test Title',
            'Test Body',
            payload: 'test_payload',
          ),
          returnsNormally,
        );
      });

      test('showImmediateNotification handles empty strings', () async {
        await expectLater(
          () => notificationService.showImmediateNotification('', ''),
          returnsNormally,
        );
      });

      test('showImmediateNotification handles null payload', () async {
        await expectLater(
          () => notificationService.showImmediateNotification(
            'Title',
            'Body',
            payload: null,
          ),
          returnsNormally,
        );
      });
    });

    group('Immediate Notification Content Tests', () {
      test('handles various title and body combinations', () async {
        final testCases = [
          {'title': 'Simple Title', 'body': 'Simple Body'},
          {'title': 'Title with emojis 🔔📱', 'body': 'Body with emojis ✨🎉'},
          {'title': 'Título con acentos', 'body': 'Cuerpo con ñ y símbolos'},
          {
            'title':
                'Very long title that might be truncated by the notification system',
            'body': 'Short body'
          },
          {
            'title': 'Short',
            'body':
                'Very long body that contains a lot of text and might be truncated or wrapped'
          },
        ];

        for (final testCase in testCases) {
          await expectLater(
            () => notificationService.showImmediateNotification(
              testCase['title']!,
              testCase['body']!,
            ),
            returnsNormally,
            reason: 'Failed for case: $testCase',
          );
        }
      });

      test('handles special characters in content', () async {
        await expectLater(
          () => notificationService.showImmediateNotification(
            'Title with "quotes" and \'apostrophes\'',
            'Body with special chars: @#\$%^&*()+={}[]|\\:";\'<>?,./~`',
          ),
          returnsNormally,
        );
      });

      test('handles newlines and formatting in content', () async {
        await expectLater(
          () => notificationService.showImmediateNotification(
            'Multi\nLine\nTitle',
            'Multi\nLine\nBody\nWith\nBreaks',
          ),
          returnsNormally,
        );
      });
    });

    group('Immediate Notification Payload Tests', () {
      test('handles various payload formats', () async {
        final payloads = [
          'simple_string',
          'string_with_spaces',
          'string-with-dashes',
          'string_with_underscores',
          'string.with.dots',
          '123456789',
          'mixed_123_payload',
          '',
        ];

        for (final payload in payloads) {
          await expectLater(
            () => notificationService.showImmediateNotification(
              'Test Title',
              'Test Body',
              payload: payload,
            ),
            returnsNormally,
            reason: 'Failed for payload: $payload',
          );
        }
      });

      test('handles JSON-like payload strings', () async {
        final jsonPayloads = [
          '{"type":"devotional","id":"123"}',
          '{"action":"open_page","data":{"page":"home"}}',
          '[1,2,3]',
          '{"nested":{"object":{"value":"test"}}}',
        ];

        for (final payload in jsonPayloads) {
          await expectLater(
            () => notificationService.showImmediateNotification(
              'JSON Test',
              'Testing JSON payload',
              payload: payload,
            ),
            returnsNormally,
            reason: 'Failed for JSON payload: $payload',
          );
        }
      });
    });

    group('Immediate Notification Error Handling', () {
      test('multiple rapid notifications work', () async {
        final futures = <Future>[];

        for (int i = 0; i < 5; i++) {
          futures.add(
            notificationService.showImmediateNotification(
              'Rapid Test $i',
              'Testing rapid notifications',
              payload: 'rapid_$i',
            ),
          );
        }

        await expectLater(
          () => Future.wait(futures),
          returnsNormally,
        );
      });

      test('service remains functional after notification errors', () async {
        // Try to show a notification (may fail in test environment)
        await expectLater(
          () => notificationService.showImmediateNotification('Test', 'Test'),
          returnsNormally,
        );

        // Service should still work for other operations
        await notificationService.setNotificationsEnabled(true);
        expect(await notificationService.areNotificationsEnabled(), isTrue);
      });

      test('notifications work regardless of settings state', () async {
        // Test with notifications disabled
        await notificationService.setNotificationsEnabled(false);
        await expectLater(
          () => notificationService.showImmediateNotification(
            'Disabled Test',
            'Test with notifications disabled',
          ),
          returnsNormally,
        );

        // Test with notifications enabled
        await notificationService.setNotificationsEnabled(true);
        await expectLater(
          () => notificationService.showImmediateNotification(
            'Enabled Test',
            'Test with notifications enabled',
          ),
          returnsNormally,
        );
      });
    });

    group('Immediate Notification Integration Tests', () {
      test('notifications work with scheduled notifications', () async {
        await notificationService.setNotificationsEnabled(true);
        await notificationService.setNotificationTime('14:30');

        // Show immediate notification
        await expectLater(
          () => notificationService.showImmediateNotification(
            'Immediate',
            'Before scheduling',
          ),
          returnsNormally,
        );

        // Schedule daily notification
        await expectLater(
          () => notificationService.scheduleDailyNotification(),
          returnsNormally,
        );

        // Show another immediate notification
        await expectLater(
          () => notificationService.showImmediateNotification(
            'Immediate',
            'After scheduling',
          ),
          returnsNormally,
        );

        // Cancel scheduled notifications
        await expectLater(
          () => notificationService.cancelScheduledNotifications(),
          returnsNormally,
        );

        // Show final immediate notification
        await expectLater(
          () => notificationService.showImmediateNotification(
            'Immediate',
            'After cancelling',
          ),
          returnsNormally,
        );
      });

      test('callback can be set and invoked', () async {
        String? receivedPayload;
        notificationService.onNotificationTapped = (payload) {
          receivedPayload = payload;
        };

        // Simulate notification tap
        notificationService.onNotificationTapped?.call('tap_test_payload');
        expect(receivedPayload, equals('tap_test_payload'));
      });

      test('callback works with immediate notifications', () async {
        final receivedPayloads = <String>[];
        notificationService.onNotificationTapped = (payload) {
          if (payload != null) {
            receivedPayloads.add(payload);
          }
        };

        // Show notifications with different payloads
        await notificationService.showImmediateNotification(
          'Test 1',
          'Body 1',
          payload: 'payload_1',
        );

        await notificationService.showImmediateNotification(
          'Test 2',
          'Body 2',
          payload: 'payload_2',
        );

        // Simulate taps
        notificationService.onNotificationTapped?.call('payload_1');
        notificationService.onNotificationTapped?.call('payload_2');

        expect(receivedPayloads, equals(['payload_1', 'payload_2']));
      });
    });
  });
}
