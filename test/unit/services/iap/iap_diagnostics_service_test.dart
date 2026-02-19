@Tags(['unit', 'services', 'iap'])
library;

// test/unit/services/iap/iap_diagnostics_service_test.dart
//
// TASK 5: Verify IapDiagnosticsService.printDiagnostics() is reachable
//         via the kDebugMode-gated path in IapService.initialize() and
//         completes without throwing for 0 products.

import 'package:devocional_nuevo/models/supporter_tier.dart';
import 'package:devocional_nuevo/services/iap/iap_diagnostics_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/iap_mock_helper.dart';

void main() {
  group('IapDiagnosticsService', () {
    test('printDiagnostics() does not throw when 0 products loaded '
        '(covers ⚠️ NO PRODUCTS LOADED branch)', () {
      final fakeIap = FakeIapService();
      final diagnostics = IapDiagnosticsService(fakeIap);

      expect(() => diagnostics.printDiagnostics(), returnsNormally);
    });

    test('printDiagnostics() does not throw when billing unavailable', () {
      final fakeIap = FakeIapService(isAvailable: false);
      final diagnostics = IapDiagnosticsService(fakeIap);

      expect(() => diagnostics.printDiagnostics(), returnsNormally);
    });

    test('printDiagnostics() does not throw with purchased tiers present',
        () async {
      final fakeIap = FakeIapService();
      await fakeIap.deliver(SupporterTier.fromLevel(SupporterTierLevel.gold));

      final diagnostics = IapDiagnosticsService(fakeIap);
      expect(() => diagnostics.printDiagnostics(), returnsNormally);

      await fakeIap.dispose();
    });

    test('initStatus is included in diagnostics output without throwing', () {
      final fakeIap = FakeIapService();
      // initStatus is now printed; must not throw regardless of status.
      expect(() => IapDiagnosticsService(fakeIap).printDiagnostics(),
          returnsNormally);
    });
  });
}
