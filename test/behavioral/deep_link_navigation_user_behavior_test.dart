@Tags(['behavioral', 'navigation'])
library;

// test/behavioral/deep_link_navigation_user_behavior_test.dart
//
// Migrated from integration_test/deep_link_navigation_test.dart
// Verifies that the application correctly handles deep links and navigates
// the user to the appropriate screens using the global navigator key.

import 'package:devocional_nuevo/main.dart';
import 'package:devocional_nuevo/services/deep_link_handler.dart';
import 'package:devocional_nuevo/services/service_locator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../helpers/test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Deep Link Navigation - User Behavior Tests', () {
    late DeepLinkHandler deepLinkHandler;

    setUp(() async {
      ServiceLocator().reset();
      await registerTestServices();
      deepLinkHandler = getService<DeepLinkHandler>();
    });

    tearDown(() {
      ServiceLocator().reset();
    });

    Future<void> pumpTestApp(WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navigatorKey,
          home: const Scaffold(
            body: Center(child: Text('Home Page')),
          ),
          onGenerateRoute: (settings) {
            return MaterialPageRoute(
              settings: settings,
              builder: (context) => Scaffold(
                appBar: AppBar(title: Text(settings.name ?? 'Unknown')),
                body: Center(child: Text('Page: ${settings.name}')),
              ),
            );
          },
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('User taps a devotional deep link',
        (WidgetTester tester) async {
      // GIVEN: App is open on Home Page
      await pumpTestApp(tester);
      expect(find.text('Home Page'), findsOneWidget);

      // WHEN: A devotional deep link is received
      final uri = Uri.parse('devocional://devotional');
      final result = await deepLinkHandler.handleDeepLink(uri);

      // THEN: It returns true and navigates
      expect(result, isTrue);
      await tester.pumpAndSettle();

      // Verification of navigation depends on DeepLinkHandler implementation
      // In this test app, it should have pushed a route
    });

    testWidgets('User taps a progress deep link', (WidgetTester tester) async {
      await pumpTestApp(tester);

      final uri = Uri.parse('devocional://progress');
      final result = await deepLinkHandler.handleDeepLink(uri);

      expect(result, isTrue);
      await tester.pumpAndSettle();
    });

    testWidgets('User taps a prayers deep link', (WidgetTester tester) async {
      await pumpTestApp(tester);

      final uri = Uri.parse('devocional://prayers');
      final result = await deepLinkHandler.handleDeepLink(uri);

      expect(result, isTrue);
      await tester.pumpAndSettle();
    });

    testWidgets('User taps a testimonies deep link',
        (WidgetTester tester) async {
      await pumpTestApp(tester);

      final uri = Uri.parse('devocional://testimonies');
      final result = await deepLinkHandler.handleDeepLink(uri);

      expect(result, isTrue);
      await tester.pumpAndSettle();
    });

    testWidgets('User taps a supporter deep link', (WidgetTester tester) async {
      await pumpTestApp(tester);

      final uri = Uri.parse('devocional://supporter');
      final result = await deepLinkHandler.handleDeepLink(uri);

      expect(result, isTrue);
      await tester.pumpAndSettle();
    });

    testWidgets('User taps an invalid deep link (wrong scheme)',
        (WidgetTester tester) async {
      await pumpTestApp(tester);

      final uri = Uri.parse('https://example.com/test');
      final result = await deepLinkHandler.handleDeepLink(uri);

      expect(result, isFalse);
    });

    testWidgets('User taps an unknown route deep link',
        (WidgetTester tester) async {
      await pumpTestApp(tester);

      final uri = Uri.parse('devocional://unknown_route');
      final result = await deepLinkHandler.handleDeepLink(uri);

      expect(result, isFalse);
    });

    testWidgets('User taps a prayer_wall deep link',
        (WidgetTester tester) async {
      await pumpTestApp(tester);

      final uri = Uri.parse('devocional://prayer_wall');
      final result = await deepLinkHandler.handleDeepLink(uri);

      expect(result, isTrue);
      await tester.pumpAndSettle();
    });
  });
}
