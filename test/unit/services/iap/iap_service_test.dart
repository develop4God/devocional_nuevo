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

// ── Mock: billing UNAVAILABLE ─────────────────────────────────────────────────
class _MockInAppPurchase extends Mock implements InAppPurchase {
  final StreamController<List<PurchaseDetails>> _purchaseController =
      StreamController<List<PurchaseDetails>>.broadcast();

  int completePurchaseCallCount = 0;

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
  Future<void> completePurchase(PurchaseDetails purchase) async {
    completePurchaseCallCount++;
  }
}

// ── Mock: billing AVAILABLE ───────────────────────────────────────────────────
class _AvailableMockInAppPurchase extends _MockInAppPurchase {
  @override
  Future<bool> isAvailable() async => true;

  void pushPurchase(PurchaseDetails purchase) {
    _purchaseController.add([purchase]);
  }
}

// ── Fake PurchaseDetails for error-status testing ─────────────────────────────
class _FakeErrorPurchaseDetails extends Fake implements PurchaseDetails {
  @override
  final String productID = 'supporter_bronze';

  @override
  final PurchaseStatus status = PurchaseStatus.error;

  @override
  final bool pendingCompletePurchase;

  @override
  IAPError? get error => null;

  _FakeErrorPurchaseDetails({this.pendingCompletePurchase = true});
}

// ── Tests ─────────────────────────────────────────────────────────────────────
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

    // ── Initialization ──────────────────────────────────────────────────────

    group('Initialization', () {
      test('starts with billing unavailable and nothing purchased', () {
        expect(service.isAvailable, isFalse);
        expect(service.purchasedLevels, isEmpty);
        expect(service.initStatus, equals(IapInitStatus.notStarted));
      });

      test('initialize() is idempotent — second call is a no-op', () async {
        await service.initialize();
        await service.initialize();
        expect(service.isAvailable, isFalse);
      });

      test('initStatus is billingUnavailable when store not available',
          () async {
        await service.initialize();
        expect(service.initStatus, equals(IapInitStatus.billingUnavailable));
      });

      test('loads purchased tiers from SharedPreferences on initialize()',
          () async {
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
    });

    // ── Purchased state ─────────────────────────────────────────────────────

    group('Purchased state', () {
      test('isPurchased returns false for unpurchased tier', () {
        expect(service.isPurchased(SupporterTierLevel.silver), isFalse);
      });

      test('purchasedLevels is unmodifiable', () {
        expect(() => service.purchasedLevels.add(SupporterTierLevel.bronze),
            throwsUnsupportedError);
      });
    });

    // ── purchaseTier ────────────────────────────────────────────────────────

    group('purchaseTier()', () {
      test('returns error when billing unavailable', () async {
        await service.initialize();
        final result = await service.purchaseTier(
          SupporterTier.fromLevel(SupporterTierLevel.bronze),
        );
        expect(result, equals(IapResult.error));
      });

      test('returns error when product not loaded', () async {
        await service.initialize();
        final result = await service.purchaseTier(
          SupporterTier.fromLevel(SupporterTierLevel.gold),
        );
        expect(result, equals(IapResult.error));
      });
    });

    // ── onPurchaseDelivered stream ──────────────────────────────────────────

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

    // ── resetForTesting ─────────────────────────────────────────────────────

    group('resetForTesting()', () {
      test('clears all state', () async {
        await service.initialize();
        service.resetForTesting();

        expect(service.purchasedLevels, isEmpty);
        expect(service.isAvailable, isFalse);
        expect(service.initStatus, equals(IapInitStatus.notStarted));
      });
    });

    // ── Dispose safety ──────────────────────────────────────────────────────

    group('dispose safety', () {
      test('post-dispose purchase update does not emit on stream', () async {
        final received = <SupporterTier>[];
        service.onPurchaseDelivered.listen(received.add);

        await service.initialize();
        // Dispose first — sets _disposed = true.
        await service.dispose();

        // Any further event on the purchase stream should be silently ignored.
        await Future<void>.delayed(const Duration(milliseconds: 10));
        expect(received, isEmpty);
      });

      test('double dispose does not throw', () async {
        await service.initialize();
        await service.dispose();
        // Second dispose call must be safe
        await expectLater(service.dispose(), completes);
      });
    });

    // ── Store compliance: completePurchase on error ─────────────────────────

    group('store compliance', () {
      test(
          'completePurchase() is called for error status with '
          'pendingCompletePurchase=true', () async {
        final availableMock = _AvailableMockInAppPurchase();
        final svc = IapService(
          inAppPurchase: availableMock,
          prefsFactory: SharedPreferences.getInstance,
        );

        await svc.initialize();

        final errorPurchase =
            _FakeErrorPurchaseDetails(pendingCompletePurchase: true);
        availableMock.pushPurchase(errorPurchase);

        await Future<void>.delayed(const Duration(milliseconds: 30));
        // completePurchase must have been called exactly once.
        expect(availableMock.completePurchaseCallCount, equals(1));

        await svc.dispose();
      });
    });
  });

  // ── Interface compliance ──────────────────────────────────────────────────

  group('IapService — interface compliance', () {
    test('IapService implements IIapService', () {
      SharedPreferences.setMockInitialValues({});
      final svc = IapService(prefsFactory: SharedPreferences.getInstance);
      expect(svc, isA<IIapService>());
    });
  });
}
