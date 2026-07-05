// lib/utils/debug_logger.dart
//
// Debug-only logging helper. In release builds kDebugMode is a compile-time
// constant false, so the body is dead code and nothing is printed.
// Use this instead of calling debugPrint directly, which DOES print in
// release mode (see https://docs.flutter.dev/testing/code-debugging).
//
// Usage:
//   debugLog('🔔 [NotificationService] FCM token obtained');

import 'package:flutter/foundation.dart';

void debugLog(String message) {
  if (kDebugMode) {
    debugPrint(message);
  }
}
