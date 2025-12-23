import 'package:devocional_nuevo/providers/devocional_provider.dart';
import 'package:devocional_nuevo/services/service_locator.dart';
import 'package:devocional_nuevo/utils/constants.dart';
import 'package:devocional_nuevo/utils/copyright_utils.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Integration test for Japanese devotional loading with new version codes
/// Tests the complete flow: Constants -> Provider -> URL generation -> Copyright display
void main() {
  // Mock platform channels
  const MethodChannel pathProviderChannel =
      MethodChannel('plugins.flutter.io/path_provider');
  const MethodChannel ttsChannel = MethodChannel('flutter_tts');

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      pathProviderChannel,
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
      ttsChannel,
      (MethodCall call) async {
        switch (call.method) {
          case 'speak':
          case 'stop':
          case 'pause':
          case 'setLanguage':
          case 'setSpeechRate':
          case 'setVolume':
          case 'setPitch':
          case 'awaitSpeakCompletion':
          case 'setQueueMode':
          case 'awaitSynthCompletion':
            return 1;
          case 'getLanguages':
            return ['es-ES', 'en-US', 'ja-JP'];
          case 'getVoices':
            return [
              {'name': 'Voice ES', 'locale': 'es-ES'},
              {'name': 'Voice EN', 'locale': 'en-US'},
              {'name': 'Voice JA', 'locale': 'ja-JP'},
            ];
          case 'isLanguageAvailable':
            return true;
          default:
            return null;
        }
      },
    );
  });

  tearDownAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProviderChannel, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(ttsChannel, null);
  });

  group('Japanese Devotional Version Integration Tests', () {
    late DevocionalProvider provider;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      ServiceLocator().reset();
      setupServiceLocator();
      provider = DevocionalProvider();
    });

    tearDown(() {
      provider.dispose();
      ServiceLocator().reset();
    });

    test('Constants class has correct Japanese version codes', () {
      // Verify that Constants has the new Japanese versions
      final japaneseVersions = Constants.bibleVersionsByLanguage['ja'];
      expect(japaneseVersions, isNotNull);
      expect(japaneseVersions, contains('新改訳2003'));
      expect(japaneseVersions, contains('リビングバイブル'));

      // Verify old codes are not present
      expect(japaneseVersions, isNot(contains('SK2003')));
      expect(japaneseVersions, isNot(contains('JCB')));

      // Verify default version
      final defaultVersion = Constants.defaultVersionByLanguage['ja'];
      expect(defaultVersion, equals('新改訳2003'));
    });

    test('URL generation uses correct Japanese version codes', () {
      const year = 2025;
      const language = 'ja';

      // Test 新改訳2003
      final url1 = Constants.getDevocionalesApiUrlMultilingual(
        year,
        language,
        '新改訳2003',
      );
      expect(
        url1,
        equals(
          'https://raw.githubusercontent.com/develop4God/Devocionales-json/refs/heads/main/Devocional_year_2025_ja_新改訳2003.json',
        ),
      );

      // Test リビングバイブル
      final url2 = Constants.getDevocionalesApiUrlMultilingual(
        year,
        language,
        'リビングバイブル',
      );
      expect(
        url2,
        equals(
          'https://raw.githubusercontent.com/develop4God/Devocionales-json/refs/heads/main/Devocional_year_2025_ja_リビングバイブル.json',
        ),
      );
    });

    test('Copyright utils have correct Japanese version copyrights', () {
      // Test 新改訳2003 copyright
      final copyright1 = CopyrightUtils.getCopyrightText('ja', '新改訳2003');
      expect(copyright1, contains('新改訳2003聖書'));
      expect(copyright1, contains('© 2003'));
      expect(copyright1, contains('新日本聖書刊行会'));

      // Test リビングバイブル copyright
      final copyright2 = CopyrightUtils.getCopyrightText('ja', 'リビングバイブル');
      expect(copyright2, contains('リビングバイブル'));
      expect(copyright2, contains('© 1997'));
      expect(copyright2, contains('新日本聖書刊行会'));

      // Verify old codes fall back to default Japanese copyright
      final copyrightOld1 = CopyrightUtils.getCopyrightText('ja', 'SK2003');
      expect(copyrightOld1, contains('聖書本文')); // Should use default Japanese

      final copyrightOld2 = CopyrightUtils.getCopyrightText('ja', 'JCB');
      expect(copyrightOld2, contains('聖書本文')); // Should use default Japanese
    });

    test('Bible version display names are correct for Japanese', () {
      final displayName1 =
          CopyrightUtils.getBibleVersionDisplayName('ja', '新改訳2003');
      expect(displayName1, equals('新改訳2003聖書'));

      final displayName2 =
          CopyrightUtils.getBibleVersionDisplayName('ja', 'リビングバイブル');
      expect(displayName2, equals('リビングバイブル'));
    });

    test('Provider loads Japanese versions correctly', () async {
      await provider.initializeData();

      // Set to Japanese
      provider.setSelectedLanguage('ja', null);
      await Future.delayed(const Duration(milliseconds: 300));

      expect(provider.selectedLanguage, equals('ja'));
      expect(provider.selectedVersion, equals('新改訳2003')); // Default

      // Check available versions
      final versions = provider.availableVersions;
      expect(versions, contains('新改訳2003'));
      expect(versions, contains('リビングバイブル'));
      expect(versions.length, equals(2));
    });

    test('Provider can switch between Japanese versions', () async {
      await provider.initializeData();

      // Set to Japanese
      provider.setSelectedLanguage('ja', null);
      await Future.delayed(const Duration(milliseconds: 300));

      expect(provider.selectedVersion, equals('新改訳2003'));

      // Switch to リビングバイブル
      provider.setSelectedVersion('リビングバイブル');
      await Future.delayed(const Duration(milliseconds: 300));

      expect(provider.selectedVersion, equals('リビングバイブル'));
      expect(provider.selectedLanguage, equals('ja'));

      // Switch back to 新改訳2003
      provider.setSelectedVersion('新改訳2003');
      await Future.delayed(const Duration(milliseconds: 300));

      expect(provider.selectedVersion, equals('新改訳2003'));
    });

    test(
        'Complete flow: Language selection -> Version change -> URL generation',
        () async {
      await provider.initializeData();

      // Start with Japanese
      provider.setSelectedLanguage('ja', null);
      await Future.delayed(const Duration(milliseconds: 300));

      // Verify default version is set
      expect(provider.selectedVersion, equals('新改訳2003'));

      // Verify URL would be generated correctly
      final url1 = Constants.getDevocionalesApiUrlMultilingual(
        DateTime.now().year,
        provider.selectedLanguage,
        provider.selectedVersion,
      );
      expect(url1, contains('ja_新改訳2003.json'));

      // Switch version
      provider.setSelectedVersion('リビングバイブル');
      await Future.delayed(const Duration(milliseconds: 300));

      // Verify URL changes
      final url2 = Constants.getDevocionalesApiUrlMultilingual(
        DateTime.now().year,
        provider.selectedLanguage,
        provider.selectedVersion,
      );
      expect(url2, contains('ja_リビングバイブル.json'));

      // Verify copyright would be correct
      final copyright = CopyrightUtils.getCopyrightText(
        provider.selectedLanguage,
        provider.selectedVersion,
      );
      expect(copyright, contains('リビングバイブル'));
    });

    test('Switching from another language to Japanese uses correct default',
        () async {
      await provider.initializeData();

      // Start with English
      provider.setSelectedLanguage('en', null);
      await Future.delayed(const Duration(milliseconds: 300));

      expect(provider.selectedLanguage, equals('en'));
      expect(provider.selectedVersion, isNotEmpty);

      // Switch to Japanese
      provider.setSelectedLanguage('ja', null);
      await Future.delayed(const Duration(milliseconds: 300));

      // Should use Japanese default version
      expect(provider.selectedLanguage, equals('ja'));
      expect(provider.selectedVersion, equals('新改訳2003'));

      // Verify available versions are Japanese
      final versions = provider.availableVersions;
      expect(versions, contains('新改訳2003'));
      expect(versions, contains('リビングバイブル'));
    });
  });
}
