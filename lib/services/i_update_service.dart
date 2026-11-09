import 'package:flutter/foundation.dart';

/// Outcome of asking Play to install a downloaded update.
enum UpdateInstallResult {
  /// Play accepted the request and restarts the app to install.
  installing,

  /// Play explicitly reported that the install failed or was canceled.
  failed,

  /// The app came back to the foreground and Play still reports the update as
  /// downloaded: the install may be waiting, so nothing is reported as an error.
  unconfirmed,
}

/// Checks the store for app updates and applies the update policy.
abstract class IUpdateService {
  /// True once a flexible update has finished downloading and only needs a
  /// restart to take effect. Derived from Play on every check, so it is also
  /// raised on cold start and resume.
  ValueListenable<bool> get updateReady;

  /// True while a flexible update is downloading in the background. Play shows
  /// no progress of its own for it, so the app has to.
  ValueListenable<bool> get updateDownloading;

  /// Checks for an update and starts a blocking update only when required.
  /// Never installs a downloaded update: it only raises [updateReady].
  /// Never throws.
  Future<void> checkForUpdate();

  /// Installs the downloaded update, restarting the app. Only ever called by
  /// the user (banner restart). The plugin never replies on success, so the
  /// returned future may never complete; see [UpdateInstallResult].
  Future<UpdateInstallResult> applyDownloadedUpdate();
}
