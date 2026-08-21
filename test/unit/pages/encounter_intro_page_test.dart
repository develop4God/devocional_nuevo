@Tags(['unit', 'pages'])
library;

import 'package:devocional_nuevo/blocs/encounter/encounter_bloc.dart';
import 'package:devocional_nuevo/blocs/encounter/encounter_event.dart';
import 'package:devocional_nuevo/blocs/encounter/encounter_state.dart';
import 'package:devocional_nuevo/models/encounter_index_entry.dart';
import 'package:devocional_nuevo/pages/encounters/encounter_intro_page.dart';
import 'package:devocional_nuevo/services/service_locator.dart';
import 'package:devocional_nuevo/services/sound/i_sound_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/test_helpers.dart';

class MockEncounterBloc extends Mock implements EncounterBloc {}

class FakeSoundService implements ISoundService {
  bool _isPlaying = false;
  int toggleCallCount = 0;
  String? lastCueKey;
  String? lastEncounterId;

  @override
  bool get isPlaying => _isPlaying;

  @override
  Future<void> toggle(String cueKey, {required String encounterId}) async {
    toggleCallCount++;
    lastCueKey = cueKey;
    lastEncounterId = encounterId;
    _isPlaying = !_isPlaying;
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
  return MaterialApp(
    home: BlocProvider<EncounterBloc>.value(
      value: bloc,
      child: EncounterIntroPage(entry: entry, lang: 'en'),
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

    testWidgets('tap calls ISoundService.toggle with cue key and encounterId', (
      tester,
    ) async {
      final entry = _fakeEntry(introSound: 'storm_waves');
      await tester.pumpWidget(_wrap(entry, mockBloc));
      await tester.pump();

      await tester.tap(find.byKey(const Key('intro_sound_toggle')));
      await tester.pump();

      expect(fakeSoundService.toggleCallCount, 1);
      expect(fakeSoundService.lastCueKey, 'storm_waves');
      expect(fakeSoundService.lastEncounterId, 'peter_water_001');
    });

    testWidgets('icon reflects playing state after tap', (tester) async {
      final entry = _fakeEntry(introSound: 'storm_waves');
      await tester.pumpWidget(_wrap(entry, mockBloc));
      await tester.pump();

      expect(find.byIcon(Icons.volume_off), findsOneWidget);

      await tester.tap(find.byKey(const Key('intro_sound_toggle')));
      await tester.pump();

      expect(find.byIcon(Icons.volume_up), findsOneWidget);
    });

    testWidgets('second tap stops playback (icon reverts)', (tester) async {
      final entry = _fakeEntry(introSound: 'storm_waves');
      await tester.pumpWidget(_wrap(entry, mockBloc));
      await tester.pump();

      await tester.tap(find.byKey(const Key('intro_sound_toggle')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('intro_sound_toggle')));
      await tester.pump();

      expect(fakeSoundService.toggleCallCount, 2);
      expect(find.byIcon(Icons.volume_off), findsOneWidget);
    });

    testWidgets('disposing the page while playing stops the sound', (
      tester,
    ) async {
      final entry = _fakeEntry(introSound: 'storm_waves');
      await tester.pumpWidget(_wrap(entry, mockBloc));
      await tester.pump();

      await tester.tap(find.byKey(const Key('intro_sound_toggle')));
      await tester.pump();
      expect(fakeSoundService.isPlaying, isTrue);

      // Replace the widget tree entirely to trigger dispose().
      await tester.pumpWidget(const SizedBox());
      await tester.pump();

      expect(fakeSoundService.toggleCallCount, 2);
      expect(fakeSoundService.isPlaying, isFalse);
    });
  });
}
