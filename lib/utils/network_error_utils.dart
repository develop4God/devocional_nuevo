// lib/utils/network_error_utils.dart
//
// Helpers for identifying transient network connectivity errors.
// These errors are caused by the device being offline, DNS failure, or a
// flaky connection — they are NOT application bugs and must NOT be reported
// as fatal crashes in Firebase Crashlytics.

import 'dart:io';

/// Returns `true` when [error] is a transient network connectivity problem
/// that is outside the app's control (e.g. no internet, DNS failure,
/// connection reset, or timeout on a slow link).
///
/// Use this to downgrade Crashlytics reports from fatal → non-fatal so that
/// flaky-network conditions don't pollute the crash dashboard.
bool isTransientNetworkError(Object error) {
  // Direct SocketException from dart:io
  if (error is SocketException) return true;
  if (error is PathNotFoundException) return true;
  if (error is FileSystemException && error.osError?.errorCode == 2) {
    return true;
  }

  // String-based checks cover wrapped exceptions
  // (e.g. http.ClientException, Flutter image pipeline errors)
  final msg = error.toString();
  return msg.contains('SocketException') ||
      msg.contains('PathNotFoundException') ||
      msg.contains('No such file or directory') ||
      msg.contains('errno = 2') ||
      msg.contains('Failed host lookup') ||
      msg.contains('No address associated with hostname') ||
      msg.contains('errno = 7') || // ENONET — no route to host
      msg.contains('Connection refused') ||
      msg.contains('Connection reset by peer') ||
      msg.contains('Connection timed out') ||
      msg.contains('Network is unreachable') ||
      (msg.contains('ClientException') &&
          (msg.contains('SocketException') ||
              msg.contains('host lookup') ||
              msg.contains('errno') ||
              msg.contains('connection abort') || // OS TCP reset (WSAECONNABORTED)
              msg.contains('Software caused connection abort')));
}
