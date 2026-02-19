// lib/blocs/supporter/supporter_bloc.dart

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../models/supporter_tier.dart';
import '../../repositories/i_supporter_profile_repository.dart';
import '../../services/iap/i_iap_service.dart';
import 'supporter_event.dart';
import 'supporter_state.dart';

/// Internal event: a product was delivered by the IAP service stream.
/// Defined here (not in supporter_event.dart) so it stays package-private.
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
    on<SaveGoldSupporterName>(_onSaveGoldName);
    on<EditGoldSupporterName>(_onEditGoldName);
    on<ClearSupporterError>(_onClearError);

    // Subscribe to delivered-product events from the service.
    _deliveredSubscription = _iapService.onPurchaseDelivered.listen(
      (tier) => add(_PurchaseDelivered(tier)),
      onError: (Object error) {
        debugPrint('❌ [SupporterBloc] Delivered stream error: $error');
      },
    );
  }

  @override
  Future<void> close() async {
    await _deliveredSubscription?.cancel();
    _deliveredSubscription = null;
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

      final goldName = await _profileRepo.loadGoldSupporterName();

      final storePrices = <String, String>{};
      for (final tier in SupporterTier.tiers) {
        final product = _iapService.getProduct(tier.productId);
        if (product != null) {
          storePrices[tier.productId] = product.price;
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

    // Guard: don't allow concurrent purchases
    if (current.purchasingProductId != null) return;

    if (!current.isBillingAvailable) {
      emit(current.copyWith(
        errorMessage: 'billing_unavailable',
      ));
      return;
    }

    emit(current.copyWith(purchasingProductId: event.tier.productId));

    final result = await _iapService.purchaseTier(event.tier);

    if (!isClosed) {
      if (result == IapResult.error) {
        emit((state as SupporterLoaded).copyWith(
          clearPurchasing: true,
          errorMessage: 'purchase_error',
        ));
      }
      // For IapResult.pending: keep showing the loading indicator
      // until _onPurchaseDelivered fires from the stream.
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
    emit(current.copyWith(isRestoring: true));
    await _iapService.restorePurchases();

    // After the restore call returns, update with final purchased set.
    // If _onPurchaseDelivered already updated state mid-restore, read
    // the latest purchased levels from the service.
    final afterState = state;
    if (afterState is SupporterLoaded) {
      emit(afterState.copyWith(
        purchasedLevels: _iapService.purchasedLevels,
        isRestoring: false,
      ));
    }
  }

  void _onPurchaseDelivered(
    _PurchaseDelivered event,
    Emitter<SupporterState> emit,
  ) {
    final current = state;
    if (current is! SupporterLoaded) return;

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
    await _profileRepo.saveGoldSupporterName(event.name);
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
}
