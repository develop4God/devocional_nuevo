import 'dart:async';

import 'package:devocional_nuevo/services/i_update_service.dart';
import 'package:devocional_nuevo/services/update_policy.dart';
import 'package:flutter/foundation.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UpdateService implements IUpdateService {
  static const String _lastOfferKey = 'update_last_offer_ms';
  static const Duration _offerInterval = Duration(hours: 24);

  final SharedPreferences _prefs;
  final DateTime Function() _clock;
  final ValueNotifier<bool> _updateReady = ValueNotifier(false);

  StreamSubscription<InstallStatus>? _statusSubscription;
  bool _coldStartHandled = false;
  Future<bool>? _completing;
  Completer<void>? _installFailed;

  /// Printed (not `developer.log`) so the lines also reach logcat in release
  /// builds, which is where Play update behaviour has to be diagnosed. Uses
  /// [debugPrintSynchronously] to bypass the release-mode `debugPrint` no-op
  /// set in main.dart.
  static void _log(String message) =>
      debugPrintSynchronously('[UpdateService] $message');

  UpdateService(
    this._prefs, {
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

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

  Future<void> _check({required bool isColdStart}) async {
    // Still on screen after an install request: Play did not restart the app.
    // Accepted trade-off: a resume event during a cold-start install also
    // counts as a failed install (a spurious banner is possible). It is the
    // only failure signal when Play never answers, so it is kept on purpose.
    _failPendingInstall('app is back in the foreground');
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
          // Nothing on screen to lose at cold start; if the install fails the
          // banner lets the user retry.
          final applied = await applyDownloadedUpdate();
          if (!applied) _updateReady.value = true;
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
    final now = _clock();
    final lastOfferMs = _prefs.getInt(_lastOfferKey);
    if (lastOfferMs != null) {
      final sinceLastOffer =
          now.difference(DateTime.fromMillisecondsSinceEpoch(lastOfferMs));
      if (sinceLastOffer < _offerInterval) {
        _log('offer skipped: last offer ${sinceLastOffer.inMinutes} min ago');
        return;
      }
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

  /// Only raises the banner: for a download that finishes while the app is
  /// open, the restart that installs the update is the user's choice (at cold
  /// start an already downloaded update is installed automatically instead).
  void _onDownloaded() => _updateReady.value = true;

  /// Repeated taps share one native completion. Cleared afterwards so a failed
  /// install can be retried.
  @override
  Future<bool> applyDownloadedUpdate() =>
      _completing ??= _completeUpdate().whenComplete(() => _completing = null);

  Future<bool> _completeUpdate() async {
    try {
      _log('completing flexible update');
      await _untilInstallEnds();
      _updateReady.value = false;
      return true;
    } catch (e) {
      _log('could not complete flexible update: $e');
      return false;
    }
  }

  /// On success Play restarts the app. On failure the plugin never answers the
  /// call, so the wait also ends on a failed or canceled install status, or
  /// when the app is back in the foreground (see [_check]).
  Future<void> _untilInstallEnds() {
    final failed = _installFailed = Completer<void>();
    final subscription = InAppUpdate.installUpdateListener.listen((status) {
      if (status == InstallStatus.failed || status == InstallStatus.canceled) {
        _failPendingInstall('install ended with $status');
      }
    });
    return Future.any([InAppUpdate.completeFlexibleUpdate(), failed.future])
        .whenComplete(() {
      subscription.cancel();
      _installFailed = null;
    });
  }

  void _failPendingInstall(String reason) {
    final pending = _installFailed;
    if (pending != null && !pending.isCompleted) {
      pending.completeError(StateError(reason));
    }
  }

  void dispose() {
    _statusSubscription?.cancel();
    _updateReady.dispose();
  }
}
