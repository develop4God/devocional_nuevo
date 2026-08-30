@Tags(['unit', 'pages'])
library;

// Regression coverage for the collapsing hero-image header on
// DevocionalesPage (see lib/pages/devocionales_page.dart, BlocBuilder branch
// around line 915). Pumps the REAL DevocionalesPage end-to-end via a real
// DevocionalesNavigationBloc backed by fake repositories registered in the
// ServiceLocator, so NavigationReady is reached exactly the way production
// does it.
//
// Covers:
//  - hero-present: SliverAppBar (pinned) renders instead of CustomAppBar,
//    the menu IconButton opens the DevocionalesDrawer (regression test for a
//    bug where it used the outer BuildContext for Scaffold.of(context) and
//    crashed — it must use the Builder-scoped innerContext instead), and the
//    DevocionalesContentWidget's own header does not render a second time.
//  - hero-absent: plain CustomAppBar renders, no SliverAppBar, and the
//    content widget's normal header does render.

import 'package:devocional_nuevo/blocs/note_bloc.dart';
import 'package:devocional_nuevo/blocs/theme/theme_bloc.dart';
import 'package:devocional_nuevo/blocs/theme/theme_state.dart';
import 'package:devocional_nuevo/controllers/audio_controller.dart';
import 'package:devocional_nuevo/models/devocional_model.dart';
import 'package:devocional_nuevo/models/devotional_note.dart';
import 'package:devocional_nuevo/pages/devocionales_page.dart';
import 'package:devocional_nuevo/providers/devocional_provider.dart';
import 'package:devocional_nuevo/repositories/devocional_repository.dart';
import 'package:devocional_nuevo/repositories/devotional_image_repository.dart';
import 'package:devocional_nuevo/repositories/i_notes_repository.dart';
import 'package:devocional_nuevo/services/service_locator.dart';
import 'package:devocional_nuevo/services/tts/i_tts_service.dart' as tts_iface;
import 'package:devocional_nuevo/widgets/devocionales/app_bar_constants.dart';
import 'package:devocional_nuevo/widgets/devocionales/devocional_header_widget.dart';
import 'package:devocional_nuevo/widgets/devocionales/devocionales_page_drawer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/flutter_tts_mock_helper.dart';
import '../../helpers/test_helpers.dart';

/// mocktail mock — DevocionalRepository is abstract, so this satisfies the
/// interface DevocionalesPage resolves via `getService<DevocionalRepository>()`.
class MockDevocionalRepository extends Mock implements DevocionalRepository {}

/// mocktail mock — DevotionalImageRepository is a concrete class (not an
/// interface), so it must be mocked the same way the bloc's own unit tests
/// do (see test/unit/blocs/devocionales_navigation_bloc_test.dart).
class MockDevotionalImageRepository extends Mock
    implements DevotionalImageRepository {}

/// DevocionalesContentWidget (rendered inside DevocionalesPage) reads a
/// NoteBloc from context — supply a minimal fake repository so NoteBloc can
/// be constructed without touching real storage.
class _FakeNotesRepository implements INotesRepository {
  @override
  Future<void> deleteNote(String devocionalId) async {}

  @override
  Future<List<DevotionalNote>> loadNotes() async => [];

  @override
  Future<void> saveNote(DevotionalNote note) async {}
}

/// Provider subclass that returns a pre-populated devotionals list without
/// running the real initializeData() network/prefs flow. DevocionalesPage's
/// initState only calls initializeData() when isLoading is false AND
/// devocionales is empty (see _initializeNavigationBloc), so a non-empty
/// override here makes the page skip straight to building its own
/// DevocionalesNavigationBloc from the ServiceLocator-registered
/// repositories above.
class _SeededDevocionalProvider extends DevocionalProvider {
  _SeededDevocionalProvider(this._seed)
      : super(
            enableAudio: false,
            devocionalRepository: MockDevocionalRepository());

  final List<Devocional> _seed;

  @override
  List<Devocional> get devocionales => _seed;

  @override
  bool isFavorite(Devocional devocional) => false;

  @override
  Future<bool> toggleFavorite(String id) async => true;
}

Devocional _buildDevocional() => Devocional(
      id: 'hero-dev-1',
      versiculo: 'Juan 3:16',
      reflexion: 'Reflexión de prueba',
      paraMeditar: const [],
      oracion: 'Oración de prueba',
      date: DateTime(2025, 1, 1),
      language: 'es',
      version: 'RVR1960',
    );

/// DevocionalesPage starts real timers via DevocionalesTracking /
/// ReadingTracker: DevocionalesTracking's 5s periodic timer is cancelled by
/// DevocionalesPage.dispose(); ReadingTracker's 1s periodic timer lives
/// inside the DevocionalProvider instance and is only cancelled by
/// DevocionalProvider.dispose() — which ChangeNotifierProvider.value() never
/// calls automatically (by design, since it doesn't own the instance), so it
/// must be disposed explicitly here. The page also starts uncancellable
/// one-shot debug/post-splash timers (the longest lasts seven seconds), so
/// the fake clock is advanced beyond that duration. Every test must call
/// this at the end (not via addTearDown — the pending-timer invariant is
/// checked before addTearDown callbacks run).
Future<void> _settleDevocionalesPage(
  WidgetTester tester,
  DevocionalProvider provider,
) async {
  await tester.pumpWidget(const SizedBox.shrink());
  provider.dispose();
  await tester.pump(const Duration(seconds: 8));
}

Future<DevocionalProvider> _pumpDevocionalesPage(
  WidgetTester tester, {
  required String? heroImageUrl,
}) async {
  await registerTestServicesWithFakes();
  FlutterTtsMockHelper.setupMockFlutterTts();
  SharedPreferences.setMockInitialValues({});

  final mockDevocionalRepository = MockDevocionalRepository();
  when(
    () => mockDevocionalRepository.findFirstUnreadDevocionalIndex(
      any(),
      any(),
    ),
  ).thenReturn(0);

  final mockImageRepository = MockDevotionalImageRepository();
  when(() => mockImageRepository.currentImageUrl).thenReturn(heroImageUrl);
  when(() => mockImageRepository.advance())
      .thenAnswer((_) async => heroImageUrl);
  when(() => mockImageRepository.pickFresh())
      .thenAnswer((_) async => heroImageUrl);

  final locator = serviceLocator;
  if (locator.isRegistered<DevocionalRepository>()) {
    locator.unregister<DevocionalRepository>();
  }
  locator.registerSingleton<DevocionalRepository>(mockDevocionalRepository);
  if (locator.isRegistered<DevotionalImageRepository>()) {
    locator.unregister<DevotionalImageRepository>();
  }
  locator.registerSingleton<DevotionalImageRepository>(mockImageRepository);

  final devocional = _buildDevocional();
  final devocionalProvider = _SeededDevocionalProvider([devocional]);

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<DevocionalProvider>.value(
          value: devocionalProvider,
        ),
        ChangeNotifierProvider<AudioController>(
          create: (_) => AudioController(getService<tts_iface.ITtsService>()),
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<ThemeBloc>(
            create: (_) => ThemeBloc()
              ..emit(
                ThemeLoaded.withThemeData(
                  themeFamily: 'Deep Purple',
                  brightness: Brightness.light,
                ),
              ),
          ),
          BlocProvider<NoteBloc>(
            create: (_) => NoteBloc(notesRepository: _FakeNotesRepository()),
          ),
        ],
        child: const MaterialApp(home: DevocionalesPage()),
      ),
    ),
  );

  // Let initState's async _initializeNavigationBloc() run: it awaits
  // nothing (provider is pre-seeded and not loading) but still crosses a
  // microtask boundary before dispatching InitializeNavigation, and the
  // bloc then emits NavigationReady synchronously from that event.
  await tester.pump();
  await tester.pump();

  return devocionalProvider;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await initializeDateFormatting('en');
  });

  group('DevocionalesPage hero image header', () {
    testWidgets(
      'hero-present: SliverAppBar renders, drawer opens via menu button, '
      'no duplicate header',
      (tester) async {
        final provider = await _pumpDevocionalesPage(
          tester,
          heroImageUrl: 'https://example.com/hero.jpg',
        );

        // SliverAppBar (pinned, inside CustomScrollView) replaces CustomAppBar.
        expect(find.byType(SliverAppBar), findsOneWidget);
        expect(find.byType(CustomScrollView), findsOneWidget);
        expect(find.byType(CustomAppBar), findsNothing);

        final sliverAppBar =
            tester.widget<SliverAppBar>(find.byType(SliverAppBar));
        expect(sliverAppBar.pinned, isTrue);

        // Exercise the sliver rather than only inspecting its configuration:
        // after the expanded hero collapses, the pinned menu must remain in
        // the toolbar at the top of the viewport.
        final menuButton = find.byIcon(Icons.menu);
        await tester.drag(find.byType(CustomScrollView), const Offset(0, -300));
        await tester.pump();
        expect(tester.getTopLeft(menuButton).dy, lessThan(100));

        // No duplicate header: DevocionalHeroSection renders its own
        // DevocionalHeaderWidget (onHeroImage:true), and
        // DevocionalesContentWidget is called with showHeader:false in this
        // branch — so exactly one header (the hero's) must exist, never two.
        expect(find.byType(DevocionalHeaderWidget), findsOneWidget);
        final headerWidget = tester.widget<DevocionalHeaderWidget>(
          find.byType(DevocionalHeaderWidget),
        );
        expect(headerWidget.onHeroImage, isTrue);

        // Regression test: tapping the menu icon must open the drawer,
        // not crash with the wrong BuildContext for Scaffold.of(context).
        // pumpAndSettle() is avoided here: DevocionalesTracking's 5s
        // criteria-check timer keeps firing indefinitely, so the pump loop
        // never observes a settled frame and pumpAndSettle() times out.
        //
        // The test surface is widened to a realistic phone width first: at
        // the default 800x600 test size, an unrelated pre-existing overflow
        // in DevocionalesDrawer's language-name row (devocionales_page_drawer
        // .dart) throws and would otherwise fail this test for a reason
        // that has nothing to do with the hero-image regression under test.
        await tester.binding.setSurfaceSize(const Size(1080, 2200));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        expect(find.byType(DevocionalesDrawer), findsNothing);
        await tester.tap(menuButton);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.byType(DevocionalesDrawer), findsOneWidget);

        await _settleDevocionalesPage(tester, provider);
      },
    );

    testWidgets(
      'hero-absent: plain CustomAppBar renders, normal header shows',
      (tester) async {
        final provider =
            await _pumpDevocionalesPage(tester, heroImageUrl: null);

        expect(find.byType(CustomAppBar), findsOneWidget);
        expect(find.byType(SliverAppBar), findsNothing);
        expect(find.byType(CustomScrollView), findsNothing);

        // showHeader defaults to true in this branch, so the content
        // widget's own header must appear.
        expect(find.byType(DevocionalHeaderWidget), findsOneWidget);

        await _settleDevocionalesPage(tester, provider);
      },
    );
  });
}
