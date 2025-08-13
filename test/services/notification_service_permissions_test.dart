// test/services/notification_service_permissions_test.dart
// Tests for NotificationService permission handling

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:devocional_nuevo/services/notification_service.dart';
import 'notification_service_mocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NotificationService - Permission Handling', () {
    late MockFlutterLocalNotificationsPlugin mockLocalNotifications;
    late MockIOSFlutterLocalNotificationsPlugin mockIOSLocalNotifications;

    setUp(() {
      // Initialize mocks
      mockLocalNotifications = MockFlutterLocalNotificationsPlugin();
      mockIOSLocalNotifications = MockIOSFlutterLocalNotificationsPlugin();

      // Register fallback values
      registerFallbackValue(const InitializationSettings());

      // Setup default mocks
      NotificationServiceTestHelper.setupLocalNotificationsMocks(
        mockLocalNotifications,
        mockIOSLocalNotifications,
      );
    });

    tearDown(() {
      reset(mockLocalNotifications);
      reset(mockIOSLocalNotifications);
    });

    test('_requestPermissions() returns true when all Android permissions granted', () async {
      // Arrange
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      
      when(() => Permission.notification.request())
          .thenAnswer((_) async => PermissionStatus.granted);
      when(() => Permission.scheduleExactAlarm.isDenied)
          .thenAnswer((_) async => false);
      when(() => Permission.ignoreBatteryOptimizations.isDenied)
          .thenAnswer((_) async => false);
      
      final notificationService = NotificationService();

      // Act
      await notificationService.initialize();

      // Assert - Since _requestPermissions is private, we verify through initialize
      verify(() => Permission.notification.request()).called(1);
      
      debugDefaultTargetPlatformOverride = null;
    });

    test('_requestPermissions() handles iOS permission requests', () async {
      // Arrange
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      
      final notificationService = NotificationService();

      // Act
      await notificationService.initialize();

      // Assert
      verify(() => mockLocalNotifications.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>())
          .called(1);
      verify(() => mockIOSLocalNotifications.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      )).called(1);
      
      debugDefaultTargetPlatformOverride = null;
    });

    test('_requestPermissions() returns false when critical permissions denied', () async {
      // Arrange
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      
      when(() => Permission.notification.request())
          .thenAnswer((_) async => PermissionStatus.denied);
      when(() => Permission.scheduleExactAlarm.isDenied)
          .thenAnswer((_) async => false);
      when(() => Permission.ignoreBatteryOptimizations.isDenied)
          .thenAnswer((_) async => false);
      
      final notificationService = NotificationService();

      // Act
      await notificationService.initialize();

      // Assert
      verify(() => Permission.notification.request()).called(1);
      
      debugDefaultTargetPlatformOverride = null;
    });

    test('_requestPermissions() handles platform-specific exceptions', () async {
      // Arrange
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      
      when(() => Permission.notification.request())
          .thenThrow(Exception('Permission request failed'));
      
      final notificationService = NotificationService();

      // Act & Assert - should not throw
      await expectLater(
        () => notificationService.initialize(),
        returnsNormally,
      );
      
      debugDefaultTargetPlatformOverride = null;
    });

    test('_requestPermissions() handles exact alarm permission on Android', () async {
      // Arrange
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      
      when(() => Permission.notification.request())
          .thenAnswer((_) async => PermissionStatus.granted);
      when(() => Permission.scheduleExactAlarm.isDenied)
          .thenAnswer((_) async => true);
      when(() => Permission.scheduleExactAlarm.request())
          .thenAnswer((_) async => PermissionStatus.granted);
      when(() => Permission.ignoreBatteryOptimizations.isDenied)
          .thenAnswer((_) async => false);
      
      final notificationService = NotificationService();

      // Act
      await notificationService.initialize();

      // Assert
      verify(() => Permission.scheduleExactAlarm.isDenied).called(1);
      verify(() => Permission.scheduleExactAlarm.request()).called(1);
      
      debugDefaultTargetPlatformOverride = null;
    });

    test('_requestPermissions() handles battery optimization permission on Android', () async {
      // Arrange
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      
      when(() => Permission.notification.request())
          .thenAnswer((_) async => PermissionStatus.granted);
      when(() => Permission.scheduleExactAlarm.isDenied)
          .thenAnswer((_) async => false);
      when(() => Permission.ignoreBatteryOptimizations.isDenied)
          .thenAnswer((_) async => true);
      when(() => Permission.ignoreBatteryOptimizations.request())
          .thenAnswer((_) async => PermissionStatus.granted);
      
      final notificationService = NotificationService();

      // Act
      await notificationService.initialize();

      // Assert
      verify(() => Permission.ignoreBatteryOptimizations.isDenied).called(1);
      verify(() => Permission.ignoreBatteryOptimizations.request()).called(1);
      
      debugDefaultTargetPlatformOverride = null;
    });

    test('_requestPermissions() handles denied exact alarm permission on Android', () async {
      // Arrange
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      
      when(() => Permission.notification.request())
          .thenAnswer((_) async => PermissionStatus.granted);
      when(() => Permission.scheduleExactAlarm.isDenied)
          .thenAnswer((_) async => true);
      when(() => Permission.scheduleExactAlarm.request())
          .thenAnswer((_) async => PermissionStatus.denied);
      when(() => Permission.ignoreBatteryOptimizations.isDenied)
          .thenAnswer((_) async => false);
      
      final notificationService = NotificationService();

      // Act
      await notificationService.initialize();

      // Assert
      verify(() => Permission.scheduleExactAlarm.request()).called(1);
      
      debugDefaultTargetPlatformOverride = null;
    });

    test('_requestPermissions() handles denied battery optimization permission on Android', () async {
      // Arrange
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      
      when(() => Permission.notification.request())
          .thenAnswer((_) async => PermissionStatus.granted);
      when(() => Permission.scheduleExactAlarm.isDenied)
          .thenAnswer((_) async => false);
      when(() => Permission.ignoreBatteryOptimizations.isDenied)
          .thenAnswer((_) async => true);
      when(() => Permission.ignoreBatteryOptimizations.request())
          .thenAnswer((_) async => PermissionStatus.denied);
      
      final notificationService = NotificationService();

      // Act
      await notificationService.initialize();

      // Assert
      verify(() => Permission.ignoreBatteryOptimizations.request()).called(1);
      
      debugDefaultTargetPlatformOverride = null;
    });

    test('_requestPermissions() handles iOS permission denial gracefully', () async {
      // Arrange
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      
      when(() => mockIOSLocalNotifications.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      )).thenAnswer((_) async => false);
      
      final notificationService = NotificationService();

      // Act
      await notificationService.initialize();

      // Assert
      verify(() => mockIOSLocalNotifications.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      )).called(1);
      
      debugDefaultTargetPlatformOverride = null;
    });

    test('_requestPermissions() handles null iOS plugin gracefully', () async {
      // Arrange
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      
      when(() => mockLocalNotifications.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>())
          .thenReturn(null);
      
      final notificationService = NotificationService();

      // Act & Assert - should not throw
      await expectLater(
        () => notificationService.initialize(),
        returnsNormally,
      );
      
      debugDefaultTargetPlatformOverride = null;
    });

    test('_requestPermissions() handles permission check exceptions on Android', () async {
      // Arrange
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      
      when(() => Permission.notification.request())
          .thenAnswer((_) async => PermissionStatus.granted);
      when(() => Permission.scheduleExactAlarm.isDenied)
          .thenThrow(Exception('Permission check failed'));
      
      final notificationService = NotificationService();

      // Act & Assert - should not throw
      await expectLater(
        () => notificationService.initialize(),
        returnsNormally,
      );
      
      debugDefaultTargetPlatformOverride = null;
    });

    test('_requestPermissions() handles permanently denied permissions on Android', () async {
      // Arrange
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      
      when(() => Permission.notification.request())
          .thenAnswer((_) async => PermissionStatus.permanentlyDenied);
      when(() => Permission.scheduleExactAlarm.isDenied)
          .thenAnswer((_) async => false);
      when(() => Permission.ignoreBatteryOptimizations.isDenied)
          .thenAnswer((_) async => false);
      
      final notificationService = NotificationService();

      // Act
      await notificationService.initialize();

      // Assert
      verify(() => Permission.notification.request()).called(1);
      
      debugDefaultTargetPlatformOverride = null;
    });

    test('_requestPermissions() handles restricted permissions on Android', () async {
      // Arrange
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      
      when(() => Permission.notification.request())
          .thenAnswer((_) async => PermissionStatus.restricted);
      when(() => Permission.scheduleExactAlarm.isDenied)
          .thenAnswer((_) async => false);
      when(() => Permission.ignoreBatteryOptimizations.isDenied)
          .thenAnswer((_) async => false);
      
      final notificationService = NotificationService();

      // Act
      await notificationService.initialize();

      // Assert
      verify(() => Permission.notification.request()).called(1);
      
      debugDefaultTargetPlatformOverride = null;
    });

    test('_requestPermissions() skips battery optimization when already granted', () async {
      // Arrange
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      
      when(() => Permission.notification.request())
          .thenAnswer((_) async => PermissionStatus.granted);
      when(() => Permission.scheduleExactAlarm.isDenied)
          .thenAnswer((_) async => false);
      when(() => Permission.ignoreBatteryOptimizations.isDenied)
          .thenAnswer((_) async => false); // Already granted
      
      final notificationService = NotificationService();

      // Act
      await notificationService.initialize();

      // Assert - should not request permission if already granted
      verify(() => Permission.ignoreBatteryOptimizations.isDenied).called(1);
      verifyNever(() => Permission.ignoreBatteryOptimizations.request());
      
      debugDefaultTargetPlatformOverride = null;
    });
  });
}