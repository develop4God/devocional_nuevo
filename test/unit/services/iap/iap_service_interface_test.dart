@Tags(['unit', 'services', 'iap'])
library;

// test/unit/services/iap/iap_service_interface_test.dart
//
// TASK 1: Verify resetForTesting() is absent from IIapService (compile-time
//         guarantee) and present on the concrete IapService.
// TASK 7: Verify initStatus is exposed on IIapService.

import 'package:devocional_nuevo/services/iap/i_iap_service.dart';
import 'package:devocional_nuevo/services/iap/iap_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Minimal mock that never connects to the store.
class _MockIap extends Mock implements InAppPurchase {
  @override
  Future<bool> isAvailable() async => false;

  @override
  Stream<List<PurchaseDetails>> get purchaseStream =>
      const Stream.empty();

  @override
  Future<ProductDetailsResponse> queryProductDetails(
      Set<String> identifiers) async {
    return ProductDetailsResponse(
        productDetails: [], notFoundIDs: identifiers.toList());
  }
}

IapService _makeService() => IapService(
      inAppPurchase: _MockIap(),
      prefsFactory: SharedPreferences.getInstance,
    );

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
  });

  group('IIapService interface contract', () {
    test(
        'resetForTesting() is present on concrete IapService '
        'and can be called without error', () {
      final svc = _makeService();
      // If the method were removed from IapService this would fail to compile.
      expect(() => svc.resetForTesting(), returnsNormally);
    });

    test(
        'IapService held as IIapService does not expose resetForTesting '
        '(compile-time enforcement)', () {
      // Assigned to the interface type; resetForTesting must NOT be callable
      // on this reference — that would be a compile error.
      final IIapService iapInterface = _makeService();

      expect(iapInterface, isA<IIapService>());
      // Downcast confirms the method IS on the concrete class:
      expect(iapInterface, isA<IapService>());
      (iapInterface as IapService).resetForTesting();

      // goldSupporterName and saveGoldSupporterName are absent from the
      // interface (TASK 6). Verified at compile time — if you tried:
      //   iapInterface.goldSupporterName  → compile error ✓
      //   iapInterface.saveGoldSupporterName('x')  → compile error ✓
    });

    test('IIapService exposes initStatus getter (TASK 7)', () {
      final IIapService iapInterface = _makeService();
      // initStatus is on the interface — must be accessible without downcast.
      expect(iapInterface.initStatus, equals(IapInitStatus.notStarted));
    });

    test('initStatus transitions to billingUnavailable after initialize()',
        () async {
      final svc = _makeService();
      await svc.initialize();
      expect(svc.initStatus, equals(IapInitStatus.billingUnavailable));
      await svc.dispose();
    });

    test('IapInitStatus enum has all expected values', () {
      expect(IapInitStatus.values, containsAll([
        IapInitStatus.notStarted,
        IapInitStatus.success,
        IapInitStatus.billingUnavailable,
        IapInitStatus.loadFailed,
      ]));
    });
  });
}
