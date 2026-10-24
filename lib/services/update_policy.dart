/// What the app should do about a Play Store update.
enum UpdateAction { none, flexible, immediate }

/// Decides between a background (flexible) and a blocking (immediate) update
/// using only the data Google Play reports.
class UpdatePolicy {
  UpdatePolicy._();

  /// Play priority (0-5, set per release) from which an update is critical.
  static const int criticalPriority = 4;

  /// Days an update may stay unapplied before it becomes critical.
  static const int criticalStalenessDays = 60;

  static UpdateAction decide({
    required bool updateAvailable,
    required bool immediateAllowed,
    required bool flexibleAllowed,
    required int? priority,
    required int? stalenessDays,
  }) {
    if (!updateAvailable) return UpdateAction.none;

    final critical = (priority ?? 0) >= criticalPriority ||
        (stalenessDays ?? 0) >= criticalStalenessDays;
    if (critical && immediateAllowed) return UpdateAction.immediate;
    if (flexibleAllowed) return UpdateAction.flexible;
    return UpdateAction.none;
  }
}
