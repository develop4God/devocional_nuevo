// lib/services/iap/iap_service.dart

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/supporter_tier.dart';
import 'i_iap_service.dart';

/// Concrete implementation of [IIapService] that wraps the
/// `in_app_purchase` plugin for Google Play Billing and the App Store.
///
/// This is a plain class — the singleton lifecycle is managed by
/// [ServiceLocator] via `registerLazySingleton`.
class IapService implements IIapService {
  static const String _purchasedKeyPrefix = 'iap_purchased_';
  static const String _goldSupporterNameKey = 'iap_gold_supporter_name';

  // Injected dependencies (allow substitution in tests)
  final InAppPurchase _iap;
  final Future<SharedPreferences> Function() _prefsFactory;

  /// Creates an [IapService].
  ///
  /// [inAppPurchase] defaults to [InAppPurchase.instance]; override in tests.
  /// [prefsFactory] defaults to [SharedPreferences.getInstance]; override in tests.
  IapService({
    InAppPurchase? inAppPurchase,
    Future<SharedPreferences> Function()? prefsFactory,
  })  : _iap = inAppPurchase ?? InAppPurchase.instance,
        _prefsFactory = prefsFactory ?? SharedPreferences.getInstance;

  // ── Broadcast stream ──────────────────────────────────────────────────────
  final StreamController<SupporterTier> _deliveredController =
      StreamController<SupporterTier>.broadcast();

  @override
  Stream<SupporterTier> get onPurchaseDelivered => _deliveredController.stream;

  // ── Internal state ────────────────────────────────────────────────────────
  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;

  final Set<SupporterTierLevel> _purchasedLevels = {};
  final Map<String, ProductDetails> _products = {};

  bool _isAvailable = false;
  bool _isInitialized = false;
  String? _goldSupporterName;

  // ── Public getters ────────────────────────────────────────────────────────

  @override
  bool get isAvailable => _isAvailable;

  @override
  String? get goldSupporterName => _goldSupporterName;

  @override
  bool isPurchased(SupporterTierLevel level) =>
      _purchasedLevels.contains(level);

  @override
  Set<SupporterTierLevel> get purchasedLevels =>
      Set.unmodifiable(_purchasedLevels);

  @override
  ProductDetails? getProduct(String productId) => _products[productId];

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  Future<void> initialize() async {
    if (_isInitialized) {
      debugPrint('ℹ️ [IapService] Already initialized');
      return;
    }
    _isInitialized = true;

    try {
      await _loadPurchasedFromPrefs();
      _isAvailable = await _iap.isAvailable();

      debugPrint('📱 [IapService] Billing available: $_isAvailable');

      if (!_isAvailable) return;

      _purchaseSubscription = _iap.purchaseStream.listen(
        _onPurchaseUpdate,
        onError: (Object error) {
          debugPrint('❌ [IapService] Purchase stream error: $error');
        },
      );

      await _loadProducts();
      debugPrint('✅ [IapService] Initialization complete');
    } catch (e) {
      debugPrint('❌ [IapService] Initialization error: $e');
      _isAvailable = false;
    }
  }

  @override
  Future<IapResult> purchaseTier(SupporterTier tier) async {
    if (!_isAvailable) {
      debugPrint('⚠️ [IapService] Billing unavailable');
      return IapResult.error;
    }

    final product = _products[tier.productId];
    if (product == null) {
      debugPrint('⚠️ [IapService] Product ${tier.productId} not loaded');
      return IapResult.error;
    }

    try {
      final purchaseParam = PurchaseParam(productDetails: product);
      final started = await _iap.buyNonConsumable(purchaseParam: purchaseParam);
      if (!started) {
        debugPrint(
            '⚠️ [IapService] Purchase not started for ${tier.productId}');
        return IapResult.error;
      }
      return IapResult.pending;
    } catch (e) {
      debugPrint('❌ [IapService] Purchase error: $e');
      return IapResult.error;
    }
  }

  @override
  Future<void> restorePurchases() async {
    if (!_isAvailable) return;
    try {
      await _iap.restorePurchases();
    } catch (e) {
      debugPrint('❌ [IapService] Restore error: $e');
    }
  }

  @override
  Future<void> saveGoldSupporterName(String name) async {
    try {
      _goldSupporterName = name;
      final prefs = await _prefsFactory();
      await prefs.setString(_goldSupporterNameKey, name);
      debugPrint('✅ [IapService] Saved gold supporter name: $name');
    } catch (e) {
      debugPrint('❌ [IapService] Error saving gold supporter name: $e');
    }
  }

  @override
  Future<void> dispose() async {
    await _purchaseSubscription?.cancel();
    _purchaseSubscription = null;
    await _deliveredController.close();
    _isInitialized = false;
  }

  @override
  @visibleForTesting
  void resetForTesting() {
    _purchasedLevels.clear();
    _products.clear();
    _isAvailable = false;
    _isInitialized = false;
    _goldSupporterName = null;
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  Future<void> _loadProducts() async {
    try {
      final productIds = SupporterTier.tiers.map((t) => t.productId).toSet();
      final response = await _iap.queryProductDetails(productIds);

      if (response.error != null) {
        debugPrint(
            '⚠️ [IapService] Product query error: ${response.error!.message}');
      }

      for (final product in response.productDetails) {
        _products[product.id] = product;
        debugPrint('✅ [IapService] Loaded: ${product.id} — ${product.price}');
      }

      if (response.notFoundIDs.isNotEmpty) {
        debugPrint(
            '⚠️ [IapService] Products not found: ${response.notFoundIDs}');
      }
    } catch (e) {
      debugPrint('❌ [IapService] Error loading products: $e');
    }
  }

  void _onPurchaseUpdate(List<PurchaseDetails> purchaseDetailsList) {
    for (final purchase in purchaseDetailsList) {
      _handlePurchase(purchase);
    }
  }

  Future<void> _handlePurchase(PurchaseDetails purchase) async {
    debugPrint(
      '🛍️ [IapService] Update: ${purchase.productID} status=${purchase.status}',
    );

    if (purchase.status == PurchaseStatus.pending) return;

    if (purchase.status == PurchaseStatus.purchased ||
        purchase.status == PurchaseStatus.restored) {
      await _deliverProduct(purchase.productID);
    } else if (purchase.status == PurchaseStatus.error) {
      debugPrint('❌ [IapService] Purchase error: ${purchase.error}');
    }

    if (purchase.pendingCompletePurchase) {
      await _iap.completePurchase(purchase);
    }
  }

  Future<void> _deliverProduct(String productId) async {
    final tier = SupporterTier.fromProductId(productId);
    if (tier == null) {
      debugPrint('⚠️ [IapService] Unknown productId delivered: $productId');
      return;
    }

    _purchasedLevels.add(tier.level);
    await _savePurchasedToPrefs(tier.level);

    // Notify listeners via broadcast stream
    if (!_deliveredController.isClosed) {
      _deliveredController.add(tier);
    }

    debugPrint('✅ [IapService] Delivered: $productId (${tier.level})');
  }

  Future<void> _loadPurchasedFromPrefs() async {
    try {
      final prefs = await _prefsFactory();
      for (final tier in SupporterTier.tiers) {
        final key = '$_purchasedKeyPrefix${tier.productId}';
        if (prefs.getBool(key) == true) {
          _purchasedLevels.add(tier.level);
        }
      }
      _goldSupporterName = prefs.getString(_goldSupporterNameKey);
    } catch (e) {
      debugPrint('❌ [IapService] Error loading prefs: $e');
    }
  }

  Future<void> _savePurchasedToPrefs(SupporterTierLevel level) async {
    try {
      final prefs = await _prefsFactory();
      final tier = SupporterTier.fromLevel(level);
      await prefs.setBool('$_purchasedKeyPrefix${tier.productId}', true);
    } catch (e) {
      debugPrint('❌ [IapService] Error saving prefs: $e');
    }
  }
}
