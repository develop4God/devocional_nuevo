// test/helpers/tts_test_setup.dart

import 'package:devocional_nuevo/services/service_locator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'flutter_tts_mock.dart';

class TtsTestSetup {
  static void initialize() {
    SharedPreferences.setMockInitialValues({});
    FlutterTtsMock.setup();
    setupServiceLocator();
  }

  static Future<void> cleanup() async {
    FlutterTtsMock.tearDown();
    ServiceLocator().reset();
  }
}
