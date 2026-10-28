import 'package:flutter/foundation.dart';

/// Handles Google Play in-app updates without interrupting the user.
abstract class IUpdateService {
  /// True once a flexible update has finished downloading and only needs a
  /// restart to take effect.
  ValueListenable<bool> get updateReady;

  /// First check of the process. Applies an already downloaded update (the
  /// app has just started, so nobody is mid-session) or starts a new one.
  Future<void> onColdStart();

  /// Check on return to foreground. Only reports a downloaded update through
  /// [updateReady]; never starts a download or restarts the app.
  Future<void> onResume();

  /// Installs the downloaded update, restarting the app. Only ever called by
  /// the user (banner restart) or on a cold start. Returns false when
  /// Play could not complete it.
  Future<bool> applyDownloadedUpdate();
}
