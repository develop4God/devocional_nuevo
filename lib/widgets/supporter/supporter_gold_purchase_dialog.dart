import 'package:devocional_nuevo/extensions/string_extensions.dart';
import 'package:devocional_nuevo/models/supporter_tier.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class SupporterGoldPurchaseDialog extends StatelessWidget {
  final SupporterTier tier;
  final BuildContext dialogContext;
  final TextEditingController nameController;
  final VoidCallback onConfirm;

  const SupporterGoldPurchaseDialog({
    super.key,
    required this.tier,
    required this.dialogContext,
    required this.nameController,
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
              const SizedBox(height: 24),
              Text(
                'supporter.gold_name_title'.tr(),
                style:
                    Theme.of(dialogContext).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: tier.badgeColor,
                        ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'supporter.gold_name_hint'.tr(),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                        color: tier.badgeColor.withValues(alpha: 0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: tier.badgeColor, width: 2),
                  ),
                  helperText: 'supporter.gold_name_helper'.tr(),
                  prefixIcon: Icon(Icons.person, color: tier.badgeColor),
                ),
                maxLength: 40,
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
                    'supporter.select_pet_button'.tr(),
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
