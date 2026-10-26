import 'dart:async';

import 'package:devocional_nuevo/services/i_update_service.dart';
import 'package:devocional_nuevo/services/update_policy.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UpdateService implements IUpdateService {
  static const String _lastOfferKey = 'update_last_offer_ms';
  static const Duration _offerInterval = Duration(hours: 24);

  final SharedPreferences _prefs;
  final DateTime Function() _clock;
  final bool Function() _isInBackground;
  final ValueNotifier<bool> _updateReady = ValueNotifier(false);

  StreamSubscription<InstallStatus>? _statusSubscription;
  bool _coldStartHandled = false;
  bool _downloadHandled = false;
  Future<bool>? _completing;

  /// Printed (not `developer.log`) so the lines also reach logcat in release
  /// builds, which is where Play update behaviour has to be diagnosed.
  static void _log(String message) => debugPrint('[UpdateService] $message');

  UpdateService(
    this._prefs, {
    DateTime Function()? clock,
    bool Function()? isInBackground,
  })  : _clock = clock ?? DateTime.now,
        _isInBackground = isInBackground ?? _isAppHidden;

  /// `paused` only: `inactive` also covers Play's own consent dialog, which
  /// must never trigger an install.
  static bool _isAppHidden() =>
      WidgetsBinding.instance.lifecycleState == AppLifecycleState.paused;

  @override
  ValueListenable<bool> get updateReady => _updateReady;

  @override
  Future<void> onColdStart() {
    final isColdStart = !_coldStartHandled;
    _coldStartHandled = true;
    return _check(isColdStart: isColdStart);
  }

  @override
  Future<void> onResume() => _check(isColdStart: false);

  @override
  Future<void> onBackground() async {
    if (!_updateReady.value) return;
    await applyDownloadedUpdate();
  }

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

      if (info.installStatus == InstallStatus.downloaded) {
        if (isColdStart) {
          await applyDownloadedUpdate();
        } else {
          _updateReady.value = true;
        }
        return;
      }
      if (!isColdStart) return;

      final action = UpdatePolicy.decide(
        updateAvailable:
            info.updateAvailability == UpdateAvailability.updateAvailable,
        immediateAllowed: info.immediateUpdateAllowed,
        flexibleAllowed: info.flexibleUpdateAllowed,
        priority: info.updatePriority,
        stalenessDays: info.clientVersionStalenessDays,
      );
      _log('decision=$action');
      switch (action) {
        case UpdateAction.immediate:
          await InAppUpdate.performImmediateUpdate();
        case UpdateAction.flexible:
          await _startFlexibleUpdate();
        case UpdateAction.none:
          break;
      }
    } catch (e) {
      _log('error checking for updates: $e');
    }
  }

  Future<void> _startFlexibleUpdate() async {
    final lastOfferMs = _prefs.getInt(_lastOfferKey);
    final now = _clock();
    if (lastOfferMs != null &&
        now.difference(DateTime.fromMillisecondsSinceEpoch(lastOfferMs)) <
            _offerInterval) {
      _log(
          'offer skipped: last offer ${now.difference(DateTime.fromMillisecondsSinceEpoch(lastOfferMs)).inMinutes} min ago');
      return;
    }

    _statusSubscription ??= InAppUpdate.installUpdateListener.listen(
      (status) {
        _log('install status=$status');
        if (status == InstallStatus.downloaded) _onDownloaded();
      },
      onError: (Object e) => _log('install status error: $e'),
    );
    final result = await InAppUpdate.startFlexibleUpdate();
    _log('startFlexibleUpdate result=$result');
    // A failed offer is not counted, so it is retried on the next start.
    if (result != AppUpdateResult.inAppUpdateFailed) {
      await _prefs.setInt(_lastOfferKey, now.millisecondsSinceEpoch);
    }
  }

  /// Only the first `downloaded` status counts: the plugin adds a listener per
  /// offer, so Play's statuses arrive more than once. A download that finishes
  /// after the user left the app is installed right away, since
  /// `onBackground` already ran. A failed install is retried on the next
  /// background or cold start.
  void _onDownloaded() {
    _updateReady.value = true;
    if (_downloadHandled) return;
    _downloadHandled = true;
    if (_isInBackground()) unawaited(applyDownloadedUpdate());
  }

  /// Background, a late `downloaded` status and the banner can all ask at
  /// once; they share one native completion. Cleared afterwards so a failed
  /// install can be retried.
  @override
  Future<bool> applyDownloadedUpdate() =>
      _completing ??= _completeUpdate().whenComplete(() => _completing = null);

  Future<bool> _completeUpdate() async {
    try {
      _log('completing flexible update');
      await InAppUpdate.completeFlexibleUpdate();
      _updateReady.value = false;
      return true;
    } catch (e) {
      _log('could not complete flexible update: $e');
      return false;
    }
  }

  void dispose() {
    _statusSubscription?.cancel();
    _updateReady.dispose();
  }
}
