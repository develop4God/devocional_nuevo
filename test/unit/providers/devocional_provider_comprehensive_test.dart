import 'package:devocional_nuevo/models/devocional_model.dart';
import 'package:devocional_nuevo/providers/devocional_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../test_setup.dart';

void main() {
  setUpAll(() {
    TestSetup.setupCommonMocks();
  });

  tearDownAll(() {
    TestSetup.cleanupMocks();
  });

  group('DevocionalProvider Core Functionality', () {
    late DevocionalProvider provider;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      provider = DevocionalProvider();
    });

    tearDown(() {
      provider.dispose();
    });

    test('should initialize with default values', () {
      expect(provider.selectedLanguage, equals('es'));
      expect(provider.selectedVersion, equals('RVR1960'));
      expect(provider.isLoading, isFalse);
      expect(provider.devocionales, isEmpty);
      expect(provider.errorMessage, isNull);
    });

    test('should handle language switching', () async {
      // Test valid language switches
      provider.setSelectedLanguage('en');
      // Wait a moment for async operations to complete
      await Future.delayed(const Duration(milliseconds: 100));
      expect(provider.selectedLanguage, equals('en'));
      expect(
          provider.selectedVersion, equals('KJV')); // Should reset to default

      provider.setSelectedLanguage('pt');
      await Future.delayed(const Duration(milliseconds: 100));
      expect(provider.selectedLanguage, equals('pt'));
      expect(provider.selectedVersion, equals('ARC'));

      provider.setSelectedLanguage('fr');
      await Future.delayed(const Duration(milliseconds: 100));
      expect(provider.selectedLanguage, equals('fr'));
      expect(provider.selectedVersion, equals('LSG1910'));
    });

    test('should handle version switching within same language', () {
      // Start with Spanish
      expect(provider.selectedLanguage, equals('es'));
      expect(provider.selectedVersion, equals('RVR1960'));

      // Switch to NVI
      provider.setSelectedVersion('NVI');
      expect(provider.selectedLanguage, equals('es')); // Language unchanged
      expect(provider.selectedVersion, equals('NVI'));

      // Switch back to RVR1960
      provider.setSelectedVersion('RVR1960');
      expect(provider.selectedVersion, equals('RVR1960'));
    });

    test('should validate supported languages', () {
      final supportedLanguages = provider.supportedLanguages;
      expect(supportedLanguages, contains('es'));
      expect(supportedLanguages, contains('en'));
      expect(supportedLanguages, contains('pt'));
      expect(supportedLanguages, contains('fr'));
      expect(supportedLanguages.length, greaterThanOrEqualTo(4));
    });

    test('should provide versions for each language', () {
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
    });

    test('should handle unsupported language gracefully', () {
      provider.setSelectedLanguage('de'); // German - not supported
      expect(provider.selectedLanguage,
          equals('es')); // Should fallback to Spanish
      expect(provider.selectedVersion, equals('RVR1960'));
    });

    test('should validate language support', () {
      expect(provider.isLanguageSupported('es'), isTrue);
      expect(provider.isLanguageSupported('en'), isTrue);
      expect(provider.isLanguageSupported('pt'), isTrue);
      expect(provider.isLanguageSupported('fr'), isTrue);
      expect(provider.isLanguageSupported('de'), isFalse);
      expect(provider.isLanguageSupported(''), isFalse);
    });

    test('should handle version validation', () {
      // Valid versions for current language (Spanish)
      final spanishVersions = provider.availableVersions;
      for (final version in spanishVersions) {
        provider.setSelectedVersion(version);
        expect(provider.selectedVersion, equals(version));
      }
    });

    test('should manage offline status properties', () {
      expect(provider.isDownloading, isFalse);
      expect(provider.downloadStatus, isNull);
      expect(provider.isOfflineMode, isFalse);
    });

    test('should handle download status management', () {
      // Should start with no download status
      expect(provider.downloadStatus, isNull);

      // Should be able to clear download status
      provider.clearDownloadStatus();
      expect(provider.downloadStatus, isNull);
    });

    test('should provide audio controller access', () {
      expect(provider.audioController, isNotNull);
      expect(provider.isAudioPlaying, isFalse);
      expect(provider.isAudioPaused, isFalse);
      expect(provider.isSpeaking, isFalse);
    });

    test('should handle TTS language settings', () {
      // Should be able to set TTS language without errors
      expect(() => provider.setTtsLanguage('es-ES'), returnsNormally);
      expect(() => provider.setTtsLanguage('en-US'), returnsNormally);
      expect(() => provider.setTtsLanguage('pt-BR'), returnsNormally);
      expect(() => provider.setTtsLanguage('fr-FR'), returnsNormally);
    });

    test('should handle TTS settings', () {
      // Should be able to set TTS speech rate
      expect(() => provider.setTtsSpeechRate(0.5), returnsNormally);
      expect(() => provider.setTtsSpeechRate(1.0), returnsNormally);
      expect(() => provider.setTtsSpeechRate(1.5), returnsNormally);
    });

    test('should handle favorites management', () {
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
    });

    test('should handle reading tracking', () {
      // Should handle reading seconds tracking
      expect(provider.currentReadingSeconds, equals(0));
      expect(provider.currentScrollPercentage, equals(0.0));

      // Should be able to start tracking
      expect(
          () => provider.startDevocionalTracking('test_id'), returnsNormally);

      // Should be able to pause and resume tracking
      expect(() => provider.pauseTracking(), returnsNormally);
      expect(() => provider.resumeTracking(), returnsNormally);
    });

    test('should handle invitation dialog state', () {
      expect(provider.showInvitationDialog, isFalse);

      provider.setInvitationDialogVisibility(true);
      expect(provider.showInvitationDialog, isTrue);

      provider.setInvitationDialogVisibility(false);
      expect(provider.showInvitationDialog, isFalse);
    });

    test('should handle error states', () {
      expect(provider.errorMessage, isNull);
      // Error handling is typically internal, but we can test that it doesn't crash
    });

    test('should handle audio operations safely', () {
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
      expect(() => provider.playDevotional(devotional), returnsNormally);
      expect(() => provider.pauseAudio(), returnsNormally);
      expect(() => provider.resumeAudio(), returnsNormally);
      expect(() => provider.stopAudio(), returnsNormally);
      expect(() => provider.stop(), returnsNormally);
    });

    test('should handle TTS voice selection', () {
      // Should be able to query available voices
      expect(() => provider.getAvailableVoices(), returnsNormally);
      expect(() => provider.getVoicesForLanguage('es'), returnsNormally);
      expect(() => provider.getVoicesForLanguage('en'), returnsNormally);
    });

    test('should dispose properly', () {
      // Should be able to dispose without errors
      expect(() => provider.dispose(), returnsNormally);

      // Should handle multiple disposals gracefully
      expect(() => provider.dispose(), returnsNormally);
    });
  });

  group('DevocionalProvider Local File Management', () {
    late DevocionalProvider provider;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      provider = DevocionalProvider();
    });

    tearDown(() {
      provider.dispose();
    });

    test('should check local file existence', () async {
      // Should be able to check for local files without crashing
      final hasLocal = await provider.hasCurrentYearLocalData();
      expect(hasLocal, isA<bool>());
    });

    test('should check target years data', () async {
      final hasTargetData = await provider.hasTargetYearsLocalData();
      expect(hasTargetData, isA<bool>());
    });

    test('should handle local file management', () async {
      expect(() => provider.clearOldLocalFiles(), returnsNormally);
    });

    test('should generate correct local file paths', () {
      // The provider should be able to generate file paths
      expect(provider, isNotNull);
      // Specific path testing would require accessing private methods
    });
  });

  group('DevocionalProvider Performance Tests', () {
    test('should handle rapid language switches', () {
      final provider = DevocionalProvider();

      // Rapid language switching should not cause issues
      for (int i = 0; i < 10; i++) {
        provider.setSelectedLanguage('es');
        provider.setSelectedLanguage('en');
        provider.setSelectedLanguage('pt');
        provider.setSelectedLanguage('fr');
      }

      expect(provider.selectedLanguage, isNotNull);
      provider.dispose();
    });

    test('should handle multiple provider instances', () {
      final providers = <DevocionalProvider>[];

      // Create multiple providers
      for (int i = 0; i < 5; i++) {
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
