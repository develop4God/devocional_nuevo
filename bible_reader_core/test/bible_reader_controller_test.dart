import 'package:bible_reader_core/src/bible_db_service.dart';
import 'package:bible_reader_core/src/bible_preferences_service.dart';
import 'package:bible_reader_core/src/bible_reader_controller.dart';
import 'package:bible_reader_core/src/bible_reader_service.dart';
import 'package:bible_reader_core/src/bible_reading_position_service.dart';
import 'package:bible_reader_core/src/bible_reader_state.dart';
import 'package:bible_reader_core/src/bible_version.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late BibleReaderController controller;
  late BibleReaderService readerService;
  late BiblePreferencesService preferencesService;
  late BibleDbService dbService;
  late List<BibleVersion> testVersions;

  setUp(() async {
    // Initialize SharedPreferences for testing
    SharedPreferences.setMockInitialValues({});

    // Create test versions
    testVersions = [
      BibleVersion(
        name: 'RVR1960',
        language: 'Español',
        languageCode: 'es',
        assetPath: 'assets/bible/es_rvr1960.db',
        dbFileName: 'es_rvr1960.db',
      ),
      BibleVersion(
        name: 'NIV',
        language: 'English',
        languageCode: 'en',
        assetPath: 'assets/bible/en_niv.db',
        dbFileName: 'en_niv.db',
      ),
    ];

    // Initialize services
    dbService = BibleDbService();
    final positionService = BibleReadingPositionService();
    readerService = BibleReaderService(
      dbService: dbService,
      positionService: positionService,
    );
    preferencesService = BiblePreferencesService();

    // Create controller
    controller = BibleReaderController(
      allVersions: testVersions,
      readerService: readerService,
      preferencesService: preferencesService,
    );
  });

  tearDown(() {
    controller.dispose();
  });

  group('BibleReaderController Initialization Tests', () {
    test('should start with default state', () {
      expect(controller.state.isLoading, false);
      expect(controller.state.availableVersions, isEmpty);
      expect(controller.state.selectedVersion, isNull);
      expect(controller.state.fontSize, 18.0);
    });

    test('should have a state stream', () {
      expect(controller.stateStream, isNotNull);
    });

    test('should emit state changes through stream', () async {
      final states = <BibleReaderState>[];
      controller.stateStream.listen(states.add);

      controller.toggleFontControls();

      await Future.delayed(const Duration(milliseconds: 50));

      expect(states, isNotEmpty);
      expect(states.last.showFontControls, true);
    });
  });

  group('BibleReaderController Font Size Tests', () {
    test('should increase font size', () async {
      final initialSize = controller.state.fontSize;

      await controller.increaseFontSize();

      expect(controller.state.fontSize, initialSize + 2);
    });

    test('should decrease font size', () async {
      final initialSize = controller.state.fontSize;

      await controller.decreaseFontSize();

      expect(controller.state.fontSize, initialSize - 2);
    });

    test('should not increase font size beyond 30', () async {
      // Set font size to 30
      await preferencesService.saveFontSize(30);
      controller = BibleReaderController(
        allVersions: testVersions,
        readerService: readerService,
        preferencesService: preferencesService,
        initialState: controller.state.copyWith(fontSize: 30),
      );

      await controller.increaseFontSize();

      expect(controller.state.fontSize, 30);
    });

    test('should not decrease font size below 12', () async {
      // Set font size to 12
      await preferencesService.saveFontSize(12);
      controller = BibleReaderController(
        allVersions: testVersions,
        readerService: readerService,
        preferencesService: preferencesService,
        initialState: controller.state.copyWith(fontSize: 12),
      );

      await controller.decreaseFontSize();

      expect(controller.state.fontSize, 12);
    });

    test('should persist font size changes', () async {
      await controller.increaseFontSize();
      final savedSize = await preferencesService.getFontSize();

      expect(savedSize, controller.state.fontSize);
    });
  });

  group('BibleReaderController Font Controls Tests', () {
    test('should toggle font controls visibility', () {
      expect(controller.state.showFontControls, false);

      controller.toggleFontControls();

      expect(controller.state.showFontControls, true);

      controller.toggleFontControls();

      expect(controller.state.showFontControls, false);
    });

    test('should set font controls visibility directly', () {
      controller.setFontControlsVisibility(true);
      expect(controller.state.showFontControls, true);

      controller.setFontControlsVisibility(false);
      expect(controller.state.showFontControls, false);
    });
  });

  group('BibleReaderController Verse Selection Tests', () {
    test('should toggle verse selection', () {
      const verseKey = 'Genesis|1|1';

      controller.toggleVerseSelection(verseKey);

      expect(controller.state.selectedVerses.contains(verseKey), true);

      controller.toggleVerseSelection(verseKey);

      expect(controller.state.selectedVerses.contains(verseKey), false);
    });

    test('should clear all selected verses', () {
      controller.toggleVerseSelection('Genesis|1|1');
      controller.toggleVerseSelection('Genesis|1|2');

      expect(controller.state.selectedVerses.length, 2);

      controller.clearSelectedVerses();

      expect(controller.state.selectedVerses, isEmpty);
    });

    test('should maintain multiple selected verses', () {
      controller.toggleVerseSelection('Genesis|1|1');
      controller.toggleVerseSelection('Genesis|1|2');
      controller.toggleVerseSelection('Genesis|1|3');

      expect(controller.state.selectedVerses.length, 3);
      expect(controller.state.selectedVerses.contains('Genesis|1|1'), true);
      expect(controller.state.selectedVerses.contains('Genesis|1|2'), true);
      expect(controller.state.selectedVerses.contains('Genesis|1|3'), true);
    });
  });

  group('BibleReaderController Persistent Marking Tests', () {
    test('should toggle persistent mark', () async {
      const verseKey = 'Genesis|1|1';

      await controller.togglePersistentMark(verseKey);

      expect(controller.state.persistentlyMarkedVerses.contains(verseKey), true);

      await controller.togglePersistentMark(verseKey);

      expect(controller.state.persistentlyMarkedVerses.contains(verseKey), false);
    });

    test('should persist marked verses', () async {
      const verseKey = 'Genesis|1|1';

      await controller.togglePersistentMark(verseKey);

      final markedVerses = await preferencesService.getMarkedVerses();

      expect(markedVerses.contains(verseKey), true);
    });

    test('should load persisted marked verses on initialization', () async {
      // Pre-save some marked verses
      const verseKey1 = 'John|3|16';
      const verseKey2 = 'Psalm|23|1';
      await preferencesService.saveMarkedVerses({verseKey1, verseKey2});

      // Create new controller
      final newController = BibleReaderController(
        allVersions: testVersions,
        readerService: readerService,
        preferencesService: preferencesService,
      );

      // Initialize to load preferences
      final loadedSize = await preferencesService.getFontSize();
      final loadedMarked = await preferencesService.getMarkedVerses();

      // Verify marked verses are loaded
      expect(loadedMarked.contains(verseKey1), true);
      expect(loadedMarked.contains(verseKey2), true);

      newController.dispose();
    });
  });

  group('BibleReaderController Search Tests', () {
    test('should clear search results on empty query', () async {
      await controller.performSearch('');

      expect(controller.state.isSearching, false);
      expect(controller.state.searchResults, isEmpty);
    });

    test('should set search state correctly', () async {
      // This test verifies the search state handling
      // Actual search would require database initialization
      expect(controller.state.isSearching, false);

      controller.clearSearch();

      expect(controller.state.isSearching, false);
      expect(controller.state.searchResults, isEmpty);
      expect(controller.state.searchQuery, '');
    });

    test('should clear search results', () {
      // Set up some search state
      controller = BibleReaderController(
        allVersions: testVersions,
        readerService: readerService,
        preferencesService: preferencesService,
        initialState: controller.state.copyWith(
          isSearching: true,
          searchQuery: 'test',
          searchResults: [
            {'book_number': 1, 'chapter': 1, 'verse': 1, 'text': 'test'}
          ],
        ),
      );

      controller.clearSearch();

      expect(controller.state.isSearching, false);
      expect(controller.state.searchResults, isEmpty);
      expect(controller.state.searchQuery, '');
    });
  });

  group('BibleReaderController Verse Navigation Tests', () {
    test('should select verse', () {
      controller.selectVerse(5);

      expect(controller.state.selectedVerse, 5);
    });

    test('should update selected verse on navigation', () {
      controller.selectVerse(1);
      expect(controller.state.selectedVerse, 1);

      controller.selectVerse(10);
      expect(controller.state.selectedVerse, 10);
    });
  });

  group('BibleReaderController State Management Tests', () {
    test('should maintain state immutability', () {
      final originalState = controller.state;

      controller.toggleFontControls();

      // Original state should not be modified
      expect(originalState.showFontControls, false);
      // New state should have the change
      expect(controller.state.showFontControls, true);
    });

    test('should create new state instances on updates', () {
      final state1 = controller.state;

      controller.toggleFontControls();

      final state2 = controller.state;

      expect(identical(state1, state2), false);
    });

    test('should properly copy state with copyWith', () {
      final state = controller.state;

      final newState = state.copyWith(
        fontSize: 20.0,
        showFontControls: true,
      );

      expect(newState.fontSize, 20.0);
      expect(newState.showFontControls, true);
      // Other properties should remain unchanged
      expect(newState.isLoading, state.isLoading);
      expect(newState.availableVersions, state.availableVersions);
    });
  });

  group('BibleReaderController Service Injection Tests', () {
    test('should use injected reader service', () {
      expect(controller.readerService, same(readerService));
    });

    test('should use injected preferences service', () {
      expect(controller.preferencesService, same(preferencesService));
    });

    test('should not create service instances internally', () {
      // Verify that controller accepts and uses injected services
      final customDbService = BibleDbService();
      final customPositionService = BibleReadingPositionService();
      final customReaderService = BibleReaderService(
        dbService: customDbService,
        positionService: customPositionService,
      );
      final customPrefsService = BiblePreferencesService();

      final customController = BibleReaderController(
        allVersions: testVersions,
        readerService: customReaderService,
        preferencesService: customPrefsService,
      );

      expect(customController.readerService, same(customReaderService));
      expect(customController.preferencesService, same(customPrefsService));

      customController.dispose();
    });
  });

  group('BibleReaderController Stream Tests', () {
    test('should emit state changes to stream subscribers', () async {
      final states = <BibleReaderState>[];
      final subscription = controller.stateStream.listen(states.add);

      await controller.increaseFontSize();
      await controller.decreaseFontSize();
      controller.toggleFontControls();

      await Future.delayed(const Duration(milliseconds: 50));

      expect(states.length, greaterThanOrEqualTo(3));

      await subscription.cancel();
    });

    test('should support multiple stream subscribers', () async {
      final states1 = <BibleReaderState>[];
      final states2 = <BibleReaderState>[];

      final sub1 = controller.stateStream.listen(states1.add);
      final sub2 = controller.stateStream.listen(states2.add);

      controller.toggleFontControls();

      await Future.delayed(const Duration(milliseconds: 50));

      expect(states1, isNotEmpty);
      expect(states2, isNotEmpty);
      expect(states1.length, states2.length);

      await sub1.cancel();
      await sub2.cancel();
    });

    test('should close stream on dispose', () async {
      final states = <BibleReaderState>[];
      final subscription = controller.stateStream.listen(states.add);

      controller.dispose();

      // After dispose, no new state changes should be emitted
      final initialCount = states.length;
      await Future.delayed(const Duration(milliseconds: 50));
      expect(states.length, initialCount);

      await subscription.cancel();
    });
  });

  group('BibleReaderController Integration Tests', () {
    test('should maintain consistent state through multiple operations', () async {
      // Perform multiple operations
      await controller.increaseFontSize();
      controller.toggleFontControls();
      controller.toggleVerseSelection('Genesis|1|1');

      // Verify all changes are reflected
      expect(controller.state.fontSize, 20.0);
      expect(controller.state.showFontControls, true);
      expect(controller.state.selectedVerses.contains('Genesis|1|1'), true);
    });

    test('should handle rapid state changes', () async {
      for (int i = 0; i < 10; i++) {
        controller.toggleFontControls();
      }

      // Font controls should be off (toggled even number of times)
      expect(controller.state.showFontControls, false);
    });

    test('should support Bloc/Riverpod integration pattern', () async {
      // Verify controller exposes necessary APIs for state management
      expect(controller.stateStream, isA<Stream<BibleReaderState>>());
      expect(controller.state, isA<BibleReaderState>());

      // Verify state is immutable
      final state = controller.state;
      controller.toggleFontControls();
      expect(identical(state, controller.state), false);
    });
  });
}
