/// lib/debug/debug_flags.dart
/// Centralized mutable debug state — ONLY for development/testing
/// This class holds all runtime-toggleable debug flags.
/// NEVER included in release builds.
library;

/// Mutable debug flags for development and testing.
/// All flags here are runtime-configurable via debug UI.
/// This separation keeps Constants immutable (SRP) and groups all
/// mutable debug state in one logical place.
class DebugFlags {
  /// Force TTS voice fallback selection for testing.
  /// When enabled, VoiceSelectorDialog displays all available voices
  /// including fallback locales (Austria, Switzerland) for QA testing.
  /// 
  /// Default: false (production behavior)
  /// Only active: in debug mode (checked by VoiceSelectorDialog)
  static bool forceFallbackForTesting = false;
}

