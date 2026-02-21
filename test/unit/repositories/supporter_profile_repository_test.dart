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

    test('loadProfileName() returns null when nothing saved', () async {
      expect(await repo.loadProfileName(), isNull);
    });

    // ── Save / Load round-trip ───────────────────────────────────────────────

    test('save then load returns the same name', () async {
      await repo.saveProfileName('Ana Sofía');
      expect(await repo.loadProfileName(), equals('Ana Sofía'));
    });

    test('save overwrites previous name', () async {
      await repo.saveProfileName('First Name');
      await repo.saveProfileName('Updated Name');
      expect(await repo.loadProfileName(), equals('Updated Name'));
    });

    test('saves are persisted in SharedPreferences under correct key',
        () async {
      await repo.saveProfileName('María José');
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('profile_display_name'), equals('María José'));
    });

    test('loadProfileName() reads from pre-seeded SharedPreferences',
        () async {
      SharedPreferences.setMockInitialValues({
        'iap_gold_supporter_name': 'Pre-seeded Name',
      });
      final seededRepo = SupporterProfileRepository(
        prefsFactory: SharedPreferences.getInstance,
      );
      expect(
          await seededRepo.loadProfileName(), equals('Pre-seeded Name'));
    });

    // ── Unicode & special characters ─────────────────────────────────────────

    test('handles unicode names correctly', () async {
      const name = 'Santiago Pérez Müñoz 🙏';
      await repo.saveProfileName(name);
      expect(await repo.loadProfileName(), equals(name));
    });

    test('handles empty string', () async {
      await repo.saveProfileName('');
      expect(await repo.loadProfileName(), equals(''));
    });
  });
}
