// lib/services/iap/iap_prefs_keys.dart

/// Single source of truth for IAP SharedPreferences key schema.
///
/// Used by [IapService] for persisting purchase state and by [SupporterBloc]
/// for the auto-restore gate and debug reset.
class IapPrefsKeys {
  IapPrefsKeys._();

  /// SharedPreferences key for whether a given [productId] has been purchased.
  static String purchasedKey(String productId) => 'iap_purchased_$productId';
}
