@Tags(['unit', 'pages'])
library;

import 'package:devocional_nuevo/blocs/encounter/encounter_bloc.dart';
import 'package:devocional_nuevo/blocs/encounter/encounter_event.dart';
import 'package:devocional_nuevo/blocs/encounter/encounter_state.dart';
import 'package:devocional_nuevo/models/encounter_card_model.dart';
import 'package:devocional_nuevo/models/encounter_index_entry.dart';
import 'package:devocional_nuevo/models/encounter_study.dart';
import 'package:devocional_nuevo/pages/encounters/encounter_detail_page.dart';
import 'package:devocional_nuevo/providers/devocional_provider.dart';
import 'package:devocional_nuevo/services/service_locator.dart';
import 'package:devocional_nuevo/services/sound/i_sound_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

import '../../helpers/test_helpers.dart';

class MockEncounterBloc extends Mock implements EncounterBloc {}

class FakeSoundService implements ISoundService {
  bool _isPlaying = true;
  int stopCallCount = 0;

  @override
  bool get isPlaying => _isPlaying;

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

  testWidgets('backgrounding the app stops playing sound', (tester) async {
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

    expect(fakeSoundService.stopCallCount, 1);
    expect(fakeSoundService.isPlaying, isFalse);
  });

  testWidgets('completing the encounter stops the ambient sound', (
    tester,
  ) async {
    final entry = _fakeEntry();
    final study = EncounterStudy(
      id: entry.id,
      cards: const [EncounterCard(order: 0, type: 'completion')],
    );
    final state = EncounterLoaded(
      index: const [],
      loadedStudies: {entry.id: study},
    );
    when(() => mockBloc.state).thenReturn(state);
    when(() => mockBloc.stream).thenAnswer((_) => Stream.value(state));

    await tester.pumpWidget(
      ChangeNotifierProvider<DevocionalProvider>(
        create: (_) => DevocionalProvider(),
        child: MaterialApp(
          home: BlocProvider<EncounterBloc>.value(
            value: mockBloc,
            child: EncounterDetailPage(entry: entry, lang: 'en'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(fakeSoundService.isPlaying, isTrue);
    expect(fakeSoundService.stopCallCount, 0);

    final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
    button.onPressed!();
    await tester.pump(const Duration(milliseconds: 500));

    expect(fakeSoundService.stopCallCount, 1);
    expect(fakeSoundService.isPlaying, isFalse);

    // Flush the 5s celebration timer scheduled by _onCompleteEncounter,
    // then tear down the page so DevocionalProvider's internal
    // AudioController periodic sync timer (unrelated pre-existing infra,
    // self-cancels once its owner is unmounted) clears before the test
    // ends — otherwise the framework's pending-timer invariant check fails.
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 250));
  });
}
