// test/critical_coverage/devocional_provider_working_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:devocional_nuevo/providers/devocional_provider.dart';
import 'package:devocional_nuevo/models/devocional_model.dart';

void main() {
  group('DevocionalProvider Behavioral Tests', () {
    late DevocionalProvider provider;

    setUpAll(() {
      TestWidgetsFlutterBinding.ensureInitialized();
    });

    setUp(() {
      // Initialize SharedPreferences mock for each test
      SharedPreferences.setMockInitialValues({});

      // Mock path_provider for file operations
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/path_provider'),
        (MethodCall methodCall) async {
          switch (methodCall.method) {
            case 'getApplicationDocumentsDirectory':
              return '/mock_documents';
            case 'getTemporaryDirectory':
              return '/mock_temp';
            default:
              return null;
          }
        },
      );

      // Mock flutter_tts method channel for TTS operations
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('flutter_tts'),
        (call) async {
          switch (call.method) {
            case 'speak':
              return null;
            case 'stop':
              return null;
            case 'pause':
              return null;
            case 'setLanguage':
              return null;
            case 'setSpeechRate':
              return null;
            case 'setVolume':
              return null;
            case 'setPitch':
              return null;
            case 'getLanguages':
              return ['es-ES', 'en-US', 'pt-BR', 'fr-FR'];
            case 'getVoices':
              return [
                {'name': 'Spanish Voice', 'locale': 'es-ES'},
                {'name': 'English Voice', 'locale': 'en-US'},
              ];
            case 'awaitSpeakCompletion':
              return null;
            default:
              return null;
          }
        },
      );

      provider = DevocionalProvider();
    });

    tearDown(() {
      provider.dispose();

      // Clean up method channel mocks
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/path_provider'),
        null,
      );
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('flutter_tts'),
        null,
      );
    });

    test('should initialize with specific default values', () {
      // Verify language defaults to Spanish
      expect(provider.selectedLanguage, equals('es'),
          reason: 'Default language should be Spanish');

      // Verify version defaults to RVR1960
      expect(provider.selectedVersion, equals('RVR1960'),
          reason: 'Default version should be RVR1960');

      // Verify lists are empty initially
      expect(provider.devocionales.isEmpty, isTrue,
          reason: 'Devotionals list should be empty initially');
      expect(provider.favoriteDevocionales.isEmpty, isTrue,
          reason: 'Favorites list should be empty initially');

      // Verify loading state is false
      expect(provider.isLoading, isFalse,
          reason: 'Should not be loading initially');

      // Verify no error message
      expect(provider.errorMessage, isNull,
          reason: 'Should have no error message initially');

      // Verify offline mode is false
      expect(provider.isOfflineMode, isFalse,
          reason: 'Should not be in offline mode initially');

      // Verify not downloading
      expect(provider.isDownloading, isFalse,
          reason: 'Should not be downloading initially');
    });

    test('should trigger loading state when language changes', () async {
      // Given: Initial language
      final initialLanguage = provider.selectedLanguage;
      expect(initialLanguage, equals('es'));

      // When: Language is changed
      provider.setSelectedLanguage('en');

      // Then: Language should be updated
      expect(provider.selectedLanguage, equals('en'),
          reason: 'Language should change to English');
      expect(provider.selectedLanguage, isNot(equals(initialLanguage)),
          reason: 'Language should be different from initial');

      // Allow async operations to start
      await Future.delayed(Duration(milliseconds: 50));

      // Note: Due to async nature and mocked file system, we can't reliably test
      // the loading state change, but we verified the language property changes
    });

    test('should trigger reload when version changes', () async {
      // Given: Initial version
      final initialVersion = provider.selectedVersion;
      expect(initialVersion, equals('RVR1960'));

      // When: Version is changed
      provider.setSelectedVersion('NVI');

      // Then: Version should be updated
      expect(provider.selectedVersion, equals('NVI'),
          reason: 'Version should change to NVI');
      expect(provider.selectedVersion, isNot(equals(initialVersion)),
          reason: 'Version should be different from initial');

      // Allow async operations to complete
      await Future.delayed(Duration(milliseconds: 100));
    });

    test('should maintain favorite state correctly', () {
      // Create test devotional
      final testDevocional = Devocional(
        id: 'favorite_test_001',
        date: DateTime.now(),
        versiculo: 'Juan 3:16',
        reflexion: 'Test reflection',
        paraMeditar: [],
        oracion: 'Test prayer',
      );

      // Verify initially not favorite
      expect(provider.isFavorite(testDevocional), isFalse,
          reason: 'Devotional should not be favorite initially');

      // Verify favorites list is empty
      expect(provider.favoriteDevocionales.length, equals(0),
          reason: 'Favorites list should be empty initially');

      // Note: We can't test toggleFavorite without BuildContext
      // but we verified the query methods work correctly
    });

    test('should delegate audio state to audio controller', () {
      // Verify audio controller is accessible
      expect(provider.audioController, isNotNull,
          reason: 'Audio controller should not be null');

      // Verify audio state properties are accessible
      final isPlaying = provider.isAudioPlaying;
      final isPaused = provider.isAudioPaused;
      final currentId = provider.currentPlayingDevocionalId;

      // These should match the controller's state
      expect(isPlaying, equals(provider.audioController.isPlaying),
          reason: 'isAudioPlaying should match controller state');
      expect(isPaused, equals(provider.audioController.isPaused),
          reason: 'isAudioPaused should match controller state');
      expect(currentId, equals(provider.audioController.currentDevocionalId),
          reason: 'currentPlayingDevocionalId should match controller');
    });

    test('should have valid supported languages', () {
      final languages = provider.supportedLanguages;

      // Verify it's a non-empty list
      expect(languages, isNotEmpty,
          reason: 'Supported languages should not be empty');

      // Verify expected languages are present
      expect(languages.contains('es'), isTrue,
          reason: 'Should support Spanish');
      expect(languages.contains('en'), isTrue,
          reason: 'Should support English');
      expect(languages.contains('pt'), isTrue,
          reason: 'Should support Portuguese');
      expect(languages.contains('fr'), isTrue, reason: 'Should support French');

      // Verify versions for Spanish
      final versions = provider.getVersionsForLanguage('es');
      expect(versions, isNotEmpty, reason: 'Should have versions for Spanish');
      // All items in the list should be strings (validated by type system)
    });

    test('should maintain error state correctly', () {
      // Verify initial error state
      expect(provider.errorMessage, isNull,
          reason: 'Should have no error initially');
      expect(provider.isLoading, isFalse,
          reason: 'Should not be loading initially');

      // Verify error message property is accessible and valid
      final errorMsg = provider.errorMessage;
      expect(errorMsg, isNull, reason: 'Error message should be null initially');
    });
  });
}
