// lib/blocs/supporter/supporter_state.dart

import '../../models/supporter_tier.dart';
import '../../services/iap/i_iap_service.dart';

abstract class SupporterState {}

/// Before initialization has started.
class SupporterInitial extends SupporterState {}

/// Initialization in progress (only shown during first load).
class SupporterLoading extends SupporterState {}

/// Initialization complete; ready for interaction.
class SupporterLoaded extends SupporterState {
  final Set<SupporterTierLevel> purchasedLevels;
  final bool isBillingAvailable;

  /// Store prices keyed by [SupporterTier.productId] (may be empty if store
  /// returned no products).
  final Map<String, String> storePrices;

  final String? goldSupporterName;
  final String? errorMessage;

  /// Status of the last [IIapService.initialize] call.
  final IapInitStatus initStatus;

  /// True while a RestorePurchases operation is in progress.
  /// The UI keeps showing tier cards (no loading skeleton) but may show
  /// a loading indicator in the restore button area.
  final bool isRestoring;

  /// The product ID currently being purchased (shows a loading state on the
  /// matching tier card). Null when no purchase is in flight.
  final String? purchasingProductId;

  /// The tier that was just successfully delivered; consumed by the UI for
  /// showing the success dialog, then null.
  final SupporterTier? justDeliveredTier;

  /// True when the UI should present the edit-name dialog for Gold supporters.
  /// Set by [EditGoldSupporterName] event; cleared after the dialog is shown.
  final bool isEditingGoldName;

  SupporterLoaded({
    required this.purchasedLevels,
    required this.isBillingAvailable,
    required this.storePrices,
    this.goldSupporterName,
    this.errorMessage,
    this.initStatus = IapInitStatus.notStarted,
    this.isRestoring = false,
    this.purchasingProductId,
    this.justDeliveredTier,
    this.isEditingGoldName = false,
  });

  bool isPurchased(SupporterTierLevel level) => purchasedLevels.contains(level);

  SupporterLoaded copyWith({
    Set<SupporterTierLevel>? purchasedLevels,
    bool? isBillingAvailable,
    Map<String, String>? storePrices,
    String? goldSupporterName,
    String? errorMessage,
    bool clearError = false,
    IapInitStatus? initStatus,
    bool? isRestoring,
    String? purchasingProductId,
    bool clearPurchasing = false,
    SupporterTier? justDeliveredTier,
    bool clearJustDelivered = false,
    bool? isEditingGoldName,
  }) {
    return SupporterLoaded(
      purchasedLevels: purchasedLevels ?? this.purchasedLevels,
      isBillingAvailable: isBillingAvailable ?? this.isBillingAvailable,
      storePrices: storePrices ?? this.storePrices,
      goldSupporterName: goldSupporterName ?? this.goldSupporterName,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      initStatus: initStatus ?? this.initStatus,
      isRestoring: isRestoring ?? this.isRestoring,
      purchasingProductId: clearPurchasing
          ? null
          : (purchasingProductId ?? this.purchasingProductId),
      justDeliveredTier: clearJustDelivered
          ? null
          : (justDeliveredTier ?? this.justDeliveredTier),
      isEditingGoldName: isEditingGoldName ?? false,
    );
  }
}

/// A fatal error before/during initialization.
class SupporterError extends SupporterState {
  final String message;

  SupporterError(this.message);
}
