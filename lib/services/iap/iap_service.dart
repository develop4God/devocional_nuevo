// lib/services/iap/iap_service.dart

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/supporter_tier.dart';
import 'i_iap_diagnostics_service.dart';
import 'i_iap_service.dart';
import 'iap_diagnostics_service.dart';
import 'iap_prefs_keys.dart';

/// Concrete implementation of [IIapService] that wraps the
/// `in_app_purchase` plugin for Google Play Billing and the App Store.
///
/// Singleton lifecycle is managed by [ServiceLocator] via
/// `registerLazySingleton`. Gold-supporter name persistence lives in
/// [SupporterProfileRepository] (injected into [SupporterBloc]).
class IapService implements IIapService {
  // Injected dependencies (allow substitution in tests)
  final InAppPurchase _iap;
  final Future<SharedPreferences> Function() _prefsFactory;

  /// Optional diagnostics printer. Defaults to [IapDiagnosticsService] in
  /// debug builds; pass a custom [IIapDiagnosticsService] in tests to silence
  /// or inspect output. Null disables diagnostics entirely.
  final IIapDiagnosticsService? _diagnosticsService;

  /// Creates an [IapService].
  ///
  /// [inAppPurchase] defaults to [InAppPurchase.instance]; override in tests.
  /// [prefsFactory] defaults to [SharedPreferences.getInstance]; override in tests.
  /// [diagnosticsService] is only active in debug builds; pass a no-op in
  /// tests or production to suppress output.
  IapService({
    InAppPurchase? inAppPurchase,
    Future<SharedPreferences> Function()? prefsFactory,
    IIapDiagnosticsService? diagnosticsService,
  })  : _iap = inAppPurchase ?? InAppPurchase.instance,
        _prefsFactory = prefsFactory ?? SharedPreferences.getInstance,
        // Lazily wire the concrete diagnostics impl only in debug builds.
        // Production builds receive null → no diagnostics overhead.
        _diagnosticsService =
            diagnosticsService ?? (kDebugMode ? _LazyDiagnostics() : null);

  // ── Broadcast stream ──────────────────────────────────────────────────────
  final StreamController<String> _errorController =
      StreamController<String>.broadcast();

  final StreamController<SupporterTier> _deliveredController =
      StreamController<SupporterTier>.broadcast();

  @override
  Stream<SupporterTier> get onPurchaseDelivered => _deliveredController.stream;

  @override
  Stream<String> get onPurchaseError => _errorController.stream;

  // ── Internal state ────────────────────────────────────────────────────────
  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;

  final Set<SupporterTierLevel> _purchasedLevels = {};
  final Map<String, ProductDetails> _products = {};

  bool _isAvailable = false;
  bool _isInitialized = false;
  bool _disposed = false;
  IapInitStatus _initStatus = IapInitStatus.notStarted;

  // ── Public getters ────────────────────────────────────────────────────────

  @override
  bool get isAvailable => _isAvailable;

  @override
  bool isPurchased(SupporterTierLevel level) =>
      _purchasedLevels.contains(level);

  @override
  Set<SupporterTierLevel> get purchasedLevels =>
      Set.unmodifiable(_purchasedLevels);

  @override
  IapInitStatus get initStatus => _initStatus;

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

      if (!_isAvailable) {
        _initStatus = IapInitStatus.billingUnavailable;
        return;
      }

      _purchaseSubscription = _iap.purchaseStream.listen(
        _onPurchaseUpdate,
        onError: (Object error) {
          debugPrint('❌ [IapService] Purchase stream error: $error');
        },
      );

      await _loadProducts();

      // Wire diagnostics in debug builds after products are loaded.
      // _diagnosticsService is injected (null in production, no-op in tests).
      if (_diagnosticsService is _LazyDiagnostics) {
        (_diagnosticsService as _LazyDiagnostics).wire(this);
      }
      _diagnosticsService?.printDiagnostics();

      _initStatus = IapInitStatus.success;
      debugPrint('✅ [IapService] Initialization complete');
    } catch (e) {
      debugPrint('❌ [IapService] Initialization error: $e');
      _isAvailable = false;
      _initStatus = IapInitStatus.loadFailed;
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
  Future<void> dispose() async {
    // Set _disposed BEFORE cancelling the subscription so any in-flight
    // _handlePurchase callback is silently dropped.
    _disposed = true;
    await _purchaseSubscription?.cancel();
    _purchaseSubscription = null;
    if (!_deliveredController.isClosed) {
      await _deliveredController.close();
      await _errorController.close();
    }
    _isInitialized = false;
  }

  /// Reset all state for testing. Not part of [IIapService]; call only on
  /// the concrete [IapService] reference in tests.
  @visibleForTesting
  void resetForTesting() {
    _purchasedLevels.clear();
    _products.clear();
    _isAvailable = false;
    _isInitialized = false;
    _disposed = false;
    _initStatus = IapInitStatus.notStarted;
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
      rethrow; // Allow initialize() to set loadFailed status
    }
  }

  void _onPurchaseUpdate(List<PurchaseDetails> purchaseDetailsList) {
    for (final purchase in purchaseDetailsList) {
      _handlePurchase(purchase);
    }
  }

  Future<void> _handlePurchase(PurchaseDetails purchase) async {
    // Guard: ignore events that arrive after dispose() was called.
    if (_disposed) {
      debugPrint(
          '⚠️ [IapService] Ignoring purchase update after dispose: ${purchase.productID}');
      return;
    }

    debugPrint(
      '🛍️ [IapService] Update: ${purchase.productID} status=${purchase.status}',
    );

    if (purchase.status == PurchaseStatus.pending) {
      // pendingCompletePurchase must still be honoured for pending status
      // to avoid store retry loops on some platforms.
      if (purchase.pendingCompletePurchase) {
        await _iap.completePurchase(purchase);
      }
      return;
    }

    if (purchase.status == PurchaseStatus.purchased ||
        purchase.status == PurchaseStatus.restored) {
      // ⚠️ RECEIPT VALIDATION NOTE (Gap #1 — acknowledged trade-off):
      // Delivery is trusted based on PurchaseStatus alone.  For a devotional
      // app with one-time tiers and no server-managed entitlements this is an
      // accepted risk: the worst-case scenario is a user unlocking a cosmetic
      // badge without paying.  If revenue grows, add server-side receipt
      // validation here (Google Play Developer API / Apple App Store Server
      // Notifications) before calling _deliverProduct().
      await _deliverProduct(purchase.productID);
    } else if (purchase.status == PurchaseStatus.error) {
      debugPrint('❌ [IapService] Purchase error: ${purchase.error}');
      if (!_errorController.isClosed) {
        _errorController.add(purchase.productID);
      }
    }

    // Google Play (and App Store) require completePurchase to be called for
    // ALL terminal statuses (purchased, restored, error) with
    // pendingCompletePurchase == true, to prevent the store from retrying.
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

    // Notify listeners via broadcast stream (guarded against closed controller)
    if (!_deliveredController.isClosed) {
      _deliveredController.add(tier);
    }

    debugPrint('✅ [IapService] Delivered: $productId (${tier.level})');
  }

  Future<void> _loadPurchasedFromPrefs() async {
    try {
      final prefs = await _prefsFactory();
      for (final tier in SupporterTier.tiers) {
        final key = IapPrefsKeys.purchasedKey(tier.productId);
        if (prefs.getBool(key) == true) {
          _purchasedLevels.add(tier.level);
        }
      }
    } catch (e) {
      debugPrint('❌ [IapService] Error loading prefs: $e');
    }
  }

  Future<void> _savePurchasedToPrefs(SupporterTierLevel level) async {
    try {
      final prefs = await _prefsFactory();
      final tier = SupporterTier.fromLevel(level);
      await prefs.setBool(IapPrefsKeys.purchasedKey(tier.productId), true);
    } catch (e) {
      debugPrint('❌ [IapService] Error saving prefs: $e');
    }
  }
}

// ── Private diagnostics bridge ─────────────────────────────────────────────

/// Bridges the lazy default diagnostics wiring: defers constructing
/// [IapDiagnosticsService] until [printDiagnostics] is first called, so the
/// [IapService] constructor stays clean while the default debug path still
/// uses the concrete implementation.
///
/// This is package-private (file-scoped underscore prefix) and is only
/// created when [kDebugMode] is true — it is never instantiated in production.
class _LazyDiagnostics implements IIapDiagnosticsService {
  IIapService? _service;

  /// Called once after [IapService.initialize] completes so the diagnostics
  /// printer can read the fully-initialised service state.
  @override
  void printDiagnostics() {
    // _service is wired by IapService after initialization completes.
    // If not yet wired (e.g. dispose raced), silently skip.
    if (_service == null) return;
    IapDiagnosticsService(_service!).printDiagnostics();
  }

  /// Called by [IapService] to provide itself as the service reference.
  void wire(IIapService service) => _service = service;
}
