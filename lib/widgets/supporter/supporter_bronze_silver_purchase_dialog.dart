import 'package:devocional_nuevo/extensions/string_extensions.dart';
import 'package:devocional_nuevo/models/supporter_tier.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class SupporterPurchaseDialog extends StatelessWidget {
  final SupporterTier tier;
  final BuildContext dialogContext;
  final VoidCallback onConfirm;

  const SupporterPurchaseDialog({
    super.key,
    required this.tier,
    required this.dialogContext,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  Lottie.asset(
                    'assets/lottie/confetti.json',
                    width: 200,
                    height: 200,
                    repeat: false,
                  ),
                  const Icon(
                    Icons.verified_rounded,
                    color: Colors.green,
                    size: 100,
                  ),
                ],
              ),
              Text(
                tier.emoji,
                style: const TextStyle(fontSize: 50),
              ),
              const SizedBox(height: 16),
              Text(
                'supporter.purchase_success_title'.tr(),
                style:
                    Theme.of(dialogContext).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: tier.badgeColor,
                        ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'supporter.medal_unlocked_body'.tr(),
                style: Theme.of(dialogContext).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(dialogContext)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.8),
                      height: 1.5,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(dialogContext)
                      .colorScheme
                      .surfaceContainerHighest
                      .withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(20),
                  border:
                      Border.all(color: tier.badgeColor.withValues(alpha: 0.2)),
                ),
                child: Column(
                  children: [
                    Text(
                      'supporter.purchase_success_verse'.tr(),
                      style: Theme.of(dialogContext)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(
                            fontStyle: FontStyle.italic,
                            fontWeight: FontWeight.w600,
                            color:
                                Theme.of(dialogContext).colorScheme.onSurface,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'supporter.purchase_success_verse_ref'.tr(),
                      style: Theme.of(dialogContext)
                          .textTheme
                          .labelSmall
                          ?.copyWith(
                            color: tier.badgeColor,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onConfirm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: tier.badgeColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                    elevation: 4,
                    shadowColor: tier.badgeColor.withValues(alpha: 0.5),
                  ),
                  child: Text(
                    'supporter.purchase_success_button'.tr(),
                    style: const TextStyle(
                        fontWeight: FontWeight.w900, fontSize: 18),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
