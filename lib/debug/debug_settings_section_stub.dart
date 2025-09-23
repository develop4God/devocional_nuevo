// lib/debug/debug_settings_section_stub.dart
// STUB para release builds - garantiza que no hay código debug en producción
import 'package:flutter/material.dart';

/// Stub/Placeholder que reemplaza DebugSettingsSection en release builds
/// Garantiza que NO hay codigo debug en producción
class DebugSettingsSection extends StatelessWidget {
  // Misma signature para compatibility
  final String donationMode;
  final bool showBadgesTab;
  final bool showBackupSection;
  final VoidCallback onRefreshFlags;

  const DebugSettingsSection({
    super.key,
    required this.donationMode,
    required this.showBadgesTab,
    required this.showBackupSection,
    required this.onRefreshFlags,
  });

  @override
  Widget build(BuildContext context) {
    // En release builds, este widget NO retorna nada
    // Garantiza cero código debug en producción
    return const SizedBox.shrink();
  }
}
