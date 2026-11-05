import 'dart:async';

import 'package:devocional_nuevo/services/i_update_service.dart';
import 'package:devocional_nuevo/services/update_policy.dart';
import 'package:flutter/foundation.dart';
import 'package:in_app_update/in_app_update.dart';

class UpdateService implements IUpdateService {
  final Duration _installTimeout;
  final ValueNotifier<bool> _updateReady = ValueNotifier(false);
  final ValueNotifier<bool> _updateDownloading = ValueNotifier(false);

  StreamSubscription<InstallStatus>? _statusSubscription;
  bool _coldStartHandled = false;
  Future<bool>? _completing;
  Future<void>? _resuming;
  Completer<void>? _installFailed;
  InstallStatus? _lastStatus;
  bool _startingFlexible = false;
  bool _disposed = false;

  /// Printed (not `developer.log`) so the lines also reach logcat in release
  /// builds, which is where Play update behaviour has to be diagnosed. Uses
  /// [debugPrintSynchronously] to bypass the release-mode `debugPrint` no-op
  /// set in main.dart.
  static void _log(String message) =>
      debugPrintSynchronously('[UpdateService] $message');

  UpdateService({Duration installTimeout = const Duration(seconds: 45)})
      : _installTimeout = installTimeout;

  // Play's dialog and status callbacks can answer after dispose; writing to a
  // disposed notifier would throw.
  void _setReady(bool value) {
    if (!_disposed) _updateReady.value = value;
  }

  void _setDownloading(bool value) {
    if (!_disposed) _updateDownloading.value = value;
  }

  @override
  ValueListenable<bool> get updateReady => _updateReady;

  @override
  ValueListenable<bool> get updateDownloading => _updateDownloading;

  @override
  Future<void> onColdStart() {
    final isColdStart = !_coldStartHandled;
    _coldStartHandled = true;
    return _check(isColdStart: isColdStart);
  }

  @override
  Future<void> onResume() => _check(isColdStart: false);

  Future<void> _check({required bool isColdStart}) async {
    try {
      final info = await InAppUpdate.checkForUpdate();
      _log(
        'check coldStart=$isColdStart availability=${info.updateAvailability} '
        'installStatus=${info.installStatus} priority=${info.updatePriority} '
        'staleness=${info.clientVersionStalenessDays} '
        'immediateAllowed=${info.immediateUpdateAllowed} '
        'flexibleAllowed=${info.flexibleUpdateAllowed} '
        'availableVersionCode=${info.availableVersionCode}',
      );
      _failStalledInstall(info.installStatus);

      if (info.installStatus == InstallStatus.downloaded) {
        if (isColdStart) {
          // Nothing on screen to lose at cold start; if the install fails the
          // banner lets the user retry.
          final applied = await applyDownloadedUpdate();
          if (!applied) _setReady(true);
        } else {
          _setReady(true);
        }
        return;
      }

      final inProgress = info.updateAvailability ==
          UpdateAvailability.developerTriggeredUpdateInProgress;
      final action = UpdatePolicy.decide(
        updateAvailable:
            info.updateAvailability == UpdateAvailability.updateAvailable,
        inProgress: inProgress,
        immediateAllowed: info.immediateUpdateAllowed,
        flexibleAllowed: info.flexibleUpdateAllowed,
        priority: info.updatePriority,
      );
      _log('decision=$action');
      // A download already running: only listen for its end. Derived from
      // every check so a download that ended without a status event (missed
      // before the listener attached) cannot leave the spinner on.
      if (inProgress) _listenForDownload();
      // Not while Play's accept dialog is open: its snapshot predates the
      // download and would hide the spinner _startFlexibleUpdate sets.
      if (!_startingFlexible) {
        _setDownloading(inProgress && action != UpdateAction.resumeImmediate);
      }
      if (action == UpdateAction.resumeImmediate) {
        await (_resuming ??= _resumeImmediate().whenComplete(
          () => _resuming = null,
        ));
        return;
      }
      if (!isColdStart) return;

      switch (action) {
        case UpdateAction.immediate:
          await InAppUpdate.performImmediateUpdate();
        case UpdateAction.flexible:
          await _startFlexibleUpdate();
        case UpdateAction.none:
        case UpdateAction.resumeImmediate:
          break;
      }
    } catch (e) {
      _log('error checking for updates: $e');
      _failPendingInstall('update check failed');
    }
  }

  Future<void> _resumeImmediate() async {
    final result = await InAppUpdate.performImmediateUpdate();
    _log('resume performImmediateUpdate result=$result');
  }

  Future<void> _startFlexibleUpdate() async {
    _listenForDownload();
    _lastStatus = null;
    _startingFlexible = true;
    final AppUpdateResult result;
    try {
      result = await InAppUpdate.startFlexibleUpdate();
    } finally {
      _startingFlexible = false;
    }
    _log('startFlexibleUpdate result=$result');
    // The call returns once the user accepts Play's dialog; the download then
    // runs on its own. A download that already ended (or failed) while this
    // call was pending has been reported by the listener.
    if (result == AppUpdateResult.success &&
        !_updateReady.value &&
        _lastStatus != InstallStatus.failed) {
      _setDownloading(true);
    }
  }

  void _listenForDownload() {
    _statusSubscription ??= InAppUpdate.installUpdateListener.listen(
      (status) {
        _log('install status=$status');
        _lastStatus = status;
        switch (status) {
          case InstallStatus.pending:
          case InstallStatus.downloading:
            _setDownloading(true);
          case InstallStatus.downloaded:
            _onDownloaded();
          case InstallStatus.failed:
          case InstallStatus.canceled:
            _setDownloading(false);
          default:
            break;
        }
      },
      onError: (Object e) => _log('install status error: $e'),
    );
  }

  /// Only raises the banner: for a download that finishes while the app is
  /// open, the restart that installs the update is the user's choice (at cold
  /// start an already downloaded update is installed automatically instead).
  void _onDownloaded() {
    _setDownloading(false);
    _setReady(true);
  }

  /// Repeated taps share one native completion. Cleared afterwards so a failed
  /// install can be retried.
  @override
  Future<bool> applyDownloadedUpdate() =>
      _completing ??= _completeUpdate().whenComplete(() => _completing = null);

  Future<bool> _completeUpdate() async {
    try {
      _log('completing flexible update');
      await _untilInstallEnds();
      _setReady(false);
      return true;
    } catch (e) {
      _log('could not complete flexible update: $e');
      return false;
    }
  }

  /// On success Play restarts the app. On failure the plugin never answers the
  /// call, so the wait also ends on a failed or canceled install status, when
  /// the app is back in the foreground with no install running (see
  /// [_failStalledInstall]), or after [_installTimeout].
  Future<void> _untilInstallEnds() {
    final failed = _installFailed = Completer<void>();
    final subscription = InAppUpdate.installUpdateListener.listen((status) {
      if (status == InstallStatus.failed || status == InstallStatus.canceled) {
        _failPendingInstall('install ended with $status');
      }
    });
    return Future.any([InAppUpdate.completeFlexibleUpdate(), failed.future])
        .timeout(_installTimeout)
        .whenComplete(() {
      subscription.cancel();
      _installFailed = null;
    });
  }

  /// Still on screen after an install request and Play is not installing: it
  /// did not restart the app. While Play reports the install as pending or
  /// installing, coming back to the foreground is not a failure.
  void _failStalledInstall(InstallStatus status) {
    if (status == InstallStatus.installing || status == InstallStatus.pending) {
      return;
    }
    _failPendingInstall('app is back in the foreground');
  }

  void _failPendingInstall(String reason) {
    final pending = _installFailed;
    if (pending != null && !pending.isCompleted) {
      pending.completeError(StateError(reason));
    }
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _statusSubscription?.cancel();
    _updateReady.dispose();
    _updateDownloading.dispose();
  }
}
