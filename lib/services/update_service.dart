import 'dart:async';
import 'dart:developer' as developer;

import 'package:devocional_nuevo/services/i_update_preferences.dart';
import 'package:devocional_nuevo/services/i_update_service.dart';
import 'package:devocional_nuevo/services/update_policy.dart';
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
/// a time. A flexible update downloaded mid-session is never installed in
/// that session; it is installed on the first check of the next cold start
/// (this lazy singleton lives once per process), so the user is never
/// restarted while using the app.
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
  bool _coldStartCheckDone = false;

  @override
  Future<void> checkForUpdate() async {
    final AppUpdateInfo info;
    try {
      info = await InAppUpdate.checkForUpdate();
    } catch (e) {
      _logError('Error checking for updates: $e');
      return;
    }
    // Only the first successful check of the process may install a
    // downloaded flexible update.
    final isColdStart = !_coldStartCheckDone;
    _coldStartCheckDone = true;

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
        return;
      case UpdateAction.immediate:
      case UpdateAction.resumeImmediate:
        await _performImmediate();
      case UpdateAction.flexible:
        await _startFlexible(info.availableVersionCode);
      case UpdateAction.completeFlexible:
        if (isColdStart) _completeFlexible();
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
    _flexibleInFlight = true;
    // Listen before starting so no install event is missed.
    _installSubscription = InAppUpdate.installUpdateListener.listen(
      _onInstallStatus,
      onError: (Object e) {
        _logError('Error listening to install status: $e');
        _endFlexibleFlow();
      },
      onDone: _endFlexibleFlow,
    );

    final AppUpdateResult result;
    try {
      result = await InAppUpdate.startFlexibleUpdate();
    } catch (e) {
      _logError('Error starting flexible update: $e');
      _endFlexibleFlow();
      return;
    }
    _logRelease('flexible update result: ${result.name}');
    if (result == AppUpdateResult.success) return;
    _endFlexibleFlow();
    if (result == AppUpdateResult.userDeniedUpdate && versionCode != null) {
      await _saveDeclined(versionCode);
    }
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
      // Installed on the next cold start, never mid-session.
      case InstallStatus.downloaded:
      case InstallStatus.failed:
      case InstallStatus.canceled:
        _endFlexibleFlow();
      case InstallStatus.unknown:
      case InstallStatus.pending:
      case InstallStatus.downloading:
      case InstallStatus.installing:
      // The app process is restarted before Play could report this.
      case InstallStatus.installed:
        break;
    }
  }

  void _completeFlexible() {
    // The plugin never replies to completeFlexibleUpdate, so the guard is
    // released before the call instead of after it.
    _flexibleInFlight = false;
    _logRelease('completing flexible update');
    unawaited(
      InAppUpdate.completeFlexibleUpdate().catchError((Object e) {
        _logError('Error completing flexible update: $e');
      }),
    );
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
