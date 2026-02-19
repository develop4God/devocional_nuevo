// lib/blocs/supporter/supporter_event.dart

import '../../models/supporter_tier.dart';

abstract class SupporterEvent {}

/// Initialize IAP and load purchased status.
class InitializeSupporter extends SupporterEvent {}

/// User tapped "Purchase" for a tier.
class PurchaseTier extends SupporterEvent {
  final SupporterTier tier;
  PurchaseTier(this.tier);
}

/// User tapped "Restore Purchases".
class RestorePurchases extends SupporterEvent {}

/// Gold supporter submitted their display name.
class SaveGoldSupporterName extends SupporterEvent {
  final String name;
  SaveGoldSupporterName(this.name);
}

/// Clear any transient error message / just-delivered state.
class ClearSupporterError extends SupporterEvent {}
