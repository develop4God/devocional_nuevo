@Tags(['unit', 'pages'])
library;

import 'dart:async';

import 'package:devocional_nuevo/blocs/note_bloc.dart';
import 'package:devocional_nuevo/blocs/theme/theme_bloc.dart';
import 'package:devocional_nuevo/blocs/theme/theme_event.dart';
import 'package:devocional_nuevo/blocs/theme/theme_state.dart';
import 'package:devocional_nuevo/controllers/audio_controller.dart';
import 'package:devocional_nuevo/extensions/string_extensions.dart';
import 'package:devocional_nuevo/models/devocional_model.dart';
import 'package:devocional_nuevo/models/devotional_note.dart';
import 'package:devocional_nuevo/pages/devocionales_page.dart';
import 'package:devocional_nuevo/providers/devocional_provider.dart';
import 'package:devocional_nuevo/repositories/devocional_repository.dart';
import 'package:devocional_nuevo/repositories/i_notes_repository.dart';
import 'package:devocional_nuevo/services/tts/i_tts_service.dart';
import 'package:devocional_nuevo/services/tts_service.dart'; // for TtsState
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

import '../../helpers/test_helpers.dart' show registerTestServicesWithFakes;

class MockDevocionalRepository extends Mock implements DevocionalRepository {}

class FakeNotesRepository implements INotesRepository {
  @override
  Future<void> deleteNote(String devocionalId) async {}

  @override
  Future<List<DevotionalNote>> loadNotes() async => [];

  @override
  Future<void> saveNote(DevotionalNote note) async {}
}

/// Mirrors FakeTtsService in test/unit/providers/devocional_provider_test.dart
/// — AudioController requires a real ITtsService, and DevocionalesPage reads
/// a real `Provider<AudioController>` from context (provided at the app's
/// composition root in main.dart), so this can't be stubbed away.
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

/// Mirrors the FakeThemeBloc already duplicated across several widget test
/// files in this repo — DevocionalesPage.build() unconditionally does
/// `context.watch<ThemeBloc>()`, so any host needs a ready ThemeLoaded state.
class FakeThemeBloc extends Fake implements ThemeBloc {
  @override
  Stream<ThemeState> get stream => Stream.value(
        ThemeLoaded.withThemeData(
          themeFamily: 'Deep Purple',
          brightness: Brightness.light,
        ),
      );

  @override
  ThemeState get state => ThemeLoaded.withThemeData(
        themeFamily: 'Deep Purple',
        brightness: Brightness.light,
      );

  @override
  void add(ThemeEvent event) {}

  @override
  Future<void> close() async {}
}

Devocional _devocional(String id, {String version = 'RVR1960'}) => Devocional(
      id: id,
      versiculo: 'Verse $id',
      reflexion: 'Reflection $id',
      paraMeditar: const [],
      oracion: 'Prayer $id',
      date: DateTime(2025, 1, 1),
      version: version,
      language: 'es',
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockDevocionalRepository repository;

  setUp(() async {
    await registerTestServicesWithFakes();
    await initializeDateFormatting('en');
    repository = MockDevocionalRepository();
  });

  Widget host(DevocionalRepository repo) => MultiProvider(
        providers: [
          BlocProvider<ThemeBloc>(create: (_) => FakeThemeBloc()),
          ChangeNotifierProvider<DevocionalProvider>(
            create: (_) => DevocionalProvider(
              enableAudio: false,
              devocionalRepository: repo,
            ),
          ),
          ChangeNotifierProvider<AudioController>(
            create: (_) => AudioController(FakeTtsService()),
          ),
          BlocProvider<NoteBloc>(
            create: (_) => NoteBloc(notesRepository: FakeNotesRepository()),
          ),
        ],
        child: const MaterialApp(home: DevocionalesPage()),
      );

  group('DevocionalesPage — initialization outcomes', () {
    testWidgets('shows the error scaffold with retry when no devotionals load',
        (tester) async {
      when(() => repository.getAvailableYears())
          .thenAnswer((_) async => <int>[2025]);
      when(() => repository.fetchAll(any(), any(), any()))
          .thenAnswer((_) async => <Devocional>[]);
      when(() => repository.wasLastFetchOffline).thenReturn(false);

      await tester.pumpWidget(host(repository));
      // Let initState's async _initializeNavigationBloc chain settle:
      // initializeData (no fallback since selected==fallback language),
      // then the StateError path closes the (never-created) bloc and
      // sets _initState = error.
      await tester.pumpAndSettle(const Duration(seconds: 3));

      expect(
          find.byKey(const Key('devocionales_error_scaffold')), findsOneWidget);
      expect(find.byIcon(Icons.refresh), findsOneWidget);
      expect(find.byIcon(Icons.cloud_off_outlined), findsOneWidget);

      // Drain DevocionalesTracking's un-cancelable one-shot 2s self-test
      // Timer (started from initState) before the test ends, or FlutterTest
      // flags it as a leaked pending timer.
      await tester.pump(const Duration(seconds: 3));
    });

    testWidgets('retry button re-runs initialization after a failed load',
        (tester) async {
      var callCount = 0;
      when(() => repository.getAvailableYears()).thenAnswer((_) async {
        callCount++;
        return <int>[2025];
      });
      when(() => repository.fetchAll(any(), any(), any()))
          .thenAnswer((_) async => <Devocional>[]);
      when(() => repository.wasLastFetchOffline).thenReturn(false);

      await tester.pumpWidget(host(repository));
      await tester.pumpAndSettle(const Duration(seconds: 3));

      expect(
          find.byKey(const Key('devocionales_error_scaffold')), findsOneWidget);
      final callsBeforeRetry = callCount;

      await tester.tap(find.byIcon(Icons.refresh));
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Retry genuinely re-invoked the repository, not just re-rendered
      // the same cached error.
      expect(callCount, greaterThan(callsBeforeRetry));
      expect(
          find.byKey(const Key('devocionales_error_scaffold')), findsOneWidget);

      // Drain DevocionalesTracking's un-cancelable one-shot 2s self-test
      // Timer (started from initState) before the test ends, or FlutterTest
      // flags it as a leaked pending timer.
      await tester.pump(const Duration(seconds: 3));
    });

    testWidgets(
        'moves past the loading scaffold once devotionals load successfully',
        (tester) async {
      final loaded = [_devocional('d1'), _devocional('d2')];
      when(() => repository.getAvailableYears())
          .thenAnswer((_) async => <int>[2025]);
      when(() => repository.fetchAll(any(), any(), any()))
          .thenAnswer((_) async => loaded);
      when(() => repository.wasLastFetchOffline).thenReturn(false);
      when(() => repository.filterByVersion(any(), any())).thenAnswer(
          (invocation) =>
              invocation.positionalArguments[0] as List<Devocional>);
      when(() => repository.findFirstUnreadDevocionalIndex(any(), any()))
          .thenReturn(0);

      await tester.pumpWidget(host(repository));
      // Not pumpAndSettle: once tracking starts, DevocionalesTracking runs a
      // real 5s periodic Timer that reschedules itself forever, so the tree
      // never goes idle. Bounded pumps are the correct tool here.
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));

      // Real success: no error scaffold, no infinite loading spinner state —
      // the BLoC actually reached NavigationReady and rendered a Scaffold
      // with the app's real app bar title.
      expect(
          find.byKey(const Key('devocionales_error_scaffold')), findsNothing);
      expect(find.text('devotionals.loading'.tr()), findsNothing);

      // Unmount before the test ends so DevocionalesPage.dispose() cancels
      // the tracking criteria-check Timer.periodic it owns — otherwise it
      // keeps firing past this test's lifetime.
      await tester.pumpWidget(const SizedBox.shrink());
    });
  });
}
