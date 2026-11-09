/// Logs [message] under `[tag]` through print(), the only logger that reaches
/// adb logcat in release builds (see _startupLog in main.dart).
void logRelease(String tag, String message) {
  // ignore: avoid_print
  print('[$tag] $message');
}
