import 'dart:async';
import 'dart:developer' as developer;

import 'package:devocional_nuevo/services/i_update_preferences.dart';
import 'package:devocional_nuevo/services/i_update_service.dart';
import 'package:devocional_nuevo/services/update_policy.dart';
import 'package:flutter/foundation.dart';
import 'package:in_app_update/in_app_update.dart';

/// Play in-app update integration driven by [UpdatePolicy].
///
/// The plugin may also relaunch an in-progress immediate flow natively on
/// activity resume, but that state lives in the plugin's Activity callbacks
/// and is lost on process death, so the resume path via [UpdatePolicy] stays.
///
/// A pending performImmediateUpdate future may never complete (plugin
/// limitation), so no in-flight state is kept; a later check simply launches
/// again.
///
/// Flexible updates are guarded: Play's consent dialog pauses and resumes the
/// activity, which triggers another check, so only one flexible flow runs at
/// a time. A downloaded update is never installed automatically: every check
/// that sees it raises [updateReady], and only the user's tap
/// ([applyDownloadedUpdate]) completes it.
class UpdateService implements IUpdateService {
  UpdateService({required IUpdatePreferences preferences})
      : _preferences = preferences;

  static const String _logName = 'UpdateService';

  final IUpdatePreferences _preferences;
  bool _flexibleInFlight = false;

  /// Declined version kept in memory so a failed write cannot cause the
  /// dialog to show again in this session.
  int? _sessionDeclinedVersionCode;
  StreamSubscription<InstallStatus>? _installSubscription;
  final ValueNotifier<bool> _updateReady = ValueNotifier<bool>(false);
  final ValueNotifier<bool> _updateDownloading = ValueNotifier<bool>(false);
  Completer<UpdateInstallResult>? _pendingApply;
  Completer<UpdateInstallResult>? _applyThisTick;

  @override
  ValueListenable<bool> get updateReady => _updateReady;

  @override
  ValueListenable<bool> get updateDownloading => _updateDownloading;

  @override
  Future<void> checkForUpdate() async {
    final AppUpdateInfo info;
    try {
      info = await InAppUpdate.checkForUpdate();
    } catch (e) {
      _logError('Error checking for updates: $e');
      return;
    }
    // A read failure must not block urgent or downloaded updates, so it is
    // treated as "not declined".
    int? declined = _sessionDeclinedVersionCode;
    try {
      declined ??= await _preferences.getDeclinedVersionCode();
    } catch (e) {
      _logError('Error reading declined update version: $e');
    }

    final action = UpdatePolicy.decide(
      updateAvailable:
          info.updateAvailability == UpdateAvailability.updateAvailable,
      inProgress: info.updateAvailability ==
          UpdateAvailability.developerTriggeredUpdateInProgress,
      immediateAllowed: info.immediateUpdateAllowed,
      flexibleAllowed: info.flexibleUpdateAllowed,
      declinedForThisVersion:
          declined != null && declined == info.availableVersionCode,
      downloaded: info.installStatus == InstallStatus.downloaded,
      priority: info.updatePriority,
    );

    _logRelease(
      'decision: ${action.name} '
      '(availability: ${info.updateAvailability.name}, '
      'priority: ${info.updatePriority}, '
      'immediateAllowed: ${info.immediateUpdateAllowed}, '
      'flexibleAllowed: ${info.flexibleUpdateAllowed}, '
      'installStatus: ${info.installStatus.name}, '
      'availableVersionCode: ${info.availableVersionCode})',
    );

    switch (action) {
      case UpdateAction.none:
        // Follows a download started in an earlier session.
        if (info.installStatus == InstallStatus.downloading) {
          _followDownload();
        }
      case UpdateAction.immediate:
      case UpdateAction.resumeImmediate:
        await _performImmediate();
      case UpdateAction.flexible:
        await _startFlexible(info.availableVersionCode);
      case UpdateAction.markReady:
        _markReady();
    }
  }

  Future<void> _performImmediate() async {
    try {
      final result = await InAppUpdate.performImmediateUpdate();
      _logRelease('immediate update result: ${result.name}');
    } catch (e) {
      _logError('Error performing immediate update: $e');
    }
  }

  Future<void> _startFlexible(int? versionCode) async {
    if (_flexibleInFlight) {
      _logRelease('flexible update already in flight, skipping');
      return;
    }
    // Listen before starting so no install event is missed. The plugin
    // registers a native listener per startFlexibleUpdate and never removes
    // it, so the in-flight and declined guards must stay strict: they are
    // what bound those leaks.
    _listenToInstallStatus();

    final AppUpdateResult result;
    try {
      result = await InAppUpdate.startFlexibleUpdate();
    } catch (e) {
      _logError('Error starting flexible update: $e');
      _endFlexibleFlow();
      return;
    }
    _logRelease('flexible update result: ${result.name}');
    // plugin 5.0.0 only completes startFlexibleUpdate once the download
    // finished, so the spinner comes from the install-status stream, not from
    // this reply.
    if (result == AppUpdateResult.success) return;
    _endFlexibleFlow();
    if (result == AppUpdateResult.userDeniedUpdate && versionCode != null) {
      await _saveDeclined(versionCode);
    }
  }

  void _listenToInstallStatus() {
    _flexibleInFlight = true;
    _installSubscription = InAppUpdate.installUpdateListener.listen(
      _onInstallStatus,
      onError: (Object e) {
        _logError('Error listening to install status: $e');
        _endFlexibleFlow();
      },
      onDone: _endFlexibleFlow,
    );
  }

  void _followDownload() {
    _updateDownloading.value = true;
    if (_flexibleInFlight) return;
    _listenToInstallStatus();
  }

  void _markReady() {
    _updateDownloading.value = false;
    _updateReady.value = true;
    // Back in the foreground and still downloaded: a pending restart request
    // was not honored.
    _completePendingApply(UpdateInstallResult.unconfirmed);
  }

  void _completePendingApply(UpdateInstallResult result) {
    final pending = _pendingApply;
    _pendingApply = null;
    if (pending != null && !pending.isCompleted) pending.complete(result);
  }

  @override
  Future<UpdateInstallResult> applyDownloadedUpdate() {
    // Only same-tick duplicates are collapsed: the plugin never replies, so a
    // longer-lived guard would go stale when the user closes the card and
    // taps again. The banner itself blocks taps while its restart is pending.
    final duplicate = _applyThisTick;
    if (duplicate != null) return duplicate.future;
    final pending = Completer<UpdateInstallResult>();
    _applyThisTick = pending;
    _pendingApply = pending;
    scheduleMicrotask(() => _applyThisTick = null);
    _logRelease('completing flexible update');
    // The plugin never replies on success, so the call is not awaited.
    unawaited(
      InAppUpdate.completeFlexibleUpdate().then<void>((_) {
        _completePendingApply(UpdateInstallResult.installing);
      }).catchError((Object e) {
        _logError('Error completing flexible update: $e');
        _completePendingApply(UpdateInstallResult.failed);
      }),
    );
    return pending.future;
  }

  Future<void> _saveDeclined(int versionCode) async {
    _sessionDeclinedVersionCode = versionCode;
    try {
      await _preferences.setDeclinedVersionCode(versionCode);
    } catch (e) {
      _logError('Error saving declined update version: $e');
    }
  }

  void _onInstallStatus(InstallStatus status) {
    _logRelease('install status: ${status.name}');
    switch (status) {
      case InstallStatus.downloading:
        _updateDownloading.value = true;
      case InstallStatus.downloaded:
        _markReady();
        _endFlexibleFlow();
      case InstallStatus.failed:
      case InstallStatus.canceled:
        _updateDownloading.value = false;
        _endFlexibleFlow();
      case InstallStatus.unknown:
      case InstallStatus.pending:
      case InstallStatus.installing:
      // The app process is restarted before Play could report this.
      case InstallStatus.installed:
        break;
    }
  }

  void _endFlexibleFlow() {
    _cancelInstallSubscription();
    _flexibleInFlight = false;
  }

  void _cancelInstallSubscription() {
    unawaited(_installSubscription?.cancel());
    _installSubscription = null;
  }

  void _logError(String message) {
    developer.log(message, name: _logName);
    _logRelease(message);
  }

  // print() is the only logger that reaches adb logcat in release builds
  // (see _startupLog in main.dart).
  void _logRelease(String message) {
    // ignore: avoid_print
    print('[UpdateService] $message');
  }
}
