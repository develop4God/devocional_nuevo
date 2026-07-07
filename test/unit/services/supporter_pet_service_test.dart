@Tags(['unit', 'services'])
library;

import 'package:devocional_nuevo/services/supporter_pet_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('SupporterPetService', () {
    late SupporterPetService service;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      service = SupporterPetService(await SharedPreferences.getInstance());
    });

    test('isPetUnlocked is false before any Gold purchase', () {
      expect(service.isPetUnlocked, isFalse);
    });

    test('isPetUnlocked reflects unlockPetFeature immediately', () async {
      expect(service.isPetUnlocked, isFalse);
      await service.unlockPetFeature();
      // Regression guard: a Gold purchase in SupporterPage must be visible
      // to any other reader of the same service instance right away --
      // SettingsPage relies on this to show the rename option on tab
      // reveal, without needing to reconstruct the service.
      expect(service.isPetUnlocked, isTrue);
    });

    test(
        'unlockPetFeature also enables the pet header and clears pending setup',
        () async {
      await service.markGoldSetupPending();
      expect(service.isGoldSetupPending, isTrue);

      await service.unlockPetFeature();

      expect(service.showPetHeader, isTrue);
      expect(service.isGoldSetupPending, isFalse);
    });
  });
}
