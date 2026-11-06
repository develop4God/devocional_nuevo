/// Action to take after checking the store for an app update.
enum UpdateAction {
  none,
  immediate,
  resumeImmediate,
  flexible,
  completeFlexible
}

/// Decides how an app update is applied.
///
/// Urgent releases (Play update priority >= [criticalPriority]) block.
/// Medium releases (>= [flexiblePriority]) download in the background after
/// Play's own consent dialog, unless the user declined that version. A
/// downloaded flexible update is completed. All other releases are left to
/// Play Store auto-update.
class UpdatePolicy {
  const UpdatePolicy._();

  /// Minimum Play in-app update priority that forces an immediate update.
  static const int criticalPriority = 4;

  /// Minimum Play in-app update priority that offers a flexible update.
  static const int flexiblePriority = 2;

  static UpdateAction decide({
    required bool updateAvailable,
    required bool inProgress,
    required bool immediateAllowed,
    required bool flexibleAllowed,
    required bool declinedForThisVersion,
    required bool downloaded,
    required int priority,
  }) {
    final urgent = priority >= criticalPriority;
    // Google's resume sample skips the update-type check, but this plugin
    // never completes the call when Play refuses to launch, so only launch
    // when Play allows immediate. Non-urgent in-progress updates (e.g. a
    // leftover flexible download) never block the user.
    if (inProgress && urgent && immediateAllowed) {
      return UpdateAction.resumeImmediate;
    }
    if (updateAvailable && urgent && immediateAllowed) {
      return UpdateAction.immediate;
    }
    if (downloaded) return UpdateAction.completeFlexible;
    if (updateAvailable &&
        !urgent &&
        priority >= flexiblePriority &&
        flexibleAllowed &&
        !declinedForThisVersion) {
      return UpdateAction.flexible;
    }
    return UpdateAction.none;
  }
}
