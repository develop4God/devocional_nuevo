@Tags(['unit', 'blocs'])
library;

import 'package:bible_reader_core/bible_reader_core.dart';
import 'package:devocional_nuevo/blocs/bible_versions/bible_versions_event.dart';
import 'package:flutter_test/flutter_test.dart';

BibleVersion _version(String dbFileName, {String name = 'Test Version'}) {
  return BibleVersion(
    name: name,
    language: 'Test',
    languageCode: 'xx',
    assetPath: '',
    dbFileName: dbFileName,
    isDownloaded: false,
    remoteUrl: 'https://example.com/$dbFileName.gz',
  );
}

void main() {
  group('BibleVersionsEvent equality', () {
    test(
        'LoadAvailableVersions is equal for the same language and '
        'forceRefresh', () {
      expect(
        const LoadAvailableVersions(languageCode: 'en'),
        const LoadAvailableVersions(languageCode: 'en'),
      );
      expect(
        const LoadAvailableVersions(languageCode: 'en', forceRefresh: true),
        isNot(const LoadAvailableVersions(languageCode: 'en')),
      );
      expect(
        const LoadAvailableVersions(languageCode: 'en'),
        isNot(const LoadAvailableVersions(languageCode: 'es')),
      );
    });

    test('LoadAvailableVersions defaults forceRefresh to false', () {
      const event = LoadAvailableVersions(languageCode: 'en');
      expect(event.forceRefresh, isFalse);
    });

    test('DownloadBibleVersion is equal for the same version', () {
      final version = _version('KJV.SQLite3');
      expect(
        DownloadBibleVersion(version),
        DownloadBibleVersion(version),
      );
      expect(
        DownloadBibleVersion(_version('KJV.SQLite3')),
        isNot(DownloadBibleVersion(_version('NVI.SQLite3'))),
      );
    });

    test('DownloadProgressUpdated is equal for the same file and progress', () {
      expect(
        const DownloadProgressUpdated(dbFileName: 'KJV.SQLite3', progress: 0.5),
        const DownloadProgressUpdated(dbFileName: 'KJV.SQLite3', progress: 0.5),
      );
      expect(
        const DownloadProgressUpdated(dbFileName: 'KJV.SQLite3', progress: 0.5),
        isNot(
          const DownloadProgressUpdated(
            dbFileName: 'KJV.SQLite3',
            progress: 0.9,
          ),
        ),
      );
    });

    test('DownloadProgressUpdated supports a null progress value', () {
      const event = DownloadProgressUpdated(
        dbFileName: 'KJV.SQLite3',
        progress: null,
      );
      expect(event.progress, isNull);
      expect(
        event,
        const DownloadProgressUpdated(
            dbFileName: 'KJV.SQLite3', progress: null),
      );
    });

    test('DownloadCompleted is equal for the same file name', () {
      expect(
        const DownloadCompleted('KJV.SQLite3'),
        const DownloadCompleted('KJV.SQLite3'),
      );
      expect(
        const DownloadCompleted('KJV.SQLite3'),
        isNot(const DownloadCompleted('NVI.SQLite3')),
      );
    });

    test('DownloadFailed is equal for the same file and error key', () {
      expect(
        const DownloadFailed(
          dbFileName: 'KJV.SQLite3',
          errorMessageKey: 'error.network',
        ),
        const DownloadFailed(
          dbFileName: 'KJV.SQLite3',
          errorMessageKey: 'error.network',
        ),
      );
      expect(
        const DownloadFailed(
          dbFileName: 'KJV.SQLite3',
          errorMessageKey: 'error.network',
        ),
        isNot(
          const DownloadFailed(
            dbFileName: 'KJV.SQLite3',
            errorMessageKey: 'error.storage',
          ),
        ),
      );
    });

    test('different event types are never equal even with matching props', () {
      expect(
        const DownloadCompleted('KJV.SQLite3'),
        isNot(
          const DownloadFailed(
            dbFileName: 'KJV.SQLite3',
            errorMessageKey: 'x',
          ),
        ),
      );
    });
  });
}
