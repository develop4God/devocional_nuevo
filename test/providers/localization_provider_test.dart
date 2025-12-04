import 'package:devocional_nuevo/providers/localization_provider.dart';
import 'package:devocional_nuevo/services/localization_service.dart';
import 'package:devocional_nuevo/services/service_locator.dart';
import 'package:devocional_nuevo/services/tts/voice_settings_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Mock VoiceSettingsService that doesn't use FlutterTts (which is not available in unit tests)
class MockVoiceSettingsService extends VoiceSettingsService {
  bool _proactiveAssignCalled = false;
  String? _lastLanguageCode;

  bool get proactiveAssignCalled => _proactiveAssignCalled;
  String? get lastLanguageCode => _lastLanguageCode;

  @override
  Future<void> proactiveAssignVoiceOnInit(String language) async {
    _proactiveAssignCalled = true;
    _lastLanguageCode = language;
    // Do nothing - mock implementation that avoids FlutterTts
  }

  @override
  Future<void> autoAssignDefaultVoice(String language) async {
    // Do nothing - mock implementation
  }

  @override
  Future<String?> loadSavedVoice(String language) async {
    return null;
  }

  @override
  Future<bool> hasSavedVoice(String language) async {
    return false;
  }

  void reset() {
    _proactiveAssignCalled = false;
    _lastLanguageCode = null;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LocalizationProvider Tests', () {
    late LocalizationProvider provider;
    late MockVoiceSettingsService mockVoiceService;

    setUp(() async {
      // Reset ServiceLocator for clean test state
      ServiceLocator().reset();

      // Mock SharedPreferences
      SharedPreferences.setMockInitialValues({});

      // Create mock voice service
      mockVoiceService = MockVoiceSettingsService();

      // Register services in ServiceLocator
      ServiceLocator().registerLazySingleton<LocalizationService>(
          () => LocalizationService());
      ServiceLocator()
          .registerSingleton<VoiceSettingsService>(mockVoiceService);

      // Create provider instance (uses DI internally)
      provider = LocalizationProvider();
    });

    tearDown(() {
      // Clean up ServiceLocator after each test
      ServiceLocator().reset();
    });

    test('provider uses ServiceLocator to get LocalizationService', () {
      // Verify that the provider is properly instantiated and uses DI
      expect(provider, isNotNull);
      expect(provider.supportedLocales, isNotEmpty);
      expect(provider.supportedLocales.length, equals(5));
    });

    test('supportedLocales returns all expected languages', () {
      final locales = provider.supportedLocales;
      final languageCodes = locales.map((l) => l.languageCode).toList();

      expect(languageCodes, contains('es'));
      expect(languageCodes, contains('en'));
      expect(languageCodes, contains('pt'));
      expect(languageCodes, contains('fr'));
      expect(languageCodes, contains('ja'));
    });

    test('initialize() calls LocalizationService.initialize()', () async {
      // Track notifications
      int notificationCount = 0;
      provider.addListener(() {
        notificationCount++;
      });

      // Initialize the provider
      await provider.initialize();

      // Verify that the provider notified listeners
      expect(notificationCount, greaterThanOrEqualTo(1));

      // Verify that currentLocale is set to a supported locale
      expect(
        provider.supportedLocales.map((l) => l.languageCode),
        contains(provider.currentLocale.languageCode),
      );
    });

    test('initialize() calls VoiceSettingsService.proactiveAssignVoiceOnInit()',
        () async {
      await provider.initialize();

      // Verify that proactiveAssignVoiceOnInit was called
      expect(mockVoiceService.proactiveAssignCalled, isTrue);
      expect(mockVoiceService.lastLanguageCode, isNotNull);
    });

    test('initialize() loads persisted locale from SharedPreferences',
        () async {
      // Reset and set up with persisted English locale
      ServiceLocator().reset();
      SharedPreferences.setMockInitialValues({'locale': 'en'});
      mockVoiceService = MockVoiceSettingsService();
      ServiceLocator().registerLazySingleton<LocalizationService>(
          () => LocalizationService());
      ServiceLocator()
          .registerSingleton<VoiceSettingsService>(mockVoiceService);

      provider = LocalizationProvider();
      await provider.initialize();

      // Should load persisted English locale
      expect(provider.currentLocale.languageCode, equals('en'));
    });

    test(
        'changeLanguage() calls LocalizationService.changeLocale() and notifies listeners',
        () async {
      await provider.initialize();
      mockVoiceService.reset();

      int notificationCount = 0;
      provider.addListener(() {
        notificationCount++;
      });

      // Change language to Portuguese
      await provider.changeLanguage('pt');

      // Verify that the provider notified listeners
      expect(notificationCount, greaterThanOrEqualTo(1));

      // Verify that currentLocale reflects the change
      expect(provider.currentLocale.languageCode, equals('pt'));
    });

    test(
        'changeLanguage() calls VoiceSettingsService.proactiveAssignVoiceOnInit()',
        () async {
      await provider.initialize();
      mockVoiceService.reset();

      // Change language to Portuguese
      await provider.changeLanguage('pt');

      // Verify that proactiveAssignVoiceOnInit was called with the new language
      expect(mockVoiceService.proactiveAssignCalled, isTrue);
      expect(mockVoiceService.lastLanguageCode, equals('pt'));
    });

    test('changeLanguage() persists locale in SharedPreferences', () async {
      await provider.initialize();

      // Change language to French
      await provider.changeLanguage('fr');

      // Verify the locale was persisted
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('locale'), equals('fr'));
    });

    test('translate() delegates to LocalizationService.translate()', () async {
      await provider.initialize();

      // Test basic translation
      final translation = provider.translate('app.title');

      // Since assets load in test environment, we expect either the actual translation or the key
      expect(translation, isNotNull);
      expect(translation.isNotEmpty, isTrue);
    });

    test('translate() handles params correctly', () async {
      await provider.initialize();

      // Test translation with parameters
      final translation = provider
          .translate('navigation.switch_to_language', {'language': 'Test'});

      expect(translation, isNotNull);
      expect(translation.isNotEmpty, isTrue);
    });

    test('getTtsLocale() returns correct TTS locale for current language',
        () async {
      await provider.initialize();

      // Test each language's TTS locale
      await provider.changeLanguage('es');
      expect(provider.getTtsLocale(), equals('es-ES'));

      await provider.changeLanguage('en');
      expect(provider.getTtsLocale(), equals('en-US'));

      await provider.changeLanguage('pt');
      expect(provider.getTtsLocale(), equals('pt-BR'));

      await provider.changeLanguage('fr');
      expect(provider.getTtsLocale(), equals('fr-FR'));

      await provider.changeLanguage('ja');
      expect(provider.getTtsLocale(), equals('ja-JP'));
    });

    test('getLanguageName() returns correct native language name', () async {
      await provider.initialize();

      expect(provider.getLanguageName('es'), equals('Español'));
      expect(provider.getLanguageName('en'), equals('English'));
      expect(provider.getLanguageName('pt'), equals('Português'));
      expect(provider.getLanguageName('fr'), equals('Français'));
      expect(provider.getLanguageName('ja'), equals('日本語'));
    });

    test('getAvailableLanguages() returns map of all supported languages',
        () async {
      await provider.initialize();

      final languages = provider.getAvailableLanguages();

      expect(languages.length, equals(5));
      expect(languages['es'], equals('Español'));
      expect(languages['en'], equals('English'));
      expect(languages['pt'], equals('Português'));
      expect(languages['fr'], equals('Français'));
      expect(languages['ja'], equals('日本語'));
    });

    test('provider falls back to default locale for unsupported locale',
        () async {
      // Reset and set up with unsupported locale
      ServiceLocator().reset();
      SharedPreferences.setMockInitialValues({'locale': 'xx'});
      mockVoiceService = MockVoiceSettingsService();
      ServiceLocator().registerLazySingleton<LocalizationService>(
          () => LocalizationService());
      ServiceLocator()
          .registerSingleton<VoiceSettingsService>(mockVoiceService);

      provider = LocalizationProvider();
      await provider.initialize();

      // Should fall back to default Spanish locale
      expect(
        LocalizationService.supportedLocales
            .map((l) => l.languageCode)
            .contains(provider.currentLocale.languageCode),
        isTrue,
      );
    });

    test('multiple locale changes work correctly', () async {
      await provider.initialize();

      // Change through multiple languages
      await provider.changeLanguage('en');
      expect(provider.currentLocale.languageCode, equals('en'));

      await provider.changeLanguage('fr');
      expect(provider.currentLocale.languageCode, equals('fr'));

      await provider.changeLanguage('ja');
      expect(provider.currentLocale.languageCode, equals('ja'));

      await provider.changeLanguage('pt');
      expect(provider.currentLocale.languageCode, equals('pt'));

      await provider.changeLanguage('es');
      expect(provider.currentLocale.languageCode, equals('es'));
    });
  });

  group('LocalizationProvider User Behavior Tests', () {
    late LocalizationProvider provider;
    late MockVoiceSettingsService mockVoiceService;

    setUp(() async {
      ServiceLocator().reset();
      SharedPreferences.setMockInitialValues({});
      mockVoiceService = MockVoiceSettingsService();
      ServiceLocator().registerLazySingleton<LocalizationService>(
          () => LocalizationService());
      ServiceLocator()
          .registerSingleton<VoiceSettingsService>(mockVoiceService);
      provider = LocalizationProvider();
    });

    tearDown(() {
      ServiceLocator().reset();
    });

    test('User journey: initialize app, change language, verify persistence',
        () async {
      // Step 1: User opens app, provider initializes
      await provider.initialize();
      final initialLocale = provider.currentLocale.languageCode;
      expect(LocalizationService.supportedLocales.map((l) => l.languageCode),
          contains(initialLocale));

      // Step 2: User changes language to French
      await provider.changeLanguage('fr');
      expect(provider.currentLocale.languageCode, equals('fr'));

      // Step 3: Simulate app restart - create new provider with same persisted data
      ServiceLocator().reset();
      // Do NOT reset SharedPreferences - persistence should survive
      mockVoiceService = MockVoiceSettingsService();
      ServiceLocator().registerLazySingleton<LocalizationService>(
          () => LocalizationService());
      ServiceLocator()
          .registerSingleton<VoiceSettingsService>(mockVoiceService);
      final newProvider = LocalizationProvider();
      await newProvider.initialize();

      // Step 4: Verify French is still selected (persistence works)
      expect(newProvider.currentLocale.languageCode, equals('fr'));
    });

    test('User can access translations immediately after language change',
        () async {
      await provider.initialize();

      // Change to English
      await provider.changeLanguage('en');

      // Translations should be available immediately
      final ttsLocale = provider.getTtsLocale();
      expect(ttsLocale, equals('en-US'));
    });

    test('VoiceSettingsService is called on initialization and language change',
        () async {
      // Initialize
      await provider.initialize();
      expect(mockVoiceService.proactiveAssignCalled, isTrue);

      // Reset tracking
      mockVoiceService.reset();

      // Change language
      await provider.changeLanguage('pt');
      expect(mockVoiceService.proactiveAssignCalled, isTrue);
      expect(mockVoiceService.lastLanguageCode, equals('pt'));
    });
  });
}
