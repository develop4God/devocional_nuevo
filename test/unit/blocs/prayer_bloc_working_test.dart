@Tags(['critical', 'unit', 'blocs'])
library;

// test/critical_coverage/prayer_bloc_working_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/services.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:devocional_nuevo/blocs/prayer_bloc.dart';
import 'package:devocional_nuevo/blocs/prayer_event.dart';
import 'package:devocional_nuevo/blocs/prayer_state.dart';
import 'package:devocional_nuevo/models/prayer_model.dart';
import 'package:devocional_nuevo/services/localization_service.dart';
import 'package:devocional_nuevo/services/service_locator.dart';

import '../../helpers/test_helpers.dart';

// Mock LocalizationService for testing
class MockLocalizationService extends Mock implements LocalizationService {}

void main() {
  group('PrayerBloc Critical Coverage Tests', () {
    late PrayerBloc prayerBloc;
    late MockLocalizationService mockLocalizationService;
    late ServiceLocator locator;

    setUpAll(() {
      TestWidgetsFlutterBinding.ensureInitialized();
    });

    setUp(() {
      // Reset SharedPreferences for each test
      SharedPreferences.setMockInitialValues({});

      // Mock path_provider for file operations
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/path_provider'),
        (MethodCall methodCall) async {
          switch (methodCall.method) {
            case 'getApplicationDocumentsDirectory':
              return '/mock_documents';
            case 'getTemporaryDirectory':
              return '/mock_temp';
            default:
              return null;
          }
        },
      );

      // Set up service locator and mock localization service
      locator = ServiceLocator();
      locator.reset();

      mockLocalizationService = MockLocalizationService();
      when(
        () => mockLocalizationService.translate(any()),
      ).thenReturn('Mocked error message');

      locator.registerSingleton<LocalizationService>(mockLocalizationService);

      prayerBloc = PrayerBloc(statsService: FakeSpiritualStatsService());
    });

    tearDown(() {
      prayerBloc.close();
      locator.reset();

      // Clean up method channel mocks
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/path_provider'),
        null,
      );
    });

    test('should have correct initial state', () {
      expect(prayerBloc.state, isA<PrayerInitial>());
    });

    blocTest<PrayerBloc, PrayerState>(
      'should emit loading then loaded when loading prayers from empty storage',
      build: () => prayerBloc,
      act: (bloc) => bloc.add(LoadPrayers()),
      expect: () => [isA<PrayerLoading>(), isA<PrayerLoaded>()],
      verify: (bloc) {
        final state = bloc.state as PrayerLoaded;
        expect(state.prayers, isEmpty);
      },
    );

    blocTest<PrayerBloc, PrayerState>(
      'empty-text error message is localized via LocalizationService, '
      'not hardcoded literal text',
      build: () => prayerBloc,
      act: (bloc) async {
        bloc.add(LoadPrayers());
        await Future<void>.delayed(Duration.zero);
        bloc.add(AddPrayer(''));
      },
      wait: const Duration(milliseconds: 10),
      verify: (bloc) {
        // The bloc must ask LocalizationService for the translated string
        // rather than emitting a hardcoded literal (e.g. Spanish text
        // baked into the source) that a non-Spanish user would see as-is.
        verify(
          () => mockLocalizationService
              .translate('prayer.enter_prayer_text_error'),
        ).called(1);
        final state = bloc.state as PrayerLoaded;
        expect(state.errorMessage, 'Mocked error message');
      },
    );

    // Skipped: Requires file system mocking - Cannot create file in mock directory
    // blocTest<PrayerBloc, PrayerState>(
    //   'should add prayer successfully',
    //   build: () => prayerBloc,
    //   act: (bloc) => bloc.add(AddPrayer('Test prayer for healing')),
    //   expect: () => [
    //     isA<PrayerLoading>(),
    //     isA<PrayerLoaded>(),
    //   ],
    //   verify: (bloc) {
    //     final state = bloc.state as PrayerLoaded;
    //     expect(state.prayers.length, equals(1));
    //     expect(state.prayers.first.text, equals('Test prayer for healing'));
    //     expect(state.prayers.first.status, equals(PrayerStatus.active));
    //   },
    // );

    test('should handle prayer filtering correctly in state', () {
      final activePrayer = Prayer(
        id: 'active-prayer',
        text: 'Active prayer',
        createdDate: DateTime.now(),
        status: PrayerStatus.active,
      );
      final answeredPrayer = Prayer(
        id: 'answered-prayer',
        text: 'Answered prayer',
        createdDate: DateTime.now(),
        status: PrayerStatus.answered,
        answeredDate: DateTime.now(),
      );

      final state = PrayerLoaded(prayers: [activePrayer, answeredPrayer]);

      expect(state.prayers.length, equals(2));
      expect(state.activePrayers.length, equals(1));
      expect(state.answeredPrayers.length, equals(1));
      expect(state.activePrayers.first.id, equals('active-prayer'));
      expect(state.answeredPrayers.first.id, equals('answered-prayer'));
    });

    test('should validate prayer model creation', () {
      final prayer = Prayer(
        id: 'test-prayer',
        text: 'Test prayer text',
        createdDate: DateTime.now(),
        status: PrayerStatus.active,
      );

      expect(prayer.id, equals('test-prayer'));
      expect(prayer.text, equals('Test prayer text'));
      expect(prayer.status, equals(PrayerStatus.active));
      expect(prayer.isActive, isTrue);
      expect(prayer.isAnswered, isFalse);
      expect(prayer.answeredDate, isNull);
    });

    test('should handle prayer status correctly', () {
      final activePrayer = Prayer(
        id: 'active',
        text: 'Active prayer',
        createdDate: DateTime.now(),
        status: PrayerStatus.active,
      );

      final answeredPrayer = Prayer(
        id: 'answered',
        text: 'Answered prayer',
        createdDate: DateTime.now(),
        status: PrayerStatus.answered,
        answeredDate: DateTime.now(),
      );

      expect(activePrayer.isActive, isTrue);
      expect(activePrayer.isAnswered, isFalse);
      expect(answeredPrayer.isActive, isFalse);
      expect(answeredPrayer.isAnswered, isTrue);
    });

    test('should handle prayer copyWith functionality', () {
      final originalPrayer = Prayer(
        id: 'original',
        text: 'Original text',
        createdDate: DateTime.now(),
        status: PrayerStatus.active,
      );

      final updatedPrayer = originalPrayer.copyWith(
        text: 'Updated text',
        status: PrayerStatus.answered,
        answeredDate: DateTime.now(),
      );

      expect(updatedPrayer.id, equals('original'));
      expect(updatedPrayer.text, equals('Updated text'));
      expect(updatedPrayer.status, equals(PrayerStatus.answered));
      expect(updatedPrayer.answeredDate, isNotNull);
    });

    test('should handle prayer serialization', () {
      final prayer = Prayer(
        id: 'serialization-test',
        text: 'Prayer for serialization test',
        createdDate: DateTime(2024, 1, 15, 10, 30),
        status: PrayerStatus.active,
      );

      final json = prayer.toJson();
      expect(json, isA<Map<String, dynamic>>());
      expect(json['id'], equals('serialization-test'));
      expect(json['text'], equals('Prayer for serialization test'));
      expect(json['status'], equals('active'));

      final fromJson = Prayer.fromJson(json);
      expect(fromJson.id, equals(prayer.id));
      expect(fromJson.text, equals(prayer.text));
      expect(fromJson.status, equals(prayer.status));
    });

    test('should handle empty prayer list state correctly', () {
      final emptyState = PrayerLoaded(prayers: []);

      expect(emptyState.prayers, isEmpty);
      expect(emptyState.activePrayers, isEmpty);
      expect(emptyState.answeredPrayers, isEmpty);
      expect(emptyState.totalPrayers, equals(0));
      expect(emptyState.activePrayersCount, equals(0));
    });

    test('should handle prayer state counting correctly', () {
      final prayers = [
        Prayer(
          id: '1',
          text: 'Prayer 1',
          createdDate: DateTime.now(),
          status: PrayerStatus.active,
        ),
        Prayer(
          id: '2',
          text: 'Prayer 2',
          createdDate: DateTime.now(),
          status: PrayerStatus.active,
        ),
        Prayer(
          id: '3',
          text: 'Prayer 3',
          createdDate: DateTime.now(),
          status: PrayerStatus.answered,
          answeredDate: DateTime.now(),
        ),
      ];

      final state = PrayerLoaded(prayers: prayers);

      expect(state.totalPrayers, equals(3));
      expect(state.activePrayersCount, equals(2));
      expect(state.answeredPrayersCount, equals(1));
    });
  });
}
