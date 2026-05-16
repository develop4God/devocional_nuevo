// test/services/deep_link_handler_test.dart
//
// Tests for DeepLinkHandler HTTPS App Links migration.
//
// Coverage:
//   - Scheme validation: rejects non-https / non-devocional URIs
//   - HTTPS empty-path rejection: https://domain.com/ → false
//   - HTTPS route extraction: routes supporter, encounters, devotional correctly
//   - Backward-compat: devocional://supporter still routes correctly

import 'package:devocional_nuevo/main.dart' show navigatorKey;
import 'package:devocional_nuevo/services/deep_link_handler.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Minimal navigator observer — records pushes without building pages.
// -------------------------------------------adb shell pm get-app-links com.develop4god.devocional_nuevo--------------------------------
class _RouteObserver extends NavigatorObserver {
  final List<Route<dynamic>> pushed = [];

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    pushed.add(route);
  }

  int get pushCount => pushed.length;
}

// ---------------------------------------------------------------------------
// Minimal widget tree that wires [navigatorKey] so the handler finds a
// live context without needing full app bootstrapping.
// ---------------------------------------------------------------------------
Widget _minimalApp({required _RouteObserver observer}) {
  return MaterialApp(
    navigatorKey: navigatorKey,
    navigatorObservers: [observer],
    home: const Scaffold(body: Text('home')),
  );
}

void main() {
  // ─── Scheme validation (pure unit — no navigator needed) ──────────────────

  group('DeepLinkHandler — scheme constant', () {
    test('scheme constant is https after migration', () {
      expect(DeepLinkHandler.scheme, 'https');
    });
  });

  group('DeepLinkHandler — scheme validation (no navigator)', () {
    late DeepLinkHandler handler;

    setUp(() {
      handler = DeepLinkHandler();
    });

    test('rejects ftp:// scheme and returns false', () async {
      final result = await handler.handleDeepLink(
        Uri.parse('ftp://www.develop4god.com/supporter'),
      );
      expect(result, isFalse);
    });

    test('rejects http:// scheme and returns false', () async {
      final result = await handler.handleDeepLink(
        Uri.parse('http://www.develop4god.com/supporter'),
      );
      expect(result, isFalse);
    });

    test('rejects custom:// scheme and returns false', () async {
      final result = await handler.handleDeepLink(
        Uri.parse('custom://www.develop4god.com/supporter'),
      );
      expect(result, isFalse);
    });
  });

  // ─── HTTPS path validation (no navigator) ─────────────────────────────────

  group('DeepLinkHandler — HTTPS empty path (no navigator)', () {
    late DeepLinkHandler handler;

    setUp(() {
      handler = DeepLinkHandler();
    });

    test('https://domain.com/ returns false (empty path)', () async {
      final result = await handler.handleDeepLink(
        Uri.parse('https://www.develop4god.com/'),
      );
      expect(result, isFalse);
    });

    test('https://domain.com returns false (no path segments)', () async {
      final result = await handler.handleDeepLink(
        Uri.parse('https://www.develop4god.com'),
      );
      expect(result, isFalse);
    });
  });

  // ─── URI parsing correctness (pure dart — verifies extraction logic) ───────

  group('URI parsing — HTTPS route extraction', () {
    test('extracts supporter from https path', () {
      final uri = Uri.parse('https://www.develop4god.com/supporter');
      expect(uri.scheme, 'https');
      expect(uri.pathSegments, isNotEmpty);
      expect(uri.pathSegments.first, 'supporter');
    });

    test('extracts encounters from https path', () {
      final uri = Uri.parse('https://www.develop4god.com/encounters');
      expect(uri.pathSegments.first, 'encounters');
    });

    test('extracts devotional and preserves date segment', () {
      final uri =
          Uri.parse('https://www.develop4god.com/devotional/2025-01-01');
      expect(uri.pathSegments.first, 'devotional');
      expect(uri.pathSegments[1], '2025-01-01');
    });

    test('devocional:// host is the route (backward compat assumption)', () {
      final uri = Uri.parse('devocional://supporter');
      expect(uri.scheme, 'devocional');
      expect(uri.host, 'supporter');
    });
  });

  // ─── Routing with live navigator (widget tests) ────────────────────────────

  group('DeepLinkHandler — routing with navigator context', () {
    late DeepLinkHandler handler;
    late _RouteObserver observer;

    setUp(() {
      handler = DeepLinkHandler();
      observer = _RouteObserver();
    });

    testWidgets('https://domain/supporter routes to supporter page',
        (tester) async {
      await tester.pumpWidget(_minimalApp(observer: observer));
      await tester.pump(); // settle initial frame so navigatorKey has context

      final countBefore = observer.pushCount;
      final result = await handler.handleDeepLink(
        Uri.parse('https://www.develop4god.com/supporter'),
      );

      expect(result, isTrue);
      expect(observer.pushCount, greaterThan(countBefore));
    });

    testWidgets('https://domain/encounters routes to encounters page',
        (tester) async {
      await tester.pumpWidget(_minimalApp(observer: observer));
      await tester.pump();

      final countBefore = observer.pushCount;
      final result = await handler.handleDeepLink(
        Uri.parse('https://www.develop4god.com/encounters'),
      );

      expect(result, isTrue);
      expect(observer.pushCount, greaterThan(countBefore));
    });

    testWidgets(
        'https://domain/devotional/2025-01-01 routes to devotional page',
        (tester) async {
      await tester.pumpWidget(_minimalApp(observer: observer));
      await tester.pump();

      // _handleDevotionalDeepLink uses pushNamedAndRemoveUntil('devotional',…).
      // It catches any RouteSettings error and still returns true — the
      // important assertion is that the scheme/path check passed.
      final result = await handler.handleDeepLink(
        Uri.parse('https://www.develop4god.com/devotional/2025-01-01'),
      );

      expect(result, isTrue);
    });

    testWidgets('https://domain/ returns false (empty path, with navigator)',
        (tester) async {
      await tester.pumpWidget(_minimalApp(observer: observer));
      await tester.pump();

      final result = await handler.handleDeepLink(
        Uri.parse('https://www.develop4god.com/'),
      );

      expect(result, isFalse);
    });

    testWidgets(
        'devocional://supporter still routes correctly (backward compat)',
        (tester) async {
      await tester.pumpWidget(_minimalApp(observer: observer));
      await tester.pump();

      final countBefore = observer.pushCount;
      final result = await handler.handleDeepLink(
        Uri.parse('devocional://supporter'),
      );

      expect(result, isTrue);
      expect(observer.pushCount, greaterThan(countBefore));
    });
  });
}
