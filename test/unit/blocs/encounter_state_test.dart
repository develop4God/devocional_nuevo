@Tags(['unit', 'blocs'])
library;

import 'package:devocional_nuevo/blocs/encounter/encounter_state.dart';
import 'package:devocional_nuevo/services/localization_service.dart';
import 'package:devocional_nuevo/services/service_locator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EncounterError.localizedMessage', () {
    setUp(() {
      ServiceLocator().reset();
      ServiceLocator().registerSingleton<LocalizationService>(
        LocalizationService(),
      );
    });

    test('resolves to the generic load-error key regardless of message', () {
      final state = EncounterError('');
      expect(state.localizedMessage, 'encounters.error_load');
    });

    test('resolves to the generic key even if message is non-empty', () {
      // The bloc always emits EncounterError('') today, but the display
      // layer must never show whatever message ends up here -- mirrors
      // BackupError/DiscoveryError's stance on not surfacing raw text.
      final state = EncounterError('Exception: some raw error');
      expect(state.localizedMessage, 'encounters.error_load');
    });
  });
}
