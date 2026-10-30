import 'package:flutter/foundation.dart';

/// Handles Google Play in-app updates without interrupting the user.
abstract class IUpdateService {
  /// True once a flexible update has finished downloading and only needs a
  /// restart to take effect.
  ValueListenable<bool> get updateReady;

  /// First check of the process. Reports an already downloaded update through
  /// [updateReady], or starts a background download. Only an update Play marks
  /// urgent is shown as a blocking screen.
  Future<void> onColdStart();

  /// Check on return to foreground. Only reports a downloaded update through
  /// [updateReady]; never starts a download or restarts the app.
  Future<void> onResume();

  /// Installs the downloaded update, restarting the app. Only ever called by
  /// the user (banner restart). Returns false when Play could not complete it.
  Future<bool> applyDownloadedUpdate();
}
