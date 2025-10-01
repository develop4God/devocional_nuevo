// test/critical_coverage/devocional_provider_working_test.dart
// ✅ PERIPHERAL TESTING - Probando comportamiento observable, sin mocks internos

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:devocional_nuevo/providers/devocional_provider.dart';
import 'package:devocional_nuevo/models/devocional_model.dart';

void main() {
  group('DevocionalProvider - Peripheral Behavior Tests', () {
    late DevocionalProvider provider;

    setUpAll(() {
      TestWidgetsFlutterBinding.ensureInitialized();
    });

    setUp(() {
      SharedPreferences.setMockInitialValues({});

      // Mock solo platform channels (infraestructura externa)
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

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('flutter_tts'),
        (call) async {
          switch (call.method) {
            case 'speak':
            case 'stop':
            case 'pause':
            case 'setLanguage':
            case 'setSpeechRate':
            case 'setVolume':
            case 'setPitch':
            case 'awaitSpeakCompletion':
              return null;
            case 'getLanguages':
              return ['es-ES', 'en-US'];
            case 'getVoices':
              return [
                {'name': 'Voice ES', 'locale': 'es-ES'},
                {'name': 'Voice EN', 'locale': 'en-US'},
              ];
            default:
              return null;
          }
        },
      );

      provider = DevocionalProvider();
    });

    tearDown() {
      provider.dispose();

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

    // ========== TESTS DE ESTADO INICIAL ==========

    test('should initialize with expected default configuration', () {
      // Valores por defecto documentados en la implementación
      expect(provider.selectedLanguage, equals('es'),
          reason: 'Default language should be Spanish');
      
      expect(provider.selectedVersion, equals('RVR1960'),
          reason: 'Default version should be RVR1960');
      
      expect(provider.isLoading, isFalse,
          reason: 'Should not be loading initially');
      
      expect(provider.errorMessage, isNull,
          reason: 'Should have no error message initially');
    });

    test('should start with empty collections', () {
      expect(provider.devocionales, isEmpty,
          reason: 'Devotionals list should be empty before loading');
      
      expect(provider.favoriteDevocionales, isEmpty,
          reason: 'Favorites should be empty initially');
    });

    test('should start in online mode without downloads', () {
      expect(provider.isOfflineMode, isFalse,
          reason: 'Should start in online mode');
      
      expect(provider.isDownloading, isFalse,
          reason: 'Should not be downloading initially');
      
      expect(provider.downloadStatus, isNull,
          reason: 'Download status should be null initially');
    });

    test('should have audio controller initialized', () {
      // AudioController debe estar disponible
      expect(provider.audioController, isNotNull,
          reason: 'Audio controller should be initialized');
      
      // Estados de audio iniciales
      expect(provider.isAudioPlaying, isFalse,
          reason: 'Audio should not be playing initially');
      
      expect(provider.isAudioPaused, isFalse,
          reason: 'Audio should not be paused initially');
      
      expect(provider.currentPlayingDevocionalId, isNull,
          reason: 'No devotional should be playing initially');
    });

    // ========== TESTS DE IDIOMAS Y VERSIONES ==========

    test('should provide supported languages list', () {
      final languages = provider.supportedLanguages;
      
      expect(languages, isNotEmpty,
          reason: 'Should have at least one supported language');
      
      expect(languages.contains('es'), isTrue,
          reason: 'Spanish should be in supported languages');
      
      expect(languages.contains('en'), isTrue,
          reason: 'English should be in supported languages');
    });

    test('should provide versions for each language', () {
      // Para español
      final esVersions = provider.getVersionsForLanguage('es');
      expect(esVersions, isNotEmpty,
          reason: 'Spanish should have available versions');
      expect(esVersions.contains('RVR1960'), isTrue,
          reason: 'RVR1960 should be available for Spanish');
      
      // Para inglés  
      final enVersions = provider.getVersionsForLanguage('en');
      expect(enVersions, isNotEmpty,
          reason: 'English should have available versions');
    });

    test('should have non-empty available versions list', () {
      final versions = provider.availableVersions;
      
      expect(versions, isNotEmpty,
          reason: 'Should have available versions for current language');
    });

    // ========== TESTS DE CAMBIO DE CONFIGURACIÓN ==========

    test('should update selected language when changed', () {
      final initialLanguage = provider.selectedLanguage;
      expect(initialLanguage, equals('es'));
      
      // Cambiar a inglés
      provider.setSelectedLanguage('en');
      
      expect(provider.selectedLanguage, equals('en'),
          reason: 'Language should update to English');
      
      // Cambiar a otro idioma soportado
      provider.setSelectedLanguage('pt');
      
      expect(provider.selectedLanguage, equals('pt'),
          reason: 'Language should update to Portuguese');
    });

    test('should update selected version when changed', () {
      final initialVersion = provider.selectedVersion;
      expect(initialVersion, equals('RVR1960'));
      
      // Cambiar versión
      provider.setSelectedVersion('NVI');
      
      expect(provider.selectedVersion, equals('NVI'),
          reason: 'Version should update to NVI');
    });

    test('should fallback to supported language if unsupported requested', () {
      // Intentar establecer idioma no soportado
      provider.setSelectedLanguage('unsupported_xyz');
      
      // Debe caer a un idioma soportado (español por defecto)
      final languages = provider.supportedLanguages;
      expect(languages.contains(provider.selectedLanguage), isTrue,
          reason: 'Should fallback to supported language');
    });

    // ========== TESTS DE GESTIÓN DE FAVORITOS ==========

    test('should correctly report favorite status', () {
      final devocional = Devocional(
        id: 'test_fav_1',
        date: DateTime.now(),
        versiculo: 'Test verse',
        reflexion: 'Test reflection',
        paraMeditar: [],
        oracion: 'Test prayer',
      );

      // Inicialmente no es favorito
      expect(provider.isFavorite(devocional), isFalse,
          reason: 'New devotional should not be favorite');
      
      expect(provider.favoriteDevocionales.length, equals(0),
          reason: 'Favorites list should be empty');
    });

    test('should provide empty favorites list initially', () {
      final favorites = provider.favoriteDevocionales;
      
      expect(favorites, isA<List<Devocional>>(),
          reason: 'Favorites should be a list');
      
      expect(favorites.isEmpty, isTrue,
          reason: 'Favorites should be empty initially');
    });

    // ========== TESTS DE DELEGACIÓN A AUDIO CONTROLLER ==========

    test('should delegate isDevocionalPlaying to audio controller', () {
      // Sin audio cargado, debe retornar false
      expect(provider.isDevocionalPlaying('any_id'), isFalse,
          reason: 'No devotional should be playing initially');
    });

    test('should expose audio controller state through getters', () {
      // Verificar que las propiedades delegadas funcionan
      expect(provider.isAudioPlaying, isA<bool>());
      expect(provider.isAudioPaused, isA<bool>());
      expect(provider.currentPlayingDevocionalId, isA<String?>());
      
      // En estado inicial, valores esperados
      expect(provider.isAudioPlaying, isFalse);
      expect(provider.isAudioPaused, isFalse);
      expect(provider.currentPlayingDevocionalId, isNull);
    });

    // ========== TESTS DE FUNCIONALIDAD OFFLINE ==========

    test('should expose offline functionality methods', () {
      // Verificar que los métodos existen y retornan tipos correctos
      expect(provider.hasCurrentYearLocalData(), isA<Future<bool>>());
      expect(provider.hasTargetYearsLocalData(), isA<Future<bool>>());
    });

    test('should track download state', () {
      expect(provider.isDownloading, isA<bool>());
      expect(provider.downloadStatus, isA<String?>());
      expect(provider.isOfflineMode, isA<bool>());
    });

    // ========== TESTS DE MÉTODOS PÚBLICOS (Existencia) ==========

    test('should provide audio control methods', () {
      final devocional = Devocional(
        id: 'test_audio',
        date: DateTime.now(),
        versiculo: 'Test',
        reflexion: 'Test',
        paraMeditar: [],
        oracion: 'Test',
      );

      // Verificar que los métodos existen y aceptan llamadas
      expect(() => provider.playDevotional(devocional), returnsNormally);
      expect(() => provider.pauseAudio(), returnsNormally);
      expect(() => provider.resumeAudio(), returnsNormally);
      expect(() => provider.stopAudio(), returnsNormally);
    });

    test('should provide TTS configuration methods', () {
      // Verificar que los métodos delegados existen
      expect(() => provider.getAvailableLanguages(), returnsNormally);
      expect(() => provider.getAvailableVoices(), returnsNormally);
      expect(() => provider.getVoicesForLanguage('es'), returnsNormally);
    });

    // ========== TESTS DE READING TRACKER ==========

    test('should expose reading tracking state', () {
      expect(provider.currentReadingSeconds, isA<int>());
      expect(provider.currentScrollPercentage, isA<double>());
      expect(provider.currentTrackedDevocionalId, isA<String?>());
      
      // Inicialmente sin tracking
      expect(provider.currentReadingSeconds, equals(0));
      expect(provider.currentScrollPercentage, equals(0.0));
      expect(provider.currentTrackedDevocionalId, isNull);
    });

    test('should provide tracking control methods', () {
      // Verificar que los métodos existen
      expect(() => provider.startDevocionalTracking('test_id'), 
          returnsNormally);
      expect(() => provider.pauseTracking(), returnsNormally);
      expect(() => provider.resumeTracking(), returnsNormally);
    });

    // ========== TESTS DE ESTADOS Y FLAGS ==========

    test('should track loading and error states', () {
      expect(provider.isLoading, isA<bool>());
      expect(provider.errorMessage, isA<String?>());
      
      // Estado inicial
      expect(provider.isLoading, isFalse);
      expect(provider.errorMessage, isNull);
    });

    test('should manage invitation dialog preference', () {
      expect(provider.showInvitationDialog, isA<bool>());
      
      // Por defecto debe ser true
      expect(provider.showInvitationDialog, isTrue,
          reason: 'Invitation dialog should be shown by default');
    });

    // ========== TESTS DE UTILIDAD ==========

    test('should validate language support correctly', () {
      expect(provider.isLanguageSupported('es'), isTrue,
          reason: 'Spanish should be supported');
      
      expect(provider.isLanguageSupported('en'), isTrue,
          reason: 'English should be supported');
      
      expect(provider.isLanguageSupported('xyz'), isFalse,
          reason: 'Invalid language should not be supported');
    });

    test('should provide download methods for different years', () {
      // Verificar que los métodos existen y retornan Future<bool>
      expect(provider.downloadCurrentYearDevocionales(), isA<Future<bool>>());
      expect(provider.downloadDevocionalesForYear(2025), isA<Future<bool>>());
    });
  });
}
