@Tags(['unit', 'utils'])
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;

void main() {
  group('Migration Safety Tests - No Singleton Antipatterns', () {
    test(
      'LocalizationService has no static _instance field or instance getter',
      () async {
        // Read the source file
        final file = File('lib/services/localization_service.dart');
        expect(
          await file.exists(),
          isTrue,
          reason: 'LocalizationService source file should exist',
        );

        final content = await file.readAsString();

        // Assert no singleton-related static fields or methods exist
        expect(
          content.contains('static LocalizationService? _instance'),
          isFalse,
          reason: 'LocalizationService should not have static _instance field',
        );

        expect(
          content.contains('static LocalizationService get instance'),
          isFalse,
          reason: 'LocalizationService should not have static instance getter',
        );

        expect(
          content.contains('resetInstance('),
          isFalse,
          reason: 'LocalizationService should not have resetInstance method',
        );

        expect(
          content.contains('LocalizationService._()'),
          isFalse,
          reason:
              'LocalizationService should not have private constructor for singleton',
        );
      },
    );

    test('LocalizationService has public constructor for DI', () async {
      // Read the source file
      final file = File('lib/services/localization_service.dart');
      final content = await file.readAsString();

      // Assert public constructor exists
      expect(
        content.contains('LocalizationService()'),
        isTrue,
        reason: 'LocalizationService should have public constructor for DI',
      );
    });

    test('LocalizationService is registered in ServiceLocator', () async {
      // Read the service locator file
      final file = File('lib/services/service_locator.dart');
      expect(
        await file.exists(),
        isTrue,
        reason: 'ServiceLocator source file should exist',
      );

      final content = await file.readAsString();

      // Assert LocalizationService is registered
      expect(
        content.contains('registerLazySingleton<LocalizationService>'),
        isTrue,
        reason:
            'LocalizationService should be registered as lazy singleton in ServiceLocator',
      );

      expect(
        content.contains('LocalizationService()'),
        isTrue,
        reason:
            'LocalizationService should be instantiated via public constructor in ServiceLocator',
      );
    });

    test('ILocalizationService is registered as singleton alias', () async {
      final file = File('lib/services/service_locator.dart');
      final content = await file.readAsString();

      expect(
        content.contains('registerSingleton<ILocalizationService>('),
        isTrue,
        reason:
            'ILocalizationService should be registered as singleton in ServiceLocator',
      );

      expect(
        content.contains('locator.get<LocalizationService>()'),
        isTrue,
        reason:
            'ILocalizationService should be registered using the existing LocalizationService instance',
      );
    });

    test('Codebase does not reference LocalizationService.instance', () async {
      // Check lib directory
      final libDir = Directory('lib');
      expect(
        await libDir.exists(),
        isTrue,
        reason: 'lib directory should exist',
      );

      await _checkDirectoryForPattern(
        libDir,
        'LocalizationService.instance',
        'lib',
      );
    });

    test('Tests do not reference LocalizationService.instance', () async {
      // Check test directory
      final testDir = Directory('test');
      expect(
        await testDir.exists(),
        isTrue,
        reason: 'test directory should exist',
      );

      await _checkDirectoryForPattern(
        testDir,
        'LocalizationService.instance',
        'test',
      );
    });

    test(
      'Codebase does not reference LocalizationService.resetInstance()',
      () async {
        // Check lib directory
        final libDir = Directory('lib');
        await _checkDirectoryForPattern(
          libDir,
          'LocalizationService.resetInstance',
          'lib',
        );

        // Check test directory
        final testDir = Directory('test');
        await _checkDirectoryForPattern(
          testDir,
          'LocalizationService.resetInstance',
          'test',
        );
      },
    );

    test('LocalizationProvider uses DI instead of singleton', () async {
      // Read the provider file
      final file = File('lib/providers/localization_provider.dart');
      expect(
        await file.exists(),
        isTrue,
        reason: 'LocalizationProvider source file should exist',
      );

      final content = await file.readAsString();

      // Assert DI usage
      expect(
        content.contains('getService<LocalizationService>()'),
        isTrue,
        reason:
            'LocalizationProvider should use getService<LocalizationService>()',
      );

      expect(
        content.contains('LocalizationService.instance'),
        isFalse,
        reason:
            'LocalizationProvider should not use LocalizationService.instance',
      );
    });

    test('LocalizationProvider uses DI for VoiceSettingsService', () async {
      // Read the provider file
      final file = File('lib/providers/localization_provider.dart');
      final content = await file.readAsString();

      // Assert DI usage for VoiceSettingsService
      expect(
        content.contains('getService<VoiceSettingsService>()'),
        isTrue,
        reason:
            'LocalizationProvider should use getService<VoiceSettingsService>()',
      );

      expect(
        content.contains('VoiceSettingsService()'),
        isFalse,
        reason:
            'LocalizationProvider should not directly instantiate VoiceSettingsService()',
      );
    });

    test('LocalizationService imports are correct', () async {
      // Read the service locator file to verify import
      final file = File('lib/services/service_locator.dart');
      final content = await file.readAsString();

      expect(
        content.contains(
          "import 'package:devocional_nuevo/services/localization_service.dart'",
        ),
        isTrue,
        reason: 'ServiceLocator should import LocalizationService',
      );
    });

    test('Documentation comments explain DI migration', () async {
      // Check LocalizationService documentation
      final localizationFile = File('lib/services/localization_service.dart');
      final localizationContent = await localizationFile.readAsString();

      expect(
        localizationContent.contains('Service Locator') ||
            localizationContent.contains('DI') ||
            localizationContent.contains('getService'),
        isTrue,
        reason:
            'LocalizationService should have documentation about DI/ServiceLocator',
      );

      // Check ServiceLocator documentation
      final serviceLocatorFile = File('lib/services/service_locator.dart');
      final serviceLocatorContent = await serviceLocatorFile.readAsString();

      expect(
        serviceLocatorContent.contains('LocalizationService'),
        isTrue,
        reason:
            'ServiceLocator should mention LocalizationService in comments or registration',
      );
    });

    // ── SupporterPetService singleton registration ─────────────────────────

    test(
        'SupporterPetService is registered as lazy singleton in ServiceLocator',
        () async {
      final file = File('lib/services/service_locator.dart');
      expect(
        await file.exists(),
        isTrue,
        reason: 'ServiceLocator source file should exist',
      );

      final content = await file.readAsString();

      expect(
        content.contains('registerLazySingleton<SupporterPetService>'),
        isTrue,
        reason:
            'SupporterPetService should be registered as lazy singleton in ServiceLocator',
      );
    });

    test('SupporterPetService does not use static singleton antipattern',
        () async {
      final file = File('lib/services/supporter_pet_service.dart');
      expect(
        await file.exists(),
        isTrue,
        reason: 'SupporterPetService source file should exist',
      );

      final content = await file.readAsString();

      expect(
        content.contains('static SupporterPetService? _instance'),
        isFalse,
        reason: 'SupporterPetService should not have static _instance field',
      );

      expect(
        content.contains('static SupporterPetService get instance'),
        isFalse,
        reason: 'SupporterPetService should not have static instance getter',
      );
    });

    // ── EncounterProgressService DI registration ───────────────────────────

    test(
        'IEncounterProgressService is registered as lazy singleton in ServiceLocator',
        () async {
      final file = File('lib/services/service_locator.dart');
      expect(
        await file.exists(),
        isTrue,
        reason: 'ServiceLocator source file should exist',
      );

      final content = await file.readAsString();

      expect(
        content.contains('registerLazySingleton<IEncounterProgressService>'),
        isTrue,
        reason:
            'IEncounterProgressService should be registered as lazy singleton in ServiceLocator',
      );
    });

    // ── BaseCacheManager DI registration ────────────────────────────────

    test('BaseCacheManager is registered as lazy singleton in ServiceLocator',
        () async {
      final file = File('lib/services/service_locator.dart');
      expect(
        await file.exists(),
        isTrue,
        reason: 'ServiceLocator source file should exist',
      );

      final content = await file.readAsString();

      expect(
        content.contains('registerLazySingleton<BaseCacheManager>'),
        isTrue,
        reason:
            'BaseCacheManager should be registered as lazy singleton in ServiceLocator',
      );

      expect(
        content.contains('DefaultCacheManager()'),
        isTrue,
        reason:
            'BaseCacheManager should be instantiated as DefaultCacheManager in ServiceLocator',
      );
    });

    test('BaseCacheManager is injected into EncounterBloc constructor',
        () async {
      final file = File('lib/blocs/encounter/encounter_bloc.dart');
      expect(
        await file.exists(),
        isTrue,
        reason: 'EncounterBloc source file should exist',
      );

      final content = await file.readAsString();

      expect(
        content.contains('final BaseCacheManager cacheManager'),
        isTrue,
        reason: 'EncounterBloc should have BaseCacheManager field',
      );

      expect(
        content.contains('required this.cacheManager'),
        isTrue,
        reason:
            'EncounterBloc constructor should require cacheManager parameter',
      );
    });

    test('EncounterBloc does not create DefaultCacheManager instances directly',
        () async {
      final file = File('lib/blocs/encounter/encounter_bloc.dart');
      expect(
        await file.exists(),
        isTrue,
        reason: 'EncounterBloc source file should exist',
      );

      final content = await file.readAsString();

      expect(
        content.contains('DefaultCacheManager()'),
        isFalse,
        reason:
            'EncounterBloc should not create DefaultCacheManager instances directly',
      );

      expect(
        content.contains('cacheManager.downloadFile'),
        isTrue,
        reason: 'EncounterBloc should use injected cacheManager for downloads',
      );
    });

    test('EncounterProgressService does not use static singleton antipattern',
        () async {
      final file = File('lib/services/encounter_progress_service.dart');
      expect(
        await file.exists(),
        isTrue,
        reason: 'EncounterProgressService source file should exist',
      );

      final content = await file.readAsString();

      expect(
        content.contains('static EncounterProgressService? _instance'),
        isFalse,
        reason:
            'EncounterProgressService should not have static _instance field',
      );

      expect(
        content.contains('static EncounterProgressService get instance'),
        isFalse,
        reason:
            'EncounterProgressService should not have static instance getter',
      );
    });

    test(
        'EncounterBloc depends on IEncounterProgressService interface, not concrete',
        () async {
      final file = File('lib/blocs/encounter/encounter_bloc.dart');
      expect(
        await file.exists(),
        isTrue,
        reason: 'EncounterBloc source file should exist',
      );

      final content = await file.readAsString();

      expect(
        content.contains('IEncounterProgressService'),
        isTrue,
        reason:
            'EncounterBloc should depend on IEncounterProgressService interface',
      );

      expect(
        content.contains('final EncounterProgressService'),
        isFalse,
        reason:
            'EncounterBloc should not depend on concrete EncounterProgressService',
      );
    });

    // ── BibleReader TTS DI patterns ───────────────────────────────────────────

    test(
      'BibleReaderPage accepts optional FlutterTts for dependency injection',
      () async {
        final file = File('lib/pages/bible_reader_page.dart');
        expect(await file.exists(), isTrue,
            reason: 'BibleReaderPage source file should exist');

        final content = await file.readAsString();

        // Widget constructor must expose an injectable FlutterTts parameter.
        expect(
          content.contains('FlutterTts? flutterTts'),
          isTrue,
          reason:
              'BibleReaderPage must have optional FlutterTts? flutterTts field for DI',
        );

        // FlutterTts must NOT be instantiated at field level.
        expect(
          RegExp(r'final FlutterTts _flutterTts\s*=\s*FlutterTts\(\)')
              .hasMatch(content),
          isFalse,
          reason:
              'BibleReaderPage must not instantiate FlutterTts at field level; '
              'use widget.flutterTts ?? FlutterTts() in initState instead',
        );
      },
    );

    test(
      'BibleReaderPage resolves VoiceSettingsService once in initState, '
      'not inside _handleTtsPlayPause',
      () async {
        final file = File('lib/pages/bible_reader_page.dart');
        final content = await file.readAsString();

        // _handleTtsPlayPause must NOT contain an inline getService call.
        // We check by extracting the method body heuristically.
        final methodStart =
            content.indexOf('Future<void> _handleTtsPlayPause(');
        final methodEnd = content.indexOf('\n  Future<void>', methodStart + 1);
        final methodBody = methodStart != -1 && methodEnd != -1
            ? content.substring(methodStart, methodEnd)
            : '';

        expect(
          methodBody.contains('getService<VoiceSettingsService>()'),
          isFalse,
          reason:
              '_handleTtsPlayPause must not call getService<VoiceSettingsService>() '
              'inline; resolve in initState and use the stored field instead',
        );
      },
    );

    test(
      'BibleReaderTtsMiniplayerPresenter accepts AnalyticsService at '
      'construction time, not via inline getService<>',
      () async {
        final file = File(
          'lib/widgets/bible/bible_reader_tts_miniplayer_presenter.dart',
        );
        expect(await file.exists(), isTrue,
            reason:
                'BibleReaderTtsMiniplayerPresenter source file should exist');

        final content = await file.readAsString();

        // Constructor must accept an IAnalyticsService parameter (interface, not concrete).
        expect(
          content.contains('required IAnalyticsService analyticsService'),
          isTrue,
          reason:
              'BibleReaderTtsMiniplayerPresenter must accept IAnalyticsService '
              'via constructor for proper dependency injection',
        );

        // The presenter must NOT import service_locator.dart.
        expect(
          content.contains(
            "import 'package:devocional_nuevo/services/service_locator.dart'",
          ),
          isFalse,
          reason:
              'BibleReaderTtsMiniplayerPresenter must not import service_locator; '
              'all services must be injected, never resolved inline',
        );

        // There must be no inline getService<AnalyticsService>() call.
        expect(
          content.contains('getService<AnalyticsService>()'),
          isFalse,
          reason: 'BibleReaderTtsMiniplayerPresenter must not call '
              'getService<AnalyticsService>() inline inside handlers',
        );
      },
    );

    test(
      'BibleReaderTtsMiniplayerPresenter exposes onShowVoiceSelector callback '
      'to eliminate duplicate voice selector paths',
      () async {
        final file = File(
          'lib/widgets/bible/bible_reader_tts_miniplayer_presenter.dart',
        );
        final content = await file.readAsString();

        expect(
          content.contains('onShowVoiceSelector'),
          isTrue,
          reason:
              'BibleReaderTtsMiniplayerPresenter must have onShowVoiceSelector '
              'callback so both the page and miniplayer share one implementation',
        );
      },
    );

    // ── DevocionalRepository DI registration ──────────────────────────────────

    test(
      'DevocionalRepository is registered as lazy singleton in ServiceLocator',
      () async {
        final file = File('lib/services/service_locator.dart');
        expect(await file.exists(), isTrue);
        final content = await file.readAsString();

        expect(
          content.contains('registerLazySingleton<DevocionalRepository>'),
          isTrue,
          reason: 'DevocionalRepository should be registered as lazy singleton',
        );
      },
    );

    test(
      'DevocionalRepositoryImpl does not use static singleton antipattern',
      () async {
        final file = File('lib/repositories/devocional_repository_impl.dart');
        expect(await file.exists(), isTrue);
        final content = await file.readAsString();

        expect(
          content.contains('static DevocionalRepositoryImpl? _instance'),
          isFalse,
          reason:
              'DevocionalRepositoryImpl should not have static _instance field',
        );

        expect(
          content.contains('static DevocionalRepositoryImpl get instance'),
          isFalse,
          reason:
              'DevocionalRepositoryImpl should not have static instance getter',
        );
      },
    );

    test(
      'DevocionalProvider depends on DevocionalRepository interface, not concrete',
      () async {
        final file = File('lib/providers/devocional_provider.dart');
        expect(await file.exists(), isTrue);
        final content = await file.readAsString();

        expect(
          content.contains('DevocionalRepository'),
          isTrue,
          reason:
              'DevocionalProvider should reference DevocionalRepository interface',
        );

        expect(
          content.contains('DevocionalRepositoryImpl()'),
          isFalse,
          reason:
              'DevocionalProvider should not directly instantiate DevocionalRepositoryImpl',
        );
      },
    );

    // ── AnalyticsService DI registration ──────────────────────────────────────

    test(
      'AnalyticsService is registered as lazy singleton under IAnalyticsService '
      'in ServiceLocator',
      () async {
        final file = File('lib/services/service_locator.dart');
        expect(await file.exists(), isTrue,
            reason: 'ServiceLocator source file should exist');

        final content = await file.readAsString();

        expect(
          content.contains('registerLazySingleton<IAnalyticsService>'),
          isTrue,
          reason:
              'IAnalyticsService should be registered as lazy singleton in ServiceLocator',
        );

        expect(
          content.contains('AnalyticsService()'),
          isTrue,
          reason:
              'AnalyticsService should be instantiated in ServiceLocator registration',
        );

        // Verify interface import exists
        expect(
          content.contains(
            "import 'package:devocional_nuevo/services/i_analytics_service.dart'",
          ),
          isTrue,
          reason: 'ServiceLocator should import IAnalyticsService interface',
        );
      },
    );

    test(
      'AnalyticsService does not use static singleton antipattern',
      () async {
        final file = File('lib/services/analytics_service.dart');
        expect(await file.exists(), isTrue,
            reason: 'AnalyticsService source file should exist');

        final content = await file.readAsString();

        expect(
          content.contains('static AnalyticsService? _instance'),
          isFalse,
          reason: 'AnalyticsService should not have static _instance field',
        );

        expect(
          content.contains('static AnalyticsService get instance'),
          isFalse,
          reason: 'AnalyticsService should not have static instance getter',
        );
      },
    );

    test(
      'AnalyticsService implements IAnalyticsService interface',
      () async {
        final file = File('lib/services/analytics_service.dart');
        expect(await file.exists(), isTrue);

        final content = await file.readAsString();

        expect(
          content
              .contains('class AnalyticsService implements IAnalyticsService'),
          isTrue,
          reason:
              'AnalyticsService should implement IAnalyticsService interface',
        );

        // Verify import of interface
        expect(
          content.contains(
            "import 'package:devocional_nuevo/services/i_analytics_service.dart'",
          ),
          isTrue,
          reason: 'AnalyticsService should import IAnalyticsService interface',
        );
      },
    );

    test(
      'FakeAnalyticsService in test helpers implements IAnalyticsService',
      () async {
        final file = File('test/helpers/test_helpers.dart');
        expect(await file.exists(), isTrue,
            reason: 'Test helpers should exist');

        final content = await file.readAsString();

        // Use regex to handle line breaks in the class declaration
        expect(
          RegExp(r'class FakeAnalyticsService extends AnalyticsService\s+implements IAnalyticsService')
              .hasMatch(content),
          isTrue,
          reason:
              'FakeAnalyticsService should implement IAnalyticsService interface',
        );

        // Verify test setup registers by interface type
        expect(
          content.contains('registerSingleton<IAnalyticsService>'),
          isTrue,
          reason:
              'Test setup should register FakeAnalyticsService under IAnalyticsService type',
        );
      },
    );

    // ── GoogleDriveAuthService DI registration ────────────────────────────────

    test(
      'GoogleDriveAuthService has no static _singletonInstance field',
      () async {
        final file = File('lib/services/backup/google_drive_auth_service.dart');
        expect(await file.exists(), isTrue,
            reason: 'GoogleDriveAuthService source file should exist');

        final content = await file.readAsString();

        expect(
          content.contains('static GoogleDriveAuthService? _singletonInstance'),
          isFalse,
          reason: 'GoogleDriveAuthService must not manage its own singleton — '
              'lifecycle is owned by ServiceLocator.registerLazySingleton',
        );

        expect(
          content.contains('static GoogleDriveAuthService get instance'),
          isFalse,
          reason:
              'GoogleDriveAuthService must not have a static instance getter',
        );
      },
    );

    test(
      'GoogleDriveAuthService has no internal factory singleton guard',
      () async {
        final file = File('lib/services/backup/google_drive_auth_service.dart');
        final content = await file.readAsString();

        expect(
          content.contains('_singletonInstance != null'),
          isFalse,
          reason:
              'GoogleDriveAuthService must not have a factory singleton guard; '
              'use a plain constructor and let ServiceLocator manage lifecycle',
        );
      },
    );

    test(
      'GoogleDriveAuthService has a public constructor that accepts SharedPreferences',
      () async {
        final file = File('lib/services/backup/google_drive_auth_service.dart');
        final content = await file.readAsString();

        expect(
          content.contains(
            'GoogleDriveAuthService({required SharedPreferences prefs})',
          ),
          isTrue,
          reason: 'GoogleDriveAuthService must have a public constructor with '
              'required SharedPreferences for constructor injection',
        );
      },
    );

    test(
      'GoogleDriveAuthService does not call SharedPreferences.getInstance() directly',
      () async {
        final file = File('lib/services/backup/google_drive_auth_service.dart');
        final content = await file.readAsString();

        expect(
          content.contains('SharedPreferences.getInstance()'),
          isFalse,
          reason:
              'GoogleDriveAuthService must use the injected _prefs field instead '
              'of calling SharedPreferences.getInstance() directly',
        );
      },
    );

    test(
      'IGoogleDriveAuthService is registered as lazy singleton in ServiceLocator',
      () async {
        final file = File('lib/services/service_locator.dart');
        expect(await file.exists(), isTrue);
        final content = await file.readAsString();

        expect(
          content.contains(
            'registerLazySingleton<IGoogleDriveAuthService>',
          ),
          isTrue,
          reason:
              'IGoogleDriveAuthService must be registered under its interface '
              'type in ServiceLocator — never the concrete type',
        );
      },
    );

    test(
      'GoogleDriveAuthService is not instantiated directly outside service_locator.dart',
      () async {
        final libDir = Directory('lib');
        expect(await libDir.exists(), isTrue);

        final libFiles = await libDir
            .list(recursive: true)
            .where(
              (entity) =>
                  entity is File &&
                  entity.path.endsWith('.dart') &&
                  !entity.path.contains('service_locator.dart') &&
                  !entity.path.contains('google_drive_auth_service.dart'),
            )
            .cast<File>()
            .toList();

        for (final file in libFiles) {
          final content = await file.readAsString();
          expect(
            content.contains('GoogleDriveAuthService('),
            isFalse,
            reason:
                'File ${file.path} must not instantiate GoogleDriveAuthService() '
                'directly; use getService<IGoogleDriveAuthService>()',
          );
        }
      },
    );

    test(
      'Codebase does not instantiate AnalyticsService directly outside '
      'service_locator.dart',
      () async {
        // Check lib directory (excluding service_locator.dart)
        final libDir = Directory('lib');
        expect(
          await libDir.exists(),
          isTrue,
          reason: 'lib directory should exist',
        );

        final libFiles = await libDir
            .list(recursive: true)
            .where(
              (entity) =>
                  entity is File &&
                  entity.path.endsWith('.dart') &&
                  !entity.path.contains('service_locator.dart'),
            )
            .cast<File>()
            .toList();

        for (final file in libFiles) {
          final content = await file.readAsString();
          expect(
            content.contains('AnalyticsService()'),
            isFalse,
            reason:
                'File ${file.path} should not directly instantiate AnalyticsService(); '
                'use getService<IAnalyticsService>() or dependency injection',
          );
        }
      },
    );
  });
}

/// Helper function to check a directory recursively for a pattern
Future<void> _checkDirectoryForPattern(
  Directory dir,
  String pattern,
  String dirName,
) async {
  final dartFiles = await dir
      .list(recursive: true)
      .where(
        (entity) =>
            entity is File &&
            entity.path.endsWith('.dart') &&
            !entity.path.contains('.skip') &&
            // Exclude this test file from the check since it contains the patterns as strings
            path.basename(entity.path) != 'no_singleton_antipatterns_test.dart',
      )
      .cast<File>()
      .toList();

  for (final file in dartFiles) {
    final content = await file.readAsString();
    if (content.contains(pattern)) {
      fail(
        'Found "$pattern" in ${file.path}. '
        'All references should be migrated to use ServiceLocator.',
      );
    }
  }
}
