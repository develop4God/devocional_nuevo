/// Persists the app update version the user declined.
abstract class IUpdatePreferences {
  /// Returns the available version code the user declined, if any.
  Future<int?> getDeclinedVersionCode();

  /// Remembers [versionCode] as declined so it is not offered again.
  Future<void> setDeclinedVersionCode(int versionCode);
}
