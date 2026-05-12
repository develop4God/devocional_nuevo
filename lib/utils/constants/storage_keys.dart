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

/// Keys for one-time startup fixes.
/// Each key guards exactly one fix run per install.
/// Never reuse a key — add a new constant for each new fix.
///
/// NOTE: readGapFixDone is deprecated and no longer actively used.
/// The read-gap fix now runs idempotently on every startup (safe operation).
/// This constant is retained for historical data cleanup (users who upgraded from older versions).
abstract final class StartupFixKeys {
  /// Deprecated: no longer actively used. Retained for historical data only.
  /// The read-gap fix now runs on every startup (idempotent, safe to repeat).
  /// See [StartupMigrationService._applyReadGapFix].
  @Deprecated('Read gap fix now runs idempotently every startup. '
      'This key is retained for legacy data only.')
  static const String readGapFixDone = 'read_gap_fix_done';
}
