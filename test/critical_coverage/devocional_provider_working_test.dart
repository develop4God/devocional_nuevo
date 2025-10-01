import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:devocional_nuevo/providers/devocional_provider.dart';
import 'package:devocional_nuevo/models/devocional_model.dart';
import 'package:flutter/material.dart';

void main() {
  late DevocionalProvider provider;

  // Mock canales plataforma externos (path_provider, flutter_tts)
  const MethodChannel pathProviderChannel =
      MethodChannel('plugins.flutter.io/path_provider');
  const MethodChannel ttsChannel = MethodChannel('flutter_tts');

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();

    pathProviderChannel.setMockMethodCallHandler((MethodCall methodCall) async {
      switch (methodCall.method) {
        case 'getApplicationDocumentsDirectory':
          return '/mock_documents';
        case 'getTemporaryDirectory':
          return '/mock_temp';
        default:
          return null;
      }
    });

    ttsChannel.setMockMethodCallHandler((MethodCall call) async {
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
    });
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({}); // Reset SharedPreferences
    provider = DevocionalProvider();
    await provider.initializeData();
  });

  tearDown(() {
    provider.dispose();

    pathProviderChannel.setMockMethodCallHandler(null);
    ttsChannel.setMockMethodCallHandler(null);
  });

  group('DevocionalProvider Robust Tests', () {
    test('initial state validation', () {
      expect(provider.selectedLanguage, 'es', reason: 'Default language is es');
      expect(provider.selectedVersion, 'RVR1960',
          reason: 'Default version is RVR1960');
      expect(provider.isLoading, isFalse);
      expect(provider.errorMessage, isNull);
      expect(provider.devocionales, isEmpty);
      expect(provider.favoriteDevocionales, isEmpty);
      expect(provider.isOfflineMode, isFalse);
      expect(provider.isDownloading, isFalse);
      expect(provider.downloadStatus, isNull);
    });

    test('supported languages and fallback behavior', () {
      expect(provider.supportedLanguages, contains('es'));
      expect(provider.supportedLanguages, contains('en'));
      // Fallback language on unsupported input
      provider.setSelectedLanguage('unsupported');
      expect(provider.selectedLanguage, 'es');
    });

    test('changing language updates data and version defaults', () async {
      await provider.setSelectedLanguage('en');
      expect(provider.selectedLanguage, 'en');
      expect(provider.selectedVersion, isNotNull);
      expect(provider.devocionales.isEmpty, isFalse);
    });

    test('changing version updates data', () async {
      final oldVersion = provider.selectedVersion;
      await provider.setSelectedVersion('NVI');
      expect(provider.selectedVersion, 'NVI');
      expect(provider.selectedVersion != oldVersion, isTrue);
    });

    test('favorite management works correctly', () async {
      final devotional = Devocional(
        id: 'fav_test_1',
        date: DateTime.now(),
        versiculo: 'Sample',
        reflexion: 'Sample reflection',
        paraMeditar: [],
        oracion: 'Sample prayer',
      );

      expect(provider.isFavorite(devotional), isFalse);
      provider.toggleFavorite(devotional,
          TestWidgetsFlutterBinding.ensureInitialized().renderViewElement!);
      expect(provider.isFavorite(devotional), isTrue);
      provider.toggleFavorite(devotional,
          TestWidgetsFlutterBinding.ensureInitialized().renderViewElement!);
      expect(provider.isFavorite(devotional), isFalse);
    });

    test('audio methods delegate without error', () async {
      final devotional = Devocional(
        id: 'audio_test',
        date: DateTime.now(),
        versiculo: 'Test',
        reflexion: 'Test',
        paraMeditar: [],
        oracion: 'Test',
      );

      await provider.playDevotional(devotional);
      await provider.pauseAudio();
      await provider.resumeAudio();
      await provider.stopAudio();
      await provider.toggleAudioPlayPause(devotional);

      final languages = await provider.getAvailableLanguages();
      expect(languages, contains('es-ES'));

      final voices = await provider.getAvailableVoices();
      expect(voices, isNotEmpty);
      final voicesForLang = await provider.getVoicesForLanguage('es');
      expect(voicesForLang, isNotEmpty);

      await provider.setTtsLanguage('es-ES');
      await provider.setTtsVoice({'name': 'Voice ES', 'locale': 'es-ES'});
      await provider.setTtsSpeechRate(0.5);
    });

    test('reading tracking and recording works correctly', () async {
      provider.startDevocionalTracking('track_id');
      expect(provider.currentTrackedDevocionalId, 'track_id');

      provider.pauseTracking();
      provider.resumeTracking();

      await provider.recordDevocionalRead('track_id');
      expect(provider.currentReadingSeconds >= 0, isTrue);
      expect(provider.currentScrollPercentage >= 0.0, isTrue);
    });

    test('offline download and storage lifecycle', () async {
      // Simulate download current year devocionales
      bool downloaded = await provider.downloadCurrentYearDevocionales();
      expect(downloaded, isTrue);

      bool hasLocal = await provider.hasCurrentYearLocalData();
      expect(hasLocal, isTrue);

      // Download for specific year
      bool specificDownload =
          await provider.downloadDevocionalesForYear(DateTime.now().year);
      expect(specificDownload, isTrue);

      // Clear local files test
      await provider.clearOldLocalFiles();

      bool hasAfterClear = await provider.hasCurrentYearLocalData();
      expect(hasAfterClear, isFalse);
    });

    test('error handling in loading data', () async {
      // Forcing unsupported language and version, setting wrong values forcibly in prefs could induce error states.
      SharedPreferences.setMockInitialValues({
        'selectedLanguage': 'zz',
        'selectedVersion': 'bad_version',
      });

      provider = DevocionalProvider();
      await provider.initializeData();

      expect(provider.errorMessage, isNotNull);
    });

    test('invitation dialog preference management', () async {
      expect(provider.showInvitationDialog, isTrue);
      await provider.setInvitationDialogVisibility(false);
      expect(provider.showInvitationDialog, isFalse);
    });

    test('utility methods behave correctly', () async {
      expect(provider.isLanguageSupported('es'), isTrue);
      expect(provider.isLanguageSupported('xyz'), isFalse);

      final success = await provider.downloadDevocionalesWithProgress(
        onProgress: (progress) {},
        startYear: DateTime.now().year,
        endYear: DateTime.now().year + 1,
      );
      expect(success, isA<bool>());
    });
  });
}
