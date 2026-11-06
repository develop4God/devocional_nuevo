/// What the app should do about a Play Store update.
enum UpdateAction { none, flexible, immediate, resumeImmediate }

/// Decides between a background (flexible) and a blocking (immediate) update.
/// A release marked urgent in Play blocks the user whenever an immediate update
/// is allowed. A regular release is flexible, and only falls back to a blocking
/// immediate update when Play allows no flexible one.
class UpdatePolicy {
  UpdatePolicy._();

  /// Play priority (0-5, set per release) from which an update is urgent.
  static const int criticalPriority = 4;

  static UpdateAction decide({
    required bool updateAvailable,
    required bool immediateAllowed,
    required bool flexibleAllowed,
    required int? priority,
    required bool inProgress,
  }) {
    final critical = (priority ?? 0) >= criticalPriority;
    if (inProgress) {
      return critical && immediateAllowed
          ? UpdateAction.resumeImmediate
          : UpdateAction.none;
    }
    if (!updateAvailable) return UpdateAction.none;

    if (critical && immediateAllowed) return UpdateAction.immediate;
    if (flexibleAllowed) return UpdateAction.flexible;
    if (immediateAllowed) return UpdateAction.immediate;
    return UpdateAction.none;
  }
}
