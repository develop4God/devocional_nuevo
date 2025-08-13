// test/services/notification_service_test_helper.dart
// Integration test utilities for NotificationService (no dependency injection)

import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Test helper class for setting up integration tests
class NotificationServiceTestHelper {
  // Setup Firebase for testing (using fake Firebase instance)
  static Future<void> setupFirebaseForTesting() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    
    // Initialize a fake Firebase app for testing
    try {
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: 'fake-api-key',
          appId: 'fake-app-id',
          messagingSenderId: 'fake-sender-id',
          projectId: 'fake-project-id',
        ),
      );
    } catch (e) {
      // Firebase already initialized
    }
  }

  // Setup SharedPreferences for testing
  static Future<void> setupSharedPreferencesForTesting() async {
    SharedPreferences.setMockInitialValues({});
  }

  // Clean up between tests
  static Future<void> cleanup() async {
    // Clear SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  // Create test user data for Firestore
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