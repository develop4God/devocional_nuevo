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
