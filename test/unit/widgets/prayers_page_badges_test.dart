@Tags(['unit', 'widgets'])
library;

import 'package:devocional_nuevo/blocs/prayer_bloc.dart';
import 'package:devocional_nuevo/blocs/prayer_state.dart';
import 'package:devocional_nuevo/blocs/testimony_bloc.dart';
import 'package:devocional_nuevo/blocs/testimony_state.dart';
import 'package:devocional_nuevo/blocs/thanksgiving_bloc.dart';
import 'package:devocional_nuevo/blocs/thanksgiving_state.dart';
import 'package:devocional_nuevo/blocs/theme/theme_bloc.dart';
import 'package:devocional_nuevo/blocs/theme/theme_state.dart';
import 'package:devocional_nuevo/models/prayer_model.dart';
import 'package:devocional_nuevo/models/thanksgiving_model.dart';
import 'package:devocional_nuevo/pages/prayers_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/test_helpers.dart';

// Mock classes

class MockPrayerBloc extends Mock implements PrayerBloc {}

class MockThanksgivingBloc extends Mock implements ThanksgivingBloc {}

class MockTestimonyBloc extends Mock implements TestimonyBloc {}

class MockThemeBloc extends Mock implements ThemeBloc {}

void main() {
  late MockPrayerBloc mockPrayerBloc;
  late MockThanksgivingBloc mockThanksgivingBloc;
  late MockTestimonyBloc mockTestimonyBloc;
  late MockThemeBloc mockThemeBloc;

  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    registerTestServices();
    mockPrayerBloc = MockPrayerBloc();
    mockThanksgivingBloc = MockThanksgivingBloc();
    mockTestimonyBloc = MockTestimonyBloc();
    mockThemeBloc = MockThemeBloc();

    // Default testimony state
    when(() => mockTestimonyBloc.state)
        .thenReturn(TestimonyLoaded(testimonies: []));
    when(() => mockTestimonyBloc.stream).thenAnswer((_) => Stream.empty());

    // Default theme state
    when(() => mockThemeBloc.state).thenReturn(
      ThemeLoaded(
        themeFamily: 'Deep Purple',
        brightness: Brightness.light,
        themeData: ThemeData.light(),
      ),
    );
    when(() => mockThemeBloc.stream).thenAnswer((_) => Stream.empty());
  });

  group('Prayers Page Count Badges', () {
    Widget createWidgetUnderTest({
      required PrayerState prayerState,
      required ThanksgivingState thanksgivingState,
    }) {
      when(() => mockPrayerBloc.state).thenReturn(prayerState);
      when(() => mockPrayerBloc.stream).thenAnswer((_) => Stream.empty());

      when(() => mockThanksgivingBloc.state).thenReturn(thanksgivingState);
      when(() => mockThanksgivingBloc.stream).thenAnswer((_) => Stream.empty());

      return MaterialApp(
        home: MultiBlocProvider(
          providers: [
            BlocProvider<PrayerBloc>.value(value: mockPrayerBloc),
            BlocProvider<ThanksgivingBloc>.value(value: mockThanksgivingBloc),
            BlocProvider<TestimonyBloc>.value(value: mockTestimonyBloc),
            BlocProvider<ThemeBloc>.value(value: mockThemeBloc),
          ],
          child: const PrayersPage(),
        ),
      );
    }

    testWidgets('should display count badge for active prayers', (
      WidgetTester tester,
    ) async {
      // Create prayers list with 5 active prayers
      final prayers = List.generate(
        5,
        (i) => Prayer(
          id: 'prayer_$i',
          text: 'Test prayer $i',
          createdDate: DateTime.now(),
          status: PrayerStatus.active,
        ),
      );

      await tester.pumpWidget(
        createWidgetUnderTest(
          prayerState: PrayerLoaded(prayers: prayers),
          thanksgivingState: ThanksgivingLoaded(thanksgivings: []),
        ),
      );
      await tester.pumpAndSettle();

      // Verify active prayers count (5) is displayed
      expect(find.text('5'), findsOneWidget);

      // Wait for AnimatedFabWithText timer to complete
      await tester.pump(const Duration(seconds: 4));
    });

    testWidgets('should display count badge for answered prayers', (
      WidgetTester tester,
    ) async {
      // Create prayers list with 3 answered prayers
      final prayers = List.generate(
        3,
        (i) => Prayer(
          id: 'prayer_$i',
          text: 'Test prayer $i',
          createdDate: DateTime.now(),
          status: PrayerStatus.answered,
          answeredDate: DateTime.now(),
        ),
      );

      await tester.pumpWidget(
        createWidgetUnderTest(
          prayerState: PrayerLoaded(prayers: prayers),
          thanksgivingState: ThanksgivingLoaded(thanksgivings: []),
        ),
      );
      await tester.pumpAndSettle();

      // Verify answered prayers count (3) is displayed
      expect(find.text('3'), findsOneWidget);

      // Wait for AnimatedFabWithText timer to complete
      await tester.pump(const Duration(seconds: 4));
    });

    testWidgets('should display count badge for thanksgivings', (
      WidgetTester tester,
    ) async {
      // Create 7 thanksgivings
      final thanksgivings = List.generate(
        7,
        (i) => Thanksgiving(
          id: 'thanksgiving_$i',
          text: 'Test thanksgiving $i',
          createdDate: DateTime.now(),
        ),
      );

      await tester.pumpWidget(
        createWidgetUnderTest(
          prayerState: PrayerLoaded(prayers: []),
          thanksgivingState: ThanksgivingLoaded(thanksgivings: thanksgivings),
        ),
      );
      await tester.pumpAndSettle();

      // Verify thanksgiving count (7) is displayed
      expect(find.text('7'), findsOneWidget);

      // Wait for AnimatedFabWithText timer to complete
      await tester.pump(const Duration(seconds: 4));
    });

    testWidgets('should not display badge when count is zero', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        createWidgetUnderTest(
          prayerState: PrayerLoaded(prayers: []),
          thanksgivingState: ThanksgivingLoaded(thanksgivings: []),
        ),
      );
      await tester.pumpAndSettle();

      // Verify no count badges are displayed (0 should not show)
      expect(find.text('0'), findsNothing);

      // Wait for AnimatedFabWithText timer to complete
      await tester.pump(const Duration(seconds: 4));
    });

    testWidgets('should display actual count for counts over 99', (
      WidgetTester tester,
    ) async {
      // Create 100 active prayers
      final prayers = List.generate(
        100,
        (i) => Prayer(
          id: 'prayer_$i',
          text: 'Test prayer $i',
          createdDate: DateTime.now(),
          status: PrayerStatus.active,
        ),
      );

      await tester.pumpWidget(
        createWidgetUnderTest(
          prayerState: PrayerLoaded(prayers: prayers),
          thanksgivingState: ThanksgivingLoaded(thanksgivings: []),
        ),
      );
      await tester.pumpAndSettle();

      // Verify actual count is displayed instead of 99+
      expect(find.text('100'), findsOneWidget);
      expect(find.text('99+'), findsNothing);

      // Wait for AnimatedFabWithText timer to complete
      await tester.pump(const Duration(seconds: 4));
    });

    testWidgets('should display exact count for 150 prayers', (
      WidgetTester tester,
    ) async {
      // Create 150 active prayers - realistic scenario for active user
      final prayers = List.generate(
        150,
        (i) => Prayer(
          id: 'prayer_$i',
          text: 'Test prayer $i',
          createdDate: DateTime.now(),
          status: PrayerStatus.active,
        ),
      );

      await tester.pumpWidget(
        createWidgetUnderTest(
          prayerState: PrayerLoaded(prayers: prayers),
          thanksgivingState: ThanksgivingLoaded(thanksgivings: []),
        ),
      );
      await tester.pumpAndSettle();

      // Verify exact count is displayed
      expect(find.text('150'), findsOneWidget);

      // Wait for AnimatedFabWithText timer to complete
      await tester.pump(const Duration(seconds: 4));
    });

    testWidgets('should display exact count for 250 thanksgivings', (
      WidgetTester tester,
    ) async {
      // Create 250 thanksgivings - power user scenario
      final thanksgivings = List.generate(
        250,
        (i) => Thanksgiving(
          id: 'thanksgiving_$i',
          text: 'Test thanksgiving $i',
          createdDate: DateTime.now(),
        ),
      );

      await tester.pumpWidget(
        createWidgetUnderTest(
          prayerState: PrayerLoaded(prayers: []),
          thanksgivingState: ThanksgivingLoaded(thanksgivings: thanksgivings),
        ),
      );
      await tester.pumpAndSettle();

      // Verify exact count is displayed
      expect(find.text('250'), findsOneWidget);

      // Wait for AnimatedFabWithText timer to complete
      await tester.pump(const Duration(seconds: 4));
    });

    testWidgets('should display exact count for large numbers (500+)', (
      WidgetTester tester,
    ) async {
      // Create 500 answered prayers - long-term user scenario
      final prayers = List.generate(
        500,
        (i) => Prayer(
          id: 'prayer_$i',
          text: 'Test prayer $i',
          createdDate: DateTime.now(),
          status: PrayerStatus.answered,
          answeredDate: DateTime.now(),
        ),
      );

      await tester.pumpWidget(
        createWidgetUnderTest(
          prayerState: PrayerLoaded(prayers: prayers),
          thanksgivingState: ThanksgivingLoaded(thanksgivings: []),
        ),
      );
      await tester.pumpAndSettle();

      // Verify exact count is displayed for large numbers
      expect(find.text('500'), findsOneWidget);

      // Wait for AnimatedFabWithText timer to complete
      await tester.pump(const Duration(seconds: 4));
    });

    testWidgets('should display multiple badges for different tabs', (
      WidgetTester tester,
    ) async {
      // Create mixed prayers and thanksgivings
      final activePrayers = List.generate(
        2,
        (i) => Prayer(
          id: 'active_$i',
          text: 'Active prayer $i',
          createdDate: DateTime.now(),
          status: PrayerStatus.active,
        ),
      );

      final answeredPrayers = List.generate(
        4,
        (i) => Prayer(
          id: 'answered_$i',
          text: 'Answered prayer $i',
          createdDate: DateTime.now(),
          status: PrayerStatus.answered,
          answeredDate: DateTime.now(),
        ),
      );

      final thanksgivings = List.generate(
        6,
        (i) => Thanksgiving(
          id: 'thanksgiving_$i',
          text: 'Test thanksgiving $i',
          createdDate: DateTime.now(),
        ),
      );

      await tester.pumpWidget(
        createWidgetUnderTest(
          prayerState: PrayerLoaded(
            prayers: [...activePrayers, ...answeredPrayers],
          ),
          thanksgivingState: ThanksgivingLoaded(thanksgivings: thanksgivings),
        ),
      );
      await tester.pumpAndSettle();

      // Verify all counts are displayed
      expect(find.text('2'), findsOneWidget); // Active prayers
      expect(find.text('4'), findsOneWidget); // Answered prayers
      expect(find.text('6'), findsOneWidget); // Thanksgivings

      // Wait for AnimatedFabWithText timer to complete
      await tester.pump(const Duration(seconds: 4));
    });
  });
}
