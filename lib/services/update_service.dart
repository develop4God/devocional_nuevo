import 'dart:async';

import 'package:devocional_nuevo/services/i_update_service.dart';
import 'package:devocional_nuevo/services/update_policy.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Reports a handled (non-fatal) error with a short reason.
typedef UpdateErrorReporter = void Function(
  Object error,
  StackTrace stack,
  String reason,
);

class UpdateService implements IUpdateService {
  /// [installedBuild] resolves the installed build number (used to tell a real
  /// downloaded update from a phantom one); [reportError] receives handled
  /// failures. Both default to the platform implementations.
  UpdateService({
    Future<int> Function()? installedBuild,
    UpdateErrorReporter? reportError,
  })  : _installedBuild = installedBuild ?? _platformBuildNumber,
        _reportError = reportError ?? _crashlyticsReport;

  final Future<int> Function() _installedBuild;
  final UpdateErrorReporter _reportError;

  static Future<int> _platformBuildNumber() async =>
      int.parse((await PackageInfo.fromPlatform()).buildNumber);

  static void _crashlyticsReport(Object e, StackTrace s, String reason) {
    FirebaseCrashlytics.instance.recordError(
      e,
      s,
      fatal: false,
      reason: reason,
    );
  }

  final ValueNotifier<bool> _updateReady = ValueNotifier(false);
  final ValueNotifier<bool> _updateDownloading = ValueNotifier(false);

  StreamSubscription<InstallStatus>? _statusSubscription;
  bool _coldStartHandled = false;
  Future<UpdateInstallResult>? _completing;
  Future<void>? _resuming;
  Completer<UpdateInstallResult>? _pendingInstall;
  InstallStatus? _lastStatus;
  bool _startingFlexible = false;
  bool _disposed = false;
  int? _installed;

  /// Printed (not `developer.log`) so the lines also reach logcat in release
  /// builds, which is where Play update behaviour has to be diagnosed. Uses
  /// [debugPrintSynchronously] to bypass the release-mode `debugPrint` no-op
  /// set in main.dart.
  static void _log(String message) =>
      debugPrintSynchronously('[UpdateService] $message');

  static void _logPhase(String phase, [String detail = '']) =>
      _log('phase=$phase${detail.isEmpty ? '' : ' $detail'}');

  /// Logs a failure with its context and sends it to the reporter. A reporter
  /// failure must never break the update flow.
  void _fail(
    String phase,
    Object error,
    StackTrace stack, {
    int? available,
  }) {
    _log(
      'error in $phase: $error (installed=$_installed available=$available)',
    );
    _logPhase('failed', 'in=$phase');
    try {
      _reportError(error, stack, 'UpdateService $phase failed');
    } catch (e) {
      _log('could not report error: $e');
    }
  }

  static bool _isUserDenial(Object e) =>
      e is PlatformException && e.code == 'USER_DENIED_UPDATE';

  /// Play can report `downloaded` for an install request it resolved to a
  /// version that is not newer than the installed one (nothing downloaded).
  /// Only a newer available version counts as a real download.
  Future<bool> _isRealDownload(AppUpdateInfo info) async {
    final installed = _installed = await _installedBuild();
    final available = info.availableVersionCode ?? 0;
    final real =
        info.installStatus == InstallStatus.downloaded && available > installed;
    if (real) {
      _logPhase(
          'downloaded-verified', 'installed=$installed available=$available');
    } else {
      _log(
        'phantom downloaded ignored installStatus=${info.installStatus} '
        'installed=$installed available=$available',
      );
      _setDownloading(false);
      _setReady(false);
      _logPhase('idle');
    }
    return real;
  }

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
    var phase = 'check';
    int? available;
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
      available = info.availableVersionCode;
      _releaseStalledInstall(info.installStatus);

      if (info.installStatus == InstallStatus.downloaded) {
        phase = 'verify';
        if (!await _isRealDownload(info)) return;
        _setDownloading(false);
        phase = 'install';
        if (isColdStart) {
          // Nothing on screen to lose at cold start; if the install fails the
          // banner lets the user retry.
          final result = await applyDownloadedUpdate();
          if (result != UpdateInstallResult.installing) _setReady(true);
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
        phase = 'resume-immediate';
        await (_resuming ??= _resumeImmediate().whenComplete(
          () => _resuming = null,
        ));
        return;
      }
      if (!isColdStart) return;

      switch (action) {
        // If the user backs out of a critical update they are not asked again
        // until the next cold start: this is intentional, resume checks never
        // start a new blocking update.
        case UpdateAction.immediate:
          phase = 'immediate';
          await InAppUpdate.performImmediateUpdate();
        case UpdateAction.flexible:
          phase = 'flexible';
          await _startFlexibleUpdate();
        case UpdateAction.none:
        case UpdateAction.resumeImmediate:
          break;
      }
    } catch (e, stack) {
      _log('error checking for updates: $e');
      _releasePendingInstall(UpdateInstallResult.unconfirmed);
      _setDownloading(false);
      if (_isUserDenial(e)) {
        _logPhase('idle', 'userDenied in=$phase');
      } else {
        _fail(phase, e, stack, available: available);
      }
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
    if (result != AppUpdateResult.success) {
      _setDownloading(false);
      _logPhase('idle', 'startFlexibleUpdate=$result');
      return;
    }
    // The call returns once the user accepts Play's dialog; the download then
    // runs on its own. A download that already ended (or failed) while this
    // call was pending has been reported by the listener.
    if (!_updateReady.value && _lastStatus != InstallStatus.failed) {
      _setDownloading(true);
      _logPhase('downloading');
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
            _logPhase('downloading', 'status=$status');
          case InstallStatus.downloaded:
            _onDownloaded();
          case InstallStatus.failed:
          case InstallStatus.canceled:
            _setDownloading(false);
            _logPhase('failed', 'status=$status');
          default:
            break;
        }
      },
      onError: (Object e, StackTrace stack) {
        _log('install status error: $e');
        _setDownloading(false);
        _fail('install-status', e, stack);
      },
    );
  }

  /// Only raises the banner: for a download that finishes while the app is
  /// open, the restart that installs the update is the user's choice (at cold
  /// start an already downloaded update is installed automatically instead).
  Future<void> _onDownloaded() async {
    int? available;
    try {
      final info = await InAppUpdate.checkForUpdate();
      available = info.availableVersionCode;
      if (!await _isRealDownload(info)) return;
      _setDownloading(false);
      _setReady(true);
    } catch (e, stack) {
      _setDownloading(false);
      _setReady(false);
      _fail('verify', e, stack, available: available);
    }
  }

  /// Repeated taps share one native completion. Cleared afterwards so an
  /// install that did not happen can be requested again.
  @override
  Future<UpdateInstallResult> applyDownloadedUpdate() =>
      _completing ??= _completeUpdate().whenComplete(() => _completing = null);

  Future<UpdateInstallResult> _completeUpdate() async {
    try {
      _logPhase('installing');
      _log('completing flexible update');
      final result = await _untilInstallEnds();
      _log('completing flexible update result=$result');
      if (result == UpdateInstallResult.installing) _setReady(false);
      if (result == UpdateInstallResult.unconfirmed) _logPhase('unconfirmed');
      return result;
    } catch (e, stack) {
      _log('could not complete flexible update: $e');
      _fail('install', e, stack);
      return UpdateInstallResult.failed;
    }
  }

  /// On success Play restarts the app. On failure the plugin never answers the
  /// call, so the wait also ends on a failed or canceled install status (a
  /// failure) or when the app is back in the foreground with no install
  /// running (see [_releaseStalledInstall], unconfirmed). There is no timeout:
  /// only Play or the user returning to the app ends the wait.
  Future<UpdateInstallResult> _untilInstallEnds() {
    final released = _pendingInstall = Completer<UpdateInstallResult>();
    final subscription = InAppUpdate.installUpdateListener.listen((status) {
      if (status == InstallStatus.failed || status == InstallStatus.canceled) {
        _releasePendingInstall(UpdateInstallResult.failed);
      }
    });
    return Future.any([
      InAppUpdate.completeFlexibleUpdate()
          .then((_) => UpdateInstallResult.installing),
      released.future,
    ]).whenComplete(() {
      subscription.cancel();
      _pendingInstall = null;
    });
  }

  /// Still on screen after an install request and Play is not installing: the
  /// app was not restarted. While Play reports the install as pending or
  /// installing, coming back to the foreground changes nothing. A failed or
  /// canceled install is a failure; anything else (for instance Play still
  /// reporting `downloaded`) is not confirmed either way, so it is released
  /// without an error.
  void _releaseStalledInstall(InstallStatus status) {
    switch (status) {
      case InstallStatus.installing:
      case InstallStatus.pending:
        return;
      case InstallStatus.failed:
      case InstallStatus.canceled:
        _releasePendingInstall(UpdateInstallResult.failed);
      default:
        _releasePendingInstall(UpdateInstallResult.unconfirmed);
    }
  }

  void _releasePendingInstall(UpdateInstallResult result) {
    final pending = _pendingInstall;
    if (pending != null && !pending.isCompleted) pending.complete(result);
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _statusSubscription?.cancel();
    _updateReady.dispose();
    _updateDownloading.dispose();
  }
}
