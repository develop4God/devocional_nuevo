// lib/services/iap/i_iap_service.dart

import 'dart:async';

import 'package:in_app_purchase/in_app_purchase.dart';

import '../../models/supporter_tier.dart';

/// Result of a purchase initiation call.
enum IapResult { success, cancelled, error, pending }

/// Describes the outcome of [IIapService.initialize].
enum IapInitStatus {
  /// initialize() has not been called yet.
  notStarted,

  /// Billing is available and products loaded successfully.
  success,

  /// The device does not support billing (emulator, no Play Services, etc.).
  billingUnavailable,

  /// Billing is available but loading products from the store failed.
  loadFailed,
}

/// Abstract interface for the IAP service.
///
/// Depend on this interface (not the concrete class) for
/// Dependency Inversion and easy test mocking.
abstract class IIapService {
  /// Broadcast stream that emits a [SupporterTier] each time a
  /// product is successfully delivered (purchased or restored).
  Stream<SupporterTier> get onPurchaseDelivered;

  /// Whether the Google Play / App Store billing is available on this device.
  bool get isAvailable;

  /// All supporter tier levels that have already been purchased.
  Set<SupporterTierLevel> get purchasedLevels;

  /// Status after the last [initialize] call.
  IapInitStatus get initStatus;

  /// Whether a given tier has already been purchased.
  bool isPurchased(SupporterTierLevel level);

  /// Returns the store [ProductDetails] for the given product ID, or null.
  ProductDetails? getProduct(String productId);

  /// Initialise billing and load products. Safe to call multiple times.
  Future<void> initialize();

  /// Initiate a one-time purchase for [tier]. Returns the initiation result.
  Future<IapResult> purchaseTier(SupporterTier tier);

  /// Restore all previous non-consumable purchases.
  Future<void> restorePurchases();

  /// Cancel active stream subscriptions and free resources.
  Future<void> dispose();
}
