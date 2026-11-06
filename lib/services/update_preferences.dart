import 'package:devocional_nuevo/services/i_update_preferences.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// [IUpdatePreferences] backed by SharedPreferences.
class UpdatePreferences implements IUpdatePreferences {
  static const String declinedVersionCodeKey =
      'update_declined_flexible_version_code';

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
}
