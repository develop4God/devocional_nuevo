// test/helpers/iap_mock_helper.dart
//
// Centralised IAP test utilities:
//   - [MockIIapService]                     — Mockito-generated mock of [IIapService]
//   - [FakeIapService]                      — Lightweight in-memory fake (no Mockito needed)
//   - [FakeSupporterProfileRepository]      — In-memory ISupporterProfileRepository fake
//   - [IapPurchaseScenarios]                — Pre-built stream scenarios

import 'dart:async';

import 'package:devocional_nuevo/models/supporter_tier.dart';
import 'package:devocional_nuevo/repositories/i_supporter_profile_repository.dart';
import 'package:devocional_nuevo/services/iap/i_iap_service.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:mockito/annotations.dart';

export 'iap_mock_helper.mocks.dart';

// ── Mockito annotation ────────────────────────────────────────────────────────
// Run `flutter pub run build_runner build` to regenerate the mocks file.
@GenerateMocks([IIapService])
class IapMockAnnotationTarget {}

// ── FakeIapService ────────────────────────────────────────────────────────────

/// In-memory [IIapService] fake suitable for unit tests that need full
/// lifecycle control without Mockito stubs.
class FakeIapService implements IIapService {
  final StreamController<SupporterTier> _deliveredController =
      StreamController<SupporterTier>.broadcast();

  final Set<SupporterTierLevel> _purchasedLevels = {};
  bool _isAvailable;
  bool _isInitialized = false;
  IapInitStatus _initStatus = IapInitStatus.notStarted;

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

  final StreamController<String> _errorController =
      StreamController<String>.broadcast();

  @override
  Stream<String> get onPurchaseError => _errorController.stream;

  @override
  bool get isAvailable => _isAvailable;

  @override
  Set<SupporterTierLevel> get purchasedLevels =>
      Set.unmodifiable(_purchasedLevels);

  @override
  IapInitStatus get initStatus => _initStatus;

  @override
  bool isPurchased(SupporterTierLevel level) =>
      _purchasedLevels.contains(level);

  @override
  ProductDetails? getProduct(String productId) => null;

  @override
  Future<void> initialize() async {
    _isInitialized = true;
    _initStatus =
        _isAvailable ? IapInitStatus.success : IapInitStatus.billingUnavailable;
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
  Future<void> dispose() async {
    await _deliveredController.close();
    await _errorController.close();
  }

  /// Reset state for testing. Not part of [IIapService] — call only on
  /// the concrete [FakeIapService] reference.
  void resetForTesting() {
    _purchasedLevels.clear();
    _isAvailable = false;
    _isInitialized = false;
    _initStatus = IapInitStatus.notStarted;
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

// ── FakeSupporterProfileRepository ───────────────────────────────────────────

/// In-memory [ISupporterProfileRepository] fake for unit tests.
/// Implements the interface (DIP) so [SupporterBloc] never sees the concrete class.
class FakeSupporterProfileRepository implements ISupporterProfileRepository {
  String? _goldName;

  @override
  Future<String?> loadProfileName() async => _goldName;

  @override
  Future<void> saveProfileName(String name) async {
    _goldName = name;
  }

  // Backwards compatibility shims used by older tests still referencing
  // the old method names. They delegate to the new interface methods.
  Future<String?> loadGoldSupporterName() async => loadProfileName();

  Future<void> saveGoldSupporterName(String name) async =>
      saveProfileName(name);
}

// ── Stream scenario helpers ───────────────────────────────────────────────────

/// Factory for test scenarios used with [FakeIapService].
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
