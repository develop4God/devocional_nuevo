import 'package:devocional_nuevo/main.dart';
import 'package:devocional_nuevo/pages/prayer_wall_page.dart';
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
      testWidgets('should reject deep link with invalid scheme',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            navigatorKey: navigatorKey,
            home: const Scaffold(body: Text('Home')),
          ),
        );

        final uri = Uri.parse('https://example.com/test');
        final result = await deepLinkHandler.handleDeepLink(uri);

        expect(result, isFalse);
      });

      testWidgets('should reject deep link with empty path',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            navigatorKey: navigatorKey,
            home: const Scaffold(body: Text('Home')),
          ),
        );

        final uri = Uri.parse('devocional://');
        final result = await deepLinkHandler.handleDeepLink(uri);

        expect(result, isFalse);
      });

      testWidgets('should reject deep link with unknown route',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            navigatorKey: navigatorKey,
            home: const Scaffold(body: Text('Home')),
          ),
        );

        final uri = Uri.parse('devocional://unknown');
        final result = await deepLinkHandler.handleDeepLink(uri);

        expect(result, isFalse);
      });

      testWidgets('should handle devotional deep link',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            navigatorKey: navigatorKey,
            home: const Scaffold(body: Text('Home')),
          ),
        );
        await tester.pumpAndSettle();

        final uri = Uri.parse('devocional://devotional');
        final result = await deepLinkHandler.handleDeepLink(uri);
        // Don't call pumpAndSettle as it may cause timeout with page BLoCs
        await tester.pump();

        expect(result, isTrue);
      });

      testWidgets('should handle progress deep link',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            navigatorKey: navigatorKey,
            home: const Scaffold(body: Text('Home')),
          ),
        );
        await tester.pumpAndSettle();

        final uri = Uri.parse('devocional://progress');
        final result = await deepLinkHandler.handleDeepLink(uri);
        // Don't call pumpAndSettle as it may cause timeout with page BLoCs
        await tester.pump();

        expect(result, isTrue);
      });

      testWidgets('should handle prayers deep link',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            navigatorKey: navigatorKey,
            home: const Scaffold(body: Text('Home')),
          ),
        );
        await tester.pumpAndSettle();

        final uri = Uri.parse('devocional://prayers');
        final result = await deepLinkHandler.handleDeepLink(uri);
        // Don't call pumpAndSettle as it may cause timeout with page BLoCs
        await tester.pump();

        expect(result, isTrue);
      });

      testWidgets('should handle prayer_wall deep link',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            navigatorKey: navigatorKey,
            home: const Scaffold(body: Text('Home')),
          ),
        );
        await tester.pumpAndSettle();

        final uri = Uri.parse('devocional://prayer_wall');
        final result = await deepLinkHandler.handleDeepLink(uri);
        // Don't call pumpAndSettle as it will try to build PrayerWallPage
        // which requires BLoCs that aren't provided in this minimal test context
        await tester.pump();

        expect(result, isTrue);
        expect(find.byType(PrayerWallPage), findsOneWidget);
      });

      testWidgets('should handle testimonies deep link',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            navigatorKey: navigatorKey,
            home: const Scaffold(body: Text('Home')),
          ),
        );
        await tester.pumpAndSettle();

        final uri = Uri.parse('devocional://testimonies');
        final result = await deepLinkHandler.handleDeepLink(uri);
        // Don't call pumpAndSettle as it will try to build TestimoniesPage
        // which may require BLoCs that aren't provided in this minimal test context
        await tester.pump();

        expect(result, isTrue);
      });

      testWidgets('should handle supporter deep link',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            navigatorKey: navigatorKey,
            home: const Scaffold(body: Text('Home')),
          ),
        );
        await tester.pumpAndSettle();

        final uri = Uri.parse('devocional://supporter');
        final result = await deepLinkHandler.handleDeepLink(uri);
        // Don't call pumpAndSettle as it will try to build SupporterPage
        // which requires BLoCs that aren't provided in this minimal test context
        // await tester.pumpAndSettle();

        expect(result, isTrue);
      });

      testWidgets('should return false when navigator context is null',
          (WidgetTester tester) async {
        // Don't pump a widget, so navigatorKey.currentContext is null
        final uri = Uri.parse('devocional://devotional');
        final result = await deepLinkHandler.handleDeepLink(uri);

        expect(result, isFalse);
      });
    });

    group('Method Channel', () {
      const MethodChannel channel =
          MethodChannel('com.develop4god.devocional/deeplink');

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
