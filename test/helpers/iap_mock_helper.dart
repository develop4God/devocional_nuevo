// test/helpers/iap_mock_helper.dart
//
// Centralised IAP test utilities:
//   - [MockIIapService]          — Mockito-generated mock of [IIapService]
//   - [FakeIapService]           — Lightweight in-memory fake (no Mockito needed)
//   - [IapPurchaseScenarios]     — Pre-built stream scenarios

import 'dart:async';

import 'package:devocional_nuevo/models/supporter_tier.dart';
import 'package:devocional_nuevo/services/iap/i_iap_service.dart';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:mockito/annotations.dart';

export 'iap_mock_helper.mocks.dart';

// ── Mockito annotation ────────────────────────────────────────────────────────
// Run `flutter pub run build_runner build` to regenerate the mocks file.
@GenerateMocks([IIapService])
class IapMockAnnotationTarget {}

// ── Fake implementation ───────────────────────────────────────────────────────

/// In-memory [IIapService] fake suitable for unit tests that need full
/// lifecycle control without Mockito stubs.
class FakeIapService implements IIapService {
  final StreamController<SupporterTier> _deliveredController =
      StreamController<SupporterTier>.broadcast();

  final Set<SupporterTierLevel> _purchasedLevels = {};
  bool _isAvailable;
  bool _isInitialized = false;
  String? _goldName;

  /// Whether the next [purchaseTier] call should succeed.
  bool purchaseShouldSucceed;

  /// Tier that will be auto-delivered when [purchaseTier] is called (if
  /// [purchaseShouldSucceed] is true).
  bool autoDeliver;

  FakeIapService({
    this.purchaseShouldSucceed = true,
    this.autoDeliver = false,
    bool isAvailable = false,
  }) : _isAvailable = isAvailable;

  @override
  Stream<SupporterTier> get onPurchaseDelivered => _deliveredController.stream;

  @override
  bool get isAvailable => _isAvailable;

  @override
  Set<SupporterTierLevel> get purchasedLevels =>
      Set.unmodifiable(_purchasedLevels);

  @override
  String? get goldSupporterName => _goldName;

  @override
  bool isPurchased(SupporterTierLevel level) =>
      _purchasedLevels.contains(level);

  @override
  ProductDetails? getProduct(String productId) => null;

  @override
  Future<void> initialize() async {
    _isInitialized = true;
  }

  @override
  Future<IapResult> purchaseTier(SupporterTier tier) async {
    if (!purchaseShouldSucceed) return IapResult.error;

    if (autoDeliver) {
      await deliver(tier);
    }
    return IapResult.pending;
  }

  @override
  Future<void> restorePurchases() async {
    // Re-emit all already-purchased tiers (simulates restore)
    for (final level in _purchasedLevels) {
      _deliveredController.add(SupporterTier.fromLevel(level));
    }
  }

  @override
  Future<void> saveGoldSupporterName(String name) async {
    _goldName = name;
  }

  @override
  Future<void> dispose() async {
    await _deliveredController.close();
  }

  @override
  @visibleForTesting
  void resetForTesting() {
    _purchasedLevels.clear();
    _goldName = null;
    _isAvailable = false;
    _isInitialized = false;
  }

  // ── Test helpers ──────────────────────────────────────────────────────────

  /// Simulate a successful delivery (purchased or restored).
  Future<void> deliver(SupporterTier tier) async {
    _purchasedLevels.add(tier.level);
    _deliveredController.add(tier);
  }

  /// Simulate billing becoming available (e.g. after connecting to store).
  void setAvailable(bool available) => _isAvailable = available;

  bool get isInitialized => _isInitialized;
}

// ── Stream scenario helpers ───────────────────────────────────────────────────

/// Factory for [PurchaseDetails]-like objects used in stream tests.
///
/// Note: [PurchaseDetails] is a sealed class from `in_app_purchase`, so we
/// use the [FakeIapService] stream helpers above for most tests.
/// These helpers document the expected scenarios.
class IapPurchaseScenarios {
  IapPurchaseScenarios._();

  /// Returns a list of tiers that would be delivered on a success scenario.
  static List<SupporterTier> successScenario(SupporterTierLevel level) {
    return [SupporterTier.fromLevel(level)];
  }

  /// Returns an empty list (simulates pending/cancelled — no delivery).
  static List<SupporterTier> pendingScenario() => [];

  /// Returns an empty list (simulates error — no delivery).
  static List<SupporterTier> errorScenario() => [];

  /// Returns all tiers (simulates full restore).
  static List<SupporterTier> restoreAllScenario() {
    return SupporterTier.tiers.toList();
  }
}
