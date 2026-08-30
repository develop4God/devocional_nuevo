@Tags(['unit', 'pages'])
library;

import 'dart:async';

import 'package:devocional_nuevo/blocs/encounter/encounter_bloc.dart';
import 'package:devocional_nuevo/blocs/encounter/encounter_state.dart';
import 'package:devocional_nuevo/extensions/string_extensions.dart';
import 'package:devocional_nuevo/models/encounter_card_model.dart';
import 'package:devocional_nuevo/models/encounter_index_entry.dart';
import 'package:devocional_nuevo/models/encounter_study.dart';
import 'package:devocional_nuevo/pages/encounters/encounter_intro_page.dart';
import 'package:devocional_nuevo/providers/devocional_provider.dart';
import 'package:devocional_nuevo/repositories/devocional_repository.dart';
import 'package:devocional_nuevo/repositories/encounter_repository.dart';
import 'package:devocional_nuevo/services/i_analytics_service.dart';
import 'package:devocional_nuevo/services/i_encounter_progress_service.dart';
import 'package:devocional_nuevo/services/service_locator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

import '../../helpers/test_helpers.dart'
    show FakeAnalyticsService, registerTestServicesWithFakes;

class MockEncounterRepository extends Mock implements EncounterRepository {}

class MockEncounterProgressService extends Mock
    implements IEncounterProgressService {}

class MockCacheManager extends Mock implements BaseCacheManager {}

class MockDevocionalRepository extends Mock implements DevocionalRepository {}

/// Fake analytics that records encounter-start events so tests can assert the
/// real user-visible side effect ("user begins an encounter → analytics logs
/// it and the detail page is pushed") without Firebase.
class RecordingAnalyticsService extends FakeAnalyticsService {
  final List<String> startedEncounters = [];

  @override
  Future<void> logEncounterStarted({required String encounterId}) async {
    startedEncounters.add(encounterId);
  }
}

EncounterIndexEntry _entry() => EncounterIndexEntry(
      id: 'peter_water_001',
      version: '1.0',
      status: 'published',
      accentColor: '#1e3a5f',
      testament: 'new',
      files: const {'en': 'peter_water_001_en.json'},
      titles: const {
        'en': 'Peter Walks on Water',
        'es': 'Pedro Camina sobre el Agua',
      },
      subtitles: const {'en': 'Faith Beyond the Storm'},
      scriptureReference: const {'en': 'Matthew 14:22-33'},
      estimatedReadingMinutes: const {'en': 10},
    );

EncounterStudy _study(String id) => EncounterStudy(
      id: id,
      cards: const [
        EncounterCard(order: 0, type: 'cinematic_scene'),
        EncounterCard(order: 1, type: 'scripture_moment'),
      ],
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockEncounterRepository repository;
  late MockEncounterProgressService progressService;
  late MockCacheManager cacheManager;
  late RecordingAnalyticsService analytics;
  late MockDevocionalRepository devocionalRepository;

  setUp(() async {
    await registerTestServicesWithFakes();

    // Swap in a recording analytics fake so we can observe real behavior.
    final locator = ServiceLocator();
    if (locator.isRegistered<IAnalyticsService>()) {
      locator.unregister<IAnalyticsService>();
    }
    locator.registerSingleton<IAnalyticsService>(RecordingAnalyticsService());
    analytics = getService<IAnalyticsService>() as RecordingAnalyticsService;

    repository = MockEncounterRepository();
    progressService = MockEncounterProgressService();
    cacheManager = MockCacheManager();
    devocionalRepository = MockDevocionalRepository();

    when(() => progressService.loadCompletedIds())
        .thenAnswer((_) async => <String>{});
  });

  tearDown(() {
    ServiceLocator().reset();
  });

  EncounterBloc bloc() => EncounterBloc(
        repository: repository,
        progressService: progressService,
        cacheManager: cacheManager,
        analyticsService: analytics,
      );

  // Real DevocionalProvider — constructor-injected with the mocked
  // repository (not swapped in after the fact) so BEGIN → EncounterDetailPage
  // actually exercises the same DI wiring the app uses, not a widget-tree
  // stub that only satisfies context.read without going through the class.
  Widget host(EncounterBloc b) => MultiProvider(
        providers: [
          BlocProvider<EncounterBloc>.value(value: b),
          ChangeNotifierProvider<DevocionalProvider>(
            create: (_) => DevocionalProvider(
              enableAudio: false,
              devocionalRepository: devocionalRepository,
            ),
          ),
        ],
        child:
            MaterialApp(home: EncounterIntroPage(entry: _entry(), lang: 'en')),
      );

  group('EncounterIntroPage — user-facing behavior', () {
    testWidgets('renders title, subtitle and scripture from the index entry',
        (tester) async {
      when(() => repository.fetchStudy(any(), any(),
              filename: any(named: 'filename'), entry: any(named: 'entry')))
          .thenAnswer((_) async => _study('peter_water_001'));

      final b = bloc();
      addTearDown(b.close);

      await tester.pumpWidget(host(b));
      await tester.pump(const Duration(milliseconds: 1600));

      expect(find.text('Peter Walks on Water'), findsOneWidget);
      expect(find.text('Faith Beyond the Storm'), findsOneWidget);
      expect(find.text('MATTHEW 14:22-33'), findsOneWidget);
    });

    testWidgets('requests the study for this entry on open', (tester) async {
      when(() => repository.fetchStudy(any(), any(),
              filename: any(named: 'filename'), entry: any(named: 'entry')))
          .thenAnswer((_) async => _study('peter_water_001'));

      final b = bloc();
      addTearDown(b.close);

      await tester.pumpWidget(host(b));
      await tester.pump();

      verify(() => repository.fetchStudy('peter_water_001', 'en',
          filename: any(named: 'filename'),
          entry: any(named: 'entry'))).called(1);
    });

    testWidgets(
        'shows spinner until study arrives; BEGIN inert while loading, '
        'then starts encounter and logs analytics', (tester) async {
      final completer = Completer<EncounterStudy>();
      when(() => repository.fetchStudy(any(), any(),
          filename: any(named: 'filename'),
          entry: any(named: 'entry'))).thenAnswer((_) => completer.future);

      final b = bloc();
      addTearDown(b.close);

      await tester.pumpWidget(host(b));
      await tester.pump(const Duration(milliseconds: 1600));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      final beginLabel =
          'encounters.enter_experience'.tr(); // via real LocalizationService
      await tester.tap(find.text(beginLabel), warnIfMissed: false);
      expect(analytics.startedEncounters, isEmpty,
          reason: 'BEGIN must be inert while the study is still loading');

      completer.complete(_study('peter_water_001'));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(CircularProgressIndicator), findsNothing);

      await tester.tap(find.text(beginLabel));
      await tester.pump(const Duration(milliseconds: 50));
      expect(analytics.startedEncounters, ['peter_water_001']);
    });

    testWidgets('does not re-request a study that is already loaded',
        (tester) async {
      final b = bloc()
        ..emit(EncounterLoaded(
          index: [_entry()],
          loadedStudies: {'peter_water_001': _study('peter_water_001')},
        ));
      addTearDown(b.close);

      await tester.pumpWidget(host(b));
      await tester.pump(const Duration(milliseconds: 100));

      verifyNever(() => repository.fetchStudy(any(), any(),
          filename: any(named: 'filename'), entry: any(named: 'entry')));
    });
  });
}
