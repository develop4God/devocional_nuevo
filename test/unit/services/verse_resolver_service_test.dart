@Tags(['unit', 'services'])
library;

import 'package:bible_reader_core/bible_reader_core.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

import '../../helpers/test_helpers.dart';

// ---------------------------------------------------------------------------
// Fake BibleDbService — controls findBookByName / getVerse without real SQLite.
// ---------------------------------------------------------------------------

class _FakeBibleDbService extends BibleDbService {
  Map<String, dynamic>? bookResult;
  Map<String, dynamic>? verseResult;
  bool initDbCalled = false;
  bool shouldThrowOnInit = false;

  // For range tests: map verse number to specific response
  Map<int, Map<String, dynamic>?>? versesByNumber;

  @override
  Future<void> initDb(String dbAssetPath, String dbName) async {
    initDbCalled = true;
    if (shouldThrowOnInit) throw Exception('DB init failed');
  }

  @override
  Future<Map<String, dynamic>?> findBookByName(String bookName) async {
    return bookResult;
  }

  @override
  Future<Map<String, dynamic>?> getVerse({
    required int bookNumber,
    required int chapter,
    required int verse,
  }) async {
    if (versesByNumber != null) {
      return versesByNumber![verse];
    }
    return verseResult;
  }
}

// ---------------------------------------------------------------------------
// Test-only subclass that bypasses the static BibleVersionRegistry.
// ---------------------------------------------------------------------------

VerseResolverService _createTestResolver(List<BibleVersion> versions) {
  return VerseResolverService(versionProvider: () async => versions);
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

BibleVersion _makeVersion({
  required String code,
  String lang = 'en',
  BibleDbService? service,
}) {
  return BibleVersion(
    name: '$code ($lang)',
    language: lang == 'en' ? 'English' : 'Español',
    languageCode: lang,
    assetPath: 'assets/biblia/${code}_$lang.SQLite3',
    dbFileName: '${code}_$lang.SQLite3',
    service: service,
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    PathProviderPlatform.instance = MockPathProviderPlatform();

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (call) async {
        switch (call.method) {
          case 'getApplicationDocumentsDirectory':
          case 'getApplicationSupportDirectory':
            return '/mock_documents';
          case 'getTemporaryDirectory':
            return '/mock_temp';
          default:
            return '/mock_unknown';
        }
      },
    );
  });

  group('VerseResolverService — contract compliance', () {
    test('implements IVerseResolverService', () {
      final service = VerseResolverService();
      expect(service, isA<IVerseResolverService>());
    });

    test('returns null for unknown version code', () async {
      final service = VerseResolverService();
      final result = await service.resolveVerseText(
        reference: 'John 3:16',
        versionCode: 'NONEXISTENT_VERSION_XYZ',
      );
      expect(result, isNull);
    });

    test('returns null for empty reference', () async {
      final service = VerseResolverService();
      final result = await service.resolveVerseText(
        reference: '',
        versionCode: 'KJ2000',
      );
      expect(result, isNull);
    });

    test('returns null for unparseable reference', () async {
      final service = VerseResolverService();
      final result = await service.resolveVerseText(
        reference: 'not-a-verse',
        versionCode: 'KJ2000',
      );
      expect(result, isNull);
    });

    test('returns null for reference without verse number', () async {
      final service = VerseResolverService();
      final result = await service.resolveVerseText(
        reference: 'John 3',
        versionCode: 'KJ2000',
      );
      expect(result, isNull);
    });

    test('never throws — returns null on internal error', () async {
      final service = VerseResolverService();
      final result = await service.resolveVerseText(
        reference: 'Genesis 1:1',
        versionCode: 'KJ2000',
      );
      expect(result, isNull);
    });
  });

  group('VerseResolverService — version matching', () {
    test('matches KJ2000 version code to KJ2000_en.SQLite3', () async {
      final versions = await BibleVersionRegistry.getAllVersions();
      final match = versions.where((v) => v.dbFileName.startsWith('KJ2000'));
      expect(match, isNotEmpty);
      expect(match.first.dbFileName, 'KJ2000_en.SQLite3');
    });

    test('matches RVR1960 version code to RVR1960_es.SQLite3', () async {
      final versions = await BibleVersionRegistry.getAllVersions();
      final match = versions.where((v) => v.dbFileName.startsWith('RVR1960'));
      expect(match, isNotEmpty);
      expect(match.first.dbFileName, 'RVR1960_es.SQLite3');
    });

    test('matches ESV version code to ESV_en.SQLite3', () async {
      final versions = await BibleVersionRegistry.getAllVersions();
      final match = versions.where((v) => v.dbFileName.startsWith('ESV'));
      expect(match, isNotEmpty);
      expect(match.first.dbFileName, 'ESV_en.SQLite3');
    });

    test('matches NVI — picks first match (Spanish NVI)', () async {
      final versions = await BibleVersionRegistry.getAllVersions();
      BibleVersion? match;
      for (final v in versions) {
        if (v.dbFileName.startsWith('NVI')) {
          match = v;
          break;
        }
      }
      expect(match, isNotNull);
      expect(match!.dbFileName, 'NVI_es.SQLite3');
    });

    test('no match for fabricated version code', () async {
      final versions = await BibleVersionRegistry.getAllVersions();
      final match = versions.where((v) => v.dbFileName.startsWith('ZZZZZ'));
      expect(match, isEmpty);
    });
  });

  group('VerseResolverService — happy path with fake DB', () {
    late _FakeBibleDbService fakeDb;

    setUp(() {
      fakeDb = _FakeBibleDbService()
        ..bookResult = {
          'book_number': 43,
          'long_name': 'John',
          'short_name': 'Jn',
        }
        ..verseResult = {
          'book_number': 43,
          'chapter': 3,
          'verse': 16,
          'text': 'For God so loved the world...',
        };
    });

    test('resolves verse text when DB returns a match', () async {
      final resolver = _createTestResolver([
        _makeVersion(code: 'KJ2000', service: fakeDb),
      ]);
      final result = await resolver.resolveVerseText(
        reference: 'John 3:16',
        versionCode: 'KJ2000',
      );
      expect(result, 'For God so loved the world...');
      expect(fakeDb.initDbCalled, isTrue);
    });

    test('returns null when book is not found', () async {
      fakeDb.bookResult = null;
      final resolver = _createTestResolver([
        _makeVersion(code: 'KJ2000', service: fakeDb),
      ]);
      final result = await resolver.resolveVerseText(
        reference: 'John 3:16',
        versionCode: 'KJ2000',
      );
      expect(result, isNull);
    });

    test('returns null when verse is not found', () async {
      fakeDb.verseResult = null;
      final resolver = _createTestResolver([
        _makeVersion(code: 'KJ2000', service: fakeDb),
      ]);
      final result = await resolver.resolveVerseText(
        reference: 'John 3:16',
        versionCode: 'KJ2000',
      );
      expect(result, isNull);
    });

    test('returns null when DB init throws', () async {
      fakeDb.shouldThrowOnInit = true;
      final resolver = _createTestResolver([
        _makeVersion(code: 'KJ2000', service: fakeDb),
      ]);
      final result = await resolver.resolveVerseText(
        reference: 'John 3:16',
        versionCode: 'KJ2000',
      );
      expect(result, isNull);
    });

    test('returns null when version list is empty', () async {
      final resolver = _createTestResolver([]);
      final result = await resolver.resolveVerseText(
        reference: 'John 3:16',
        versionCode: 'KJ2000',
      );
      expect(result, isNull);
    });

    test('picks first matching version when multiple match prefix', () async {
      final fakeDb2 = _FakeBibleDbService()
        ..bookResult = {
          'book_number': 43,
          'long_name': 'John',
          'short_name': 'Jn',
        }
        ..verseResult = {'text': 'Second version text'};

      final resolver = _createTestResolver([
        _makeVersion(code: 'KJ2000', service: fakeDb),
        _makeVersion(code: 'KJ2000', lang: 'alt', service: fakeDb2),
      ]);
      final result = await resolver.resolveVerseText(
        reference: 'John 3:16',
        versionCode: 'KJ2000',
      );
      expect(result, 'For God so loved the world...');
    });
  });

  group('VerseResolverService — user behavior scenarios', () {
    test('user with KJ2000 sees resolved text for a valid verse', () async {
      final fakeDb = _FakeBibleDbService()
        ..bookResult = {
          'book_number': 1,
          'long_name': 'Genesis',
          'short_name': 'Gen',
        }
        ..verseResult = {
          'text': 'In the beginning God created the heaven and the earth.',
        };

      final resolver = _createTestResolver([
        _makeVersion(code: 'KJ2000', service: fakeDb),
      ]);
      final result = await resolver.resolveVerseText(
        reference: 'Genesis 1:1',
        versionCode: 'KJ2000',
      );
      expect(result, 'In the beginning God created the heaven and the earth.');
    });

    test('user with unsupported version silently falls back', () async {
      final resolver = _createTestResolver([_makeVersion(code: 'KJ2000')]);
      final result = await resolver.resolveVerseText(
        reference: 'Genesis 1:1',
        versionCode: 'UNSUPPORTED_VERSION',
      );
      expect(result, isNull);
    });

    test('user sees fallback when encounter has malformed reference', () async {
      final fakeDb = _FakeBibleDbService()
        ..bookResult = {
          'book_number': 43,
          'long_name': 'John',
          'short_name': 'Jn',
        }
        ..verseResult = {'text': 'For God so loved...'};

      final resolver = _createTestResolver([
        _makeVersion(code: 'KJ2000', service: fakeDb),
      ]);

      expect(
        await resolver.resolveVerseText(
          reference: 'InvalidRef!!!',
          versionCode: 'KJ2000',
        ),
        isNull,
      );
      expect(
        await resolver.resolveVerseText(reference: '', versionCode: 'KJ2000'),
        isNull,
      );
      expect(
        await resolver.resolveVerseText(
            reference: '123', versionCode: 'KJ2000'),
        isNull,
      );
    });

    test('user with Spanish RVR1960 resolves a Spanish verse', () async {
      final fakeDb = _FakeBibleDbService()
        ..bookResult = {
          'book_number': 43,
          'long_name': 'Juan',
          'short_name': 'Jn',
        }
        ..verseResult = {
          'text':
              'Porque de tal manera amó Dios al mundo, que ha dado a su Hijo unigénito...',
        };

      final resolver = _createTestResolver([
        _makeVersion(code: 'RVR1960', lang: 'es', service: fakeDb),
      ]);
      final result = await resolver.resolveVerseText(
        reference: 'Juan 3:16',
        versionCode: 'RVR1960',
      );
      expect(result, contains('Porque de tal manera amó Dios'));
    });

    test('resolver handles verse range with multiple consecutive verses',
        () async {
      final fakeDb = _FakeBibleDbService()
        ..bookResult = {
          'book_number': 1,
          'long_name': 'Genesis',
          'short_name': 'Gen',
        }
        ..versesByNumber = {
          1: {
            'text': 'In the beginning God created the heavens and the earth.',
          },
          2: {
            'text':
                'Now the earth was formless and empty, darkness was over the surface of the deep.',
          },
          3: {
            'text': 'And God said, "Let there be light: and there was light.',
          },
        };

      final resolver = _createTestResolver([
        _makeVersion(code: 'KJ2000', service: fakeDb),
      ]);
      final result = await resolver.resolveVerseText(
        reference: 'Genesis 1:1-3',
        versionCode: 'KJ2000',
      );
      expect(
        result,
        'In the beginning God created the heavens and the earth. Now the earth was formless and empty, darkness was over the surface of the deep. And God said, "Let there be light: and there was light.',
      );
    });

    test('resolver returns null when any verse in range is missing', () async {
      final fakeDb = _FakeBibleDbService()
        ..bookResult = {
          'book_number': 43,
          'long_name': 'John',
          'short_name': 'Jn',
        }
        ..versesByNumber = {
          16: {'text': 'For God so loved the world...'},
          // verse 17 is intentionally missing
          18: {'text': 'Whoever believes in him is not condemned...'},
        };

      final resolver = _createTestResolver([
        _makeVersion(code: 'KJ2000', service: fakeDb),
      ]);
      final result = await resolver.resolveVerseText(
        reference: 'John 3:16-18',
        versionCode: 'KJ2000',
      );
      expect(result, isNull);
    });

    test('resolver handles single verse (no range) as before', () async {
      final fakeDb = _FakeBibleDbService()
        ..bookResult = {
          'book_number': 43,
          'long_name': 'John',
          'short_name': 'Jn',
        }
        ..verseResult = {'text': 'For God so loved the world...'};

      final resolver = _createTestResolver([
        _makeVersion(code: 'KJ2000', service: fakeDb),
      ]);
      final result = await resolver.resolveVerseText(
        reference: 'John 3:16',
        versionCode: 'KJ2000',
      );
      expect(result, 'For God so loved the world...');
    });

    test(
      'resolver ignores hyphen not in range format (e.g., "John-3:16")',
      () async {
        final fakeDb = _FakeBibleDbService()
          ..bookResult = {
            'book_number': 43,
            'long_name': 'John',
            'short_name': 'Jn',
          }
          ..verseResult = {'text': 'Test verse'};

        final resolver = _createTestResolver([
          _makeVersion(code: 'KJ2000', service: fakeDb),
        ]);
        final result = await resolver.resolveVerseText(
          reference: 'John-3:16',
          versionCode: 'KJ2000',
        );
        expect(result, isNull);
      },
    );

    test('resolver never throws for any registered version code', () async {
      final service = VerseResolverService();
      final versionCodes = [
        'KJ2000',
        'NIV',
        'ESV',
        'RVR1960',
        'NVI',
        'NTV',
        'ARC',
        'LSG1910',
        'BDS',
        'SK2003',
        'JCB',
        'CUV1919',
        'CNVS',
        'HIOV',
        'HERV',
        'LU17',
        'SCH2000',
        'NAV',
        'SVDA',
        'MBB05',
        'ASND',
        'ADB',
      ];
      for (final code in versionCodes) {
        final result = await service.resolveVerseText(
          reference: 'John 3:16',
          versionCode: code,
        );
        expect(result, isNull, reason: '$code should return null, not throw');
      }
    });

    test('resolver reuses pre-existing service instance', () async {
      final fakeDb = _FakeBibleDbService()
        ..bookResult = {
          'book_number': 43,
          'long_name': 'John',
          'short_name': 'Jn',
        }
        ..verseResult = {'text': 'First call'};

      final version = _makeVersion(code: 'KJ2000', service: fakeDb);
      final resolver = _createTestResolver([version]);

      await resolver.resolveVerseText(
        reference: 'John 3:16',
        versionCode: 'KJ2000',
      );
      expect(version.service, same(fakeDb));
    });

    test(
      'resolver assigns BibleDbService when version has no service',
      () async {
        final version = _makeVersion(code: 'KJ2000');
        expect(version.service, isNull);

        final resolver = _createTestResolver([version]);
        await resolver.resolveVerseText(
          reference: 'John 3:16',
          versionCode: 'KJ2000',
        );
        // service was assigned (initDb will throw since no real asset, caught)
        expect(version.service, isA<BibleDbService>());
      },
    );
  });
}
