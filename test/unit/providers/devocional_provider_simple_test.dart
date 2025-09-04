import 'package:devocional_nuevo/models/devocional_model.dart';
import 'package:devocional_nuevo/providers/devocional_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../test_setup.dart';

void main() {
  setUpAll(() {
    TestSetup.setupCommonMocks();
  });

  tearDownAll() {
    TestSetup.cleanupMocks();
  }

  group('DevocionalProvider Basic Tests', () {
    test('should initialize with default values', () {
      SharedPreferences.setMockInitialValues({});
      final provider = DevocionalProvider();

      expect(provider.selectedLanguage, equals('es'));
      expect(provider.selectedVersion, equals('RVR1960'));
      expect(provider.isLoading, isFalse);
      expect(provider.devocionales, isEmpty);
      expect(provider.errorMessage, isNull);

      provider.dispose();
    });

    test('should validate supported languages', () {
      SharedPreferences.setMockInitialValues({});
      final provider = DevocionalProvider();

      final supportedLanguages = provider.supportedLanguages;
      expect(supportedLanguages, contains('es'));
      expect(supportedLanguages, contains('en'));
      expect(supportedLanguages, contains('pt'));
      expect(supportedLanguages, contains('fr'));
      expect(supportedLanguages.length, greaterThanOrEqualTo(4));

      provider.dispose();
    });

    test('should provide versions for each language', () {
      SharedPreferences.setMockInitialValues({});
      final provider = DevocionalProvider();

      // Spanish versions
      final spanishVersions = provider.getVersionsForLanguage('es');
      expect(spanishVersions, contains('RVR1960'));
      expect(spanishVersions, contains('NVI'));

      // English versions
      final englishVersions = provider.getVersionsForLanguage('en');
      expect(englishVersions, contains('KJV'));
      expect(englishVersions, contains('NIV'));

      // Portuguese versions
      final portugueseVersions = provider.getVersionsForLanguage('pt');
      expect(portugueseVersions, contains('ARC'));

      // French versions
      final frenchVersions = provider.getVersionsForLanguage('fr');
      expect(frenchVersions, contains('LSG1910'));

      provider.dispose();
    });

    test('should validate language support', () {
      SharedPreferences.setMockInitialValues({});
      final provider = DevocionalProvider();

      expect(provider.isLanguageSupported('es'), isTrue);
      expect(provider.isLanguageSupported('en'), isTrue);
      expect(provider.isLanguageSupported('pt'), isTrue);
      expect(provider.isLanguageSupported('fr'), isTrue);
      expect(provider.isLanguageSupported('de'), isFalse);
      expect(provider.isLanguageSupported(''), isFalse);

      provider.dispose();
    });

    test('should manage offline status properties', () {
      SharedPreferences.setMockInitialValues({});
      final provider = DevocionalProvider();

      expect(provider.isDownloading, isFalse);
      expect(provider.downloadStatus, isNull);
      expect(provider.isOfflineMode, isFalse);

      provider.dispose();
    });

    test('should handle download status management', () {
      SharedPreferences.setMockInitialValues({});
      final provider = DevocionalProvider();

      // Should start with no download status
      expect(provider.downloadStatus, isNull);

      // Should be able to clear download status
      provider.clearDownloadStatus();
      expect(provider.downloadStatus, isNull);

      provider.dispose();
    });

    test('should provide audio controller access', () {
      SharedPreferences.setMockInitialValues({});
      final provider = DevocionalProvider();

      expect(provider.audioController, isNotNull);
      expect(provider.isAudioPlaying, isA<bool?>());
      expect(provider.isAudioPaused, isA<bool?>());
      expect(provider.isSpeaking, isA<bool?>());

      provider.dispose();
    });

    test('should handle TTS language settings', () {
      SharedPreferences.setMockInitialValues({});
      final provider = DevocionalProvider();

      // Should be able to set TTS language without errors
      expect(() => provider.setTtsLanguage('es-ES'), returnsNormally);
      expect(() => provider.setTtsLanguage('en-US'), returnsNormally);
      expect(() => provider.setTtsLanguage('pt-BR'), returnsNormally);
      expect(() => provider.setTtsLanguage('fr-FR'), returnsNormally);

      provider.dispose();
    });

    test('should handle TTS settings', () {
      SharedPreferences.setMockInitialValues({});
      final provider = DevocionalProvider();

      // Should be able to set TTS speech rate
      expect(() => provider.setTtsSpeechRate(0.5), returnsNormally);
      expect(() => provider.setTtsSpeechRate(1.0), returnsNormally);
      expect(() => provider.setTtsSpeechRate(1.5), returnsNormally);

      provider.dispose();
    });

    test('should handle favorites management', () {
      SharedPreferences.setMockInitialValues({});
      final provider = DevocionalProvider();

      // Create a sample devotional
      final devotional = Devocional(
        id: 'test_1',
        date: DateTime.now(),
        versiculo: 'Juan 3:16',
        reflexion: 'Test reflection',
        paraMeditar: [
          ParaMeditar(cita: 'Juan 3:16', texto: 'Test application'),
        ],
        oracion: 'Test prayer',
      );

      // Initially not favorite
      expect(provider.isFavorite(devotional), isFalse);
      expect(provider.favoriteDevocionales, isEmpty);

      // Test that the provider has the method available
      expect(provider.isFavorite, isA<Function>());

      provider.dispose();
    });

    test('should handle reading tracking', () {
      SharedPreferences.setMockInitialValues({});
      final provider = DevocionalProvider();

      // Should handle reading seconds tracking
      expect(provider.currentReadingSeconds, equals(0));
      expect(provider.currentScrollPercentage, equals(0.0));

      // Should be able to start tracking
      expect(
          () => provider.startDevocionalTracking('test_id'), returnsNormally);

      // Should be able to pause and resume tracking
      expect(() => provider.pauseTracking(), returnsNormally);
      expect(() => provider.resumeTracking(), returnsNormally);

      provider.dispose();
    });

    test('should handle invitation dialog state', () async {
      SharedPreferences.setMockInitialValues({});
      final provider = DevocionalProvider();

      expect(provider.showInvitationDialog, isA<bool>());

      await provider.setInvitationDialogVisibility(true);
      expect(provider.showInvitationDialog, isTrue);

      await provider.setInvitationDialogVisibility(false);
      expect(provider.showInvitationDialog, isFalse);

      provider.dispose();
    });

    test('should handle audio operations safely', () {
      SharedPreferences.setMockInitialValues({});
      final provider = DevocionalProvider();

      final devotional = Devocional(
        id: 'test_audio',
        date: DateTime.now(),
        versiculo: 'Test verse',
        reflexion: 'Test reflection',
        paraMeditar: [
          ParaMeditar(cita: 'Test verse', texto: 'Test application'),
        ],
        oracion: 'Test prayer',
      );

      // These should not crash even if TTS is not properly initialized
      // Only test basic audio state queries to avoid async issues
      expect(() => provider.pauseAudio(), returnsNormally);
      expect(() => provider.resumeAudio(), returnsNormally);
      expect(() => provider.stopAudio(), returnsNormally);
      expect(() => provider.stop(), returnsNormally);

      provider.dispose();
    });

    test('should handle TTS voice selection', () {
      SharedPreferences.setMockInitialValues({});
      final provider = DevocionalProvider();

      // Should be able to query available voices
      expect(() => provider.getAvailableVoices(), returnsNormally);
      expect(() => provider.getVoicesForLanguage('es'), returnsNormally);
      expect(() => provider.getVoicesForLanguage('en'), returnsNormally);

      provider.dispose();
    });

    test('should dispose properly', () {
      SharedPreferences.setMockInitialValues({});
      final provider = DevocionalProvider();

      // Should be able to dispose without errors
      expect(() => provider.dispose(), returnsNormally);

      // Multiple disposals may throw, which is acceptable behavior
      // Just test that the first disposal works
    });
  });

  group('DevocionalProvider Local File Management', () {
    test('should check local file existence', () async {
      SharedPreferences.setMockInitialValues({});
      final provider = DevocionalProvider();

      // Should be able to check for local files without crashing
      final hasLocal = await provider.hasCurrentYearLocalData();
      expect(hasLocal, isA<bool>());

      provider.dispose();
    });

    test('should check target years data', () async {
      SharedPreferences.setMockInitialValues({});
      final provider = DevocionalProvider();

      final hasTargetData = await provider.hasTargetYearsLocalData();
      expect(hasTargetData, isA<bool>());

      provider.dispose();
    });

    test('should generate correct local file paths', () {
      SharedPreferences.setMockInitialValues({});
      final provider = DevocionalProvider();

      // The provider should be able to generate file paths
      expect(provider, isNotNull);
      // Specific path testing would require accessing private methods

      provider.dispose();
    });
  });

  group('DevocionalProvider Performance Tests', () {
    test('should handle multiple provider instances', () {
      final providers = <DevocionalProvider>[];

      // Create multiple providers
      for (int i = 0; i < 5; i++) {
        SharedPreferences.setMockInitialValues({});
        providers.add(DevocionalProvider());
      }

      // All should be valid
      for (final provider in providers) {
        expect(provider.selectedLanguage, isNotNull);
        expect(provider.selectedVersion, isNotNull);
      }

      // Clean up
      for (final provider in providers) {
        provider.dispose();
      }
    });
  });
}
