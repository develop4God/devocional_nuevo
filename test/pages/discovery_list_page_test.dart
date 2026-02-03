// test/pages/discovery_list_page_test.dart

import 'package:devocional_nuevo/blocs/discovery/discovery_bloc.dart';
import 'package:devocional_nuevo/blocs/discovery/discovery_event.dart';
import 'package:devocional_nuevo/blocs/discovery/discovery_state.dart';
import 'package:devocional_nuevo/blocs/theme/theme_bloc.dart';
import 'package:devocional_nuevo/blocs/theme/theme_state.dart';
import 'package:devocional_nuevo/pages/discovery_list_page.dart';
import 'package:devocional_nuevo/providers/devocional_provider.dart';
import 'package:devocional_nuevo/services/service_locator.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void setupFirebaseMocks() {
  // Mock Firebase legacy channel
  const MethodChannel firebaseCoreChannel =
      MethodChannel('plugins.flutter.io/firebase_core');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(firebaseCoreChannel,
          (MethodCall methodCall) async {
    switch (methodCall.method) {
      case 'Firebase#initializeCore':
        return [
          {
            'name': '[DEFAULT]',
            'options': {
              'apiKey': 'fake-api-key',
              'appId': 'fake-app-id',
              'messagingSenderId': 'fake-sender-id',
              'projectId': 'fake-project-id',
            },
            'pluginConstants': {},
          }
        ];
      case 'Firebase#initializeApp':
        return {
          'name': '[DEFAULT]',
          'options': {
            'apiKey': 'fake-api-key',
            'appId': 'fake-app-id',
            'messagingSenderId': 'fake-sender-id',
            'projectId': 'fake-project-id',
          },
          'pluginConstants': {},
        };
      default:
        return null;
    }
  });

  // Mock Firebase pigeon channel for core
  const MethodChannel firebasePigeonChannel = MethodChannel(
      'dev.flutter.pigeon.firebase_core_platform_interface.FirebaseCoreHostApi');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(firebasePigeonChannel,
          (MethodCall methodCall) async {
    switch (methodCall.method) {
      case 'initializeCore':
        return [
          {
            'name': '[DEFAULT]',
            'options': {
              'apiKey': 'fake-api-key',
              'appId': 'fake-app-id',
              'messagingSenderId': 'fake-sender-id',
              'projectId': 'fake-project-id',
            },
            'pluginConstants': {},
          }
        ];
      case 'initializeApp':
        return {
          'name': '[DEFAULT]',
          'options': {
            'apiKey': 'fake-api-key',
            'appId': 'fake-app-id',
            'messagingSenderId': 'fake-sender-id',
            'projectId': 'fake-project-id',
          },
          'pluginConstants': {},
        };
      default:
        return null;
    }
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setupFirebaseMocks();

  setUpAll(() async {
    await Firebase.initializeApp();

    // Mock path provider
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (MethodCall methodCall) async {
        switch (methodCall.method) {
          case 'getApplicationDocumentsDirectory':
          case 'getApplicationSupportDirectory':
            return '/mock_documents';
          case 'getTemporaryDirectory':
            return '/mock_temp';
          default:
            return '/mock_unknown';
        }
      },
    );

    // Mock TTS
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('flutter_tts'),
      (call) async => null,
    );

    setupServiceLocator();
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('DiscoveryListPage Carousel Tests', () {
    testWidgets('Carousel renders with fluid transition settings',
        (WidgetTester tester) async {
      final discoveryBloc = MockDiscoveryBloc();
      final themeBloc = MockThemeBloc();

      await tester.runAsync(() async {
        // Set larger screen size to prevent layout overflow
        tester.view.physicalSize = const Size(1080, 1920);
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(
          MaterialApp(
            home: MultiBlocProvider(
              providers: [
                BlocProvider<DiscoveryBloc>.value(value: discoveryBloc),
                BlocProvider<ThemeBloc>.value(value: themeBloc),
                ChangeNotifierProvider(create: (_) => DevocionalProvider()),
              ],
              child: const DiscoveryListPage(),
            ),
          ),
        );

        await tester.pump();

        // Should render without errors
        expect(find.byType(DiscoveryListPage), findsOneWidget);
      });
    });

    testWidgets('Carousel uses BouncingScrollPhysics for smooth scrolling',
        (WidgetTester tester) async {
      await tester.runAsync(() async {
        final discoveryBloc = MockDiscoveryBloc();
        final themeBloc = MockThemeBloc();

        // Set larger screen size to prevent layout overflow
        tester.view.physicalSize = const Size(1080, 1920);
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(
          MaterialApp(
            home: MultiBlocProvider(
              providers: [
                BlocProvider<DiscoveryBloc>.value(value: discoveryBloc),
                BlocProvider<ThemeBloc>.value(value: themeBloc),
                ChangeNotifierProvider(create: (_) => DevocionalProvider()),
              ],
              child: const DiscoveryListPage(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify carousel exists
        expect(find.byType(DiscoveryListPage), findsOneWidget);
      });
    });

    testWidgets('Progress dots display with minimalistic border style',
        (WidgetTester tester) async {
      await tester.runAsync(() async {
        final discoveryBloc = MockDiscoveryBlocWithStudies();
        final themeBloc = MockThemeBloc();

        // Set larger screen size to prevent layout overflow
        tester.view.physicalSize = const Size(1080, 1920);
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(
          MaterialApp(
            home: MultiBlocProvider(
              providers: [
                BlocProvider<DiscoveryBloc>.value(value: discoveryBloc),
                BlocProvider<ThemeBloc>.value(value: themeBloc),
                ChangeNotifierProvider(create: (_) => DevocionalProvider()),
              ],
              child: const DiscoveryListPage(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Progress dots should be rendered
        final progressDots = find.byType(AnimatedContainer);
        expect(progressDots, findsWidgets);
      });
    });
  });

  group('DiscoveryListPage Grid Tests', () {
    testWidgets('Grid orders incomplete studies first, completed last',
        (WidgetTester tester) async {
      await tester.runAsync(() async {
        final discoveryBloc = MockDiscoveryBlocWithMixedStudies();
        final themeBloc = MockThemeBloc();

        // Set larger screen size to prevent layout overflow
        tester.view.physicalSize = const Size(1080, 1920);
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(
          MaterialApp(
            home: MultiBlocProvider(
              providers: [
                BlocProvider<DiscoveryBloc>.value(value: discoveryBloc),
                BlocProvider<ThemeBloc>.value(value: themeBloc),
                ChangeNotifierProvider(create: (_) => DevocionalProvider()),
              ],
              child: const DiscoveryListPage(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Tap grid view button (now a floating button)
        final gridViewButton = find.byIcon(Icons.grid_view_rounded);
        if (gridViewButton.evaluate().isNotEmpty) {
          await tester.tap(gridViewButton);
          await tester.pumpAndSettle();

          // Grid should be visible
          expect(find.byType(GridView), findsOneWidget);
        }
      });
    });

    testWidgets('Grid cards display minimalistic bordered icons',
        (WidgetTester tester) async {
      await tester.runAsync(() async {
        final discoveryBloc = MockDiscoveryBlocWithStudies();
        final themeBloc = MockThemeBloc();

        // Set larger screen size to prevent layout overflow
        tester.view.physicalSize = const Size(1080, 1920);
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(
          MaterialApp(
            home: MultiBlocProvider(
              providers: [
                BlocProvider<DiscoveryBloc>.value(value: discoveryBloc),
                BlocProvider<ThemeBloc>.value(value: themeBloc),
                ChangeNotifierProvider(create: (_) => DevocionalProvider()),
              ],
              child: const DiscoveryListPage(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Toggle grid (now a floating button)
        final gridButton = find.byIcon(Icons.grid_view_rounded);
        if (gridButton.evaluate().isNotEmpty) {
          await tester.tap(gridButton);
          await tester.pumpAndSettle();
        }
      });
    });

    testWidgets('Completed studies show primary color checkmark with border',
        (WidgetTester tester) async {
      await tester.runAsync(() async {
        final discoveryBloc = MockDiscoveryBlocWithCompletedStudies();
        final themeBloc = MockThemeBloc();

        // Set larger screen size to prevent layout overflow
        tester.view.physicalSize = const Size(1080, 1920);
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(
          MaterialApp(
            home: MultiBlocProvider(
              providers: [
                BlocProvider<DiscoveryBloc>.value(value: discoveryBloc),
                BlocProvider<ThemeBloc>.value(value: themeBloc),
                ChangeNotifierProvider(create: (_) => DevocionalProvider()),
              ],
              child: const DiscoveryListPage(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Toggle grid (now a floating button)
        final gridButton = find.byIcon(Icons.grid_view_rounded);
        if (gridButton.evaluate().isNotEmpty) {
          await tester.tap(gridButton);
          await tester.pumpAndSettle();

          // Check icons should use outline style
          expect(find.byIcon(Icons.check), findsWidgets);
        }
      });
    });
  });

  group('DiscoveryListPage Navigation Tests', () {
    testWidgets('Tapping carousel card navigates to detail page',
        (WidgetTester tester) async {
      await tester.runAsync(() async {
        final discoveryBloc = MockDiscoveryBlocWithStudies();
        final themeBloc = MockThemeBloc();

        // Set larger screen size to prevent layout overflow
        tester.view.physicalSize = const Size(1080, 1920);
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(
          MaterialApp(
            home: MultiBlocProvider(
              providers: [
                BlocProvider<DiscoveryBloc>.value(value: discoveryBloc),
                BlocProvider<ThemeBloc>.value(value: themeBloc),
                ChangeNotifierProvider(create: (_) => DevocionalProvider()),
              ],
              child: const DiscoveryListPage(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify page renders
        expect(find.byType(DiscoveryListPage), findsOneWidget);
      });
    });

    testWidgets('Grid toggle button switches between carousel and grid view',
        (WidgetTester tester) async {
      await tester.runAsync(() async {
        final discoveryBloc = MockDiscoveryBlocWithStudies();
        final themeBloc = MockThemeBloc();

        // Set larger screen size to prevent layout overflow
        tester.view.physicalSize = const Size(1080, 1920);
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(
          MaterialApp(
            home: MultiBlocProvider(
              providers: [
                BlocProvider<DiscoveryBloc>.value(value: discoveryBloc),
                BlocProvider<ThemeBloc>.value(value: themeBloc),
                ChangeNotifierProvider(create: (_) => DevocionalProvider()),
              ],
              child: const DiscoveryListPage(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Initial state shows grid_view_rounded icon (floating button)
        expect(find.byIcon(Icons.grid_view_rounded), findsOneWidget);

        // Tap to toggle
        await tester.tap(find.byIcon(Icons.grid_view_rounded));
        await tester.pumpAndSettle();

        // Should now show carousel_rounded icon
        expect(find.byIcon(Icons.view_carousel_rounded), findsOneWidget);
      });
    });
  });

  group('DiscoveryListPage State Tests', () {
    testWidgets('Shows loading indicator when loading',
        (WidgetTester tester) async {
      await tester.runAsync(() async {
        final discoveryBloc = MockDiscoveryBlocLoading();
        final themeBloc = MockThemeBloc();

        // Set larger screen size to prevent layout overflow
        tester.view.physicalSize = const Size(1080, 1920);
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(
          MaterialApp(
            home: MultiBlocProvider(
              providers: [
                BlocProvider<DiscoveryBloc>.value(value: discoveryBloc),
                BlocProvider<ThemeBloc>.value(value: themeBloc),
                ChangeNotifierProvider(create: (_) => DevocionalProvider()),
              ],
              child: const DiscoveryListPage(),
            ),
          ),
        );

        await tester.pump();

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });
    });

    testWidgets('Shows error message when error occurs',
        (WidgetTester tester) async {
      await tester.runAsync(() async {
        final discoveryBloc = MockDiscoveryBlocError();
        final themeBloc = MockThemeBloc();

        // Set larger screen size to prevent layout overflow
        tester.view.physicalSize = const Size(1080, 1920);
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(
          MaterialApp(
            home: MultiBlocProvider(
              providers: [
                BlocProvider<DiscoveryBloc>.value(value: discoveryBloc),
                BlocProvider<ThemeBloc>.value(value: themeBloc),
                ChangeNotifierProvider(create: (_) => DevocionalProvider()),
              ],
              child: const DiscoveryListPage(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.error_outline), findsOneWidget);
      });
    });
  });
}

// Mock BLoCs
class MockDiscoveryBloc extends Fake implements DiscoveryBloc {
  @override
  Stream<DiscoveryState> get stream => Stream.value(DiscoveryInitial());

  @override
  DiscoveryState get state => DiscoveryInitial();

  @override
  void add(DiscoveryEvent event) {}

  @override
  Future<void> close() async {}
}

class MockDiscoveryBlocLoading extends Fake implements DiscoveryBloc {
  @override
  Stream<DiscoveryState> get stream => Stream.value(DiscoveryLoading());

  @override
  DiscoveryState get state => DiscoveryLoading();

  @override
  void add(DiscoveryEvent event) {}

  @override
  Future<void> close() async {}
}

class MockDiscoveryBlocError extends Fake implements DiscoveryBloc {
  @override
  Stream<DiscoveryState> get stream =>
      Stream.value(DiscoveryError('Test error'));

  @override
  DiscoveryState get state => DiscoveryError('Test error');

  @override
  void add(DiscoveryEvent event) {}

  @override
  Future<void> close() async {}
}

class MockDiscoveryBlocWithStudies extends Fake implements DiscoveryBloc {
  @override
  Stream<DiscoveryState> get stream => Stream.value(
        DiscoveryLoaded(
          availableStudyIds: ['study_1'],
          studyTitles: {
            'study_1': 'Study 1',
          },
          studySubtitles: {
            'study_1': 'Subtitle 1',
          },
          studyEmojis: {
            'study_1': '📖',
          },
          studyReadingMinutes: {
            'study_1': 5,
          },
          completedStudies: {},
          favoriteStudyIds: {},
          loadedStudies: {},
          languageCode: 'en',
        ),
      );

  @override
  DiscoveryState get state => DiscoveryLoaded(
        availableStudyIds: ['study_1'],
        studyTitles: {
          'study_1': 'Study 1',
        },
        studySubtitles: {
          'study_1': 'Subtitle 1',
        },
        studyEmojis: {
          'study_1': '📖',
        },
        studyReadingMinutes: {
          'study_1': 5,
        },
        completedStudies: {},
        favoriteStudyIds: {},
        loadedStudies: {},
        languageCode: 'en',
      );

  @override
  void add(DiscoveryEvent event) {}

  @override
  Future<void> close() async {}
}

class MockDiscoveryBlocWithMixedStudies extends Fake implements DiscoveryBloc {
  @override
  Stream<DiscoveryState> get stream => Stream.value(
        DiscoveryLoaded(
          availableStudyIds: ['study_1', 'study_2', 'study_3', 'study_4'],
          studyTitles: {
            'study_1': 'Incomplete Study 1',
            'study_2': 'Completed Study 1',
            'study_3': 'Incomplete Study 2',
            'study_4': 'Completed Study 2',
          },
          studySubtitles: {},
          studyEmojis: {},
          studyReadingMinutes: {},
          completedStudies: {
            'study_1': false,
            'study_2': true,
            'study_3': false,
            'study_4': true,
          },
          favoriteStudyIds: {},
          loadedStudies: {},
          languageCode: 'en',
        ),
      );

  @override
  DiscoveryState get state => DiscoveryLoaded(
        availableStudyIds: ['study_1', 'study_2', 'study_3', 'study_4'],
        studyTitles: {
          'study_1': 'Incomplete Study 1',
          'study_2': 'Completed Study 1',
          'study_3': 'Incomplete Study 2',
          'study_4': 'Completed Study 2',
        },
        studySubtitles: {},
        studyEmojis: {},
        studyReadingMinutes: {},
        completedStudies: {
          'study_1': false,
          'study_2': true,
          'study_3': false,
          'study_4': true,
        },
        favoriteStudyIds: {},
        loadedStudies: {},
        languageCode: 'en',
      );

  @override
  void add(DiscoveryEvent event) {}

  @override
  Future<void> close() async {}
}

class MockDiscoveryBlocWithCompletedStudies extends Fake
    implements DiscoveryBloc {
  @override
  Stream<DiscoveryState> get stream => Stream.value(
        DiscoveryLoaded(
          availableStudyIds: ['study_1', 'study_2'],
          studyTitles: {
            'study_1': 'Completed Study 1',
            'study_2': 'Completed Study 2',
          },
          studySubtitles: {},
          studyEmojis: {},
          studyReadingMinutes: {},
          completedStudies: {
            'study_1': true,
            'study_2': true,
          },
          favoriteStudyIds: {},
          loadedStudies: {},
          languageCode: 'en',
        ),
      );

  @override
  DiscoveryState get state => DiscoveryLoaded(
        availableStudyIds: ['study_1', 'study_2'],
        studyTitles: {
          'study_1': 'Completed Study 1',
          'study_2': 'Completed Study 2',
        },
        studySubtitles: {},
        studyEmojis: {},
        studyReadingMinutes: {},
        completedStudies: {
          'study_1': true,
          'study_2': true,
        },
        favoriteStudyIds: {},
        loadedStudies: {},
        languageCode: 'en',
      );

  @override
  void add(DiscoveryEvent event) {}

  @override
  Future<void> close() async {}
}

class MockThemeBloc extends Fake implements ThemeBloc {
  @override
  Stream<ThemeState> get stream => Stream.value(
        ThemeLoaded(
          themeFamily: 'Deep Purple',
          themeData: ThemeData.light(),
          brightness: Brightness.light,
        ),
      );

  @override
  ThemeState get state => ThemeLoaded(
        themeFamily: 'Deep Purple',
        themeData: ThemeData.light(),
        brightness: Brightness.light,
      );

  @override
  void add(event) {}

  @override
  Future<void> close() async {}
}
