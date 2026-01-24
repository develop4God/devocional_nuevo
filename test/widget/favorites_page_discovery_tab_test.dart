// test/widget/favorites_page_discovery_tab_test.dart
// Widget test to verify Discovery tab loads correctly and doesn't show infinite spinner

import 'package:devocional_nuevo/blocs/discovery/discovery_bloc.dart';
import 'package:devocional_nuevo/blocs/discovery/discovery_event.dart';
import 'package:devocional_nuevo/blocs/discovery/discovery_state.dart';
import 'package:devocional_nuevo/blocs/theme/theme_bloc.dart';
import 'package:devocional_nuevo/models/devocional_model.dart';
import 'package:devocional_nuevo/pages/favorites_page.dart';
import 'package:devocional_nuevo/providers/devocional_provider.dart';
import 'package:devocional_nuevo/repositories/discovery_repository.dart';
import 'package:devocional_nuevo/services/discovery_favorites_service.dart';
import 'package:devocional_nuevo/services/discovery_progress_tracker.dart';
import 'package:devocional_nuevo/services/service_locator.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'favorites_page_discovery_tab_test.mocks.dart';

@GenerateMocks([
  DiscoveryRepository,
  DiscoveryProgressTracker,
  DiscoveryFavoritesService,
  DevocionalProvider,
])
void main() {
  late MockDiscoveryRepository mockRepository;
  late MockDiscoveryProgressTracker mockProgressTracker;
  late MockDiscoveryFavoritesService mockFavoritesService;
  late MockDevocionalProvider mockDevocionalProvider;

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();

    // Mock path provider
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (MethodCall methodCall) async {
        return '/mock_path';
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
    mockRepository = MockDiscoveryRepository();
    mockProgressTracker = MockDiscoveryProgressTracker();
    mockFavoritesService = MockDiscoveryFavoritesService();
    mockDevocionalProvider = MockDevocionalProvider();

    // Setup default mocks
    when(mockFavoritesService.loadFavoriteIds(any))
        .thenAnswer((_) async => <String>{});
    when(mockDevocionalProvider.favoriteDevocionales).thenReturn([]);
    when(mockDevocionalProvider.selectedLanguage).thenReturn('es');
  });

  testWidgets(
      'Bible Studies tab triggers LoadDiscoveryStudies when in DiscoveryInitial state',
      (WidgetTester tester) async {
    // Create a DiscoveryBloc in Initial state
    final discoveryBloc = DiscoveryBloc(
      repository: mockRepository,
      progressTracker: mockProgressTracker,
      favoritesService: mockFavoritesService,
    );

    // Verify initial state
    expect(discoveryBloc.state, isA<DiscoveryInitial>());

    // Track events
    final events = <DiscoveryEvent>[];
    discoveryBloc.stream.listen((state) {});

    // Mock successful index fetch
    when(mockRepository.fetchIndex(forceRefresh: anyNamed('forceRefresh')))
        .thenAnswer((_) async => {
              'studies': [],
            });

    // Build widget
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<DevocionalProvider>.value(
              value: mockDevocionalProvider),
        ],
        child: MultiBlocProvider(
          providers: [
            BlocProvider<DiscoveryBloc>.value(value: discoveryBloc),
            BlocProvider<ThemeBloc>(
              create: (_) => ThemeBloc(),
            ),
          ],
          child: const MaterialApp(
            home: FavoritesPage(initialIndex: 1), // Bible Studies tab
          ),
        ),
      ),
    );

    // Initial build shows spinner
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Wait for postFrameCallback to execute
    await tester.pumpAndSettle();

    // Verify LoadDiscoveryStudies event was dispatched
    // The bloc should transition from Initial to Loading
    expect(discoveryBloc.state, isA<DiscoveryLoading>());

    discoveryBloc.close();
  });

  testWidgets('Bible Studies tab shows empty state when no favorites',
      (WidgetTester tester) async {
    final discoveryBloc = DiscoveryBloc(
      repository: mockRepository,
      progressTracker: mockProgressTracker,
      favoritesService: mockFavoritesService,
    );

    // Mock successful index fetch with no favorites
    when(mockRepository.fetchIndex(forceRefresh: anyNamed('forceRefresh')))
        .thenAnswer((_) async => {
              'studies': [],
            });

    // Build widget
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<DevocionalProvider>.value(
              value: mockDevocionalProvider),
        ],
        child: MultiBlocProvider(
          providers: [
            BlocProvider<DiscoveryBloc>.value(value: discoveryBloc),
            BlocProvider<ThemeBloc>(
              create: (_) => ThemeBloc(),
            ),
          ],
          child: const MaterialApp(
            home: FavoritesPage(initialIndex: 1),
          ),
        ),
      ),
    );

    // Wait for loading to complete
    await tester.pumpAndSettle();

    // Should show empty state, not infinite spinner
    expect(find.byType(CircularProgressIndicator), findsNothing);

    discoveryBloc.close();
  });

  testWidgets('Bible Studies tab shows error state on fetch failure',
      (WidgetTester tester) async {
    final discoveryBloc = DiscoveryBloc(
      repository: mockRepository,
      progressTracker: mockProgressTracker,
      favoritesService: mockFavoritesService,
    );

    // Mock fetch failure
    when(mockRepository.fetchIndex(forceRefresh: anyNamed('forceRefresh')))
        .thenThrow(Exception('Network error'));

    // Build widget
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<DevocionalProvider>.value(
              value: mockDevocionalProvider),
        ],
        child: MultiBlocProvider(
          providers: [
            BlocProvider<DiscoveryBloc>.value(value: discoveryBloc),
            BlocProvider<ThemeBloc>(
              create: (_) => ThemeBloc(),
            ),
          ],
          child: const MaterialApp(
            home: FavoritesPage(initialIndex: 1),
          ),
        ),
      ),
    );

    // Wait for error state
    await tester.pumpAndSettle();

    // Should show error state with error icon, not infinite spinner
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.byIcon(Icons.error_outline), findsOneWidget);

    discoveryBloc.close();
  });

  testWidgets('Devotionals tab shows favorites list correctly',
      (WidgetTester tester) async {
    // Create mock favorites
    final mockFavorites = <Devocional>[
      Devocional(
        id: 'fav_1',
        date: DateTime.now(),
        versiculo: 'John 3:16',
        reflexion: 'Test reflection',
        paraMeditar: [],
        oracion: 'Test prayer',
        version: 'RVR1960',
      ),
    ];

    when(mockDevocionalProvider.favoriteDevocionales).thenReturn(mockFavorites);
    final discoveryBloc = DiscoveryBloc(
      repository: mockRepository,
      progressTracker: mockProgressTracker,
      favoritesService: mockFavoritesService,
    );

    // Build widget on Devotionals tab
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<DevocionalProvider>.value(
              value: mockDevocionalProvider),
        ],
        child: MultiBlocProvider(
          providers: [
            BlocProvider<DiscoveryBloc>.value(value: discoveryBloc),
            BlocProvider<ThemeBloc>(
              create: (_) => ThemeBloc(),
            ),
          ],
          child: const MaterialApp(
            home: FavoritesPage(initialIndex: 0), // Devotionals tab
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Should show favorites list
    expect(find.text('John 3:16'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);

    discoveryBloc.close();
  });
}
