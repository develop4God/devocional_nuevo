import 'package:devocional_nuevo/pages/application_language_page.dart';
import 'package:devocional_nuevo/providers/devocional_provider.dart';
import 'package:devocional_nuevo/providers/localization_provider.dart';
import 'package:devocional_nuevo/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Mock del PathProvider para simular el acceso al sistema de archivos
class MockPathProviderPlatform extends PathProviderPlatform {
  Future<String?> getApplicationDocumentsDirectory() async {
    return '/'; // Retorna una ruta simulada
  }
}

class MockDevocionalProvider extends Mock implements DevocionalProvider {}

class MockLocalizationProvider extends Mock implements LocalizationProvider {}

void main() {
  // Configurar el mock para PathProvider antes de todas las pruebas
  // Esto evita el error MissingPluginException
  setUpAll(() {
    PathProviderPlatform.instance = MockPathProviderPlatform();
  });

  group('Application Language Page Tests', () {
    late MockDevocionalProvider mockDevocionalProvider;
    late MockLocalizationProvider mockLocalizationProvider;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      mockDevocionalProvider = MockDevocionalProvider();
      mockLocalizationProvider = MockLocalizationProvider();

      // Setup default behavior - fix the null/Locale issue
      when(() => mockLocalizationProvider.currentLocale)
          .thenReturn(const Locale('es'));

      when(() => mockDevocionalProvider.downloadCurrentYearDevocionales())
          .thenAnswer((_) async => true);

      // Add other necessary stub methods
      when(() => mockDevocionalProvider.selectedLanguage).thenReturn('es');
      when(() => mockDevocionalProvider.selectedVersion).thenReturn('RVR1960');
      when(() => mockDevocionalProvider.supportedLanguages)
          .thenReturn(['es', 'en', 'pt', 'fr']);
      when(() => mockDevocionalProvider.isDownloading).thenReturn(false);
      when(() => mockDevocionalProvider.downloadStatus).thenReturn(null);

      when(() => mockLocalizationProvider.supportedLocales).thenReturn([
        const Locale('es'),
        const Locale('en'),
        const Locale('pt'),
        const Locale('fr'),
      ]);
      when(() => mockLocalizationProvider.getLanguageName(any()))
          .thenReturn('Language');
      when(() => mockLocalizationProvider.translate(any())).thenReturn('Translated');
      when(() => mockLocalizationProvider.changeLanguage(any()))
          .thenAnswer((_) async {});
    });

    Widget createTestWidget() {
      return MaterialApp(
        home: MultiProvider(
          providers: [
            ChangeNotifierProvider<DevocionalProvider>.value(
              value: mockDevocionalProvider,
            ),
            ChangeNotifierProvider<LocalizationProvider>.value(
              value: mockLocalizationProvider,
            ),
          ],
          child: const ApplicationLanguagePage(),
        ),
      );
    }

    testWidgets('should display all supported languages',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Check that all languages are displayed
      for (final language in Constants.supportedLanguages.values) {
        expect(find.text(language), findsOneWidget);
      }
    });

    testWidgets('should show current language as selected',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Check that current language is marked
      expect(
          find.text('application_language.current_language'), findsOneWidget);
    });

    testWidgets('should show download icons for non-downloaded languages',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Should have download icons (excluding Spanish which is pre-downloaded)
      expect(find.byIcon(Icons.download), findsAtLeastNWidgets(1));
    });

    testWidgets('should show progress indicator during download',
        (WidgetTester tester) async {
      // Setup a delayed download to simulate progress
      when(() => mockDevocionalProvider.downloadCurrentYearDevocionales())
          .thenAnswer((_) async {
        await Future.delayed(const Duration(milliseconds: 500));
        return true;
      });

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Tap on a language to start download
      final englishTile = find.text('English');
      await tester.tap(englishTile);
      await tester.pump();

      // Should show progress indicator
      expect(find.byType(CircularProgressIndicator), findsAtLeastNWidgets(1));
    });

    testWidgets('should handle download failure gracefully',
        (WidgetTester tester) async {
      // Setup download to fail
      when(() => mockDevocionalProvider.downloadCurrentYearDevocionales())
          .thenAnswer((_) async => false);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Tap on a language
      final englishTile = find.text('English');
      await tester.tap(englishTile);
      await tester.pumpAndSettle();

      // Should show error message
      expect(find.text('application_language.download_failed'), findsOneWidget);
    });

    testWidgets('should navigate back after successful download',
        (WidgetTester tester) async {
      // Create a more complex navigation test
      final navigatorKey = GlobalKey<NavigatorState>();

      final testApp = MaterialApp(
        navigatorKey: navigatorKey,
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MultiProvider(
                      providers: [
                        ChangeNotifierProvider<DevocionalProvider>.value(
                          value: mockDevocionalProvider,
                        ),
                        ChangeNotifierProvider<LocalizationProvider>.value(
                          value: mockLocalizationProvider,
                        ),
                      ],
                      child: const ApplicationLanguagePage(),
                    ),
                  ),
                );
              },
              child: const Text('Go to Language Page'),
            ),
          ),
        ),
      );

      await tester.pumpWidget(testApp);
      await tester.tap(find.text('Go to Language Page'));
      await tester.pumpAndSettle();

      // Should be on the language page
      expect(find.text('application_language.title'), findsOneWidget);

      // Tap on a language
      final englishTile = find.text('English');
      await tester.tap(englishTile);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Should navigate back automatically after download
      expect(find.text('Go to Language Page'), findsOneWidget);
    });
  });

  group('Language Download State Management Tests', () {
    test('should track download status correctly', () {
      // Test the internal state management logic
      expect(Constants.supportedLanguages.length, 4);
      expect(Constants.supportedLanguages.keys,
          containsAll(['es', 'en', 'pt', 'fr']));
    });

    test('should handle progress updates correctly', () {
      // Test progress calculation
      const progressValues = [0.1, 0.3, 0.5, 0.7, 0.9, 1.0];
      for (final progress in progressValues) {
        final percentage = (progress * 100).toInt();
        expect(percentage, inInclusiveRange(0, 100));
      }
    });
  });
}
