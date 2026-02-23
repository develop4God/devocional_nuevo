// lib/blocs/supporter/supporter_bloc.dart

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/supporter_tier.dart';
import '../../repositories/i_supporter_profile_repository.dart';
import '../../services/iap/i_iap_service.dart';
import '../../services/iap/iap_prefs_keys.dart';
import 'supporter_event.dart';
import 'supporter_state.dart';

/// Internal event: a product was delivered by the IAP service stream.
/// Defined here (not in supporter_event.dart) so it stays package-private.
class _PurchaseFailed extends SupporterEvent {
  final String productId;

  _PurchaseFailed(this.productId);
}

/// Internal event: user cancelled (back/dismiss) the payment sheet.
/// Clears the loading spinner without showing an error message.
class _PurchaseCancelled extends SupporterEvent {
  final String productId;

  _PurchaseCancelled(this.productId);
}

class _PurchaseDelivered extends SupporterEvent {
  final SupporterTier tier;

  _PurchaseDelivered(this.tier);
}

/// BLoC that orchestrates the supporter / IAP flow.
///
/// Depends on:
/// - [IIapService] — purchase lifecycle & delivery stream
/// - [ISupporterProfileRepository] — Gold supporter name persistence
class SupporterBloc extends Bloc<SupporterEvent, SupporterState> {
  final IIapService _iapService;
  final ISupporterProfileRepository _profileRepo;
  StreamSubscription<SupporterTier>? _deliveredSubscription;
  StreamSubscription<String>? _errorSubscription;
  StreamSubscription<String>? _cancelledSubscription;

  SupporterBloc({
    required IIapService iapService,
    required ISupporterProfileRepository profileRepository,
  })  : _iapService = iapService,
        _profileRepo = profileRepository,
        super(SupporterInitial()) {
    on<InitializeSupporter>(_onInitialize);
    on<PurchaseTier>(_onPurchaseTier);
    on<RestorePurchases>(_onRestorePurchases);
    on<_PurchaseDelivered>(_onPurchaseDelivered);
    on<_PurchaseFailed>(_onPurchaseFailed);
    on<_PurchaseCancelled>(_onPurchaseCancelled);
    on<SaveGoldSupporterName>(_onSaveGoldName);
    on<EditGoldSupporterName>(_onEditGoldName);
    on<AcknowledgeGoldNameEdit>(_onAcknowledgeGoldNameEdit);
    on<ClearSupporterError>(_onClearError);
    // Debug-only handlers — no-ops in release builds.
    on<DebugSimulatePurchase>(_onDebugSimulatePurchase);
    on<DebugResetIapState>(_onDebugResetIapState);

    // Subscribe to delivered-product events from the service.
    // Both subscriptions are stored so they can be cancelled in close().
    _errorSubscription = _iapService.onPurchaseError.listen(
      (productId) => add(_PurchaseFailed(productId)),
      onError: (Object e) => debugPrint('❌ [SupporterBloc] Error stream: $e'),
    );
    _cancelledSubscription = _iapService.onPurchaseCancelled.listen(
      (productId) => add(_PurchaseCancelled(productId)),
      onError: (Object e) =>
          debugPrint('❌ [SupporterBloc] Cancelled stream: $e'),
    );
    _deliveredSubscription = _iapService.onPurchaseDelivered.listen(
      (tier) {
        debugPrint(
            '✅ [SupporterBloc] onPurchaseDelivered -> ${tier.productId}');
        add(_PurchaseDelivered(tier));
      },
      onError: (Object error) {
        debugPrint('❌ [SupporterBloc] Delivered stream error: $error');
      },
    );
  }

  @override
  Future<void> close() async {
    await _deliveredSubscription?.cancel();
    _deliveredSubscription = null;
    await _errorSubscription?.cancel();
    _errorSubscription = null;
    await _cancelledSubscription?.cancel();
    _cancelledSubscription = null;
    return super.close();
  }

  // ── Event handlers ────────────────────────────────────────────────────────

  Future<void> _onInitialize(
    InitializeSupporter event,
    Emitter<SupporterState> emit,
  ) async {
    emit(SupporterLoading());
    try {
      await _iapService.initialize();

      // Use the new interface method name (loadProfileName) — the repository
      // also provides a legacy wrapper loadGoldSupporterName() for callers
      // that have not yet been migrated.
      final goldName = await _profileRepo.loadProfileName();

      final storePrices = <String, String>{};
      for (final tier in SupporterTier.tiers) {
        final product = _iapService.getProduct(tier.productId);
        if (product != null) {
          storePrices[tier.productId] = product.price;
        }
      }

      // Task 3 — Auto-restore on clean install:
      // Only fires when billing is available AND SharedPreferences shows no
      // previously purchased tiers (distinguishes a genuine clean install /
      // reinstall from a user who simply hasn't bought anything yet).
      if (_iapService.isAvailable && _iapService.purchasedLevels.isEmpty) {
        final prefs = await SharedPreferences.getInstance();
        final hasAnyLocalPurchase = SupporterTier.tiers.any(
          (t) => prefs.getBool(IapPrefsKeys.purchasedKey(t.productId)) == true,
        );
        if (!hasAnyLocalPurchase) {
          debugPrint('🔄 [SupporterBloc] No local purchases — auto-restoring…');
          await _iapService.restorePurchases();
        }
      }

      emit(SupporterLoaded(
        purchasedLevels: _iapService.purchasedLevels,
        isBillingAvailable: _iapService.isAvailable,
        storePrices: storePrices,
        goldSupporterName: goldName,
        initStatus: _iapService.initStatus,
      ));
    } catch (e) {
      debugPrint('❌ [SupporterBloc] Initialize error: $e');
      emit(SupporterError(e.toString()));
    }
  }

  Future<void> _onPurchaseTier(
    PurchaseTier event,
    Emitter<SupporterState> emit,
  ) async {
    final current = state;
    if (current is! SupporterLoaded) return;

    // Guard: don't allow concurrent purchases.
    if (current.purchasingProductId != null) return;

    if (!current.isBillingAvailable) {
      emit(current.copyWith(errorMessage: 'billing_unavailable'));
      return;
    }

    debugPrint(
        '🛒 [SupporterBloc] Starting purchase -> ${event.tier.productId}');
    emit(current.copyWith(purchasingProductId: event.tier.productId));

    final result = await _iapService.purchaseTier(event.tier);
    debugPrint(
        '🛒 [SupporterBloc] Purchase result for ${event.tier.productId} -> $result');

    if (!isClosed) {
      if (result == IapResult.error) {
        emit((state as SupporterLoaded).copyWith(
          clearPurchasing: true,
          errorMessage: 'purchase_error',
        ));
      }
      // For IapResult.pending: keep the loading indicator until
      // _onPurchaseDelivered fires from the stream.
    }
  }

  Future<void> _onRestorePurchases(
    RestorePurchases event,
    Emitter<SupporterState> emit,
  ) async {
    final current = state;
    if (current is! SupporterLoaded) return;

    // Use isRestoring flag instead of SupporterLoading so that any
    // _PurchaseDelivered events that arrive while restoring can still
    // update purchasedLevels in the SupporterLoaded state.
    debugPrint('🔄 [SupporterBloc] restorePurchases() called');
    emit(current.copyWith(isRestoring: true));
    try {
      await _iapService.restorePurchases();
      debugPrint('🔄 [SupporterBloc] restorePurchases() completed');
    } catch (e) {
      debugPrint('❌ [SupporterBloc] restorePurchases error: $e');
      rethrow;
    } finally {
      // Always reset isRestoring — prevents an infinite spinner when
      // restorePurchases() throws a Google Billing error.
      final afterState = state;
      if (!isClosed && afterState is SupporterLoaded) {
        emit(afterState.copyWith(
          purchasedLevels: _iapService.purchasedLevels,
          isRestoring: false,
        ));
      }
    }
  }

  void _onPurchaseFailed(
    _PurchaseFailed event,
    Emitter<SupporterState> emit,
  ) {
    final current = state;
    if (current is! SupporterLoaded) return;
    debugPrint('❌ [SupporterBloc] Purchase failed -> ${event.productId}');
    emit(current.copyWith(
        clearPurchasing: true, errorMessage: 'purchase_error'));
  }

  /// Clears the loading spinner when the user cancels (backs out of) the
  /// payment sheet.  Does NOT set an error message — cancellation is a
  /// normal user action, not an error.
  void _onPurchaseCancelled(
    _PurchaseCancelled event,
    Emitter<SupporterState> emit,
  ) {
    final current = state;
    if (current is! SupporterLoaded) return;
    debugPrint(
        '🚫 [SupporterBloc] Purchase cancelled by user -> ${event.productId}');
    emit(current.copyWith(clearPurchasing: true));
  }

  void _onPurchaseDelivered(
    _PurchaseDelivered event,
    Emitter<SupporterState> emit,
  ) {
    final current = state;
    if (current is! SupporterLoaded) return;

    debugPrint(
        '✅ [SupporterBloc] purchase delivered -> ${event.tier.productId}');
    emit(current.copyWith(
      purchasedLevels: _iapService.purchasedLevels,
      clearPurchasing: true,
      justDeliveredTier: event.tier,
    ));
  }

  Future<void> _onSaveGoldName(
    SaveGoldSupporterName event,
    Emitter<SupporterState> emit,
  ) async {
    // Use the new interface method name (saveProfileName).
    await _profileRepo.saveProfileName(event.name);
    final current = state;
    if (current is SupporterLoaded) {
      emit(current.copyWith(goldSupporterName: event.name));
    }
  }

  void _onClearError(
    ClearSupporterError event,
    Emitter<SupporterState> emit,
  ) {
    final current = state;
    if (current is SupporterLoaded) {
      emit(current.copyWith(clearError: true, clearJustDelivered: true));
    }
  }

  /// Signals the UI to open the edit-name dialog for Gold supporters who
  /// dismissed the success dialog without entering a name, or who want to
  /// update an existing name.  The actual persistence happens via
  /// [SaveGoldSupporterName] after the user confirms.
  void _onEditGoldName(
    EditGoldSupporterName event,
    Emitter<SupporterState> emit,
  ) {
    final current = state;
    if (current is! SupporterLoaded) return;
    emit(current.copyWith(isEditingGoldName: true));
  }

  /// Clears the [isEditingGoldName] signal after the UI has consumed it.
  /// Dedicated event — does NOT touch [errorMessage] or [justDeliveredTier].
  void _onAcknowledgeGoldNameEdit(
    AcknowledgeGoldNameEdit event,
    Emitter<SupporterState> emit,
  ) {
    final current = state;
    if (current is! SupporterLoaded) return;
    emit(current.copyWith(isEditingGoldName: false));
  }

  // ── Debug-only handlers ───────────────────────────────────────────────────

  /// Simulates a purchase delivery via the BLoC stream.
  /// No-op in release builds (guarded by [kDebugMode]).
  Future<void> _onDebugSimulatePurchase(
    DebugSimulatePurchase event,
    Emitter<SupporterState> emit,
  ) async {
    if (!kDebugMode) return;
    final current = state;
    if (current is! SupporterLoaded) return;
    // Directly add the internal delivery event — bypasses real billing.
    add(_PurchaseDelivered(event.tier));
    debugPrint(
        '🛒 [SupporterBloc] DEBUG: simulated purchase for ${event.tier.productId}');
  }

  /// Resets all locally-stored IAP state for retesting.
  /// No-op in release builds (guarded by [kDebugMode]).
  ///
  /// Clears SharedPreferences keys so the next [InitializeSupporter] starts
  /// from a clean slate.  The [ServiceLocator] teardown (evicting the
  /// [IIapService] singleton) is handled by the caller (e.g. debug_page.dart)
  /// because it is an infrastructure concern that doesn't belong in the BLoC.
  Future<void> _onDebugResetIapState(
    DebugResetIapState event,
    Emitter<SupporterState> emit,
  ) async {
    if (!kDebugMode) return;

    // Force re-initialization of the IAP service via the interface method
    // (debug-only no-op in production builds and fakes).
    _iapService.forceReinitialize();

    // Clear the IAP SharedPreferences keys so auto-restore won't skip.
    final prefs = await SharedPreferences.getInstance();
    for (final tier in SupporterTier.tiers) {
      await prefs.remove(IapPrefsKeys.purchasedKey(tier.productId));
    }

    debugPrint('🔄 [SupporterBloc] DEBUG: IAP state reset — prefs cleared');
    // Re-initialize so the page reflects the cleared state.
    add(InitializeSupporter());
  }
}
