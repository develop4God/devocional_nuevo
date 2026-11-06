/// Checks the store for app updates and applies the update policy.
abstract class IUpdateService {
  /// Checks for an update and starts a blocking update only when required.
  /// Never throws.
  Future<void> checkForUpdate();
}
