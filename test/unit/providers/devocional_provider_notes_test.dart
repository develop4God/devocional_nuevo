@Tags(['unit', 'providers', 'notes'])
library;

import 'dart:async';
import 'dart:convert';

import 'package:devocional_nuevo/models/devocional_model.dart';
import 'package:devocional_nuevo/providers/devocional_provider.dart';
import 'package:devocional_nuevo/repositories/devocional_repository.dart';
import 'package:devocional_nuevo/services/localization_service.dart';
import 'package:devocional_nuevo/services/service_locator.dart';
import 'package:devocional_nuevo/services/tts/i_tts_service.dart';
import 'package:devocional_nuevo/services/tts_service.dart';
import 'package:devocional_nuevo/services/cache_metadata_service.dart';
import 'package:devocional_nuevo/services/devocional_index_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mocktail/mocktail.dart';

/// Complete fake implementation of ITtsService for testing
class FakeTtsService implements ITtsService {
  final StreamController<TtsState> _stateController =
      StreamController.broadcast();
  final StreamController<double> _progressController =
      StreamController<double>.broadcast();

  @override
  Stream<TtsState> get stateStream => _stateController.stream;

  @override
  Stream<double> get progressStream => _progressController.stream;

  @override
  void setLanguageContext(String language, String version) {}

  @override
  Future<void> assignDefaultVoiceForLanguage(String languageCode) async {}

  @override
  Future<void> dispose() async {
    await _stateController.close();
    await _progressController.close();
  }

  @override
  Future<List<String>> getLanguages() async => [];

  @override
  Future<List<String>> getVoices() async => [];

  @override
  Future<List<String>> getVoicesForLanguage(String language) async => [];

  @override
  String formatBibleBook(String reference) => reference;

  @override
  String? get currentDevocionalId => null;

  @override
  TtsState get currentState => TtsState.idle;

  @override
  bool get isActive => true;

  @override
  bool get isDisposed => false;

  @override
  bool get isPaused => false;

  @override
  bool get isPlaying => false;

  @override
  Future<void> initialize() async {}

  @override
  Future<void> initializeTtsOnAppStart(String languageCode) async {}

  @override
  Future<void> pause() async {}

  @override
  Future<void> resume() async {}

  @override
  Future<void> setLanguage(String language) async {}

  @override
  Future<void> setSpeechRate(double rate) async {}

  @override
  Future<void> setVoice(Map<String, String> voice) async {}

  @override
  Future<void> speakDevotional(Devocional devocional) async {}

  @override
  Future<void> speakText(String text) async {}

  @override
  Future<void> stop() async {}
}

class _MockDevocionalIndexService extends Mock
    implements DevocionalIndexService {}

class _MockCacheMetadataService extends Mock implements CacheMetadataService {}

class _MockDevocionalRepository extends Mock implements DevocionalRepository {}

/// Helper to create a provider with mocked dependencies for notes testing
Future<DevocionalProvider> _createProvider({
  Map<String, Object> initialPrefs = const {},
}) async {
  SharedPreferences.setMockInitialValues(initialPrefs);

  final localIndexService = _MockDevocionalIndexService();
  final localMetadataService = _MockCacheMetadataService();
  final localRepository = _MockDevocionalRepository();
  when(() => localIndexService.fetchIndex()).thenAnswer((_) async => null);
  when(
    () => localMetadataService.readManifestDate(any()),
  ).thenAnswer((_) async => null);
  when(
    () => localMetadataService.writeMetadata(any(), any()),
  ).thenAnswer((_) async {});

  final provider = DevocionalProvider(
    devocionalIndexService: localIndexService,
    cacheMetadataService: localMetadataService,
    devocionalRepository: localRepository,
  );

  return provider;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    ServiceLocator().reset();
    ServiceLocator().registerSingleton<ITtsService>(FakeTtsService());
    ServiceLocator().registerSingleton<LocalizationService>(
      LocalizationService(),
    );
  });

  tearDown(() {
    ServiceLocator().reset();
  });

  group('Notes Feature — saveNoteForDevocional & getNoteForDevocional', () {
    test(
        'saveNoteForDevocional persists a note and getNoteForDevocional retrieves it',
        () async {
      final provider = await _createProvider();
      const devocionalId = 'test-id-001';
      const noteText = 'This is my personal reflection on this devotional.';

      // Save a note
      await provider.saveNoteForDevocional(devocionalId, noteText);

      // Retrieve it
      final retrievedNote = provider.getNoteForDevocional(devocionalId);

      expect(retrievedNote, equals(noteText));
    });

    test('getNoteForDevocional returns null when no note exists', () async {
      final provider = await _createProvider();
      const devocionalId = 'non-existent-id';

      final note = provider.getNoteForDevocional(devocionalId);

      expect(note, isNull);
    });

    test('empty note deletes the entry and is not retrieved', () async {
      final provider = await _createProvider();
      const devocionalId = 'test-id-002';
      const noteText = 'Initial note';

      // Save initial note
      await provider.saveNoteForDevocional(devocionalId, noteText);
      expect(provider.getNoteForDevocional(devocionalId), equals(noteText));

      // Save empty note (should delete)
      await provider.saveNoteForDevocional(devocionalId, '');

      // Verify it's deleted
      expect(provider.getNoteForDevocional(devocionalId), isNull);
    });

    test('null note deletes the entry', () async {
      final provider = await _createProvider();
      const devocionalId = 'test-id-003';
      const noteText = 'Note to remove';

      // Save initial note
      await provider.saveNoteForDevocional(devocionalId, noteText);
      expect(provider.getNoteForDevocional(devocionalId), equals(noteText));

      // Save null note (should delete)
      await provider.saveNoteForDevocional(devocionalId, null);

      // Verify it's deleted
      expect(provider.getNoteForDevocional(devocionalId), isNull);
    });

    test('whitespace-only note is trimmed and treated as empty', () async {
      final provider = await _createProvider();
      const devocionalId = 'test-id-004';

      // Save whitespace-only note
      await provider.saveNoteForDevocional(devocionalId, '   \n\t  ');

      // Verify it's treated as empty and deleted
      expect(provider.getNoteForDevocional(devocionalId), isNull);
    });

    test('saveNoteForDevocional ignores empty id', () async {
      final provider = await _createProvider();

      // Should return early without error
      await provider.saveNoteForDevocional('', 'note text');

      // Verify nothing was saved
      expect(provider.getNoteForDevocional(''), isNull);
    });

    test('getNoteForDevocional returns null for empty id', () async {
      final provider = await _createProvider();

      final note = provider.getNoteForDevocional('');

      expect(note, isNull);
    });

    test('note text is trimmed when saved', () async {
      final provider = await _createProvider();
      const devocionalId = 'test-id-005';
      const noteWithWhitespace = '  Leading and trailing  ';
      const expectedTrimmed = 'Leading and trailing';

      await provider.saveNoteForDevocional(devocionalId, noteWithWhitespace);

      final retrieved = provider.getNoteForDevocional(devocionalId);
      expect(retrieved, equals(expectedTrimmed));
    });

    test('multiple notes can be saved independently', () async {
      final provider = await _createProvider();

      await provider.saveNoteForDevocional('id-1', 'Note 1');
      await provider.saveNoteForDevocional('id-2', 'Note 2');
      await provider.saveNoteForDevocional('id-3', 'Note 3');

      expect(provider.getNoteForDevocional('id-1'), equals('Note 1'));
      expect(provider.getNoteForDevocional('id-2'), equals('Note 2'));
      expect(provider.getNoteForDevocional('id-3'), equals('Note 3'));
    });

    test('updating an existing note overwrites previous value', () async {
      final provider = await _createProvider();
      const devocionalId = 'test-id-006';

      await provider.saveNoteForDevocional(devocionalId, 'Old note');
      expect(provider.getNoteForDevocional(devocionalId), equals('Old note'));

      await provider.saveNoteForDevocional(devocionalId, 'New note');
      expect(provider.getNoteForDevocional(devocionalId), equals('New note'));
    });
  });

  group('Notes Persistence — SharedPreferences', () {
    test('saveNoteForDevocional persists data to SharedPreferences', () async {
      final provider = await _createProvider();
      const devocionalId = 'persist-test-001';
      const noteText = 'This note should persist';

      await provider.saveNoteForDevocional(devocionalId, noteText);

      // Verify it was saved to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final savedJson = prefs.getString('devotional_notes');
      expect(savedJson, isNotNull);

      final decoded = json.decode(savedJson!) as Map<String, dynamic>;
      expect(decoded[devocionalId], equals(noteText));
    });
  });

  group('Notes Error Handling — Malformed JSON', () {
    test('malformed JSON in SharedPreferences is caught and handled gracefully',
        () async {
      // Set up with malformed JSON
      SharedPreferences.setMockInitialValues({
        'devotional_notes': '{this is not valid json [',
      });

      final provider = await _createProvider();
      // Give _loadNotes time to load and handle the error
      await Future.delayed(const Duration(milliseconds: 100));

      // Should not crash; notes should be empty
      expect(provider.getNoteForDevocional('any-id'), isNull);

      // Should still be able to save new notes after error recovery
      await provider.saveNoteForDevocional('new-id', 'New note after error');
      expect(provider.getNoteForDevocional('new-id'),
          equals('New note after error'));
    });

    test('notes with non-string values in JSON are handled', () async {
      // Set up with invalid value types
      SharedPreferences.setMockInitialValues({
        'devotional_notes': json.encode({
          'id-1': 'valid string',
          'id-2': 123, // This should cause issues during cast
        }),
      });

      final provider = await _createProvider();
      // Give _loadNotes time to attempt load
      await Future.delayed(const Duration(milliseconds: 100));

      // Should recover gracefully; may or may not have id-1 depending on
      // when the cast error occurs, but should not crash the app
      // The important thing is that we can still use the provider
      await provider.saveNoteForDevocional('id-3', 'After error recovery');
      expect(provider.getNoteForDevocional('id-3'),
          equals('After error recovery'));
    });
  });

  group('Notes Concurrency — _notesLock isolation', () {
    test('concurrent saves do not cause race conditions', () async {
      final provider = await _createProvider();

      // Fire multiple saves concurrently
      final futures = <Future<void>>[];
      for (int i = 0; i < 10; i++) {
        futures.add(
          provider.saveNoteForDevocional('concurrent-id-$i', 'Note $i'),
        );
      }

      await Future.wait(futures);

      // All notes should be saved correctly
      for (int i = 0; i < 10; i++) {
        expect(
          provider.getNoteForDevocional('concurrent-id-$i'),
          equals('Note $i'),
        );
      }
    });

    test('concurrent read/write does not cause inconsistency', () async {
      final provider = await _createProvider();

      await provider.saveNoteForDevocional('rw-test', 'Initial value');

      // Fire reads and writes concurrently
      final readFutures = <Future<String?>>[];
      for (int i = 0; i < 5; i++) {
        readFutures.add(
          Future.microtask(() => provider.getNoteForDevocional('rw-test')),
        );
      }

      final writesFutures = <Future<void>>[];
      for (int i = 0; i < 5; i++) {
        writesFutures.add(
          provider.saveNoteForDevocional('rw-test', 'Value $i'),
        );
      }

      await Future.wait([...readFutures, ...writesFutures]);

      // Final read should return a valid note (last write wins)
      final finalNote = provider.getNoteForDevocional('rw-test');
      expect(finalNote, isNotNull);
    });
  });
}
