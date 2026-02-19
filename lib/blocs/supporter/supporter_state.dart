// lib/blocs/supporter/supporter_state.dart

import '../../models/supporter_tier.dart';

abstract class SupporterState {}

/// Before initialization has started.
class SupporterInitial extends SupporterState {}

/// Initialization or restore in progress.
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

  /// The product ID currently being purchased (shows a loading state on the
  /// matching tier card). Null when no purchase is in flight.
  final String? purchasingProductId;

  /// The tier that was just successfully delivered; consumed by the UI for
  /// showing the success dialog, then null.
  final SupporterTier? justDeliveredTier;

  SupporterLoaded({
    required this.purchasedLevels,
    required this.isBillingAvailable,
    required this.storePrices,
    this.goldSupporterName,
    this.errorMessage,
    this.purchasingProductId,
    this.justDeliveredTier,
  });

  bool isPurchased(SupporterTierLevel level) => purchasedLevels.contains(level);

  SupporterLoaded copyWith({
    Set<SupporterTierLevel>? purchasedLevels,
    bool? isBillingAvailable,
    Map<String, String>? storePrices,
    String? goldSupporterName,
    String? errorMessage,
    bool clearError = false,
    String? purchasingProductId,
    bool clearPurchasing = false,
    SupporterTier? justDeliveredTier,
    bool clearJustDelivered = false,
  }) {
    return SupporterLoaded(
      purchasedLevels: purchasedLevels ?? this.purchasedLevels,
      isBillingAvailable: isBillingAvailable ?? this.isBillingAvailable,
      storePrices: storePrices ?? this.storePrices,
      goldSupporterName: goldSupporterName ?? this.goldSupporterName,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      purchasingProductId: clearPurchasing
          ? null
          : (purchasingProductId ?? this.purchasingProductId),
      justDeliveredTier: clearJustDelivered
          ? null
          : (justDeliveredTier ?? this.justDeliveredTier),
    );
  }
}

/// A fatal error before/during initialization.
class SupporterError extends SupporterState {
  final String message;
  SupporterError(this.message);
}
