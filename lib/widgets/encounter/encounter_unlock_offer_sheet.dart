// lib/widgets/encounter/encounter_unlock_offer_sheet.dart
//
// Soft offer shown when the user taps a waiting (locked) encounter.
// Encounters are free: this only lets a supporter skip the reading order.

import 'package:devocional_nuevo/blocs/supporter/supporter_bloc.dart';
import 'package:devocional_nuevo/blocs/supporter/supporter_event.dart';
import 'package:devocional_nuevo/blocs/supporter/supporter_state.dart';
import 'package:devocional_nuevo/extensions/string_extensions.dart';
import 'package:devocional_nuevo/models/supporter_tier.dart';
import 'package:devocional_nuevo/services/i_analytics_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Opens the offer as a modal bottom sheet and logs that it was shown.
Future<void> showEncounterUnlockOffer(
  BuildContext context, {
  required IAnalyticsService analyticsService,
}) {
  analyticsService.logEncounterUnlockOfferShown();
  // The sheet lives in its own route: hand it the bloc explicitly so it does
  // not depend on where the provider sits relative to the Navigator.
  final supporterBloc = context.read<SupporterBloc>();
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => BlocProvider<SupporterBloc>.value(
      value: supporterBloc,
      child: EncounterUnlockOfferSheet(analyticsService: analyticsService),
    ),
  );
}

class EncounterUnlockOfferSheet extends StatelessWidget {
  final IAnalyticsService analyticsService;

  const EncounterUnlockOfferSheet({super.key, required this.analyticsService});

  static SupporterTier get _tier =>
      SupporterTier.fromLevel(SupporterTierLevel.encounters);

  static bool _isOwned(SupporterState state) =>
      state is SupporterLoaded &&
      state.isPurchased(SupporterTierLevel.encounters);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return BlocConsumer<SupporterBloc, SupporterState>(
      listenWhen: (previous, current) =>
          !_isOwned(previous) && _isOwned(current),
      listener: (context, state) {
        final messenger = ScaffoldMessenger.of(context);
        Navigator.of(context).pop();
        messenger.showSnackBar(
          SnackBar(content: Text('encounters.unlock_offer_thanks'.tr())),
        );
      },
      builder: (context, state) {
        final loaded = state is SupporterLoaded ? state : null;
        final price =
            loaded?.storePrices[_tier.productId] ?? _tier.priceDisplay;
        final isPurchasing = loaded?.purchasingProductId == _tier.productId;
        final canBuy = loaded != null && !isPurchasing;

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  _tier.emoji,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 44),
                ),
                const SizedBox(height: 12),
                Text(
                  'encounters.unlock_offer_title'.tr(),
                  textAlign: TextAlign.center,
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'encounters.unlock_offer_body'.tr(),
                  textAlign: TextAlign.center,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.8),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  key: const ValueKey('encounter_unlock_offer_buy'),
                  onPressed: canBuy
                      ? () {
                          analyticsService
                              .logEncounterUnlockOfferPurchaseTapped();
                          context.read<SupporterBloc>().add(
                                PurchaseTier(_tier),
                              );
                        }
                      : null,
                  child: isPurchasing
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          'encounters.unlock_offer_button'.tr({'price': price}),
                        ),
                ),
                const SizedBox(height: 4),
                TextButton(
                  key: const ValueKey('encounter_unlock_offer_dismiss'),
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('encounters.unlock_offer_keep_reading'.tr()),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
