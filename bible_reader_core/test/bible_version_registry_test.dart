@Tags(['unit', 'utils'])
library;

import 'dart:convert';
import 'dart:io';

import 'package:bible_reader_core/src/bible_version_registry.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakePathProviderPlatform extends PathProviderPlatform
    with MockPlatformInterfaceMixin {
  final String path;
  _FakePathProviderPlatform(this.path);

  @override
  Future<String?> getApplicationDocumentsPath() async => path;
}

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir =
        await Directory.systemTemp.createTemp('bible_version_registry_test');
    PathProviderPlatform.instance = _FakePathProviderPlatform(tempDir.path);
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() async {
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('BibleVersionRegistry.getDownloadedRemoteVersionsForLanguage', () {
    test('returns empty list when no downloaded remote files exist', () async {
      final result =
          await BibleVersionRegistry.getDownloadedRemoteVersionsForLanguage(
        'en',
      );
      expect(result, isEmpty);
    });

    test('finds a downloaded remote version file not in the bundled list',
        () async {
      // LSG1910_fr is bundled (see _versionsByLanguage), so use a code not
      // in the bundled list for 'fr' to simulate a genuinely remote file.
      final file = File('${tempDir.path}/CUSTOM_fr.SQLite3');
      await file.writeAsBytes([1, 2, 3]);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'bible_remote_version_names',
        jsonEncode({'CUSTOM_fr.SQLite3': 'Custom French Version'}),
      );

      final result =
          await BibleVersionRegistry.getDownloadedRemoteVersionsForLanguage(
        'fr',
      );

      expect(result, hasLength(1));
      expect(result.first.dbFileName, 'CUSTOM_fr.SQLite3');
      expect(result.first.name, 'Custom French Version');
      expect(result.first.languageCode, 'fr');
      expect(result.first.isDownloaded, isTrue);
    });

    test('falls back to filename when no display name is stored', () async {
      final file = File('${tempDir.path}/UNKNOWN_en.SQLite3');
      await file.writeAsBytes([1, 2, 3]);

      final result =
          await BibleVersionRegistry.getDownloadedRemoteVersionsForLanguage(
        'en',
      );

      expect(result, hasLength(1));
      expect(result.first.name, 'UNKNOWN_en.SQLite3');
    });

    test('excludes files already present in the bundled versions list',
        () async {
      // KJV_en.SQLite3 is bundled for 'en' — even if present on disk it
      // should not be double-counted as a "remote" version here.
      final file = File('${tempDir.path}/KJV_en.SQLite3');
      await file.writeAsBytes([1, 2, 3]);

      final result =
          await BibleVersionRegistry.getDownloadedRemoteVersionsForLanguage(
        'en',
      );

      expect(result, isEmpty);
    });

    test('getVersionsForLanguage includes downloaded remote versions',
        () async {
      final file = File('${tempDir.path}/CUSTOM_fr.SQLite3');
      await file.writeAsBytes([1, 2, 3]);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'bible_remote_version_names',
        jsonEncode({'CUSTOM_fr.SQLite3': 'Custom French Version'}),
      );

      final result = await BibleVersionRegistry.getVersionsForLanguage('fr');

      expect(
        result.any((v) => v.dbFileName == 'CUSTOM_fr.SQLite3'),
        isTrue,
      );
    });
  });
}
