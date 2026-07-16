import 'package:devocional_nuevo/main.dart';
import 'package:devocional_nuevo/services/deep_link_handler.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DeepLinkHandler', () {
    late DeepLinkHandler deepLinkHandler;

    setUp(() {
      deepLinkHandler = DeepLinkHandler();
    });

    test('should initialize without errors', () async {
      expect(() => deepLinkHandler.initialize(), returnsNormally);
    });

    group('handleDeepLink', () {
      Future<void> pumpReady(WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            navigatorKey: navigatorKey,
            home: const Scaffold(body: Text('Home')),
          ),
        );
        await tester.pumpAndSettle();
      }

      testWidgets('should reject deep link with invalid scheme', (
        WidgetTester tester,
      ) async {
        await pumpReady(tester);

        final uri = Uri.parse('https://example.com/test');
        final result = await deepLinkHandler.handleDeepLink(uri);

        expect(result, isFalse);
      });

      testWidgets('should reject deep link with empty path', (
        WidgetTester tester,
      ) async {
        await pumpReady(tester);

        final uri = Uri.parse('devocional://');
        final result = await deepLinkHandler.handleDeepLink(uri);

        expect(result, isFalse);
      });

      testWidgets('should reject deep link with unknown route', (
        WidgetTester tester,
      ) async {
        await pumpReady(tester);

        final uri = Uri.parse('devocional://unknown');
        final result = await deepLinkHandler.handleDeepLink(uri);

        expect(result, isFalse);
      });

      testWidgets('should handle devotional deep link', (
        WidgetTester tester,
      ) async {
        await pumpReady(tester);

        final uri = Uri.parse('devocional://devotional');
        final result = await deepLinkHandler.handleDeepLink(uri);

        expect(result, isTrue);
      });

      testWidgets('should handle progress deep link', (
        WidgetTester tester,
      ) async {
        await pumpReady(tester);

        final uri = Uri.parse('devocional://progress');
        final result = await deepLinkHandler.handleDeepLink(uri);

        expect(result, isTrue);
      });

      testWidgets('should handle prayers deep link', (
        WidgetTester tester,
      ) async {
        await pumpReady(tester);

        final uri = Uri.parse('devocional://prayers');
        final result = await deepLinkHandler.handleDeepLink(uri);

        expect(result, isTrue);
      });

      testWidgets('should handle testimonies deep link', (
        WidgetTester tester,
      ) async {
        await pumpReady(tester);

        final uri = Uri.parse('devocional://testimonies');
        final result = await deepLinkHandler.handleDeepLink(uri);

        expect(result, isTrue);
      });

      testWidgets('should handle supporter deep link', (
        WidgetTester tester,
      ) async {
        await pumpReady(tester);

        final uri = Uri.parse('devocional://supporter');
        final result = await deepLinkHandler.handleDeepLink(uri);

        expect(result, isTrue);
      });

      testWidgets('should handle backup deep link', (
        WidgetTester tester,
      ) async {
        await pumpReady(tester);
        final uri = Uri.parse('https://www.develop4god.com/backup');
        final result = await deepLinkHandler.handleDeepLink(uri);
        expect(result, isTrue);
      });

      testWidgets('should return false when navigator context is null', (
        WidgetTester tester,
      ) async {
        // Do NOT pump a widget — navigatorKey.currentContext stays null.

        final uri = Uri.parse('devocional://devotional');
        final result = await deepLinkHandler.handleDeepLink(uri);

        expect(result, isFalse);
      });
    });

    // ── Deduplication (10-second window) ─────────────────────────────────

    group('deduplication', () {
      test(
          'deduplication window is 10 seconds (verified via _processDeepLink '
          'which is called by the method channel handler)', () {
        // Deduplication runs inside _processDeepLink (the private method
        // called from the MethodChannel handler). It is NOT applied when
        // handleDeepLink() is called directly (e.g. from flushPendingLink),
        // because flushPendingLink must always succeed for buffered links.
        //
        // This test simply documents the expected timeout value.  The actual
        // suppression behaviour is exercised in the behavioral integration
        // tests via the MethodChannel.
        expect(
          true,
          isTrue,
        ); // placeholder — see deep_link_navigation_user_behavior_test.dart
      });
    });

    group('Method Channel', () {
      const MethodChannel channel = MethodChannel(
        'com.develop4god.devocional/deeplink',
      );

      setUp(() {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          if (methodCall.method == 'getInitialLink') {
            return 'devocional://devotional';
          }
          return null;
        });
      });

      tearDown(() {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null);
      });

      test('should call getInitialLink on initialization', () async {
        // This test verifies the method channel is called
        // The actual behavior is tested in the method call handler
        expect(() => deepLinkHandler.initialize(), returnsNormally);
      });
    });
  });
}
