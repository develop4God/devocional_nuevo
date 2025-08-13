// test/services/notification_service_immediate_test.dart
// Tests for NotificationService immediate notifications

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:devocional_nuevo/services/notification_service.dart';
import 'notification_service_mocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NotificationService - Immediate Notifications', () {
    late MockFlutterLocalNotificationsPlugin mockLocalNotifications;

    setUp(() {
      // Initialize mocks
      mockLocalNotifications = MockFlutterLocalNotificationsPlugin();

      // Register fallback values
      registerFallbackValue(const NotificationDetails());

      // Setup default mocks
      when(() => mockLocalNotifications.show(any(), any(), any(), any(), payload: any(named: 'payload')))
          .thenAnswer((_) async => {});
    });

    tearDown(() {
      reset(mockLocalNotifications);
    });

    test('showImmediateNotification() creates notification with correct platform specifics', () async {
      // Arrange
      final notificationService = NotificationService();

      // Act
      await notificationService.showImmediateNotification(
        'Test Title',
        'Test Body',
        payload: 'test_payload',
        id: 123,
      );

      // Assert
      verify(() => mockLocalNotifications.show(
        123,
        'Test Title',
        'Test Body',
        any(that: allOf([
          isA<NotificationDetails>(),
          predicate<NotificationDetails>((details) => 
            details.android != null || details.iOS != null
          ),
        ])),
        payload: 'test_payload',
      )).called(1);
    });

    test('showImmediateNotification() uses provided id or defaults to 1', () async {
      // Arrange
      final notificationService = NotificationService();

      // Act - with custom id
      await notificationService.showImmediateNotification(
        'Test Title 1',
        'Test Body 1',
        id: 456,
      );

      // Act - without id (should default to 1)
      await notificationService.showImmediateNotification(
        'Test Title 2',
        'Test Body 2',
      );

      // Assert
      verify(() => mockLocalNotifications.show(
        456,
        'Test Title 1',
        'Test Body 1',
        any(),
        payload: 'immediate_devotional',
      )).called(1);

      verify(() => mockLocalNotifications.show(
        1,
        'Test Title 2',
        'Test Body 2',
        any(),
        payload: 'immediate_devotional',
      )).called(1);
    });

    test('showImmediateNotification() handles custom payload', () async {
      // Arrange
      final notificationService = NotificationService();

      // Act
      await notificationService.showImmediateNotification(
        'Custom Title',
        'Custom Body',
        payload: 'custom_payload_data',
      );

      // Assert
      verify(() => mockLocalNotifications.show(
        1,
        'Custom Title',
        'Custom Body',
        any(),
        payload: 'custom_payload_data',
      )).called(1);
    });

    test('showImmediateNotification() uses default payload when none provided', () async {
      // Arrange
      final notificationService = NotificationService();

      // Act
      await notificationService.showImmediateNotification(
        'Default Title',
        'Default Body',
      );

      // Assert
      verify(() => mockLocalNotifications.show(
        1,
        'Default Title',
        'Default Body',
        any(),
        payload: 'immediate_devotional',
      )).called(1);
    });

    test('showImmediateNotification() handles notification plugin failures', () async {
      // Arrange
      when(() => mockLocalNotifications.show(any(), any(), any(), any(), payload: any(named: 'payload')))
          .thenThrow(Exception('Notification plugin failed'));
      final notificationService = NotificationService();

      // Act & Assert - should not throw
      await expectLater(
        () => notificationService.showImmediateNotification('Title', 'Body'),
        returnsNormally,
      );
    });

    test('showImmediateNotification() configures Android notification details correctly', () async {
      // Arrange
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      final notificationService = NotificationService();

      // Act
      await notificationService.showImmediateNotification(
        'Android Title',
        'Android Body',
      );

      // Assert
      verify(() => mockLocalNotifications.show(
        1,
        'Android Title',
        'Android Body',
        any(that: allOf([
          isA<NotificationDetails>(),
          predicate<NotificationDetails>((details) => 
            details.android != null &&
            details.android!.channelId == 'immediate_devotional' &&
            details.android!.channelName == 'Devocional Inmediato' &&
            details.android!.importance == Importance.max &&
            details.android!.priority == Priority.high
          ),
        ])),
        payload: 'immediate_devotional',
      )).called(1);

      debugDefaultTargetPlatformOverride = null;
    });

    test('showImmediateNotification() configures iOS notification details correctly', () async {
      // Arrange
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      final notificationService = NotificationService();

      // Act
      await notificationService.showImmediateNotification(
        'iOS Title',
        'iOS Body',
      );

      // Assert
      verify(() => mockLocalNotifications.show(
        1,
        'iOS Title',
        'iOS Body',
        any(that: allOf([
          isA<NotificationDetails>(),
          predicate<NotificationDetails>((details) => 
            details.iOS != null &&
            details.iOS!.sound == 'default' &&
            details.iOS!.presentAlert == true &&
            details.iOS!.presentBadge == true &&
            details.iOS!.presentSound == true
          ),
        ])),
        payload: 'immediate_devotional',
      )).called(1);

      debugDefaultTargetPlatformOverride = null;
    });

    test('showImmediateNotification() handles empty title gracefully', () async {
      // Arrange
      final notificationService = NotificationService();

      // Act
      await notificationService.showImmediateNotification(
        '',
        'Body with empty title',
      );

      // Assert
      verify(() => mockLocalNotifications.show(
        1,
        '',
        'Body with empty title',
        any(),
        payload: 'immediate_devotional',
      )).called(1);
    });

    test('showImmediateNotification() handles empty body gracefully', () async {
      // Arrange
      final notificationService = NotificationService();

      // Act
      await notificationService.showImmediateNotification(
        'Title with empty body',
        '',
      );

      // Assert
      verify(() => mockLocalNotifications.show(
        1,
        'Title with empty body',
        '',
        any(),
        payload: 'immediate_devotional',
      )).called(1);
    });

    test('showImmediateNotification() handles very long title and body', () async {
      // Arrange
      final longTitle = 'A' * 1000; // Very long title
      final longBody = 'B' * 5000; // Very long body
      final notificationService = NotificationService();

      // Act
      await notificationService.showImmediateNotification(
        longTitle,
        longBody,
      );

      // Assert
      verify(() => mockLocalNotifications.show(
        1,
        longTitle,
        longBody,
        any(),
        payload: 'immediate_devotional',
      )).called(1);
    });

    test('showImmediateNotification() handles special characters in title and body', () async {
      // Arrange
      final specialTitle = 'Title with 特殊字符 and émojis 🎉';
      final specialBody = 'Body with special chars: @#$%^&*()[]{}|;:,.<>?/~`';
      final notificationService = NotificationService();

      // Act
      await notificationService.showImmediateNotification(
        specialTitle,
        specialBody,
      );

      // Assert
      verify(() => mockLocalNotifications.show(
        1,
        specialTitle,
        specialBody,
        any(),
        payload: 'immediate_devotional',
      )).called(1);
    });

    test('showImmediateNotification() handles multiple rapid notifications', () async {
      // Arrange
      final notificationService = NotificationService();

      // Act
      final futures = List.generate(5, (index) => 
        notificationService.showImmediateNotification(
          'Title $index',
          'Body $index',
          id: index,
        ),
      );
      await Future.wait(futures);

      // Assert
      for (int i = 0; i < 5; i++) {
        verify(() => mockLocalNotifications.show(
          i,
          'Title $i',
          'Body $i',
          any(),
          payload: 'immediate_devotional',
        )).called(1);
      }
    });

    test('showImmediateNotification() handles null payload correctly', () async {
      // Arrange
      final notificationService = NotificationService();

      // Act
      await notificationService.showImmediateNotification(
        'Null Payload Test',
        'Testing null payload',
        payload: null,
      );

      // Assert
      verify(() => mockLocalNotifications.show(
        1,
        'Null Payload Test',
        'Testing null payload',
        any(),
        payload: 'immediate_devotional', // Should use default
      )).called(1);
    });

    test('showImmediateNotification() handles negative id values', () async {
      // Arrange
      final notificationService = NotificationService();

      // Act
      await notificationService.showImmediateNotification(
        'Negative ID Test',
        'Testing negative ID',
        id: -1,
      );

      // Assert
      verify(() => mockLocalNotifications.show(
        -1,
        'Negative ID Test',
        'Testing negative ID',
        any(),
        payload: 'immediate_devotional',
      )).called(1);
    });

    test('showImmediateNotification() handles zero id value', () async {
      // Arrange
      final notificationService = NotificationService();

      // Act
      await notificationService.showImmediateNotification(
        'Zero ID Test',
        'Testing zero ID',
        id: 0,
      );

      // Assert
      verify(() => mockLocalNotifications.show(
        0,
        'Zero ID Test',
        'Testing zero ID',
        any(),
        payload: 'immediate_devotional',
      )).called(1);
    });
  });
}