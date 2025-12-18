import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:devocional_nuevo/pages/debug_flag_page.dart' as debug_page;
import 'package:devocional_nuevo/services/tts/voice_settings_service.dart';
import 'package:devocional_nuevo/providers/localization_provider.dart';

class MockVoiceSettingsService extends Mock implements VoiceSettingsService {}

class MockLocalizationProvider extends ChangeNotifier
    implements LocalizationProvider {
  @override
  Locale get currentLocale => const Locale('es');
  @override
  List<Locale> get supportedLocales => [const Locale('es')];
  @override
  Future<void> initialize() async {}
  @override
  Future<void> changeLanguage(String languageCode) async {}
  @override
  String translate(String key, [Map<String, dynamic>? params]) => key;
  @override
  String getTtsLocale() => 'es-ES';
  @override
  String getLanguageName(String languageCode) => 'Español';
  @override
  Map<String, String> getAvailableLanguages() => {'es': 'Español'};
  @override
  void notifyListeners() {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DebugVoiceFlagPage', () {
    late MockVoiceSettingsService mockVoiceSettingsService;
    late MockLocalizationProvider mockLocalizationProvider;

    setUp(() {
      mockVoiceSettingsService = MockVoiceSettingsService();
      mockLocalizationProvider = MockLocalizationProvider();
    });

    testWidgets(
        'Borrar flag de voz llama clearUserSavedVoiceFlag y muestra SnackBar',
        (tester) async {
      // Arrange
      when(() => mockVoiceSettingsService.clearUserSavedVoiceFlag(any()))
          .thenAnswer((_) async {});

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<VoiceSettingsService>.value(
                value: mockVoiceSettingsService),
            ChangeNotifierProvider<LocalizationProvider>.value(
                value: mockLocalizationProvider),
          ],
          child: const MaterialApp(
            home: debug_page.DebugFlagPage(),
          ),
        ),
      );

      // Act
      final buttonFinder = find.text('Borrar flag de voz (pruebas)');
      expect(buttonFinder, findsOneWidget);
      await tester.tap(buttonFinder);
      await tester.pumpAndSettle();

      // Assert
      verify(() => mockVoiceSettingsService.clearUserSavedVoiceFlag('es'))
          .called(1);
      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.textContaining('Flag de voz borrado'), findsOneWidget);
    });
  });
}
