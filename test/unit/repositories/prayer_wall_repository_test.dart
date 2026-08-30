@Tags(['unit', 'repositories'])
library;

import 'package:devocional_nuevo/repositories/prayer_wall_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PrayerWallRepository.hashUserId', () {
    test('produces a deterministic SHA-256 hash for the same uid', () {
      const uid = 'firebase-uid-123';

      final hash1 = PrayerWallRepository.hashUserId(uid);
      final hash2 = PrayerWallRepository.hashUserId(uid);

      expect(hash1, equals(hash2));
    });

    test('produces different hashes for different uids', () {
      final hashA = PrayerWallRepository.hashUserId('uid-a');
      final hashB = PrayerWallRepository.hashUserId('uid-b');

      expect(hashA, isNot(equals(hashB)));
    });

    test('never returns the raw uid', () {
      const uid = 'raw-uid-should-not-leak';

      final hash = PrayerWallRepository.hashUserId(uid);

      expect(hash, isNot(contains(uid)));
    });

    test('returns a 64-character lowercase hex string (SHA-256)', () {
      final hash = PrayerWallRepository.hashUserId('any-uid');

      expect(hash.length, equals(64));
      expect(hash, matches(RegExp(r'^[0-9a-f]{64}$')));
    });
  });
}
