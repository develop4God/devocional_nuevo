import 'dart:async';

import 'package:devocional_nuevo/services/i_stale_task_cleaner.dart';
import 'package:devocional_nuevo/services/i_update_preferences.dart';
import 'package:devocional_nuevo/services/i_update_service.dart';
import 'package:devocional_nuevo/services/update_policy.dart';
import 'package:devocional_nuevo/utils/release_log.dart';
import 'package:flutter/foundation.dart';
import 'package:in_app_update/in_app_update.dart';

/// Play in-app update integration driven by [UpdatePolicy].
///
/// The plugin may also relaunch an in-progress immediate flow natively on
/// activity resume, but that state lives in the plugin's Activity callbacks
/// and is lost on process death, so the resume path via [UpdatePolicy] stays.
///
/// A pending performImmediateUpdate future may never complete (plugin
/// limitation), and Play's immediate UI pauses/resumes the activity, which
/// triggers another check. A plain in-flight flag could therefore block
/// forever, so launches are only de-duplicated for [_immediateWindow]: a check
/// inside the window is skipped, a later one launches again. The window is
/// cleared as soon as the plugin future completes.
///
/// Flexible updates are guarded: Play's consent dialog pauses and resumes the
/// activity, which triggers another check, so only one flexible flow runs at
/// a time. A downloaded update is never installed automatically: every check
/// that sees it raises [updateReady], and only the user's tap
/// ([applyDownloadedUpdate]) completes it.
class UpdateService implements IUpdateService {
  UpdateService({
    required IUpdatePreferences preferences,
    required IStaleTaskCleaner staleTaskCleaner,
    DateTime Function() now = DateTime.now,
  })  : _preferences = preferences,
        _staleTaskCleaner = staleTaskCleaner,
        _now = now;

  static const String _logName = 'UpdateService';
  static const Duration _immediateWindow = Duration(minutes: 1);

  final IUpdatePreferences _preferences;
  final IStaleTaskCleaner _staleTaskCleaner;
  final DateTime Function() _now;
  DateTime? _immediateLaunchedAt;
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
  Future<void> checkForUpdate({String source = 'unknown'}) async {
    _log('checkForUpdate from $source');
    if (source == 'initState') await _cleanStaleTasksAfterRestart();
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
    final declinedInSession = declined != null;
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

    if (declined != null && declined == info.availableVersionCode) {
      _log(
        'declined version skip: code $declined '
        '(${declinedInSession ? 'session' : 'prefs'})',
      );
    }

    _log(
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

  /// Launches the Play immediate update unless one was launched within
  /// [_immediateWindow]. Trade-off: if the Play UI is dismissed without the
  /// plugin future ever completing, a resume inside that window is skipped.
  Future<void> _performImmediate() async {
    final launchedAt = _immediateLaunchedAt;
    final now = _now();
    if (launchedAt != null && now.difference(launchedAt) < _immediateWindow) {
      _log('immediate update already launched, skipping');
      return;
    }
    _immediateLaunchedAt = now;
    try {
      final result = await InAppUpdate.performImmediateUpdate();
      _log('immediate update result: ${result.name}');
    } catch (e) {
      _logError('Error performing immediate update: $e');
    }
    // A stale completion of an older launch must not clear a newer guard.
    if (_immediateLaunchedAt == now) _immediateLaunchedAt = null;
  }

  Future<void> _startFlexible(int? versionCode) async {
    if (_flexibleInFlight) {
      _log('flexible update already in flight, skipping');
      return;
    }
    _log('starting flexible update versionCode=$versionCode');
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
    _log('flexible update result: ${result.name}');
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
    _log('listening to install status');
    _flexibleInFlight = true;
    _installSubscription = InAppUpdate.installUpdateListener.listen(
      _onInstallStatus,
      onError: (Object e) {
        _logError('Error listening to install status: $e');
        _endFlexibleFlow();
      },
      onDone: () {
        _log('install stream done');
        _endFlexibleFlow();
      },
    );
  }

  void _followDownload() {
    _log('following a download started earlier');
    _updateDownloading.value = true;
    if (_flexibleInFlight) return;
    _listenToInstallStatus();
  }

  void _markReady() {
    _log('update ready raised');
    _updateDownloading.value = false;
    _updateReady.value = true;
    // Back in the foreground and still downloaded: a pending restart request
    // was not honored, so no restart cleanup may follow on a later cold start.
    if (_pendingApply != null) unawaited(_setRestartPending(false));
    _completePendingApply(UpdateInstallResult.unconfirmed);
  }

  void _completePendingApply(UpdateInstallResult result) {
    final pending = _pendingApply;
    _pendingApply = null;
    if (pending != null && !pending.isCompleted) {
      _log('pending apply completed as ${result.name}');
      pending.complete(result);
    }
  }

  @override
  Future<UpdateInstallResult> applyDownloadedUpdate() {
    // Only same-tick duplicates are collapsed: the plugin never replies, so a
    // longer-lived guard would go stale when the user closes the card and
    // taps again. The banner itself blocks taps while its restart is pending.
    final duplicate = _applyThisTick;
    if (duplicate != null) return duplicate.future;
    // Reuse an unanswered earlier request so its future is never orphaned.
    final pending = _pendingApply ?? Completer<UpdateInstallResult>();
    _applyThisTick = pending;
    _pendingApply = pending;
    scheduleMicrotask(() => _applyThisTick = null);
    _log('completing flexible update');
    // The plugin never replies on success, so the call is not awaited.
    unawaited(
      _setRestartPending(true).then((persisted) {
        _log(
          persisted
              ? 'restart requested, restartPending=true persisted'
              : 'restartPending write failed',
        );
        return InAppUpdate.completeFlexibleUpdate();
      }).then<void>((_) {
        _completePendingApply(UpdateInstallResult.installing);
      }).catchError((Object e) async {
        _logError('Error completing flexible update: $e');
        await _setRestartPending(false);
        _completePendingApply(UpdateInstallResult.failed);
      }),
    );
    return pending.future;
  }

  /// After a Play-driven restart Android can keep a stale recents card of the
  /// pre-update task. The marker is cleared first so cleanup runs at most
  /// once, and no failure here may affect startup.
  Future<void> _cleanStaleTasksAfterRestart() async {
    try {
      final restartPending = await _preferences.getRestartPending();
      _log('restartPending=$restartPending');
      if (!restartPending) {
        _log('stale task cleanup skipped (no restart pending)');
        return;
      }
      _log('restart pending, running stale task cleanup');
      await _preferences.setRestartPending(false);
      final removed = await _staleTaskCleaner.removeStaleAppTasks();
      _log(
        'removed $removed stale app task(s), ${removed > 0 ? 'cleanup was needed' : 'cleanup found nothing to remove'}',
      );
    } catch (e) {
      _logError('Error in stale task cleanup (reading flag or cleaning): $e');
    }
  }

  /// Returns whether the flag was persisted.
  Future<bool> _setRestartPending(bool pending) async {
    try {
      await _preferences.setRestartPending(pending);
      return true;
    } catch (e) {
      _logError('Error saving restart pending flag: $e');
      return false;
    }
  }

  Future<void> _saveDeclined(int versionCode) async {
    _sessionDeclinedVersionCode = versionCode;
    _log('saved declined versionCode $versionCode');
    try {
      await _preferences.setDeclinedVersionCode(versionCode);
    } catch (e) {
      _logError('Error saving declined update version: $e');
    }
  }

  void _onInstallStatus(InstallStatus status) {
    _log('install status: ${status.name}');
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

  /// Ends the flexible flow and clears the spinner, unless the flow ended
  /// because the download finished ([_markReady] already settled the state).
  void _endFlexibleFlow() {
    _log('flow ended');
    if (!_updateReady.value) _updateDownloading.value = false;
    _cancelInstallSubscription();
    _flexibleInFlight = false;
  }

  void _cancelInstallSubscription() {
    unawaited(_installSubscription?.cancel());
    _installSubscription = null;
  }

  void _logError(String message) => _log(message);

  void _log(String message) => logRelease(_logName, message);
}
