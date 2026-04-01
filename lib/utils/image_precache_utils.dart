// lib/utils/image_precache_utils.dart
//
// Safe wrapper around Flutter's [precacheImage] that prevents network errors
// from reaching [FlutterError.reportError] — and therefore from being
// recorded as **fatal** crashes in Firebase Crashlytics.
//
// ## Why this exists
//
// [precacheImage] internally wires an [ImageStreamListener.onError] callback.
// When that callback fires and NO caller-supplied [onError] is provided,
// Flutter calls [FlutterError.reportError], which propagates to
// [FlutterError.onError].  Because the app sets
// `FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError`,
// every image-load failure on a flaky network becomes a reported fatal crash.
//
// Note: the `Future` returned by [precacheImage] is **always completed
// successfully** (even on error — it calls `completer.complete()` not
// `completer.completeError()`).  This means `.catchError()` chains on that
// future **never fire** for image-load failures; only the `onError` parameter
// prevents the crash report.

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

/// Precaches [provider] into Flutter's image cache without reporting load
/// failures as fatal Flutter errors.
///
/// When the image cannot be fetched (e.g. no internet, DNS failure, slow
/// connection), the error is silently swallowed after a [debugPrint] log.
/// The optional [onNetworkError] callback lets callers react to failures
/// (e.g. remove a URL from a retry-guard set) without triggering Crashlytics.
///
/// Example — fire-and-forget:
/// ```dart
/// safePrecacheImage(CachedNetworkImageProvider(url), context,
///     debugTag: 'card[1]');
/// ```
///
/// Example — with retry cleanup:
/// ```dart
/// safePrecacheImage(provider, context,
///     debugTag: 'card[$i]',
///     onNetworkError: (_, __) => _precachedUrls.remove(url));
/// ```
///
/// Example — with timeout (caps how long we wait for a slow network):
/// ```dart
/// await safePrecacheImage(provider, context, debugTag: 'card[0]')
///     .timeout(const Duration(milliseconds: 500));
/// // Note: TimeoutException is swallowed by the caller's own try/catch.
/// ```
Future<void> safePrecacheImage(
  ImageProvider provider,
  BuildContext context, {
  String? debugTag,
  void Function(Object error, StackTrace? stackTrace)? onNetworkError,
}) {
  return precacheImage(
    provider,
    context,
    onError: (Object error, StackTrace? stackTrace) {
      // Log for debugging — never re-throw, never call FlutterError.reportError.
      debugPrint('⚠️ [safePrecacheImage] ${debugTag ?? '(no tag)'}: $error');
      onNetworkError?.call(error, stackTrace);
    },
  );
}
