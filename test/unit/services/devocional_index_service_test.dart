@Tags(['unit', 'services'])
library;

import 'package:devocional_nuevo/services/devocional_index_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';

class MockHttpClient extends Mock implements http.Client {}

void main() {
  late DevocionalIndexService service;

  setUp(() {
    service = DevocionalIndexService(MockHttpClient());
  });

  // ── extractAvailableYears ──────────────────────────────────────────────────

  group('extractAvailableYears', () {
    test('returns empty list for null index', () {
      expect(service.extractAvailableYears(null), isEmpty);
    });

    test('returns empty list when index has no files key', () {
      expect(service.extractAvailableYears({}), isEmpty);
      expect(service.extractAvailableYears({'schema_version': 1}), isEmpty);
    });

    test('returns empty list when files map is empty', () {
      expect(
        service.extractAvailableYears({'files': <String, dynamic>{}}),
        isEmpty,
      );
    });

    test('extracts years from a single language/version', () {
      final index = {
        'files': {
          'es': {
            'RVR1960': {'2025': '2026-01-01', '2026': '2026-03-01'},
          },
        },
      };

      expect(service.extractAvailableYears(index), [2025, 2026]);
    });

    test('deduplicates years present across multiple languages', () {
      final index = {
        'files': {
          'es': {
            'RVR1960': {'2025': '2026-01-01', '2026': '2026-01-01'},
          },
          'en': {
            'KJV': {'2025': '2026-01-01', '2026': '2026-01-01'},
          },
          'pt': {
            'ARC': {'2025': '2026-01-01'},
          },
        },
      };

      final result = service.extractAvailableYears(index);

      // 2025 and 2026 appear multiple times — deduplicated
      expect(result, [2025, 2026]);
    });

    test('collects years across multiple versions of the same language', () {
      final index = {
        'files': {
          'es': {
            'RVR1960': {'2025': '2026-01-01'},
            'NVI': {'2026': '2026-01-01'},
          },
        },
      };

      expect(service.extractAvailableYears(index), [2025, 2026]);
    });

    test('result is always sorted ascending', () {
      // Keys in map are not guaranteed ordered — sorting must be explicit
      final index = {
        'files': {
          'es': {
            'RVR1960': {
              '2026': '2026-01-01',
              '2025': '2026-01-01',
              '2027': '2026-01-01',
            },
          },
        },
      };

      final result = service.extractAvailableYears(index);

      expect(result, [2025, 2026, 2027]);
      for (int i = 0; i < result.length - 1; i++) {
        expect(
          result[i] < result[i + 1],
          isTrue,
          reason: 'years must be sorted ascending',
        );
      }
    });

    test('skips malformed year keys that cannot be parsed as int', () {
      final index = {
        'files': {
          'es': {
            'RVR1960': {
              '2025': '2026-01-01',
              'invalid': '2026-01-01', // int.tryParse → null, must be skipped
              '': '2026-01-01', // empty string → null
              'abc': '2026-01-01', // alpha → null
              '2026': '2026-01-01',
            },
          },
        },
      };

      expect(service.extractAvailableYears(index), [2025, 2026]);
    });

    test('skips non-map language values gracefully', () {
      final index = {
        'files': {
          'es': 'not-a-map', // malformed — should be skipped
          'en': {
            'KJV': {'2025': '2026-01-01'},
          },
        },
      };

      expect(service.extractAvailableYears(index), [2025]);
    });

    test('skips non-map version values gracefully', () {
      final index = {
        'files': {
          'es': {
            'RVR1960': 'not-a-map', // malformed version block
            'NVI': {'2026': '2026-01-01'},
          },
        },
      };

      expect(service.extractAvailableYears(index), [2026]);
    });

    test('returns correct years for real index.json structure', () {
      // Mirror of the actual remote index.json schema (2026-03-03 snapshot)
      final index = {
        'schema_version': 1,
        'updated_at': '2026-03-03',
        'files': {
          'es': {
            'RVR1960': {'2025': '2026-03-03', '2026': '2026-03-03'},
            'NVI': {'2025': '2026-03-03', '2026': '2026-03-03'},
          },
          'en': {
            'KJV': {'2025': '2026-03-03', '2026': '2026-03-03'},
            'NIV': {'2025': '2026-03-03', '2026': '2026-03-03'},
          },
          'pt': {
            'ARC': {'2025': '2026-03-03', '2026': '2026-03-03'},
          },
          'hi': {
            'HIOV': {'2025': '2026-03-10', '2026': '2026-03-03'},
            'HERV': {'2025': '2026-03-04', '2026': '2026-03-03'},
          },
        },
      };

      final result = service.extractAvailableYears(index);

      expect(result, [2025, 2026]);
      expect(result.length, 2, reason: 'duplicates must be collapsed');
    });
  });
}
