import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void setupFirebaseMocks() {
  const MethodChannel firebaseCoreChannel =
      MethodChannel('plugins.flutter.io/firebase_core');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(firebaseCoreChannel,
          (MethodCall methodCall) async {
    switch (methodCall.method) {
      case 'Firebase#initializeCore':
        return [
          {
            'name': '[DEFAULT]',
            'options': {
              'apiKey': 'fake-api-key',
              'appId': 'fake-app-id',
              'messagingSenderId': 'fake-sender-id',
              'projectId': 'fake-project-id',
            },
            'pluginConstants': {},
          }
        ];
      case 'Firebase#initializeApp':
        return {
          'name': '[DEFAULT]',
          'options': {
            'apiKey': 'fake-api-key',
            'appId': 'fake-app-id',
            'messagingSenderId': 'fake-sender-id',
            'projectId': 'fake-project-id',
          },
          'pluginConstants': {},
        };
      default:
        return null;
    }
  });
}

void main() {
  setupFirebaseMocks();
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    try {
      await Firebase.initializeApp();
    } catch (_) {}
  });
}
