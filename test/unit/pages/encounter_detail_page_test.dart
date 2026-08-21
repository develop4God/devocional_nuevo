@Tags(['unit', 'pages'])
library;

import 'package:devocional_nuevo/blocs/encounter/encounter_bloc.dart';
import 'package:devocional_nuevo/blocs/encounter/encounter_event.dart';
import 'package:devocional_nuevo/blocs/encounter/encounter_state.dart';
import 'package:devocional_nuevo/models/encounter_index_entry.dart';
import 'package:devocional_nuevo/pages/encounters/encounter_detail_page.dart';
import 'package:devocional_nuevo/services/service_locator.dart';
import 'package:devocional_nuevo/services/sound/i_sound_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/test_helpers.dart';

class MockEncounterBloc extends Mock implements EncounterBloc {}

class FakeSoundService implements ISoundService {
  bool _isPlaying = true;
  bool _isPaused = false;
  int stopCallCount = 0;
  int pauseCallCount = 0;
  int resumeCallCount = 0;

  @override
  bool get isPlaying => _isPlaying;

  @override
  bool get isPaused => _isPaused;

  @override
  Future<void> toggle(
    String cueKey, {
    required String encounterId,
    String? version,
  }) async {
    _isPlaying = !_isPlaying;
  }

  @override
  Future<void> stop() async {
    stopCallCount++;
    _isPlaying = false;
    _isPaused = false;
  }

  @override
  Future<void> pause() async {
    if (!_isPlaying || _isPaused) return;
    pauseCallCount++;
    _isPaused = true;
  }

  @override
  Future<void> resume() async {
    if (!_isPaused) return;
    resumeCallCount++;
    _isPaused = false;
  }

  @override
  Future<void> dispose() async {}
}

EncounterIndexEntry _fakeEntry() => EncounterIndexEntry(
      id: 'peter_water_001',
      version: '1.0',
      status: 'published',
      files: {'en': 'peter_water_001_en.json'},
      titles: {'en': 'The Night Peter Walked on Water'},
      subtitles: {'en': 'Faith Beyond the Storm'},
      scriptureReference: {'en': 'Matthew 14:22-33'},
      estimatedReadingMinutes: {'en': 5},
    );

void main() {
  late MockEncounterBloc mockBloc;
  late FakeSoundService fakeSoundService;

  setUpAll(() {
    registerFallbackValue(LoadEncounterIndex());
  });

  setUp(() async {
    await registerTestServices();
    fakeSoundService = FakeSoundService();
    final locator = ServiceLocator();
    if (locator.isRegistered<ISoundService>()) {
      locator.unregister<ISoundService>();
    }
    locator.registerSingleton<ISoundService>(fakeSoundService);

    mockBloc = MockEncounterBloc();
    // EncounterLoaded with no study for this id renders the
    // study_not_found error branch, which needs no DevocionalProvider or
    // card widgets — keeps this test isolated to dispose-time behavior.
    final state = EncounterLoaded(index: const []);
    when(() => mockBloc.state).thenReturn(state);
    when(() => mockBloc.stream).thenAnswer((_) => Stream.value(state));
    when(() => mockBloc.add(any())).thenReturn(null);
  });

  testWidgets('stops the ambient sound when the page is disposed', (
    tester,
  ) async {
    final entry = _fakeEntry();
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<EncounterBloc>.value(
          value: mockBloc,
          child: EncounterDetailPage(entry: entry, lang: 'en'),
        ),
      ),
    );
    await tester.pump();

    expect(fakeSoundService.isPlaying, isTrue);
    expect(fakeSoundService.stopCallCount, 0);

    // Replace the widget tree entirely to trigger dispose() — mirrors
    // popping back out of the encounter (back button, exit, or completion).
    await tester.pumpWidget(const SizedBox());
    await tester.pump();

    expect(fakeSoundService.stopCallCount, 1);
    expect(fakeSoundService.isPlaying, isFalse);
  });

  testWidgets('backgrounding the app pauses playing sound', (tester) async {
    final entry = _fakeEntry();
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<EncounterBloc>.value(
          value: mockBloc,
          child: EncounterDetailPage(entry: entry, lang: 'en'),
        ),
      ),
    );
    await tester.pump();
    expect(fakeSoundService.isPlaying, isTrue);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();

    expect(fakeSoundService.pauseCallCount, 1);
    expect(fakeSoundService.isPaused, isTrue);
  });

  testWidgets(
      'foregrounding the app auto-resumes paused sound (no manual control on this page)',
      (tester) async {
    final entry = _fakeEntry();
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<EncounterBloc>.value(
          value: mockBloc,
          child: EncounterDetailPage(entry: entry, lang: 'en'),
        ),
      ),
    );
    await tester.pump();

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    expect(fakeSoundService.isPaused, isTrue);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();

    expect(fakeSoundService.resumeCallCount, 1);
    expect(fakeSoundService.isPaused, isFalse);
    expect(fakeSoundService.isPlaying, isTrue);
  });
}
