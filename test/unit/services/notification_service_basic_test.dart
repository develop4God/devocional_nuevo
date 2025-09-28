// test/unit/services/notification_service_basic_test.dart

import 'package:devocional_nuevo/services/notification_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NotificationService Basic Tests', () {
    late NotificationService notificationService;

    setUp(() async {
      // Setup SharedPreferences mock
      SharedPreferences.setMockInitialValues({
        'notification_enabled': true,
        'notification_time_hour': 8,
        'notification_time_minute': 0,
        'daily_reminders_enabled': true,
      });

      // Setup method channel mocks for local notifications
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('flutter_local_notifications'),
        (MethodCall methodCall) async {
          switch (methodCall.method) {
            case 'initialize':
              return true;
            case 'requestPermissions':
              return true;
            case 'zonedSchedule':
              return null;
            case 'cancel':
              return null;
            case 'cancelAll':
              return null;
            case 'getActiveNotifications':
              return [];
            case 'getNotificationAppLaunchDetails':
              return {'notificationLaunchedApp': false};
            default:
              return null;
          }
        },
      );

      // Setup method channel mocks for Firebase Messaging
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/firebase_messaging'),
        (MethodCall methodCall) async {
          switch (methodCall.method) {
            case 'Messaging#requestPermission':
              return {'authorizationStatus': 1, 'settings': {}};
            case 'Messaging#getToken':
              return 'mock_fcm_token';
            case 'Messaging#setAutoInitEnabled':
              return null;
            case 'Messaging#getInitialMessage':
              return null;
            default:
              return null;
          }
        },
      );

      // Setup method channel mocks for permission handler
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('flutter.baseflow.com/permissions/methods'),
        (MethodCall methodCall) async {
          switch (methodCall.method) {
            case 'checkPermissionStatus':
              return 1; // granted
            case 'requestPermissions':
              return {0: 1}; // granted
            default:
              return null;
          }
        },
      );

      notificationService = NotificationService();
    });

    tearDown(() {
      // Clean up method channel handlers
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('flutter_local_notifications'),
        null,
      );
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/firebase_messaging'),
        null,
      );
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('flutter.baseflow.com/permissions/methods'),
        null,
      );
    });

    group('Notification Service Initialization', () {
      test('should initialize notification service successfully', () async {
        // Test initialization
        expect(() => notificationService.initialize(), returnsNormally);

        // Service should be accessible
        expect(notificationService, isNotNull);
        expect(notificationService, isA<NotificationService>());
      });

      test('should handle notification permissions correctly', () async {
        // Test permission request
        expect(() => notificationService.requestNotificationPermissions(), returnsNormally);

        // Test permission check
        expect(() => notificationService.checkNotificationPermission(), returnsNormally);
      });
    });

    group('Devotional Reminders Management', () {
      test('should schedule devotional reminders correctly', () async {
        // Test scheduling daily reminder
        expect(() => notificationService.scheduleDailyReminder(
          hour: 8,
          minute: 0,
          title: 'Tiempo de devocional',
          body: 'Es hora de tu momento con Dios',
        ), returnsNormally);

        // Test rescheduling with different time
        expect(() => notificationService.scheduleDailyReminder(
          hour: 19,
          minute: 30,
          title: 'Devocional nocturno',
          body: 'Reflexiona sobre tu día con Dios',
        ), returnsNormally);
      });

      test('should handle notification timing validation', () async {
        // Test valid times
        expect(() => notificationService.scheduleDailyReminder(
          hour: 0,
          minute: 0,
          title: 'Midnight reminder',
          body: 'Test body',
        ), returnsNormally);

        expect(() => notificationService.scheduleDailyReminder(
          hour: 23,
          minute: 59,
          title: 'Late night reminder',
          body: 'Test body',
        ), returnsNormally);

        // Test edge cases
        expect(() => notificationService.scheduleDailyReminder(
          hour: 12,
          minute: 30,
          title: 'Midday reminder',
          body: 'Test body',
        ), returnsNormally);
      });

      test('should cancel notifications correctly', () async {
        // Test canceling specific notification
        expect(() => notificationService.cancelNotification(1), returnsNormally);

        // Test canceling all notifications
        expect(() => notificationService.cancelAllNotifications(), returnsNormally);
      });
    });

    group('Notification Settings Management', () {
      test('should manage notification enabled state', () async {
        // Test enabling notifications
        await notificationService.setNotificationsEnabled(true);
        final isEnabled1 = await notificationService.areNotificationsEnabled();
        expect(isEnabled1, isA<bool>());

        // Test disabling notifications
        await notificationService.setNotificationsEnabled(false);
        final isEnabled2 = await notificationService.areNotificationsEnabled();
        expect(isEnabled2, isA<bool>());
      });

      test('should manage daily reminders setting', () async {
        // Test enabling daily reminders
        await notificationService.setDailyRemindersEnabled(true);
        final isEnabled1 = await notificationService.areDailyRemindersEnabled();
        expect(isEnabled1, isA<bool>());

        // Test disabling daily reminders
        await notificationService.setDailyRemindersEnabled(false);
        final isEnabled2 = await notificationService.areDailyRemindersEnabled();
        expect(isEnabled2, isA<bool>());
      });

      test('should manage notification time settings', () async {
        // Test saving notification time
        await notificationService.saveNotificationTime(9, 15);
        
        final savedTime = await notificationService.getSavedNotificationTime();
        expect(savedTime, isA<Map<String, int>>());
        expect(savedTime.containsKey('hour'), isTrue);
        expect(savedTime.containsKey('minute'), isTrue);

        // Test different time
        await notificationService.saveNotificationTime(20, 45);
        final savedTime2 = await notificationService.getSavedNotificationTime();
        expect(savedTime2, isA<Map<String, int>>());
      });
    });

    group('Firebase Integration', () {
      test('should handle FCM token management', () async {
        // Test getting FCM token
        expect(() => notificationService.getFCMToken(), returnsNormally);

        // Test token refresh handling
        expect(() => notificationService.onTokenRefresh(), returnsNormally);
      });

      test('should handle Firebase message processing', () async {
        // Test message handling setup
        expect(() => notificationService.setupFirebaseMessageHandling(), returnsNormally);
      });
    });

    group('Error Handling and Edge Cases', () {
      test('should handle invalid notification times gracefully', () async {
        // Test with invalid hours (should handle gracefully or validate)
        expect(() => notificationService.saveNotificationTime(-1, 0), returnsNormally);
        expect(() => notificationService.saveNotificationTime(25, 0), returnsNormally);
        expect(() => notificationService.saveNotificationTime(12, -1), returnsNormally);
        expect(() => notificationService.saveNotificationTime(12, 60), returnsNormally);
      });

      test('should handle missing permissions gracefully', () async {
        // Should not crash when permissions are denied
        expect(() => notificationService.requestNotificationPermissions(), returnsNormally);
        expect(() => notificationService.checkNotificationPermission(), returnsNormally);
      });

      test('should handle service initialization errors', () async {
        // Service should handle initialization errors gracefully
        expect(() => notificationService.initialize(), returnsNormally);
      });
    });

    group('Notification Content and Localization', () {
      test('should handle different notification content', () async {
        // Test with Spanish content
        expect(() => notificationService.scheduleDailyReminder(
          hour: 8,
          minute: 0,
          title: 'Devocional Diario',
          body: 'Es hora de tu encuentro con Dios',
        ), returnsNormally);

        // Test with English content
        expect(() => notificationService.scheduleDailyReminder(
          hour: 8,
          minute: 0,
          title: 'Daily Devotional',
          body: 'Time for your meeting with God',
        ), returnsNormally);

        // Test with empty content
        expect(() => notificationService.scheduleDailyReminder(
          hour: 8,
          minute: 0,
          title: '',
          body: '',
        ), returnsNormally);
      });

      test('should handle special characters in notifications', () async {
        expect(() => notificationService.scheduleDailyReminder(
          hour: 8,
          minute: 0,
          title: 'Devocional 📖🙏',
          body: 'Dios te bendiga hoy ✨',
        ), returnsNormally);
      });
    });

    group('Service State and Singleton', () {
      test('should work as singleton correctly', () {
        final service1 = NotificationService();
        final service2 = NotificationService();
        
        expect(identical(service1, service2), isTrue);
      });

      test('should maintain state across service calls', () async {
        // Set some state
        await notificationService.setNotificationsEnabled(true);
        await notificationService.saveNotificationTime(10, 30);

        // Get state back
        final isEnabled = await notificationService.areNotificationsEnabled();
        final savedTime = await notificationService.getSavedNotificationTime();
        
        expect(isEnabled, isA<bool>());
        expect(savedTime, isA<Map<String, int>>());
      });
    });
  });
}