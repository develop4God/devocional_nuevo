import 'package:devocional_nuevo/blocs/prayer_bloc.dart';
import 'package:devocional_nuevo/blocs/prayer_state.dart';
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

// Mock classes
class MockPrayerBloc extends Mock implements PrayerBloc {}

class MockThanksgivingBloc extends Mock implements ThanksgivingBloc {}

class MockThemeBloc extends Mock implements ThemeBloc {}

void main() {
  late MockPrayerBloc mockPrayerBloc;
  late MockThanksgivingBloc mockThanksgivingBloc;
  late MockThemeBloc mockThemeBloc;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    mockPrayerBloc = MockPrayerBloc();
    mockThanksgivingBloc = MockThanksgivingBloc();
    mockThemeBloc = MockThemeBloc();

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
            BlocProvider<ThemeBloc>.value(value: mockThemeBloc),
          ],
          child: const PrayersPage(),
        ),
      );
    }

    testWidgets('should display count badge for active prayers',
        (WidgetTester tester) async {
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

      await tester.pumpWidget(createWidgetUnderTest(
        prayerState: PrayerLoaded(prayers: prayers),
        thanksgivingState: ThanksgivingLoaded(thanksgivings: []),
      ));
      await tester.pumpAndSettle();

      // Verify active prayers count (5) is displayed
      expect(find.text('5'), findsOneWidget);
    });

    testWidgets('should display count badge for answered prayers',
        (WidgetTester tester) async {
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

      await tester.pumpWidget(createWidgetUnderTest(
        prayerState: PrayerLoaded(prayers: prayers),
        thanksgivingState: ThanksgivingLoaded(thanksgivings: []),
      ));
      await tester.pumpAndSettle();

      // Verify answered prayers count (3) is displayed
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('should display count badge for thanksgivings',
        (WidgetTester tester) async {
      // Create 7 thanksgivings
      final thanksgivings = List.generate(
        7,
        (i) => Thanksgiving(
          id: 'thanksgiving_$i',
          text: 'Test thanksgiving $i',
          createdDate: DateTime.now(),
        ),
      );

      await tester.pumpWidget(createWidgetUnderTest(
        prayerState: PrayerLoaded(prayers: []),
        thanksgivingState: ThanksgivingLoaded(thanksgivings: thanksgivings),
      ));
      await tester.pumpAndSettle();

      // Verify thanksgiving count (7) is displayed
      expect(find.text('7'), findsOneWidget);
    });

    testWidgets('should not display badge when count is zero',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest(
        prayerState: PrayerLoaded(prayers: []),
        thanksgivingState: ThanksgivingLoaded(thanksgivings: []),
      ));
      await tester.pumpAndSettle();

      // Verify no count badges are displayed (0 should not show)
      expect(find.text('0'), findsNothing);
    });

    testWidgets('should display 99+ for counts over 99',
        (WidgetTester tester) async {
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

      await tester.pumpWidget(createWidgetUnderTest(
        prayerState: PrayerLoaded(prayers: prayers),
        thanksgivingState: ThanksgivingLoaded(thanksgivings: []),
      ));
      await tester.pumpAndSettle();

      // Verify 99+ is displayed instead of 100
      expect(find.text('99+'), findsOneWidget);
    });

    testWidgets('should display multiple badges for different tabs',
        (WidgetTester tester) async {
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

      await tester.pumpWidget(createWidgetUnderTest(
        prayerState:
            PrayerLoaded(prayers: [...activePrayers, ...answeredPrayers]),
        thanksgivingState: ThanksgivingLoaded(thanksgivings: thanksgivings),
      ));
      await tester.pumpAndSettle();

      // Verify all counts are displayed
      expect(find.text('2'), findsOneWidget); // Active prayers
      expect(find.text('4'), findsOneWidget); // Answered prayers
      expect(find.text('6'), findsOneWidget); // Thanksgivings
    });
  });
}
