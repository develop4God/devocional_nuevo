// test/services/notification_service_test_helper.dart

import 'package:flutter/services.dart';

import 'package:flutter_test/flutter_test.dart';

import 'package:firebase_core/firebase_core.dart';

import 'package:shared_preferences/shared_preferences.dart';

class NotificationServiceTestHelper {
  static bool _initialized = false;

  static Future<void> setupFirebaseForTesting() async {
    if (_initialized) return;

    TestWidgetsFlutterBinding.ensureInitialized();

    _setupPlatformChannelMocks();

    try {
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: 'fake-api-key-for-testing',
          appId: 'fake-app-id-for-testing',
          messagingSenderId: 'fake-sender-id-for-testing',
          projectId: 'fake-project-id-for-testing',
          storageBucket: 'fake-storage-bucket',
          authDomain: 'fake-auth-domain',
        ),
      );
    } catch (e) {
      // Firebase ya inicializado
    }

    _initialized = true;
  }

  static Future<void> setupSharedPreferencesForTesting() async {
    SharedPreferences.setMockInitialValues({
      'notifications_enabled': false,
      'notification_time': '09:00',
    });
  }

  static void _setupPlatformChannelMocks() {
    // Flutter Local Notifications

    const MethodChannel('dexterous.com/flutter/local_notifications')
        .setMockMethodCallHandler((MethodCall methodCall) async {
      return methodCall.method == 'initialize' ? true : null;
    });

    // Firebase Messaging

    const MethodChannel('plugins.flutter.io/firebase_messaging')
        .setMockMethodCallHandler((MethodCall methodCall) async {
      switch (methodCall.method) {
        case 'Messaging#requestPermission':
          return {'authorizationStatus': 1};

        case 'Messaging#getToken':
          return 'mock_fcm_token_123456789';

        default:
          return null;
      }
    });

    // Firebase Auth

    const MethodChannel('plugins.flutter.io/firebase_auth')
        .setMockMethodCallHandler((MethodCall methodCall) async {
      switch (methodCall.method) {
        case 'Auth#currentUser':
          return {'uid': 'mock_user_123', 'email': 'test@test.com'};

        default:
          return null;
      }
    });

    // Firebase Firestore

    const MethodChannel('plugins.flutter.io/cloud_firestore')
        .setMockMethodCallHandler((MethodCall methodCall) async {
      switch (methodCall.method) {
        case 'DocumentReference#set':
        case 'DocumentReference#update':
          return null;

        case 'DocumentReference#get':
          return {
            'data': {
              'notificationsEnabled': true,
              'notificationTime': '09:00',
              'lastUpdated': DateTime.now().millisecondsSinceEpoch,
            },
            'exists': true,
          };

        default:
          return null;
      }
    });

    // Permission Handler

    const MethodChannel('flutter.baseflow.com/permissions/methods')
        .setMockMethodCallHandler((MethodCall methodCall) async {
      return methodCall.method == 'requestPermissions' ? {0: 1} : 1;
    });

    // Timezone

    const MethodChannel('plugins.flutter.io/timezone')
        .setMockMethodCallHandler((MethodCall methodCall) async {
      return 'America/New_York';
    });
  }

  static Future<void> cleanup() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.clear();
    } catch (e) {
      // Ignorar errores de cleanup
    }
  }

  static Map<String, dynamic> createTestUserData({
    bool notificationsEnabled = true,
    String notificationTime = '09:00',
    String userTimezone = 'America/New_York',
  }) {
    return {
      'notificationsEnabled': notificationsEnabled,
      'notificationTime': notificationTime,
      'userTimezone': userTimezone,
      'lastUpdated': DateTime.now().toIso8601String(),
    };
  }
}
