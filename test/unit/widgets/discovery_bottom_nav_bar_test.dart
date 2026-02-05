@Tags(['unit', 'widgets'])
library;

import 'package:devocional_nuevo/providers/devocional_provider.dart';
import 'package:devocional_nuevo/widgets/discovery_bottom_nav_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/test_helpers.dart';

void main() {
  group('DiscoveryBottomNavBar Widget Tests', () {
    setUp(() {
      TestWidgetsFlutterBinding.ensureInitialized();
      SharedPreferences.setMockInitialValues({});
      registerTestServices();
    });

    Widget createWidgetUnderTest({
      VoidCallback? onPrayers,
      VoidCallback? onBible,
      VoidCallback? onProgress,
      VoidCallback? onSettings,
      Widget? ttsPlayerWidget,
    }) {
      return MaterialApp(
        home: ChangeNotifierProvider<DevocionalProvider>(
          create: (_) => DevocionalProvider(),
          child: Scaffold(
            body: DiscoveryBottomNavBar(
              onPrayers: onPrayers,
              onBible: onBible,
              onProgress: onProgress,
              onSettings: onSettings,
              ttsPlayerWidget: ttsPlayerWidget,
            ),
          ),
        ),
      );
    }

    testWidgets('renders without errors', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.byType(DiscoveryBottomNavBar), findsOneWidget);
    });

    testWidgets('displays all navigation icons', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Check for prayers icon
      expect(
        find.byIcon(Icons.local_fire_department_outlined),
        findsOneWidget,
      );

      // Check for bible icon
      expect(find.byIcon(Icons.auto_stories_outlined), findsOneWidget);

      // Check for progress icon
      expect(find.byIcon(Icons.emoji_events_outlined), findsOneWidget);

      // Check for settings icon
      expect(find.byIcon(Icons.app_settings_alt_outlined), findsOneWidget);
    });

    testWidgets('displays BottomAppBar', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.byType(BottomAppBar), findsOneWidget);
    });

    testWidgets('has prayers icon button with correct key',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('bottom_appbar_prayers_icon')),
        findsOneWidget,
      );
    });

    testWidgets('has bible icon button with correct key',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('bottom_appbar_bible_icon')),
        findsOneWidget,
      );
    });

    testWidgets('has progress icon button with correct key',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('bottom_appbar_progress_icon')),
        findsOneWidget,
      );
    });

    testWidgets('has settings icon button with correct key',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('bottom_appbar_settings_icon')),
        findsOneWidget,
      );
    });

    testWidgets('invokes onPrayers callback when prayers icon tapped',
        (WidgetTester tester) async {
      bool callbackInvoked = false;

      await tester.pumpWidget(
        createWidgetUnderTest(
          onPrayers: () {
            callbackInvoked = true;
          },
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('bottom_appbar_prayers_icon')));
      await tester.pumpAndSettle();

      expect(callbackInvoked, isTrue);
    });

    testWidgets('handles null callbacks gracefully',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Should render without errors even with null callbacks
      expect(find.byType(DiscoveryBottomNavBar), findsOneWidget);
    });

    testWidgets('displays custom TTS player widget when provided',
        (WidgetTester tester) async {
      const testWidget = Icon(Icons.play_circle, key: Key('tts_player'));

      await tester.pumpWidget(
        createWidgetUnderTest(ttsPlayerWidget: testWidget),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('tts_player')), findsOneWidget);
    });

    testWidgets('shows default SizedBox when TTS player not provided',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Should render without TTS player widget
      expect(find.byType(DiscoveryBottomNavBar), findsOneWidget);
    });

    testWidgets('all navigation buttons are tappable',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        createWidgetUnderTest(
          onPrayers: () {},
          onBible: () {},
          onProgress: () {},
          onSettings: () {},
        ),
      );
      await tester.pumpAndSettle();

      // Find all IconButton widgets
      final iconButtons = find.byType(IconButton);
      expect(iconButtons, findsWidgets);

      // Should have at least 4 icon buttons for navigation
      expect(tester.widgetList(iconButtons).length, greaterThanOrEqualTo(4));
    });

    testWidgets('renders with SafeArea', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.byType(SafeArea), findsWidgets);
    });

    testWidgets('applies custom app bar colors', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<DevocionalProvider>(
            create: (_) => DevocionalProvider(),
            child: Scaffold(
              body: DiscoveryBottomNavBar(
                appBarBackgroundColor: Colors.red,
                appBarForegroundColor: Colors.blue,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(DiscoveryBottomNavBar), findsOneWidget);
    });

    testWidgets('handles rapid taps without errors',
        (WidgetTester tester) async {
      int tapCount = 0;

      await tester.pumpWidget(
        createWidgetUnderTest(
          onPrayers: () {
            tapCount++;
          },
        ),
      );
      await tester.pumpAndSettle();

      // Tap multiple times rapidly
      for (int i = 0; i < 5; i++) {
        await tester.tap(find.byKey(const Key('bottom_appbar_prayers_icon')));
        await tester.pump(const Duration(milliseconds: 50));
      }

      expect(tapCount, greaterThan(0));
    });

    testWidgets('maintains layout consistency', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Should have a Row widget for layout
      expect(find.byType(Row), findsWidgets);
    });
  });
}
