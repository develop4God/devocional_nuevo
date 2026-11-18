@Tags(['critical', 'unit', 'services'])
library;

import 'package:devocional_nuevo/services/stale_task_cleaner.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('com.devocional_nuevo.test_channel');
  late StaleTaskCleaner cleaner;

  void mockHandler(Future<Object?> Function(MethodCall call) handler) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, handler);
  }

  setUp(() => cleaner = StaleTaskCleaner());

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('returns the removed count on success', () async {
    String? method;
    mockHandler((call) async {
      method = call.method;
      return 2;
    });

    expect(await cleaner.removeStaleAppTasks(), 2);
    expect(method, 'removeStaleAppTasks');
  });

  test('returns 0 on PlatformException', () async {
    mockHandler((call) async => throw PlatformException(code: 'ERROR'));

    expect(await cleaner.removeStaleAppTasks(), 0);
  });

  test('returns 0 on MissingPluginException', () async {
    mockHandler((call) async => throw MissingPluginException());

    expect(await cleaner.removeStaleAppTasks(), 0);
  });

  test('returns 0 on null result', () async {
    mockHandler((call) async => null);

    expect(await cleaner.removeStaleAppTasks(), 0);
  });
}
