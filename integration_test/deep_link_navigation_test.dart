import 'package:devocional_nuevo/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:devocional_nuevo/services/service_locator.dart';
import 'package:devocional_nuevo/services/deep_link_handler.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Deep Link Navigation Integration Tests', () {
    setUpAll(() async {
      // Setup service locator before tests
      await setupServiceLocator();
    });

    tearDownAll(() {
      // Clean up service locator after tests
      ServiceLocator().reset();
    });

    testWidgets('should navigate to devotional page from deep link',
        (WidgetTester tester) async {
      // Start the app
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navigatorKey,
          home: const Scaffold(
            body: Center(child: Text('Home Page')),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Simulate deep link
      final deepLinkHandler = getService<DeepLinkHandler>();
      final uri = Uri.parse('devocional://devotional');
      final result = await deepLinkHandler.handleDeepLink(uri);

      expect(result, isTrue);
      await tester.pumpAndSettle();
    });

    testWidgets('should navigate to progress page from deep link',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navigatorKey,
          home: const Scaffold(
            body: Center(child: Text('Home Page')),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final deepLinkHandler = getService<DeepLinkHandler>();
      final uri = Uri.parse('devocional://progress');
      final result = await deepLinkHandler.handleDeepLink(uri);

      expect(result, isTrue);
      await tester.pumpAndSettle();
    });

    testWidgets('should navigate to prayers page from deep link',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navigatorKey,
          home: const Scaffold(
            body: Center(child: Text('Home Page')),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final deepLinkHandler = getService<DeepLinkHandler>();
      final uri = Uri.parse('devocional://prayers');
      final result = await deepLinkHandler.handleDeepLink(uri);

      expect(result, isTrue);
      await tester.pumpAndSettle();
    });

    testWidgets('should navigate to testimonies page from deep link',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navigatorKey,
          home: const Scaffold(
            body: Center(child: Text('Home Page')),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final deepLinkHandler = getService<DeepLinkHandler>();
      final uri = Uri.parse('devocional://testimonies');
      final result = await deepLinkHandler.handleDeepLink(uri);

      expect(result, isTrue);
      await tester.pumpAndSettle();
    });

    testWidgets('should navigate to supporter page from deep link',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navigatorKey,
          home: const Scaffold(
            body: Center(child: Text('Home Page')),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final deepLinkHandler = getService<DeepLinkHandler>();
      final uri = Uri.parse('devocional://supporter');
      final result = await deepLinkHandler.handleDeepLink(uri);

      expect(result, isTrue);
      await tester.pumpAndSettle();
    });

    testWidgets('should reject invalid deep link',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navigatorKey,
          home: const Scaffold(
            body: Center(child: Text('Home Page')),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final deepLinkHandler = getService<DeepLinkHandler>();
      final uri = Uri.parse('https://example.com/test');
      final result = await deepLinkHandler.handleDeepLink(uri);

      expect(result, isFalse);
    });

    testWidgets('should reject unknown route deep link',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navigatorKey,
          home: const Scaffold(
            body: Center(child: Text('Home Page')),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final deepLinkHandler = getService<DeepLinkHandler>();
      final uri = Uri.parse('devocional://unknown_route');
      final result = await deepLinkHandler.handleDeepLink(uri);

      expect(result, isFalse);
    });
  });
}
