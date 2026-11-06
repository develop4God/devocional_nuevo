import 'dart:developer' as developer;

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
class UpdateService implements IUpdateService {
  static const String _logName = 'UpdateService';

  @override
  Future<void> checkForUpdate() async {
    final AppUpdateInfo info;
    try {
      info = await InAppUpdate.checkForUpdate();
    } catch (e) {
      _logError('Error checking for updates: $e');
      return;
    }

    final action = UpdatePolicy.decide(
      updateAvailable:
          info.updateAvailability == UpdateAvailability.updateAvailable,
      inProgress: info.updateAvailability ==
          UpdateAvailability.developerTriggeredUpdateInProgress,
      immediateAllowed: info.immediateUpdateAllowed,
      priority: info.updatePriority,
    );

    _logRelease(
      'decision: ${action.name} '
      '(availability: ${info.updateAvailability.name}, '
      'priority: ${info.updatePriority}, '
      'immediateAllowed: ${info.immediateUpdateAllowed}, '
      'availableVersionCode: ${info.availableVersionCode})',
    );

    if (action == UpdateAction.none) return;

    try {
      final result = await InAppUpdate.performImmediateUpdate();
      _logRelease('immediate update result: ${result.name}');
    } catch (e) {
      _logError('Error performing immediate update: $e');
    }
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
