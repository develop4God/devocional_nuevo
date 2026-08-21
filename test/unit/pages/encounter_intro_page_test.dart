@Tags(['unit', 'pages'])
library;

import 'dart:async';

import 'package:devocional_nuevo/blocs/encounter/encounter_bloc.dart';
import 'package:devocional_nuevo/blocs/encounter/encounter_event.dart';
import 'package:devocional_nuevo/blocs/encounter/encounter_state.dart';
import 'package:devocional_nuevo/extensions/string_extensions.dart';
import 'package:devocional_nuevo/models/encounter_card_model.dart';
import 'package:devocional_nuevo/models/encounter_index_entry.dart';
import 'package:devocional_nuevo/models/encounter_study.dart';
import 'package:devocional_nuevo/pages/encounters/encounter_intro_page.dart';
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
  bool _isPlaying = false;
  int toggleCallCount = 0;
  int stopCallCount = 0;
  String? lastCueKey;
  String? lastEncounterId;
  String? lastVersion;

  /// When set, toggle() doesn't resolve until this completer resolves —
  /// simulates a real device's cache/player setup taking a beat, so tests
  /// can fire a second invocation while the first is still in flight.
  Completer<void>? toggleGate;

  @override
  bool get isPlaying => _isPlaying;

  @override
  Future<void> toggle(
    String cueKey, {
    required String encounterId,
    String? version,
  }) async {
    if (toggleGate != null) {
      await toggleGate!.future;
    }
    toggleCallCount++;
    lastCueKey = cueKey;
    lastEncounterId = encounterId;
    lastVersion = version;
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

EncounterIndexEntry _fakeEntry({String? introSound}) => EncounterIndexEntry(
      id: 'peter_water_001',
      version: '1.0',
      status: 'published',
      introSound: introSound,
      files: {'en': 'peter_water_001_en.json'},
      titles: {'en': 'The Night Peter Walked on Water'},
      subtitles: {'en': 'Faith Beyond the Storm'},
      scriptureReference: {'en': 'Matthew 14:22-33'},
      estimatedReadingMinutes: {'en': 5},
    );

Widget _wrap(EncounterIndexEntry entry, EncounterBloc bloc) {
  return ChangeNotifierProvider<DevocionalProvider>(
    create: (_) => DevocionalProvider(),
    child: BlocProvider<EncounterBloc>.value(
      value: bloc,
      child: MaterialApp(
        home: EncounterIntroPage(entry: entry, lang: 'en'),
      ),
    ),
  );
}

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
    when(() => mockBloc.state).thenReturn(EncounterInitial());
    when(() => mockBloc.stream).thenAnswer((_) => const Stream.empty());
    when(() => mockBloc.add(any())).thenReturn(null);
  });

  group('EncounterIntroPage sound toggle', () {
    testWidgets('button is absent when entry.introSound is null', (
      tester,
    ) async {
      final entry = _fakeEntry(introSound: null);
      await tester.pumpWidget(_wrap(entry, mockBloc));
      await tester.pump();

      expect(find.byKey(const Key('intro_sound_toggle')), findsNothing);
    });

    testWidgets('button is present when entry.introSound is set', (
      tester,
    ) async {
      final entry = _fakeEntry(introSound: 'storm_waves');
      await tester.pumpWidget(_wrap(entry, mockBloc));
      await tester.pump();

      expect(find.byKey(const Key('intro_sound_toggle')), findsOneWidget);
    });

    testWidgets(
        'auto-plays on open (Constants.autoPlayIntroSound) with cue key and encounterId',
        (
      tester,
    ) async {
      final entry = _fakeEntry(introSound: 'storm_waves');
      await tester.pumpWidget(_wrap(entry, mockBloc));
      await tester.pump();

      expect(fakeSoundService.toggleCallCount, 1);
      expect(fakeSoundService.lastCueKey, 'storm_waves');
      expect(fakeSoundService.lastEncounterId, 'peter_water_001');
      expect(fakeSoundService.lastVersion, '1.0');
      expect(fakeSoundService.isPlaying, isTrue);
    });

    testWidgets('tap after auto-play stops playback (icon reverts)', (
      tester,
    ) async {
      final entry = _fakeEntry(introSound: 'storm_waves');
      await tester.pumpWidget(_wrap(entry, mockBloc));
      await tester.pump();
      expect(fakeSoundService.isPlaying, isTrue);

      await tester.tap(find.byKey(const Key('intro_sound_toggle')));
      await tester.pump();

      expect(fakeSoundService.toggleCallCount, 2);
      expect(fakeSoundService.isPlaying, isFalse);
    });

    testWidgets(
        'closing the page (e.g. X button) while playing stops the sound', (
      tester,
    ) async {
      final entry = _fakeEntry(introSound: 'storm_waves');
      await tester.pumpWidget(_wrap(entry, mockBloc));
      await tester.pump();
      expect(fakeSoundService.isPlaying, isTrue);

      // Replace the widget tree entirely to trigger dispose() without
      // going through _beginEncounter (mirrors tapping the close button).
      await tester.pumpWidget(const SizedBox());
      await tester.pump();

      expect(fakeSoundService.stopCallCount, 1);
      expect(fakeSoundService.isPlaying, isFalse);
    });

    testWidgets('no introSound set never auto-plays or stops on dispose', (
      tester,
    ) async {
      final entry = _fakeEntry(introSound: null);
      await tester.pumpWidget(_wrap(entry, mockBloc));
      await tester.pump();

      expect(fakeSoundService.toggleCallCount, 0);

      await tester.pumpWidget(const SizedBox());
      await tester.pump();

      // stop() is still safe/idempotent to call, but nothing was ever playing.
      expect(fakeSoundService.isPlaying, isFalse);
    });

    testWidgets('backgrounding the app stops playing sound', (tester) async {
      final entry = _fakeEntry(introSound: 'storm_waves');
      await tester.pumpWidget(_wrap(entry, mockBloc));
      await tester.pump();
      expect(fakeSoundService.isPlaying, isTrue);

      tester.binding.handleAppLifecycleStateChanged(
        AppLifecycleState.paused,
      );
      await tester.pump();

      expect(fakeSoundService.stopCallCount, 1);
      expect(fakeSoundService.isPlaying, isFalse);
      expect(find.byIcon(Icons.volume_off), findsOneWidget);
    });

    testWidgets(
        'a tap landing while auto-play is still in flight is dropped, not '
        'raced — reproduces a real-device bug where the first tap after '
        'auto-play read a stale isPlaying and the toggle only "worked" on '
        'the second tap', (tester) async {
      fakeSoundService.toggleGate = Completer<void>();
      final entry = _fakeEntry(introSound: 'storm_waves');
      await tester.pumpWidget(_wrap(entry, mockBloc));
      // Auto-play's postFrameCallback has fired and is now blocked inside
      // toggle(), awaiting the gate — isPlaying is still false at this point.
      await tester.pump();

      // A tap lands here, before auto-play's toggle() has resolved.
      await tester.tap(find.byKey(const Key('intro_sound_toggle')));
      await tester.pump();

      // Let auto-play's toggle() resolve.
      fakeSoundService.toggleGate!.complete();
      await tester.pump();
      await tester.pump();

      // Only one toggle() call ever reached the service — the tap that
      // landed mid-flight was dropped, not raced against auto-play's call.
      expect(fakeSoundService.toggleCallCount, 1);
      expect(fakeSoundService.isPlaying, isTrue);
    });

    testWidgets('backgrounding while sound was never playing is a no-op', (
      tester,
    ) async {
      final entry = _fakeEntry(introSound: null);
      await tester.pumpWidget(_wrap(entry, mockBloc));
      await tester.pump();

      tester.binding.handleAppLifecycleStateChanged(
        AppLifecycleState.paused,
      );
      await tester.pump();

      expect(fakeSoundService.stopCallCount, 0);
    });

    testWidgets('tapping Begin does not stop the sound before navigating away',
        (
      tester,
    ) async {
      final entry = _fakeEntry(introSound: 'storm_waves');
      final study = EncounterStudy(
        id: entry.id,
        cards: const [
          EncounterCard(order: 0, type: 'cinematic_scene', title: 'Card 1'),
        ],
      );
      final loadedState = EncounterLoaded(
        index: [entry],
        loadedStudies: {entry.id: study},
      );
      when(() => mockBloc.state).thenReturn(loadedState);
      when(() => mockBloc.stream).thenAnswer(
        (_) => Stream.value(loadedState),
      );

      await tester.pumpWidget(_wrap(entry, mockBloc));
      await tester.pump();
      expect(fakeSoundService.isPlaying, isTrue);

      await tester.tap(find.text('encounters.enter_experience'.tr()));
      await tester.pump();
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      // EncounterIntroPage.dispose() must not have stopped the sound —
      // EncounterDetailPage owns stopping it, not this transition.
      expect(fakeSoundService.stopCallCount, 0);
      expect(fakeSoundService.isPlaying, isTrue);

      // Tear down the pushed page so DevocionalProvider's internal
      // AudioController periodic sync timer (unrelated pre-existing infra,
      // self-cancels once its owner is unmounted) clears before the test
      // ends — otherwise the framework's pending-timer invariant check fails.
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 250));
    });
  });
}
