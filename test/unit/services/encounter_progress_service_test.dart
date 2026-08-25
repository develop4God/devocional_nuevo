@Tags(['unit', 'services'])
library;

import 'package:devocional_nuevo/services/encounter_progress_service.dart';
import 'package:devocional_nuevo/services/i_encounter_progress_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late EncounterProgressService service;

  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    service = EncounterProgressService();
  });

  group('EncounterProgressService.loadCompletedIds', () {
    test('returns an empty set when nothing is stored', () async {
      SharedPreferences.setMockInitialValues({});

      expect(await service.loadCompletedIds(), isEmpty);
    });

    test('returns previously stored ids as a set', () async {
      SharedPreferences.setMockInitialValues({
        IEncounterProgressService.completedIdsKey: ['peter_intro', 'paul_1'],
      });

      expect(
        await service.loadCompletedIds(),
        {'peter_intro', 'paul_1'},
      );
    });
  });

  group('EncounterProgressService.markCompleted', () {
    test('adds a new encounter id to the persisted set', () async {
      SharedPreferences.setMockInitialValues({});

      await service.markCompleted('peter_intro');

      expect(await service.loadCompletedIds(), {'peter_intro'});
    });

    test('accumulates multiple distinct ids', () async {
      SharedPreferences.setMockInitialValues({});

      await service.markCompleted('peter_intro');
      await service.markCompleted('paul_1');

      expect(await service.loadCompletedIds(), {'peter_intro', 'paul_1'});
    });

    test('is idempotent for an id already marked completed', () async {
      SharedPreferences.setMockInitialValues({});

      await service.markCompleted('peter_intro');
      await service.markCompleted('peter_intro');

      expect(await service.loadCompletedIds(), {'peter_intro'});
    });
  });

  group('EncounterProgressService.isCompleted', () {
    test('returns false for an id that was never marked', () async {
      SharedPreferences.setMockInitialValues({});

      expect(await service.isCompleted('peter_intro'), isFalse);
    });

    test('returns true after the id has been marked completed', () async {
      SharedPreferences.setMockInitialValues({});

      await service.markCompleted('peter_intro');

      expect(await service.isCompleted('peter_intro'), isTrue);
    });
  });

  group('EncounterProgressService.resetProgress', () {
    test('removes a single id while keeping the others', () async {
      SharedPreferences.setMockInitialValues({});
      await service.markCompleted('peter_intro');
      await service.markCompleted('paul_1');

      await service.resetProgress('peter_intro');

      expect(await service.loadCompletedIds(), {'paul_1'});
    });

    test('is a no-op when the id was never completed', () async {
      SharedPreferences.setMockInitialValues({});
      await service.markCompleted('paul_1');

      await service.resetProgress('peter_intro');

      expect(await service.loadCompletedIds(), {'paul_1'});
    });
  });

  group('EncounterProgressService.clearAll', () {
    test('removes every persisted completed id', () async {
      SharedPreferences.setMockInitialValues({});
      await service.markCompleted('peter_intro');
      await service.markCompleted('paul_1');

      await service.clearAll();

      expect(await service.loadCompletedIds(), isEmpty);
    });
  });
}
