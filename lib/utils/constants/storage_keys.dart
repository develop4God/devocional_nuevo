// lib/utils/constants/storage_keys.dart
//
// Single source of truth for all SharedPreferences keys used by the app.
// Add new keys here — never inline magic strings in services or providers.

/// Keys for general app state stored in SharedPreferences.
abstract final class StorageKeys {
  // ── Devocional navigation ─────────────────────────────────────────────────
  static const String seenIndices = 'seenIndices';
  static const String currentIndex = 'currentIndex';

  // ── Favorites ─────────────────────────────────────────────────────────────
  static const String favorites = 'favorites';

  // ── Notifications ─────────────────────────────────────────────────────────
  static const String lastNotificationDate = 'lastNotificationDate';

  // ── Invitation dialogs ────────────────────────────────────────────────────
  static const String dontShowInvitation = 'dontShowInvitation';
  static const String showInvitationDialog = 'showInvitationDialog';
}

/// Keys for one-time startup migrations.
/// Each key guards exactly one migration run per install.
/// Never reuse a key — add a new constant for each new migration.
abstract final class MigrationKeys {
  /// Guards the V3 single-entry gap fix (Pattern A: index 0 + Pattern B: interior).
  static const String singleGapFix = 'migration_single_gap_fix_done';
}
