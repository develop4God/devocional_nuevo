import 'package:flutter_test/flutter_test.dart';
import 'package:devocional_nuevo/providers/devocional_provider.dart';
import 'package:devocional_nuevo/utils/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Offline Download Logic Tests', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
    });

    test('should generate correct API URLs for all language/version combinations', () {
      const testYear = 2025;

      // Test Spanish backward compatibility
      final spanishRvr1960Url = Constants.getDevocionalesApiUrlMultilingual(testYear, 'es', 'RVR1960');
      expect(spanishRvr1960Url, equals('https://raw.githubusercontent.com/develop4God/Devocionales-json/refs/heads/main/Devocional_year_$testYear.json'));

      // Test Spanish NVI (new format)
      final spanishNviUrl = Constants.getDevocionalesApiUrlMultilingual(testYear, 'es', 'NVI');
      expect(spanishNviUrl, equals('https://raw.githubusercontent.com/develop4God/Devocionales-json/refs/heads/main/Devocional_year_${testYear}_es_NVI.json'));

      // Test English KJV
      final englishKjvUrl = Constants.getDevocionalesApiUrlMultilingual(testYear, 'en', 'KJV');
      expect(englishKjvUrl, equals('https://raw.githubusercontent.com/develop4God/Devocionales-json/refs/heads/main/Devocional_year_${testYear}_en_KJV.json'));

      // Test English NIV
      final englishNivUrl = Constants.getDevocionalesApiUrlMultilingual(testYear, 'en', 'NIV');
      expect(englishNivUrl, equals('https://raw.githubusercontent.com/develop4God/Devocionales-json/refs/heads/main/Devocional_year_${testYear}_en_NIV.json'));

      // Test Portuguese ARC
      final portugueseArcUrl = Constants.getDevocionalesApiUrlMultilingual(testYear, 'pt', 'ARC');
      expect(portugueseArcUrl, equals('https://raw.githubusercontent.com/develop4God/Devocionales-json/refs/heads/main/Devocional_year_${testYear}_pt_ARC.json'));

      // Test Portuguese NVI
      final portugueseNviUrl = Constants.getDevocionalesApiUrlMultilingual(testYear, 'pt', 'NVI');
      expect(portugueseNviUrl, equals('https://raw.githubusercontent.com/develop4God/Devocionales-json/refs/heads/main/Devocional_year_${testYear}_pt_NVI.json'));

      // Test French LSG1910
      final frenchLsgUrl = Constants.getDevocionalesApiUrlMultilingual(testYear, 'fr', 'LSG1910');
      expect(frenchLsgUrl, equals('https://raw.githubusercontent.com/develop4God/Devocionales-json/refs/heads/main/Devocional_year_${testYear}_fr_LSG1910.json'));

      // Test French TOB
      final frenchTobUrl = Constants.getDevocionalesApiUrlMultilingual(testYear, 'fr', 'TOB');
      expect(frenchTobUrl, equals('https://raw.githubusercontent.com/develop4God/Devocionales-json/refs/heads/main/Devocional_year_${testYear}_fr_TOB.json'));
    });

    test('should maintain backward compatibility for Spanish RVR1960', () {
      const testYear = 2025;
      
      // Original method
      final originalUrl = Constants.getDevocionalesApiUrl(testYear);
      
      // Multilingual method with Spanish RVR1960
      final multilingualUrl = Constants.getDevocionalesApiUrlMultilingual(testYear, 'es', 'RVR1960');
      
      // Should be identical
      expect(multilingualUrl, equals(originalUrl));
      expect(originalUrl, equals('https://raw.githubusercontent.com/develop4God/Devocionales-json/refs/heads/main/Devocional_year_$testYear.json'));
    });

    test('should handle all supported language/version combinations', () {
      final provider = DevocionalProvider();
      
      // Test all language/version combinations from Constants
      final testCombinations = [
        {'language': 'es', 'versions': ['RVR1960', 'NVI']},
        {'language': 'en', 'versions': ['KJV', 'NIV']},
        {'language': 'pt', 'versions': ['ARC', 'NVI']},
        {'language': 'fr', 'versions': ['LSG1910', 'TOB']},
      ];

      for (final combo in testCombinations) {
        final language = combo['language'] as String;
        final versions = combo['versions'] as List<String>;
        
        provider.setSelectedLanguage(language);
        expect(provider.selectedLanguage, equals(language));
        
        final availableVersions = provider.getVersionsForLanguage(language);
        expect(availableVersions, isNotEmpty);
        
        for (final version in versions) {
          expect(availableVersions, contains(version), 
                 reason: 'Language $language should support version $version');
          
          provider.setSelectedVersion(version);
          expect(provider.selectedVersion, equals(version));
          
          // Verify URL generation works
          final url = Constants.getDevocionalesApiUrlMultilingual(2025, language, version);
          expect(url, isNotEmpty);
          expect(url, startsWith('https://'));
        }
      }
    });

    test('should have offline download methods available', () {
      final provider = DevocionalProvider();
      
      // These properties should be available for offline functionality
      expect(provider.isDownloading, isFalse);
      expect(provider.downloadStatus, isNull);
      expect(provider.isOfflineMode, isFalse);
      
      // These methods should exist (even if they fail in test environment)
      expect(provider.downloadAndStoreDevocionales, isA<Function>());
      expect(provider.downloadCurrentYearDevocionales, isA<Function>());
      expect(provider.hasCurrentYearLocalData, isA<Function>());
      expect(provider.clearDownloadStatus, isA<Function>());
    });

    test('should support multilingual offline functionality', () async {
      final provider = DevocionalProvider();
      
      // Test different language configurations
      final testConfigs = [
        {'lang': 'es', 'version': 'RVR1960'},
        {'lang': 'es', 'version': 'NVI'}, 
        {'lang': 'en', 'version': 'KJV'},
        {'lang': 'pt', 'version': 'ARC'},
        {'lang': 'fr', 'version': 'LSG1910'},
      ];
      
      for (final config in testConfigs) {
        provider.setSelectedLanguage(config['lang']!);
        provider.setSelectedVersion(config['version']!);
        
        expect(provider.selectedLanguage, equals(config['lang']!));
        expect(provider.selectedVersion, equals(config['version']!));
        
        // Test that hasLocalData method exists and can be called
        final hasLocalData = await provider.hasCurrentYearLocalData();
        expect(hasLocalData, isA<bool>());
        
        // Verify the URL generation works for each configuration
        final url = Constants.getDevocionalesApiUrlMultilingual(
          DateTime.now().year, 
          config['lang']!, 
          config['version']!
        );
        expect(url, isNotEmpty);
        expect(url, startsWith('https://'));
        
        // For Spanish RVR1960, should use backward compatible URL
        if (config['lang'] == 'es' && config['version'] == 'RVR1960') {
          expect(url, contains('Devocional_year_${DateTime.now().year}.json'));
        } else {
          expect(url, contains(config['lang']!));
          expect(url, contains(config['version']!));
        }
      }
    });

    test('should handle download status management', () {
      final provider = DevocionalProvider();
      
      // Initially should have no download status
      expect(provider.downloadStatus, isNull);
      expect(provider.isDownloading, isFalse);
      
      // Should be able to clear download status
      provider.clearDownloadStatus();
      expect(provider.downloadStatus, isNull);
    });

    test('should support all required languages and versions', () {
      // Verify Constants configuration matches expected multilingual support
      expect(Constants.supportedLanguages.keys, containsAll(['es', 'en', 'pt', 'fr']));
      expect(Constants.bibleVersionsByLanguage.keys, containsAll(['es', 'en', 'pt', 'fr']));
      expect(Constants.defaultVersionByLanguage.keys, containsAll(['es', 'en', 'pt', 'fr']));
      
      // Verify each language has versions
      for (final language in Constants.supportedLanguages.keys) {
        final versions = Constants.bibleVersionsByLanguage[language];
        expect(versions, isNotNull);
        expect(versions!.isNotEmpty, isTrue);
        
        final defaultVersion = Constants.defaultVersionByLanguage[language];
        expect(defaultVersion, isNotNull);
        expect(versions, contains(defaultVersion));
      }
    });
  });
}