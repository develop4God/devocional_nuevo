// lib/debug/debug_settings_section.dart
// ESTE ARCHIVO SOLO EXISTE EN DEBUG - NUNCA VA A PRODUCCIÓN
import 'package:devocional_nuevo/debug/test_badges_page.dart';
import 'package:devocional_nuevo/debug/debug_flags.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Widget que contiene todas las opciones de debug
/// SOLO disponible en modo debug, completamente excluido de release builds
class DebugSettingsSection extends StatelessWidget {
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
    // Triple protección - este widget NUNCA debe mostrarse en release
    assert(
      kDebugMode,
      'DebugSettingsSection should NEVER be used in release mode',
    );

    if (!kDebugMode) {
      // Failsafe - si por alguna razón se ejecuta en release, retorna vacío
      return const SizedBox.shrink();
    }

    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),

        // Header para debug section
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.bug_report, color: Colors.red),
              const SizedBox(width: 8),
              Text(
                '🔧 DEBUG MODE ONLY',
                style: textTheme.titleSmall?.copyWith(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Test Badges
        InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const TestBadgesPage()),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              children: [
                Icon(Icons.bug_report, color: colorScheme.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Test Badges System',
                    style: textTheme.bodyMedium?.copyWith(
                      fontSize: 16,
                      color: colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 10),

        // Feature Flags Debug Panel
        ExpansionTile(
          leading: Icon(Icons.flag, color: colorScheme.primary),
          title: const Text('Feature Flags (Debug)'),
          subtitle: Text(
            'Donation: $donationMode | Badges: $showBadgesTab | Backup: $showBackupSection',
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          children: [
            ListTile(
              title: Text('Donation Mode: $donationMode'),
              subtitle: Text(
                donationMode == 'paypal'
                    ? 'PayPal Direct (Active)'
                    : 'Google Pay Flow (Active)',
              ),
              leading: Icon(
                donationMode == 'paypal'
                    ? Icons.payment
                    : Icons.account_balance_wallet,
                color: colorScheme.primary,
              ),
            ),
            ListTile(
              title: Text('Show Badges Tab: $showBadgesTab'),
              leading: Icon(
                showBadgesTab ? Icons.check_circle : Icons.cancel,
                color: showBadgesTab ? Colors.green : Colors.grey,
              ),
            ),
            ListTile(
              title: Text('Show Backup Section: $showBackupSection'),
              leading: Icon(
                showBackupSection ? Icons.check_circle : Icons.cancel,
                color: showBackupSection ? Colors.green : Colors.grey,
              ),
            ),
            ListTile(
              title: const Text('Refresh from Firebase'),
              leading: const Icon(Icons.cloud_sync),
              onTap: onRefreshFlags,
            ),
            const Divider(),
            StatefulBuilder(
              builder: (context, setState) {
                return ListTile(
                  title: const Text('🎤 TTS Force Fallback (Testing)'),
                  subtitle: const Text('Test voice fallback selection flow'),
                  leading: Icon(
                    Icons.mic,
                    color: DebugFlags.forceFallbackForTesting
                        ? Colors.orange
                        : Colors.grey,
                  ),
                  trailing: Switch(
                    value: DebugFlags.forceFallbackForTesting,
                    onChanged: (value) {
                      setState(() {
                        DebugFlags.forceFallbackForTesting = value;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            DebugFlags.forceFallbackForTesting
                                ? '🎤 TTS Fallback enabled - voices will use fallback locales'
                                : '🎤 TTS Fallback disabled - voices will use premium only',
                          ),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ],
    );
  }
}
