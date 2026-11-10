@Tags(['critical', 'unit', 'services'])
library;

import 'package:devocional_nuevo/services/update_preferences.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late UpdatePreferences preferences;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    preferences = UpdatePreferences();
  });

  group('restartPending', () {
    test('defaults to false', () async {
      expect(await preferences.getRestartPending(), isFalse);
    });

    test('round trips true then false', () async {
      await preferences.setRestartPending(true);
      expect(await preferences.getRestartPending(), isTrue);

      await preferences.setRestartPending(false);
      expect(await preferences.getRestartPending(), isFalse);
    });

    test('is stored under its own key', () async {
      await preferences.setRestartPending(true);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool(UpdatePreferences.restartPendingKey), isTrue);
      expect(await preferences.getDeclinedVersionCode(), isNull);
    });
  });
}
