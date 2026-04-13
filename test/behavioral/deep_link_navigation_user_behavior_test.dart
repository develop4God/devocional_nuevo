@Tags(['behavioral', 'navigation'])
library;

// test/behavioral/deep_link_navigation_user_behavior_test.dart
//
// Migrated from integration_test/deep_link_navigation_test.dart
// Verifies that the application correctly handles deep links and navigates
// the user to the appropriate screens using the global navigator key.

import 'package:devocional_nuevo/blocs/prayer_wall/prayer_wall_bloc.dart';
import 'package:devocional_nuevo/blocs/prayer_wall/prayer_wall_state.dart';
import 'package:devocional_nuevo/blocs/supporter/supporter_bloc.dart';
import 'package:devocional_nuevo/blocs/supporter/supporter_state.dart';
import 'package:devocional_nuevo/blocs/theme/theme_bloc.dart';
import 'package:devocional_nuevo/blocs/theme/theme_state.dart';
import 'package:devocional_nuevo/main.dart';
import 'package:devocional_nuevo/pages/prayer_wall_page.dart';
import 'package:devocional_nuevo/pages/supporter_page.dart';
import 'package:devocional_nuevo/services/deep_link_handler.dart';
import 'package:devocional_nuevo/services/service_locator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import '../helpers/test_helpers.dart';

class MockSupporterBloc extends Mock implements SupporterBloc {}

class MockPrayerWallBloc extends Mock implements PrayerWallBloc {}

class MockThemeBloc extends Mock implements ThemeBloc {}

void main() {
  group('Deep Link Navigation - User Behavior Tests', () {
    late DeepLinkHandler deepLinkHandler;
    late MockSupporterBloc mockSupporterBloc;
    late MockPrayerWallBloc mockPrayerWallBloc;
    late MockThemeBloc mockThemeBloc;

    setUpAll(() async {
      // Initialize Firebase mocks only once
    });

    setUp(() async {
      await setupFirebaseMocks();
      ServiceLocator().reset();
      await registerTestServicesWithFakes();
      deepLinkHandler = getService<DeepLinkHandler>();

      mockSupporterBloc = MockSupporterBloc();
      mockPrayerWallBloc = MockPrayerWallBloc();
      mockThemeBloc = MockThemeBloc();

      // Default state stubs to avoid null errors
      when(() => mockSupporterBloc.state).thenReturn(SupporterInitial());
      when(() => mockPrayerWallBloc.state).thenReturn(PrayerWallInitial());
      when(() => mockThemeBloc.state).thenReturn(ThemeLoaded.withThemeData(
        themeFamily: 'spirit',
        brightness: Brightness.light,
      ));

      // Mock streams to avoid null stream errors
      when(() => mockSupporterBloc.stream)
          .thenAnswer((_) => Stream.fromIterable([SupporterInitial()]));
      when(() => mockPrayerWallBloc.stream)
          .thenAnswer((_) => Stream.fromIterable([PrayerWallInitial()]));
      when(() => mockThemeBloc.stream).thenAnswer((_) => Stream.fromIterable([
            ThemeLoaded.withThemeData(
              themeFamily: 'spirit',
              brightness: Brightness.light,
            )
          ]));
    });

    tearDown(() {
      ServiceLocator().reset();
    });

    Future<void> pumpTestApp(WidgetTester tester) async {
      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider<SupporterBloc>.value(value: mockSupporterBloc),
            BlocProvider<PrayerWallBloc>.value(value: mockPrayerWallBloc),
            BlocProvider<ThemeBloc>.value(value: mockThemeBloc),
          ],
          child: MaterialApp(
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

      // In pumpTestApp, we mock the devotional route to return a Scaffold with title "devotional"
      expect(find.text('Page: devotional'), findsOneWidget);
    });

    testWidgets('User taps a progress deep link', (WidgetTester tester) async {
      await pumpTestApp(tester);

      final uri = Uri.parse('devocional://progress');
      final result = await deepLinkHandler.handleDeepLink(uri);

      expect(result, isTrue);
      await tester.pumpAndSettle();
      // Current implementation only logs, doesn't push yet, but let's check what it does
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
      // Use pump instead of pumpAndSettle if there's an infinite animation
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(SupporterPage), findsOneWidget);
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
      // Use pump instead of pumpAndSettle to avoid timeout from animations or Firebase initialization issues
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(PrayerWallPage), findsOneWidget);
    });
  });
}
