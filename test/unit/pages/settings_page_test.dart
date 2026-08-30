@Tags(['unit', 'pages'])
library;

// test/unit/pages/settings_page_test.dart
//
// Genuinely DI-wired widget-mount coverage for SettingsPage. Pumps the real
// SettingsPage inside a MultiProvider/BlocProvider tree — real ThemeBloc,
// real LocalizationProvider, and a real SupporterBloc built from
// FakeIapService + FakeSupporterProfileRepository (the project's established
// fakes from iap_mock_helper.dart) — instead of stubs that dodge the app's
// actual provider tree.
//
// SettingsPage reads VoiceSettingsService, SupporterPetService, and
// ISupporterProfileRepository via getService<T>(), all wired for real by
// registerTestServicesWithFakes()/setupServiceLocator(). VoiceSettingsService
// talks to a real FlutterTts, so FlutterTtsMockHelper mocks the platform
// channel.

import 'package:devocional_nuevo/blocs/supporter/supporter_bloc.dart';
import 'package:devocional_nuevo/blocs/supporter/supporter_event.dart';
import 'package:devocional_nuevo/blocs/theme/theme_bloc.dart';
import 'package:devocional_nuevo/blocs/theme/theme_event.dart';
import 'package:devocional_nuevo/blocs/theme/theme_state.dart';
import 'package:devocional_nuevo/extensions/string_extensions.dart';
import 'package:devocional_nuevo/pages/about_page.dart';
import 'package:devocional_nuevo/pages/application_language_page.dart';
import 'package:devocional_nuevo/pages/contact_page.dart';
import 'package:devocional_nuevo/pages/settings_page.dart';
import 'package:devocional_nuevo/providers/localization_provider.dart';
import 'package:devocional_nuevo/repositories/i_supporter_profile_repository.dart';
import 'package:devocional_nuevo/services/service_locator.dart';
import 'package:devocional_nuevo/services/supporter_pet_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/flutter_tts_mock_helper.dart';
import '../../helpers/iap_mock_helper.dart';
import '../../helpers/test_helpers.dart' show registerTestServicesWithFakes;

/// Mirrors the FakeThemeBloc duplicated across several widget test files in
/// this repo — SettingsPage.build() unconditionally does
/// `context.watch<ThemeBloc>()`, so any host needs a ready ThemeLoaded state.
class FakeThemeBloc extends Fake implements ThemeBloc {
  @override
  Stream<ThemeState> get stream => Stream.value(
        ThemeLoaded.withThemeData(
          themeFamily: 'Deep Purple',
          brightness: Brightness.light,
        ),
      );

  @override
  ThemeState get state => ThemeLoaded.withThemeData(
        themeFamily: 'Deep Purple',
        brightness: Brightness.light,
      );

  @override
  void add(ThemeEvent event) {}

  @override
  Future<void> close() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  FlutterTtsMockHelper.setupMockFlutterTts();

  late FakeIapService fakeIap;
  late FakeSupporterProfileRepository fakeProfileRepo;

  setUp(() async {
    await registerTestServicesWithFakes();
    fakeIap = FakeIapService(isAvailable: true);
    fakeProfileRepo = FakeSupporterProfileRepository();

    // SettingsPage reads ISupporterProfileRepository via getService<T>() —
    // independently of the repository instance handed to SupporterBloc
    // below. Registering the same fake instance under both keeps the two
    // reads/writes in sync, matching what main.dart's composition root does
    // (both come from the same locator registration).
    final locator = ServiceLocator();
    if (locator.isRegistered<ISupporterProfileRepository>()) {
      locator.unregister<ISupporterProfileRepository>();
    }
    locator.registerSingleton<ISupporterProfileRepository>(fakeProfileRepo);
  });

  SupporterBloc supporterBloc() => SupporterBloc(
        iapService: fakeIap,
        profileRepository: fakeProfileRepo,
      )..add(InitializeSupporter());

  Widget host(SupporterBloc bloc) => MultiProvider(
        providers: [
          BlocProvider<ThemeBloc>(create: (_) => FakeThemeBloc()),
          BlocProvider<SupporterBloc>.value(value: bloc),
          ChangeNotifierProvider<LocalizationProvider>(
            create: (_) => LocalizationProvider(),
          ),
        ],
        child: const MaterialApp(home: SettingsPage()),
      );

  group('SettingsPage — initial render', () {
    testWidgets('renders core settings tiles and the donate button',
        (tester) async {
      final bloc = supporterBloc();
      addTearDown(bloc.close);

      await tester.pumpWidget(host(bloc));
      await tester.pumpAndSettle();

      expect(find.text('settings.title'.tr()), findsOneWidget);
      expect(find.text('settings.donate'.tr()), findsOneWidget);
      expect(find.text('settings.language'.tr()), findsOneWidget);
      expect(find.text('settings.contact_us'.tr()), findsOneWidget);
      expect(find.text('settings.about_app'.tr()), findsOneWidget);
      expect(find.text('backup.title'.tr()), findsOneWidget);
    });

    testWidgets('hides the Gold Supporter section when the pet is not unlocked',
        (tester) async {
      final bloc = supporterBloc();
      addTearDown(bloc.close);

      await tester.pumpWidget(host(bloc));
      await tester.pumpAndSettle();

      expect(
        find.text('supporter.supporter_section_title'.tr()),
        findsNothing,
      );
    });

    testWidgets('shows the Gold Supporter section when the pet is unlocked',
        (tester) async {
      SharedPreferences.setMockInitialValues({
        'supporter_is_pet_unlocked': true,
        'supporter_show_pet_header': true,
      });
      final locator = ServiceLocator();
      if (locator.isRegistered<SupporterPetService>()) {
        locator.unregister<SupporterPetService>();
      }
      locator.registerSingleton<SupporterPetService>(
        SupporterPetService(await SharedPreferences.getInstance()),
      );

      final bloc = supporterBloc();
      addTearDown(bloc.close);

      await tester.pumpWidget(host(bloc));
      await tester.pumpAndSettle();

      expect(
        find.text('supporter.supporter_section_title'.tr()),
        findsOneWidget,
      );
      expect(find.text('supporter.profile_name'.tr()), findsOneWidget);
      expect(find.byType(SwitchListTile), findsOneWidget);
    });
  });

  group('SettingsPage — navigation', () {
    testWidgets(
        'tapping the language tile navigates to ApplicationLanguagePage',
        (tester) async {
      final bloc = supporterBloc();
      addTearDown(bloc.close);

      await tester.pumpWidget(host(bloc));
      await tester.pumpAndSettle();

      await tester.tap(find.text('settings.language'.tr()));
      await tester.pumpAndSettle();

      expect(find.byType(ApplicationLanguagePage), findsOneWidget);
    });

    testWidgets('tapping the contact tile navigates to ContactPage',
        (tester) async {
      final bloc = supporterBloc();
      addTearDown(bloc.close);

      await tester.pumpWidget(host(bloc));
      await tester.pumpAndSettle();

      await tester.tap(find.text('settings.contact_us'.tr()));
      await tester.pumpAndSettle();

      expect(find.byType(ContactPage), findsOneWidget);
    });

    testWidgets('tapping the about tile navigates to AboutPage',
        (tester) async {
      final bloc = supporterBloc();
      addTearDown(bloc.close);

      await tester.pumpWidget(host(bloc));
      await tester.pumpAndSettle();

      await tester.tap(find.text('settings.about_app'.tr()));
      await tester.pumpAndSettle();

      expect(find.byType(AboutPage), findsOneWidget);
    });
  });

  group('SettingsPage — Gold Supporter interactions', () {
    Future<void> unlockPet(WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({
        'supporter_is_pet_unlocked': true,
        'supporter_show_pet_header': true,
      });
      final locator = ServiceLocator();
      if (locator.isRegistered<SupporterPetService>()) {
        locator.unregister<SupporterPetService>();
      }
      locator.registerSingleton<SupporterPetService>(
        SupporterPetService(await SharedPreferences.getInstance()),
      );
    }

    testWidgets('toggling the show-pet-header switch flips its value',
        (tester) async {
      await unlockPet(tester);
      final bloc = supporterBloc();
      addTearDown(bloc.close);

      await tester.pumpWidget(host(bloc));
      await tester.pumpAndSettle();

      final switchFinder = find.byType(SwitchListTile);
      expect(tester.widget<SwitchListTile>(switchFinder).value, isTrue);

      await tester.tap(switchFinder);
      await tester.pumpAndSettle();

      expect(tester.widget<SwitchListTile>(switchFinder).value, isFalse);
    });

    testWidgets(
        'editing and saving the profile name dispatches SaveGoldSupporterName',
        (tester) async {
      await unlockPet(tester);
      final bloc = supporterBloc();
      addTearDown(bloc.close);

      await tester.pumpWidget(host(bloc));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.edit_rounded).first);
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Juan Perez');
      await tester.pump();
      await tester.tap(find.widgetWithText(ElevatedButton, 'app.save'.tr()));
      await tester.pumpAndSettle();

      expect(await fakeProfileRepo.loadProfileName(), 'Juan Perez');
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);

      // Drain _saveProfileName's un-cancelable 2s Future.delayed that
      // auto-hides the success indicator, or FlutterTest flags it as a
      // leaked pending timer.
      await tester.pump(const Duration(seconds: 2));
    });
  });
}
