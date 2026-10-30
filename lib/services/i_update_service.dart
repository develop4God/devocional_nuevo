import 'package:flutter/foundation.dart';

/// Handles Google Play in-app updates without interrupting the user.
abstract class IUpdateService {
  /// True once a flexible update has finished downloading and only needs a
  /// restart to take effect.
  ValueListenable<bool> get updateReady;

  /// First check of the process. Installs an already downloaded update right
  /// away (falling back to [updateReady] if the install fails), or starts a
  /// background download. Only an update Play marks urgent is shown as a
  /// blocking screen. When the install succeeds Play restarts the app, so the
  /// returned future may never complete: callers must not await it.
  Future<void> onColdStart();

  /// Check on return to foreground. Only reports a downloaded update through
  /// [updateReady]; never starts a download or restarts the app.
  Future<void> onResume();

  /// Installs the downloaded update, restarting the app. Only ever called by
  /// the user (banner restart) or on a cold start. Returns false when Play
  /// could not complete it.
  Future<bool> applyDownloadedUpdate();
}
