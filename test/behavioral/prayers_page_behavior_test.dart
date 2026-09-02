// test/behavioral/prayers_page_behavior_test.dart

import 'package:bloc_test/bloc_test.dart';
import 'package:devocional_nuevo/blocs/prayer_bloc.dart';
import 'package:devocional_nuevo/blocs/prayer_event.dart';
import 'package:devocional_nuevo/blocs/prayer_state.dart';
import 'package:devocional_nuevo/blocs/testimony_bloc.dart';
import 'package:devocional_nuevo/blocs/testimony_event.dart';
import 'package:devocional_nuevo/blocs/testimony_state.dart';
import 'package:devocional_nuevo/blocs/thanksgiving_bloc.dart';
import 'package:devocional_nuevo/blocs/thanksgiving_event.dart';
import 'package:devocional_nuevo/blocs/thanksgiving_state.dart';
import 'package:devocional_nuevo/blocs/theme/theme_bloc.dart';
import 'package:devocional_nuevo/blocs/theme/theme_event.dart';
import 'package:devocional_nuevo/blocs/theme/theme_state.dart';
import 'package:devocional_nuevo/models/prayer_model.dart';
import 'package:devocional_nuevo/pages/prayers_page.dart';
import 'package:devocional_nuevo/services/localization_service.dart';
import 'package:devocional_nuevo/services/service_locator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import '../helpers/test_helpers.dart';

class MockLocalizationService extends Mock implements LocalizationService {}

class MockPrayerBloc extends MockBloc<PrayerEvent, PrayerState>
    implements PrayerBloc {}

class MockThanksgivingBloc
    extends MockBloc<ThanksgivingEvent, ThanksgivingState>
    implements ThanksgivingBloc {}

class MockTestimonyBloc extends MockBloc<TestimonyEvent, TestimonyState>
    implements TestimonyBloc {}

class MockThemeBloc extends MockBloc<ThemeEvent, ThemeState>
    implements ThemeBloc {}

void main() {
  late MockPrayerBloc prayerBloc;
  late MockThanksgivingBloc thanksgivingBloc;
  late MockTestimonyBloc testimonyBloc;
  late MockThemeBloc themeBloc;
  late MockLocalizationService mockLocalizationService;

  setUpAll(() {
    registerFallbackValue(LoadPrayers());
    registerFallbackValue(LoadThanksgivings());
    registerFallbackValue(LoadTestimonies());
    registerFallbackValue(InitializeThemeDefaults());
  });

  setUp(() async {
    await registerTestServicesWithFakes();

    mockLocalizationService = MockLocalizationService();
    // Default translations - Unique strings to avoid ambiguity
    when(() => mockLocalizationService.translate(any(), any()))
        .thenAnswer((invocation) {
      return 'T';
    });

    when(() => mockLocalizationService.translate(any()))
        .thenAnswer((invocation) {
      final key = invocation.positionalArguments[0] as String;
      if (key == 'prayer.no_active_prayers_title') return 'NoActiveTitle';
      if (key == 'prayer.no_active_prayers_description') return 'NoActiveDesc';
      if (key == 'prayer.prayer') return 'ChoicePrayer';
      if (key == 'prayer.create_prayer') return 'CreateBtn';
      if (key == 'prayer.update_prayer') return 'UpdateBtn';
      if (key == 'prayer.mark_as_answered') return 'MenuAnswer';
      if (key == 'prayer.confirm_answered') return 'ConfirmBtn';
      if (key == 'prayer.no_answered_prayers_title') return 'NoAnsweredTitle';
      if (key == 'prayer.active') return 'TabActive';
      if (key == 'prayer.answered_prayers') return 'TabAnswered';
      if (key == 'prayer.prayers') return 'TabPrayers';
      if (key == 'thanksgiving.thanksgivings') return 'TabThanks';
      if (key == 'testimony.testimonies') return 'TabTestimonies';
      if (key == 'prayer.my_prayers') return 'PageTitle';
      if (key == 'prayer.add_prayer_thanksgiving_hint') return 'AddHint';
      if (key == 'devotionals.choose_option') return 'ChooseOption';
      if (key == 'prayer.new_prayer') return 'NewPrayerTitle';
      if (key == 'prayer.edit_prayer') return 'EditPrayerTitle';
      if (key == 'prayer.new_prayer_description') return 'NewPrayerDesc';
      if (key == 'prayer.answer_prayer') return 'AnswerModalTitle';
      if (key == 'prayer.answer_prayer_description') return 'AnswerModalDesc';
      if (key == 'prayer.created') return 'Created:';
      if (key == 'prayer.days_old_single') return '1 day';
      if (key == 'prayer.days_old_plural') return '2 days';
      if (key == 'app.delete') return 'MenuDelete';
      if (key == 'prayer.delete_prayer') return 'DeleteDialogTitle';
      if (key == 'prayer.delete_confirmation') return 'DeleteConfirm';
      if (key == 'app.cancel') return 'CancelBtn';
      if (key == 'prayer.prayer_marked_answered') return 'MarkedSuccess';
      if (key == 'thanksgiving.no_thanksgivings_title') return 'NoThanksTitle';
      if (key == 'testimony.no_testimonies_title') return 'NoTestimoniesTitle';
      if (key == 'thanksgiving.thankful_for') return 'ThankfulFor';
      if (key == 'testimony.my_testimony') return 'MyTestimony';
      if (key == 'thanksgiving.thanksgiving') return 'ChoiceThanks';
      if (key == 'testimony.testimony') return 'ChoiceTestimony';
      if (key == 'prayer.retry') return 'RetryBtn';
      if (key == 'prayer.mark_as_active') return 'MenuMarkActive';
      if (key == 'prayer.answered') return 'AnsweredOn';

      return key;
    });

    final locator = ServiceLocator();
    locator.unregister<LocalizationService>();
    locator.registerSingleton<LocalizationService>(mockLocalizationService);

    prayerBloc = MockPrayerBloc();
    thanksgivingBloc = MockThanksgivingBloc();
    testimonyBloc = MockTestimonyBloc();
    themeBloc = MockThemeBloc();

    // Default states
    when(() => prayerBloc.state).thenReturn(PrayerLoaded(prayers: []));
    when(() => thanksgivingBloc.state)
        .thenReturn(ThanksgivingLoaded(thanksgivings: []));
    when(() => testimonyBloc.state)
        .thenReturn(TestimonyLoaded(testimonies: []));
    when(() => themeBloc.state).thenReturn(
      ThemeLoaded.withThemeData(
        themeFamily: 'default',
        brightness: Brightness.light,
      ),
    );
  });

  Widget createWidgetUnderTest() {
    return MultiBlocProvider(
      providers: [
        BlocProvider<PrayerBloc>.value(value: prayerBloc),
        BlocProvider<ThanksgivingBloc>.value(value: thanksgivingBloc),
        BlocProvider<TestimonyBloc>.value(value: testimonyBloc),
        BlocProvider<ThemeBloc>.value(value: themeBloc),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData.light(),
        home: const PrayersPage(),
      ),
    );
  }

  testWidgets('PrayersPage shows empty state message for active prayers',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump();

    expect(find.text('NoActiveTitle'), findsOneWidget);
  });

  testWidgets('PrayersPage workflow: Add a prayer flow', (tester) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump();

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    await tester.tap(find.text('ChoicePrayer'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byType(TextField),
      'Lord, help me with this task today',
    );

    when(() => prayerBloc.add(any(that: isA<AddPrayer>())))
        .thenAnswer((_) async {});

    final createButton = find.text('CreateBtn');
    await tester.tap(createButton);
    await tester.pumpAndSettle();

    verify(() => prayerBloc.add(any(that: isA<AddPrayer>()))).called(1);
  });

  testWidgets('PrayersPage workflow: Mark a prayer as answered',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final prayer = Prayer(
      id: '1',
      text: 'Test Prayer',
      createdDate: DateTime.now(),
      status: PrayerStatus.active,
    );

    when(() => prayerBloc.state).thenReturn(PrayerLoaded(prayers: [prayer]));

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump();

    final optionsButton = find.byIcon(Icons.more_vert);
    await tester.tap(optionsButton);
    await tester.pumpAndSettle();

    await tester.tap(find.text('MenuAnswer'));
    await tester.pumpAndSettle();

    final confirmButton = find.text('ConfirmBtn');
    await tester.tap(confirmButton);
    await tester.pumpAndSettle();

    verify(() => prayerBloc.add(any(that: isA<MarkPrayerAsAnswered>())))
        .called(1);
  });

  testWidgets('PrayersPage workflow: Navigate and Add Thanksgiving',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump();

    // 1. Switch to Thanksgivings tab
    await tester.tap(find.text('☺️'));
    await tester.pumpAndSettle();
    expect(find.text('NoThanksTitle'), findsOneWidget);

    // 2. Add Thanksgiving
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    await tester.tap(find.text('ChoiceThanks'));
    await tester.pumpAndSettle();

    await tester.enterText(
        find.byType(TextField), 'Thank you Lord for this day');

    when(() => thanksgivingBloc.add(any(that: isA<AddThanksgiving>())))
        .thenAnswer((_) async {});

    // Assuming AddThanksgivingModal has a Create button
    // It's likely similar to AddPrayerModal but maybe different text?
    // Let's use generic text finder if needed or check its file.
    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();

    verify(() => thanksgivingBloc.add(any(that: isA<AddThanksgiving>())))
        .called(1);
  });

  testWidgets('PrayersPage workflow: Navigate and Add Testimony',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump();

    // 1. Switch to Testimonies tab
    await tester.tap(find.text('✨'));
    await tester.pumpAndSettle();
    expect(find.text('NoTestimoniesTitle'), findsOneWidget);

    // 2. Add Testimony
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    await tester.tap(find.text('ChoiceTestimony'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'God did a miracle today!');

    when(() => testimonyBloc.add(any(that: isA<AddTestimony>())))
        .thenAnswer((_) async {});

    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();

    verify(() => testimonyBloc.add(any(that: isA<AddTestimony>()))).called(1);
  });

  testWidgets('PrayersPage workflow: Mark an answered prayer as active',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final prayer = Prayer(
      id: '1',
      text: 'Test Prayer',
      createdDate: DateTime.now(),
      status: PrayerStatus.answered,
      answeredDate: DateTime.now(),
    );

    when(() => prayerBloc.state).thenReturn(PrayerLoaded(prayers: [prayer]));

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump();

    await tester.tap(find.text('TabAnswered'));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();

    when(() => prayerBloc.add(any(that: isA<MarkPrayerAsActive>())))
        .thenAnswer((_) async {});

    await tester.tap(find.text('MenuMarkActive'));
    await tester.pumpAndSettle();

    verify(() => prayerBloc.add(any(that: isA<MarkPrayerAsActive>())))
        .called(1);
  });

  testWidgets('PrayersPage workflow: Delete a prayer via confirmation dialog',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final prayer = Prayer(
      id: '1',
      text: 'Test Prayer',
      createdDate: DateTime.now(),
      status: PrayerStatus.active,
    );

    when(() => prayerBloc.state).thenReturn(PrayerLoaded(prayers: [prayer]));

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump();

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();

    await tester.tap(find.text('MenuDelete'));
    await tester.pumpAndSettle();

    expect(find.text('DeleteDialogTitle'), findsOneWidget);

    when(() => prayerBloc.add(any(that: isA<DeletePrayer>())))
        .thenAnswer((_) async {});

    await tester.tap(find.text('MenuDelete').last);
    await tester.pumpAndSettle();

    verify(() => prayerBloc.add(any(that: isA<DeletePrayer>()))).called(1);
  });

  testWidgets('PrayersPage shows error state and retries on tap',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    when(() => prayerBloc.state).thenReturn(PrayerError('Load failed'));

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump();

    expect(find.text('Load failed'), findsOneWidget);

    when(() => prayerBloc.add(any(that: isA<RefreshPrayers>())))
        .thenAnswer((_) async {});

    await tester.tap(find.text('RetryBtn'));
    await tester.pumpAndSettle();

    verify(() => prayerBloc.add(any(that: isA<RefreshPrayers>()))).called(1);
  });
}
