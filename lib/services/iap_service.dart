// lib/services/iap_service.dart
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/supporter_tier.dart';

/// Result of a purchase or restore operation.
enum IapResult { success, cancelled, error, pending }

/// Service that manages Google Play Billing / App Store IAP lifecycle.
class IapService {
  static const String _purchasedKeyPrefix = 'iap_purchased_';
  static const String _goldSupporterNameKey = 'iap_gold_supporter_name';

  // Singleton
  static final IapService _instance = IapService._internal();
  factory IapService() => _instance;
  IapService._internal();

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;

  /// Purchased tier levels (loaded from SharedPreferences on init).
  final Set<SupporterTierLevel> _purchasedLevels = {};

  /// Map of loaded products from the store.
  final Map<String, ProductDetails> _products = {};

  bool _isAvailable = false;
  bool _isInitialized = false;
  String? _goldSupporterName;

  /// Whether the billing service is available on this device.
  bool get isAvailable => _isAvailable;

  /// The display name for the Gold supporter (set by user after purchase).
  String? get goldSupporterName => _goldSupporterName;

  /// Whether a given tier has already been purchased.
  bool isPurchased(SupporterTierLevel level) =>
      _purchasedLevels.contains(level);

  /// All purchased tier levels.
  Set<SupporterTierLevel> get purchasedLevels =>
      Set.unmodifiable(_purchasedLevels);

  /// Returns the loaded ProductDetails for the given productId, or null.
  ProductDetails? getProduct(String productId) => _products[productId];

  /// Initialize the IAP service. Call once at app start or on demand.
  Future<void> initialize() async {
    if (_isInitialized) return;
    _isInitialized = true;

    try {
      await _loadPurchasedFromPrefs();
      _isAvailable = await _iap.isAvailable();

      if (!_isAvailable) {
        debugPrint('⚠️ [IapService] Billing not available on this device');
        return;
      }

      _purchaseSubscription = _iap.purchaseStream.listen(
        _onPurchaseUpdate,
        onError: (Object error) {
          debugPrint('❌ [IapService] Purchase stream error: $error');
        },
      );

      await _loadProducts();
    } catch (e) {
      debugPrint('❌ [IapService] Initialization error: $e');
      _isAvailable = false;
    }
  }

  /// Load product details for all supporter tiers.
  Future<void> _loadProducts() async {
    try {
      final productIds = SupporterTier.tiers.map((t) => t.productId).toSet();
      final response = await _iap.queryProductDetails(productIds);

      if (response.error != null) {
        debugPrint(
          '⚠️ [IapService] Product query error: ${response.error!.message}',
        );
      }

      for (final product in response.productDetails) {
        _products[product.id] = product;
        debugPrint(
          '✅ [IapService] Loaded product: ${product.id} - ${product.price}',
        );
      }

      if (response.notFoundIDs.isNotEmpty) {
        debugPrint(
          '⚠️ [IapService] Products not found in store: ${response.notFoundIDs}',
        );
      }
    } catch (e) {
      debugPrint('❌ [IapService] Error loading products: $e');
    }
  }

  /// Initiate a purchase for the given tier. Returns the result.
  Future<IapResult> purchaseTier(SupporterTier tier) async {
    if (!_isAvailable) {
      debugPrint('⚠️ [IapService] Billing unavailable - cannot purchase');
      return IapResult.error;
    }

    final product = _products[tier.productId];
    if (product == null) {
      debugPrint(
        '⚠️ [IapService] Product ${tier.productId} not loaded - cannot purchase',
      );
      return IapResult.error;
    }

    try {
      final purchaseParam = PurchaseParam(productDetails: product);
      final started = await _iap.buyNonConsumable(
        purchaseParam: purchaseParam,
      );
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

  /// Restore previous purchases.
  Future<void> restorePurchases() async {
    if (!_isAvailable) return;
    try {
      await _iap.restorePurchases();
    } catch (e) {
      debugPrint('❌ [IapService] Restore error: $e');
    }
  }

  /// Handles incoming purchase updates from the purchase stream.
  void _onPurchaseUpdate(List<PurchaseDetails> purchaseDetailsList) {
    for (final purchase in purchaseDetailsList) {
      _handlePurchase(purchase);
    }
  }

  Future<void> _handlePurchase(PurchaseDetails purchase) async {
    debugPrint(
      '🛍️ [IapService] Purchase update: ${purchase.productID} status=${purchase.status}',
    );

    if (purchase.status == PurchaseStatus.pending) {
      // Show pending UI if needed
      return;
    }

    if (purchase.status == PurchaseStatus.error) {
      debugPrint('❌ [IapService] Purchase error: ${purchase.error}');
    } else if (purchase.status == PurchaseStatus.purchased ||
        purchase.status == PurchaseStatus.restored) {
      // Deliver the product
      await _deliverProduct(purchase.productID);
    }

    // Always complete the purchase to avoid re-delivery loops
    if (purchase.pendingCompletePurchase) {
      await _iap.completePurchase(purchase);
    }
  }

  /// Mark a product as delivered and persist it.
  Future<void> _deliverProduct(String productId) async {
    final tier = SupporterTier.fromProductId(productId);
    if (tier == null) {
      debugPrint(
        '⚠️ [IapService] Unknown product ID delivered: $productId',
      );
      return;
    }

    _purchasedLevels.add(tier.level);
    await _savePurchasedToPrefs(tier.level);

    debugPrint('✅ [IapService] Delivered product: $productId (${tier.level})');
  }

  /// Save the display name for the Gold supporter to SharedPreferences.
  Future<void> saveGoldSupporterName(String name) async {
    try {
      _goldSupporterName = name;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_goldSupporterNameKey, name);
      debugPrint('✅ [IapService] Saved gold supporter name: $name');
    } catch (e) {
      debugPrint('❌ [IapService] Error saving gold supporter name: $e');
    }
  }

  /// Load purchased tiers from SharedPreferences.
  Future<void> _loadPurchasedFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      for (final tier in SupporterTier.tiers) {
        final key = '$_purchasedKeyPrefix${tier.productId}';
        if (prefs.getBool(key) == true) {
          _purchasedLevels.add(tier.level);
          debugPrint(
            '📦 [IapService] Loaded purchased tier from prefs: ${tier.level}',
          );
        }
      }
      _goldSupporterName = prefs.getString(_goldSupporterNameKey);
    } catch (e) {
      debugPrint('❌ [IapService] Error loading purchased from prefs: $e');
    }
  }

  /// Persist a purchased tier to SharedPreferences.
  Future<void> _savePurchasedToPrefs(SupporterTierLevel level) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final tier = SupporterTier.fromLevel(level);
      final key = '$_purchasedKeyPrefix${tier.productId}';
      await prefs.setBool(key, true);
    } catch (e) {
      debugPrint('❌ [IapService] Error saving purchased to prefs: $e');
    }
  }

  /// Dispose the purchase stream subscription.
  Future<void> dispose() async {
    await _purchaseSubscription?.cancel();
    _purchaseSubscription = null;
    _isInitialized = false;
  }

  /// Reset state (for testing purposes).
  @visibleForTesting
  void resetForTesting() {
    _purchasedLevels.clear();
    _products.clear();
    _isAvailable = false;
    _isInitialized = false;
    _goldSupporterName = null;
  }
}
