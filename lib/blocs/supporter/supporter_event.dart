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

/// Gold supporter submitted their display name (from success dialog on first
/// purchase, or from the edit-name flow for returning Gold supporters).
class SaveGoldSupporterName extends SupporterEvent {
  final String name;

  SaveGoldSupporterName(this.name);
}

/// Gold supporter tapped "Edit name" to update a previously stored display name.
///
/// This event triggers the same [SaveGoldSupporterName] persistence path
/// via the UI — it exists to signal intent and keep the event log readable.
class EditGoldSupporterName extends SupporterEvent {}

/// Clear any transient error message / just-delivered state.
class ClearSupporterError extends SupporterEvent {}
