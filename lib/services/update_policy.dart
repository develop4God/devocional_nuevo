/// What the app should do about a Play Store update.
enum UpdateAction { none, flexible, immediate }

/// Decides between a background (flexible) and a blocking (immediate) update.
/// Only a release marked urgent in Play blocks the user.
class UpdatePolicy {
  UpdatePolicy._();

  /// Play priority (0-5, set per release) from which an update is urgent.
  static const int criticalPriority = 4;

  static UpdateAction decide({
    required bool updateAvailable,
    required bool immediateAllowed,
    required bool flexibleAllowed,
    required int? priority,
  }) {
    if (!updateAvailable) return UpdateAction.none;

    final critical = (priority ?? 0) >= criticalPriority;
    if (critical && immediateAllowed) return UpdateAction.immediate;
    if (flexibleAllowed) return UpdateAction.flexible;
    return UpdateAction.none;
  }
}
