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

/// Handles Google Play in-app updates without interrupting the user.
abstract class IUpdateService {
  /// True once a flexible update has finished downloading and only needs a
  /// restart to take effect.
  ValueListenable<bool> get updateReady;

  /// True while a flexible update is downloading in the background. Play shows
  /// no progress of its own for it, so the app has to.
  ValueListenable<bool> get updateDownloading;

  /// First check of the process. Installs an already downloaded update right
  /// away (falling back to [updateReady] if the install fails), or starts a
  /// background download. Only an update Play marks urgent is shown as a
  /// blocking screen; an urgent update already in progress is resumed, and a
  /// background download already running is followed to raise [updateReady].
  /// When the install succeeds Play restarts the app, so the returned future
  /// may never complete: callers must not await it.
  Future<void> onColdStart();

  /// Check on return to foreground. Reports a downloaded update through
  /// [updateReady] and resumes an urgent update already in progress; never
  /// starts a new download.
  Future<void> onResume();

  /// Installs the downloaded update, restarting the app. Only ever called by
  /// the user (banner restart) or on a cold start. See [UpdateInstallResult]
  /// for the outcomes.
  Future<UpdateInstallResult> applyDownloadedUpdate();
}
