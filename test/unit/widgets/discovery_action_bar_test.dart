@Tags(['unit', 'widgets'])
library;

import 'package:devocional_nuevo/blocs/prayer_bloc.dart';
import 'package:devocional_nuevo/models/devocional_model.dart';
import 'package:devocional_nuevo/widgets/discovery_action_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/test_helpers.dart';

void main() {
  setUpAll(() {
    PathProviderPlatform.instance = MockPathProviderPlatform();
  });

  group('DiscoveryActionBar Widget Tests', () {
    late PrayerBloc prayerBloc;
    late Devocional testDevocional;

    setUp(() {
      TestWidgetsFlutterBinding.ensureInitialized();
      SharedPreferences.setMockInitialValues({});
      registerTestServices();
      prayerBloc = PrayerBloc();

      testDevocional = Devocional(
        id: 'test-devocional-1',
        versiculo: 'John 3:16',
        reflexion: 'For God so loved the world...',
        paraMeditar: [],
        oracion: 'Thank you Lord',
        date: DateTime.now(),
      );
    });

    tearDown(() {
      prayerBloc.close();
    });

    Widget createWidgetUnderTest({
      Devocional? devocional,
      VoidCallback? onMarkComplete,
      bool isComplete = false,
      VoidCallback? onPlayPause,
      bool isPlaying = false,
      VoidCallback? onNext,
      VoidCallback? onPrevious,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: BlocProvider<PrayerBloc>.value(
            value: prayerBloc,
            child: DiscoveryActionBar(
              devocional: devocional ?? testDevocional,
              onMarkComplete: onMarkComplete,
              isComplete: isComplete,
              onPlayPause: onPlayPause,
              isPlaying: isPlaying,
              onNext: onNext,
              onPrevious: onPrevious,
            ),
          ),
        ),
      );
    }

    testWidgets('renders without errors', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.byType(DiscoveryActionBar), findsOneWidget);
    });

    testWidgets('displays required action buttons',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Check for share button
      expect(find.byIcon(Icons.share), findsOneWidget);

      // Check for play button
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);

      // Check for add to prayers button
      expect(find.byIcon(Icons.favorite_border), findsOneWidget);

      // Check for mark complete button
      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
    });

    testWidgets('shows play icon when not playing',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        createWidgetUnderTest(isPlaying: false),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
      expect(find.byIcon(Icons.pause), findsNothing);
    });

    testWidgets('shows pause icon when playing', (WidgetTester tester) async {
      await tester.pumpWidget(
        createWidgetUnderTest(isPlaying: true),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.pause), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow), findsNothing);
    });

    testWidgets('shows check_circle when complete',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        createWidgetUnderTest(isComplete: true),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.check_circle), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_outline), findsNothing);
    });

    testWidgets('shows check_circle_outline when not complete',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        createWidgetUnderTest(isComplete: false),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsNothing);
    });

    testWidgets('shows navigation buttons when provided',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        createWidgetUnderTest(
          onNext: () {},
          onPrevious: () {},
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.arrow_back_ios), findsOneWidget);
      expect(find.byIcon(Icons.arrow_forward_ios), findsOneWidget);
    });

    testWidgets('hides navigation buttons when not provided',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.arrow_back_ios), findsNothing);
      expect(find.byIcon(Icons.arrow_forward_ios), findsNothing);
    });

    testWidgets('invokes onMarkComplete callback when tapped',
        (WidgetTester tester) async {
      bool callbackInvoked = false;

      await tester.pumpWidget(
        createWidgetUnderTest(
          onMarkComplete: () {
            callbackInvoked = true;
          },
        ),
      );
      await tester.pumpAndSettle();

      // Tap the mark complete button
      await tester.tap(find.byIcon(Icons.check_circle_outline));
      await tester.pumpAndSettle();

      expect(callbackInvoked, isTrue);
    });

    testWidgets('invokes onPlayPause callback when tapped',
        (WidgetTester tester) async {
      bool callbackInvoked = false;

      await tester.pumpWidget(
        createWidgetUnderTest(
          onPlayPause: () {
            callbackInvoked = true;
          },
        ),
      );
      await tester.pumpAndSettle();

      // Tap the play button
      await tester.tap(find.byIcon(Icons.play_arrow));
      await tester.pumpAndSettle();

      expect(callbackInvoked, isTrue);
    });

    testWidgets('invokes onNext callback when tapped',
        (WidgetTester tester) async {
      bool callbackInvoked = false;

      await tester.pumpWidget(
        createWidgetUnderTest(
          onNext: () {
            callbackInvoked = true;
          },
        ),
      );
      await tester.pumpAndSettle();

      // Tap the next button
      await tester.tap(find.byIcon(Icons.arrow_forward_ios));
      await tester.pumpAndSettle();

      expect(callbackInvoked, isTrue);
    });

    testWidgets('invokes onPrevious callback when tapped',
        (WidgetTester tester) async {
      bool callbackInvoked = false;

      await tester.pumpWidget(
        createWidgetUnderTest(
          onPrevious: () {
            callbackInvoked = true;
          },
        ),
      );
      await tester.pumpAndSettle();

      // Tap the previous button
      await tester.tap(find.byIcon(Icons.arrow_back_ios));
      await tester.pumpAndSettle();

      expect(callbackInvoked, isTrue);
    });

    testWidgets('handles action buttons when callbacks are null',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        createWidgetUnderTest(
          onMarkComplete: null,
          onPlayPause: null,
        ),
      );
      await tester.pumpAndSettle();

      // Should still render without errors
      expect(find.byType(DiscoveryActionBar), findsOneWidget);
    });

    testWidgets('all buttons are tappable', (WidgetTester tester) async {
      await tester.pumpWidget(
        createWidgetUnderTest(
          onMarkComplete: () {},
          onPlayPause: () {},
          onNext: () {},
          onPrevious: () {},
        ),
      );
      await tester.pumpAndSettle();

      // Find all ElevatedButton widgets
      final buttons = find.byType(ElevatedButton);
      expect(buttons, findsWidgets);

      // Verify buttons are enabled (can tap them without errors)
      for (var i = 0; i < tester.widgetList(buttons).length; i++) {
        final button = tester.widget<ElevatedButton>(buttons.at(i));
        expect(button.onPressed, isNotNull);
      }
    });
  });
}
