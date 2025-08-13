// test/services/notification_service_comprehensive_test.dart
// Comprehensive test runner for all NotificationService test suites

import 'package:flutter_test/flutter_test.dart';

// Import all test suites
import 'notification_service_initialization_test.dart' as initialization_tests;
import 'notification_service_configuration_test.dart' as configuration_tests;
import 'notification_service_fcm_test.dart' as fcm_tests;
import 'notification_service_settings_test.dart' as settings_tests;
import 'notification_service_permissions_test.dart' as permissions_tests;
import 'notification_service_immediate_test.dart' as immediate_tests;

void main() {
  group('NotificationService Comprehensive Test Suite', () {
    group('Initialization Tests', initialization_tests.main);
    group('Configuration Tests', configuration_tests.main);
    group('FCM Integration Tests', fcm_tests.main);
    group('Settings Persistence Tests', settings_tests.main);
    group('Permission Handling Tests', permissions_tests.main);
    group('Immediate Notifications Tests', immediate_tests.main);
  });
}