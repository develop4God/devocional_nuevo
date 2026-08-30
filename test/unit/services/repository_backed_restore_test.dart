@Tags(['unit', 'services', 'backup'])
library;

import 'package:devocional_nuevo/services/backup/repository_backed_restore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RepositoryBackedRestore.run', () {
    test('persists every entry and returns the restored count', () async {
      final persisted = <String>[];
      final errors = <String>[];

      final restoredCount = await RepositoryBackedRestore.run<String>(
        rawList: [
          {'name': 'a'},
          {'name': 'b'},
        ],
        decode: (json) => json['name'] as String,
        persist: (item) async => persisted.add(item),
        onEntryError: errors.add,
      );

      expect(restoredCount, 2);
      expect(persisted, ['a', 'b']);
      expect(errors, isEmpty);
    });

    test('skips a malformed entry and still restores the rest', () async {
      final persisted = <String>[];
      final errors = <String>[];

      final restoredCount = await RepositoryBackedRestore.run<String>(
        rawList: [
          {'name': 'a'},
          'not a map', // fails the `raw as Map` cast inside decode
          {'name': 'c'},
        ],
        decode: (json) => json['name'] as String,
        persist: (item) async => persisted.add(item),
        onEntryError: errors.add,
      );

      expect(restoredCount, 2);
      expect(persisted, ['a', 'c']);
      expect(errors, hasLength(1));
    });

    test('skips an entry that fails to persist and still counts successes',
        () async {
      final persisted = <String>[];
      final errors = <String>[];

      final restoredCount = await RepositoryBackedRestore.run<String>(
        rawList: [
          {'name': 'a'},
          {'name': 'boom'},
          {'name': 'c'},
        ],
        decode: (json) => json['name'] as String,
        persist: (item) async {
          if (item == 'boom') throw StateError('persist failed');
          persisted.add(item);
        },
        onEntryError: errors.add,
      );

      expect(restoredCount, 2);
      expect(persisted, ['a', 'c']);
      expect(errors, hasLength(1));
    });

    test('returns zero and reports every entry when all fail', () async {
      final errors = <String>[];

      final restoredCount = await RepositoryBackedRestore.run<String>(
        rawList: ['bad', 'also bad'],
        decode: (json) => json['name'] as String,
        persist: (item) async {},
        onEntryError: errors.add,
      );

      expect(restoredCount, 0);
      expect(errors, hasLength(2));
    });

    test('returns zero for an empty list without calling decode or persist',
        () async {
      var decodeCalls = 0;
      var persistCalls = 0;

      final restoredCount = await RepositoryBackedRestore.run<String>(
        rawList: const [],
        decode: (json) {
          decodeCalls++;
          return json['name'] as String;
        },
        persist: (item) async => persistCalls++,
        onEntryError: (_) {},
      );

      expect(restoredCount, 0);
      expect(decodeCalls, 0);
      expect(persistCalls, 0);
    });
  });
}
