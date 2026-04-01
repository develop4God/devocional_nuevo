// ignore_for_file: use_build_context_synchronously
import 'package:devocional_nuevo/blocs/supporter/supporter_bloc.dart';
import 'package:devocional_nuevo/blocs/supporter/supporter_event.dart';
import 'package:devocional_nuevo/blocs/supporter/supporter_state.dart';
import 'package:devocional_nuevo/models/supporter_tier.dart';
import 'package:devocional_nuevo/services/iap/i_iap_service.dart';
import 'package:devocional_nuevo/services/iap/iap_prefs_keys.dart';
import 'package:devocional_nuevo/services/service_locator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Debug section for In-App Purchase simulation and state reset.
/// Single Responsibility: only handles IAP debug tooling.
class DebugIapSection extends StatelessWidget {
  const DebugIapSection({super.key});

  void _simulatePurchase(BuildContext context, SupporterTier tier) {
    context.read<SupporterBloc>().add(DebugSimulatePurchase(tier));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('🛒 Simulated: ${tier.productId}'),
      duration: const Duration(seconds: 2),
    ));
  }

  void _resetIapState(BuildContext context) {
    try {
      serviceLocator.unregister<IIapService>();
    } catch (_) {}
    context.read<SupporterBloc>().add(DebugResetIapState());
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('🔄 IAP state reset — re-run restore to re-purchase'),
      duration: Duration(seconds: 3),
    ));
  }

  void _restorePurchases(BuildContext context) {
    context.read<SupporterBloc>().add(RestorePurchases());
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🔄 Restore Purchases triggered'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _clearAllPurchases(BuildContext context) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      for (final tier in SupporterTier.tiers) {
        await prefs.remove(IapPrefsKeys.purchasedKey(tier.productId));
      }
      try {
        serviceLocator.unregister<IIapService>();
      } catch (_) {}
      if (context.mounted) {
        context.read<SupporterBloc>().add(DebugResetIapState());
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('✨ All purchased items cleared — app will restore fresh on next init'),
          duration: Duration(seconds: 3),
        ));
      }
    } catch (e) {
      debugPrint('❌ Error clearing purchases: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error clearing purchases: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.orange.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.orange.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.payments_outlined, color: Colors.orange.shade800),
                const SizedBox(width: 8),
                Text(
                  '🛒 IAP Debug Tools',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.orange.shade800),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Simulate purchases via BLoC events only.\nNo real billing is triggered. Debug builds only.',
              style: TextStyle(fontSize: 11, color: Colors.orange.shade700),
            ),
            const SizedBox(height: 12),
            BlocBuilder<SupporterBloc, SupporterState>(
              builder: (context, state) {
                final purchased = state is SupporterLoaded
                    ? state.purchasedLevels
                    : <SupporterTierLevel>{};
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    // Simulate purchase per tier
                    ...SupporterTier.tiers.map((tier) {
                      final owned = purchased.contains(tier.level);
                      return ElevatedButton.icon(
                        onPressed: owned ? null : () => _simulatePurchase(context, tier),
                        icon: Text(tier.emoji, style: const TextStyle(fontSize: 16)),
                        label: Text(owned ? '${tier.productId} ✅' : tier.productId),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: owned ? Colors.grey.shade400 : tier.badgeColor,
                          foregroundColor: Colors.white,
                        ),
                      );
                    }),

                    // Reset
                    OutlinedButton.icon(
                      onPressed: () => _resetIapState(context),
                      icon: const Icon(Icons.restart_alt, color: Colors.red),
                      label: const Text('Reset IAP State', style: TextStyle(color: Colors.red)),
                      style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.red)),
                    ),

                    // Restore
                    OutlinedButton.icon(
                      onPressed: () => _restorePurchases(context),
                      icon: const Icon(Icons.settings_backup_restore, color: Colors.blue),
                      label: const Text('Restore Purchases', style: TextStyle(color: Colors.blue)),
                      style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.blue)),
                    ),

                    // Clear all
                    OutlinedButton.icon(
                      onPressed: () => _clearAllPurchases(context),
                      icon: const Icon(Icons.delete_sweep, color: Colors.deepOrange),
                      label: const Text('Clear All Purchases',
                          style: TextStyle(color: Colors.deepOrange)),
                      style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.deepOrange)),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

