import 'package:devocional_nuevo/services/service_locator.dart';
import 'package:devocional_nuevo/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();

    // Mock Firebase
    const firebaseCoreChannel =
        MethodChannel('plugins.flutter.io/firebase_core');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(firebaseCoreChannel, (call) async {
      if (call.method == 'Firebase#initializeCore') {
        return [
          {'name': '[DEFAULT]', 'options': {}, 'pluginConstants': {}}
        ];
      }
      return null;
    });

    const crashlyticsChannel =
        MethodChannel('plugins.flutter.io/firebase_crashlytics');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(crashlyticsChannel, (_) async => null);

    const remoteConfigChannel =
        MethodChannel('plugins.flutter.io/firebase_remote_config');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(remoteConfigChannel, (call) async {
      return call.method == 'RemoteConfig#instance' ? {} : null;
    });

    // Mock SharedPreferences which is needed by LocalizationService
    SharedPreferences.setMockInitialValues({});

    // Initialize service locator for tests
    setupServiceLocator();
  });

  testWidgets('SplashScreen renders successfully', (WidgetTester tester) async {
    // Build the SplashScreen widget in a complete app context with navigation
    await tester.pumpWidget(
      MaterialApp(
        home: const SplashScreen(),
        // Provide a route for navigation (SplashScreen navigates after 9s)
        routes: {
          '/devocionales': (context) =>
              const Scaffold(body: Text('Devocionales')),
        },
      ),
    );

    // Verify the widget renders initially
    expect(find.byType(SplashScreen), findsOneWidget);

    // Pump to allow widget to build
    await tester.pump();

    // Verify widget is still visible
    expect(find.byType(SplashScreen), findsOneWidget);

    // Note: We pump enough time to let the 9-second timer complete
    // This prevents "pending timer" test failures
    // The mounted check in SplashScreen prevents actual navigation since
    // DevocionalesPage isn't in our test route map
    await tester.pump(const Duration(seconds: 10));
  });
}
