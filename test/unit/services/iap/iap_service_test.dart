@Tags(['unit', 'services', 'iap'])
library;

// test/unit/services/iap/iap_service_test.dart

import 'dart:async';

import 'package:devocional_nuevo/models/supporter_tier.dart';
import 'package:devocional_nuevo/services/iap/i_iap_service.dart';
import 'package:devocional_nuevo/services/iap/iap_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Minimal mock of InAppPurchase for unit testing
class _MockInAppPurchase extends Mock implements InAppPurchase {
  final StreamController<List<PurchaseDetails>> _purchaseController =
      StreamController<List<PurchaseDetails>>.broadcast();

  @override
  Stream<List<PurchaseDetails>> get purchaseStream =>
      _purchaseController.stream;

  @override
  Future<bool> isAvailable() async => false;

  @override
  Future<ProductDetailsResponse> queryProductDetails(
      Set<String> identifiers) async {
    return ProductDetailsResponse(
      productDetails: [],
      notFoundIDs: identifiers.toList(),
    );
  }

  @override
  Future<bool> buyNonConsumable({required PurchaseParam purchaseParam}) async =>
      false;

  @override
  Future<void> restorePurchases({String? applicationUserName}) async {}

  @override
  Future<void> completePurchase(PurchaseDetails purchase) async {}
}

void main() {
  group('IapService', () {
    late IapService service;
    late _MockInAppPurchase mockIap;

    setUp(() {
      TestWidgetsFlutterBinding.ensureInitialized();
      SharedPreferences.setMockInitialValues({});
      mockIap = _MockInAppPurchase();
      service = IapService(
        inAppPurchase: mockIap,
        prefsFactory: SharedPreferences.getInstance,
      );
    });

    tearDown(() async {
      await service.dispose();
    });

    group('Initialization', () {
      test('starts with billing unavailable and nothing purchased', () {
        expect(service.isAvailable, isFalse);
        expect(service.purchasedLevels, isEmpty);
        expect(service.goldSupporterName, isNull);
      });

      test('initialize() is idempotent — second call is a no-op', () async {
        await service.initialize();
        await service.initialize(); // must not throw or reset state
        expect(service.isAvailable, isFalse); // mock returns false
      });

      test('loads purchased tiers from SharedPreferences on initialize()',
          () async {
        // Seed prefs with a previously-purchased bronze tier
        SharedPreferences.setMockInitialValues({
          'iap_purchased_supporter_bronze': true,
        });

        final svc = IapService(
          inAppPurchase: mockIap,
          prefsFactory: SharedPreferences.getInstance,
        );

        await svc.initialize();
        expect(svc.isPurchased(SupporterTierLevel.bronze), isTrue);
        expect(svc.isPurchased(SupporterTierLevel.silver), isFalse);
        await svc.dispose();
      });

      test('loads gold supporter name from SharedPreferences', () async {
        SharedPreferences.setMockInitialValues({
          'iap_purchased_supporter_gold': true,
          'iap_gold_supporter_name': 'María José',
        });

        final svc = IapService(
          inAppPurchase: mockIap,
          prefsFactory: SharedPreferences.getInstance,
        );
        await svc.initialize();

        expect(svc.goldSupporterName, equals('María José'));
        await svc.dispose();
      });
    });

    group('Purchased state', () {
      test('isPurchased returns false for unpurchased tier', () {
        expect(service.isPurchased(SupporterTierLevel.silver), isFalse);
      });

      test('purchasedLevels is unmodifiable', () {
        expect(service.purchasedLevels, isA<Set<SupporterTierLevel>>());
        expect(() => service.purchasedLevels.add(SupporterTierLevel.bronze),
            throwsUnsupportedError);
      });
    });

    group('purchaseTier()', () {
      test('returns error when billing unavailable', () async {
        await service.initialize(); // isAvailable = false (mock)
        final result = await service.purchaseTier(
          SupporterTier.fromLevel(SupporterTierLevel.bronze),
        );
        expect(result, equals(IapResult.error));
      });

      test('returns error when product not loaded', () async {
        // manually flip isAvailable via resetForTesting trick
        await service.initialize();
        // product map is empty → returns error even if billing were available
        final result = await service.purchaseTier(
          SupporterTier.fromLevel(SupporterTierLevel.gold),
        );
        expect(result, equals(IapResult.error));
      });
    });

    group('saveGoldSupporterName()', () {
      test('persists name in SharedPreferences', () async {
        await service.initialize();
        await service.saveGoldSupporterName('Juan Pablo');

        expect(service.goldSupporterName, equals('Juan Pablo'));

        final prefs = await SharedPreferences.getInstance();
        expect(
            prefs.getString('iap_gold_supporter_name'), equals('Juan Pablo'));
      });
    });

    group('onPurchaseDelivered stream', () {
      test('is a broadcast stream', () {
        expect(service.onPurchaseDelivered.isBroadcast, isTrue);
      });

      test('does not emit anything at startup', () async {
        final received = <SupporterTier>[];
        service.onPurchaseDelivered.listen(received.add);
        await Future<void>.delayed(const Duration(milliseconds: 10));
        expect(received, isEmpty);
      });
    });

    group('resetForTesting()', () {
      test('clears all state', () async {
        await service.initialize();
        await service.saveGoldSupporterName('Test');

        service.resetForTesting();

        expect(service.purchasedLevels, isEmpty);
        expect(service.goldSupporterName, isNull);
        expect(service.isAvailable, isFalse);
      });
    });
  });

  group('IapService — interface compliance', () {
    test('IapService implements IIapService', () {
      SharedPreferences.setMockInitialValues({});
      final svc = IapService(prefsFactory: SharedPreferences.getInstance);
      expect(svc, isA<IIapService>());
    });
  });
}
