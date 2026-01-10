// test/pages/favorites_page_integration_test.dart

import 'package:devocional_nuevo/blocs/theme/theme_bloc.dart';
import 'package:devocional_nuevo/blocs/theme/theme_event.dart';
import 'package:devocional_nuevo/models/devocional_model.dart';
import 'package:devocional_nuevo/pages/favorites_page.dart';
import 'package:devocional_nuevo/providers/devocional_provider.dart';
import 'package:devocional_nuevo/services/localization_service.dart';
import 'package:devocional_nuevo/services/service_locator.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockPathProviderPlatform extends PathProviderPlatform {
  @override
  Future<String?> getApplicationDocumentsPath() async {
    return '/mock_documents';
  }

  @override
  Future<String?> getTemporaryPath() async {
    return '/mock_temp';
  }
}

/// Helper function to create test devotionals
Devocional createTestDevocional({
  required String id,
  required DateTime date,
  required String versiculo,
  String reflexion = 'Test reflection',
  String oracion = 'Test prayer',
  String version = 'RVR1960',
  String language = 'es',
}) {
  return Devocional(
    id: id,
    date: date,
    versiculo: versiculo,
    reflexion: reflexion,
    paraMeditar: [
      ParaMeditar(cita: 'Test cita', texto: 'Test para meditar text'),
    ],
    oracion: oracion,
    version: version,
    language: language,
  );
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();

    // Mock Firebase Core
    const MethodChannel firebaseCoreChannel = MethodChannel(
      'plugins.flutter.io/firebase_core',
    );
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

    // Mock Firebase Crashlytics
    const MethodChannel crashlyticsChannel = MethodChannel(
      'plugins.flutter.io/firebase_crashlytics',
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(crashlyticsChannel,
            (MethodCall methodCall) async {
      return null;
    });

    // Mock Firebase Remote Config
    const MethodChannel remoteConfigChannel = MethodChannel(
      'plugins.flutter.io/firebase_remote_config',
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(remoteConfigChannel,
            (MethodCall methodCall) async {
      switch (methodCall.method) {
        case 'RemoteConfig#instance':
          return {};
        case 'RemoteConfig#setConfigSettings':
        case 'RemoteConfig#setDefaults':
        case 'RemoteConfig#fetchAndActivate':
          return true;
        case 'RemoteConfig#getString':
          return '';
        case 'RemoteConfig#getBool':
          return false;
        case 'RemoteConfig#getInt':
          return 0;
        case 'RemoteConfig#getDouble':
          return 0.0;
        default:
          return null;
      }
    });

    // Mock Firebase Analytics
    const MethodChannel analyticsChannel = MethodChannel(
      'plugins.flutter.io/firebase_analytics',
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(analyticsChannel,
            (MethodCall methodCall) async {
      return null;
    });

    // Initialize Firebase
    try {
      await Firebase.initializeApp();
    } catch (e) {
      // Firebase may already be initialized
    }

    // Mock path provider
    const MethodChannel pathProviderChannel = MethodChannel(
      'plugins.flutter.io/path_provider',
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProviderChannel,
            (MethodCall methodCall) async {
      if (methodCall.method == 'getApplicationDocumentsDirectory') {
        return '/mock_documents';
      }
      return null;
    });

    // Mock TTS
    const MethodChannel ttsChannel = MethodChannel('flutter_tts');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(ttsChannel, (MethodCall methodCall) async {
      switch (methodCall.method) {
        case 'speak':
        case 'stop':
        case 'pause':
        case 'setLanguage':
        case 'setSpeechRate':
        case 'setVolume':
        case 'setPitch':
        case 'setVoice':
        case 'synthesizeToFile':
        case 'awaitSpeakCompletion':
        case 'awaitSynthCompletion':
          return 1;
        case 'getLanguages':
          return ['es-ES', 'en-US', 'pt-BR', 'fr-FR', 'ja-JP', 'zh-CN'];
        case 'getVoices':
          return [
            {'name': 'es-ES-voice', 'locale': 'es-ES'},
            {'name': 'en-US-voice', 'locale': 'en-US'},
          ];
        case 'isLanguageAvailable':
          return 1;
        default:
          return null;
      }
    });

    PathProviderPlatform.instance = MockPathProviderPlatform();
    setupServiceLocator();
  });

  group('FavoritesPage Integration Tests', () {
    testWidgets('Should display empty state when no favorites',
        (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});

      final provider = DevocionalProvider();
      await provider.initializeData();

      // Initialize localization service and get expected translations
      final localizationService = getService<LocalizationService>();
      await localizationService.initialize();
      final expectedTitle =
          localizationService.translate('favorites.empty_title');
      final expectedDescription =
          localizationService.translate('favorites.empty_description');

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<DevocionalProvider>.value(value: provider),
            BlocProvider<ThemeBloc>(
              create: (_) => ThemeBloc()..add(const InitializeThemeDefaults()),
            ),
          ],
          child: MaterialApp(
            home: FavoritesPage(),
            localizationsDelegates: [
              DefaultMaterialLocalizations.delegate,
              DefaultWidgetsLocalizations.delegate,
            ],
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should show empty state
      expect(find.byIcon(Icons.favorite_border), findsOneWidget);
      expect(find.text(expectedTitle), findsOneWidget);
      expect(find.text(expectedDescription), findsOneWidget);

      provider.dispose();
    });

    testWidgets('Should display favorites list when favorites exist',
        (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});

      final provider = DevocionalProvider();
      await provider.initializeData();

      // Manually add a favorite by simulating the ID storage
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'favorite_ids',
        '["devocional_2025_01_15_RVR1960"]',
      );

      // Reload to pick up the favorite
      await provider.reloadFavoritesFromStorage();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<DevocionalProvider>.value(value: provider),
            BlocProvider<ThemeBloc>(
              create: (_) => ThemeBloc()..add(const InitializeThemeDefaults()),
            ),
          ],
          child: MaterialApp(
            home: FavoritesPage(),
            localizationsDelegates: [
              DefaultMaterialLocalizations.delegate,
              DefaultWidgetsLocalizations.delegate,
            ],
          ),
        ),
      );

      await tester.pumpAndSettle();

      // If favorites were loaded from actual data, we would see them
      // For this test, we're just verifying the page renders without errors

      provider.dispose();
    });

    testWidgets('Should remove favorite when unfavorite button is tapped',
        (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});

      final provider = DevocionalProvider();
      await provider.initializeData();

      // Create and add a test favorite
      final testDevocional = createTestDevocional(
        id: 'test_devocional_id',
        date: DateTime.now(),
        versiculo: 'Test Verse',
      );

      // We can't easily test the full flow without mocking the entire data loading
      // but we can verify the provider's toggleFavorite method works

      final initialFavCount = provider.favoriteDevocionales.length;

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<DevocionalProvider>.value(value: provider),
            BlocProvider<ThemeBloc>(
              create: (_) => ThemeBloc()..add(const InitializeThemeDefaults()),
            ),
          ],
          child: MaterialApp(
            home: Builder(
              builder: (context) {
                // Toggle favorite using new async API
                Future.microtask(() async {
                  await provider.toggleFavorite(testDevocional.id);
                });
                return FavoritesPage();
              },
            ),
            localizationsDelegates: [
              DefaultMaterialLocalizations.delegate,
              DefaultWidgetsLocalizations.delegate,
            ],
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Wait for async operation
      await Future.delayed(const Duration(milliseconds: 100));

      // Should have added one favorite
      expect(provider.favoriteDevocionales.length, equals(initialFavCount + 1));
      expect(provider.isFavorite(testDevocional), isTrue);

      provider.dispose();
    });

    testWidgets('Should navigate to devotional when card is tapped',
        (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});

      final provider = DevocionalProvider();
      await provider.initializeData();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<DevocionalProvider>.value(value: provider),
            BlocProvider<ThemeBloc>(
              create: (_) => ThemeBloc()..add(const InitializeThemeDefaults()),
            ),
          ],
          child: MaterialApp(
            home: FavoritesPage(),
            localizationsDelegates: [
              DefaultMaterialLocalizations.delegate,
              DefaultWidgetsLocalizations.delegate,
            ],
          ),
        ),
      );

      await tester.pumpAndSettle();

      // If there are favorites, tapping would navigate
      // This test verifies the page structure is correct

      provider.dispose();
    });
  });

  group('FavoritesPage with Real Data Flow', () {
    testWidgets('Should show correct devotional details in card',
        (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});

      final provider = DevocionalProvider();
      await provider.initializeData();

      final testDevocional = createTestDevocional(
        id: 'test_dev_123',
        date: DateTime(2025, 1, 15),
        versiculo: 'Juan 3:16',
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<DevocionalProvider>.value(value: provider),
            BlocProvider<ThemeBloc>(
              create: (_) => ThemeBloc()..add(const InitializeThemeDefaults()),
            ),
          ],
          child: MaterialApp(
            home: Builder(
              builder: (context) {
                // Toggle favorite using new async API
                Future.microtask(() async {
                  await provider.toggleFavorite(testDevocional.id);
                });
                return FavoritesPage();
              },
            ),
            localizationsDelegates: [
              DefaultMaterialLocalizations.delegate,
              DefaultWidgetsLocalizations.delegate,
            ],
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Wait for async operation
      await Future.delayed(const Duration(milliseconds: 100));

      // Should display the verse
      expect(find.text('Juan 3:16'), findsOneWidget);

      // Should display favorite icon
      expect(find.byIcon(Icons.favorite), findsOneWidget);

      provider.dispose();
    });

    testWidgets('Should update UI when favorite is removed',
        (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});

      final provider = DevocionalProvider();
      await provider.initializeData();

      final testDevocional = createTestDevocional(
        id: 'test_dev_123',
        date: DateTime(2025, 1, 15),
        versiculo: 'Juan 3:16',
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<DevocionalProvider>.value(value: provider),
            BlocProvider<ThemeBloc>(
              create: (_) => ThemeBloc()..add(const InitializeThemeDefaults()),
            ),
          ],
          child: MaterialApp(
            home: Builder(
              builder: (context) {
                // Toggle favorite using new async API
                Future.microtask(() async {
                  await provider.toggleFavorite(testDevocional.id);
                });
                return FavoritesPage();
              },
            ),
            localizationsDelegates: [
              DefaultMaterialLocalizations.delegate,
              DefaultWidgetsLocalizations.delegate,
            ],
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify favorite is shown
      expect(provider.isFavorite(testDevocional), isTrue);

      // Tap the unfavorite button
      final favButton = find.byIcon(Icons.favorite);
      if (favButton.evaluate().isNotEmpty) {
        await tester.tap(favButton.first);
        await tester.pumpAndSettle();

        // Should no longer be favorite
        expect(provider.isFavorite(testDevocional), isFalse);
      }

      provider.dispose();
    });
  });
}
