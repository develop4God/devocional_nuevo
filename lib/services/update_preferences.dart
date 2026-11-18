import 'package:devocional_nuevo/services/i_update_preferences.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// [IUpdatePreferences] backed by SharedPreferences.
class UpdatePreferences implements IUpdatePreferences {
  static const String declinedVersionCodeKey =
      'update_declined_flexible_version_code';
  static const String restartPendingKey = 'update_restart_pending';

  @override
  Future<int?> getDeclinedVersionCode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(declinedVersionCodeKey);
  }

  @override
  Future<void> setDeclinedVersionCode(int versionCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(declinedVersionCodeKey, versionCode);
  }

  @override
  Future<bool> getRestartPending() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(restartPendingKey) ?? false;
  }

  @override
  Future<void> setRestartPending(bool pending) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(restartPendingKey, pending);
  }
}
