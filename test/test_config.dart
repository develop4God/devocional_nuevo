import 'dart:io';

import 'package:flutter/foundation.dart';

/// Test configuration utilities
class TestConfig {
  static bool get isTestEnvironment {
    return Platform.environment['FLUTTER_TEST'] == 'true' || 
           kDebugMode && Platform.environment.containsKey('FLUTTER_TEST');
  }
  
  /// Use this instead of debugPrint in production code to suppress output during tests
  static void debugPrint(String message) {
    if (!isTestEnvironment) {
      // ignore: avoid_print
      print(message);
    }
  }
}