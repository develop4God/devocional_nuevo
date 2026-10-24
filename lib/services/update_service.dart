import 'dart:async';
import 'dart:developer' as developer;

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

  UpdateService(this._prefs, {DateTime Function()? clock})
      : _clock = clock ?? DateTime.now;

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
    try {
      final info = await InAppUpdate.checkForUpdate();

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
      switch (action) {
        case UpdateAction.immediate:
          await InAppUpdate.performImmediateUpdate();
        case UpdateAction.flexible:
          await _startFlexibleUpdate();
        case UpdateAction.none:
          break;
      }
    } catch (e) {
      developer.log('Error checking for updates: $e', name: 'UpdateService');
    }
  }

  Future<void> _startFlexibleUpdate() async {
    final lastOfferMs = _prefs.getInt(_lastOfferKey);
    final now = _clock();
    if (lastOfferMs != null &&
        now.difference(DateTime.fromMillisecondsSinceEpoch(lastOfferMs)) <
            _offerInterval) {
      return;
    }

    _statusSubscription ??= InAppUpdate.installUpdateListener.listen(
      (status) {
        if (status == InstallStatus.downloaded) _updateReady.value = true;
      },
      onError: (Object e) => developer.log(
        'Install status error: $e',
        name: 'UpdateService',
      ),
    );
    final result = await InAppUpdate.startFlexibleUpdate();
    // A failed offer is not counted, so it is retried on the next start.
    if (result != AppUpdateResult.inAppUpdateFailed) {
      await _prefs.setInt(_lastOfferKey, now.millisecondsSinceEpoch);
    }
  }

  @override
  Future<bool> applyDownloadedUpdate() async {
    try {
      await InAppUpdate.completeFlexibleUpdate();
      _updateReady.value = false;
      return true;
    } catch (e) {
      developer.log(
        'Could not complete flexible update: $e',
        name: 'UpdateService',
      );
      return false;
    }
  }

  void dispose() {
    _statusSubscription?.cancel();
    _updateReady.dispose();
  }
}
