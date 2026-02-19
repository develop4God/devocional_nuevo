@Tags(['unit', 'repositories'])
library;

// test/unit/repositories/supporter_profile_repository_test.dart
//
// TASK 6: Tests for SupporterProfileRepository (gold name persistence).

import 'package:devocional_nuevo/repositories/supporter_profile_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('SupporterProfileRepository', () {
    late SupporterProfileRepository repo;

    setUp(() {
      TestWidgetsFlutterBinding.ensureInitialized();
      SharedPreferences.setMockInitialValues({});
      repo = SupporterProfileRepository(
        prefsFactory: SharedPreferences.getInstance,
      );
    });

    // ── Load ────────────────────────────────────────────────────────────────

    test('loadGoldSupporterName() returns null when nothing saved', () async {
      expect(await repo.loadGoldSupporterName(), isNull);
    });

    // ── Save / Load round-trip ───────────────────────────────────────────────

    test('save then load returns the same name', () async {
      await repo.saveGoldSupporterName('Ana Sofía');
      expect(await repo.loadGoldSupporterName(), equals('Ana Sofía'));
    });

    test('save overwrites previous name', () async {
      await repo.saveGoldSupporterName('First Name');
      await repo.saveGoldSupporterName('Updated Name');
      expect(await repo.loadGoldSupporterName(), equals('Updated Name'));
    });

    test('saves are persisted in SharedPreferences under correct key',
        () async {
      await repo.saveGoldSupporterName('María José');
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('iap_gold_supporter_name'),
          equals('María José'));
    });

    test('loadGoldSupporterName() reads from pre-seeded SharedPreferences',
        () async {
      SharedPreferences.setMockInitialValues({
        'iap_gold_supporter_name': 'Pre-seeded Name',
      });
      final seededRepo = SupporterProfileRepository(
        prefsFactory: SharedPreferences.getInstance,
      );
      expect(await seededRepo.loadGoldSupporterName(),
          equals('Pre-seeded Name'));
    });

    // ── Unicode & special characters ─────────────────────────────────────────

    test('handles unicode names correctly', () async {
      const name = 'Santiago Pérez Müñoz 🙏';
      await repo.saveGoldSupporterName(name);
      expect(await repo.loadGoldSupporterName(), equals(name));
    });

    test('handles empty string', () async {
      await repo.saveGoldSupporterName('');
      expect(await repo.loadGoldSupporterName(), equals(''));
    });
  });
}
