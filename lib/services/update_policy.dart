/// Action to take after checking the store for an app update.
enum UpdateAction { none, immediate, resumeImmediate }

/// Decides whether an app update must block the user.
///
/// Only urgent releases (Play update priority >= [criticalPriority]) block.
/// All other releases are left to Play Store auto-update.
class UpdatePolicy {
  const UpdatePolicy._();

  /// Minimum Play in-app update priority that forces an immediate update.
  static const int criticalPriority = 4;

  static UpdateAction decide({
    required bool updateAvailable,
    required bool inProgress,
    required bool immediateAllowed,
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
    return UpdateAction.none;
  }
}
