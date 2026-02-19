// lib/services/iap/iap_diagnostics_service.dart

import 'package:flutter/foundation.dart';

import '../../models/supporter_tier.dart';
import 'i_iap_service.dart';

/// Prints diagnostic information about IAP status.
///
/// Extracted from [IapService] to satisfy SRP — this class has
/// no purchasing logic, only debugging output.
class IapDiagnosticsService {
  final IIapService _iapService;

  IapDiagnosticsService(this._iapService);

  /// Prints a formatted diagnostic report to the debug console.
  void printDiagnostics() {
    debugPrint('═══════════════════════════════════════════');
    debugPrint('📊 [IAP] Diagnostics Report');
    debugPrint('═══════════════════════════════════════════');
    debugPrint('Billing Available: ${_iapService.isAvailable}');
    debugPrint('Init Status: ${_iapService.initStatus}');
    debugPrint('Purchased Tiers: ${_iapService.purchasedLevels.length}');

    final loadedCount = SupporterTier.tiers
        .where((t) => _iapService.getProduct(t.productId) != null)
        .length;
    debugPrint('Products Loaded: $loadedCount/${SupporterTier.tiers.length}');

    if (loadedCount == 0) {
      debugPrint('⚠️  NO PRODUCTS LOADED');
      debugPrint('   Expected IDs:');
      for (final tier in SupporterTier.tiers) {
        debugPrint('   - ${tier.productId}');
      }
    } else {
      for (final tier in SupporterTier.tiers) {
        final product = _iapService.getProduct(tier.productId);
        if (product != null) {
          debugPrint('   ✅ ${product.id}: ${product.title} — ${product.price}');
        }
      }
    }

    for (final level in _iapService.purchasedLevels) {
      debugPrint('   🏆 $level');
    }

    debugPrint('═══════════════════════════════════════════');
  }
}
