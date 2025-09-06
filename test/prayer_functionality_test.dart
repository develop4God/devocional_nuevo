// test/prayer_functionality_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:devocional_nuevo/models/prayer_model.dart';
import 'package:devocional_nuevo/blocs/prayer_bloc.dart';
import 'package:devocional_nuevo/blocs/prayer_event.dart';
import 'package:devocional_nuevo/blocs/prayer_state.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bloc_test/bloc_test.dart';
import 'dart:convert';
import 'test_setup.dart';

void main() {
  setUpAll(() {
    TestSetup.setupCommonMocks();
  });

  tearDownAll(() {
    TestSetup.cleanupMocks();
  });

  group('Prayer Model Tests', () {
    test('should create prayer with all required fields', () {
      final prayer = Prayer(
        id: '1',
        text: 'Señor, ayúdame en este día',
        createdDate: DateTime(2024, 1, 1),
        status: PrayerStatus.active,
      );

      expect(prayer.id, equals('1'));
      expect(prayer.text, equals('Señor, ayúdame en este día'));
      expect(prayer.isActive, isTrue);
      expect(prayer.isAnswered, isFalse);
    });

    test('should calculate days old correctly', () {
      final prayer = Prayer(
        id: '1',
        text: 'Test prayer',
        createdDate: DateTime.now().subtract(const Duration(days: 5)),
        status: PrayerStatus.active,
      );

      expect(prayer.daysOld, equals(5));
    });

    test('should serialize and deserialize correctly', () {
      final originalPrayer = Prayer(
        id: '1',
        text: 'Test prayer for JSON',
        createdDate: DateTime(2024, 1, 1),
        status: PrayerStatus.active,
      );

      final json = originalPrayer.toJson();
      final deserializedPrayer = Prayer.fromJson(json);

      expect(deserializedPrayer.id, equals(originalPrayer.id));
      expect(deserializedPrayer.text, equals(originalPrayer.text));
      expect(deserializedPrayer.status, equals(originalPrayer.status));
      expect(
          deserializedPrayer.createdDate, equals(originalPrayer.createdDate));
    });

    test('should copy with different values', () {
      final originalPrayer = Prayer(
        id: '1',
        text: 'Original text',
        createdDate: DateTime(2024, 1, 1),
        status: PrayerStatus.active,
      );

      final copiedPrayer = originalPrayer.copyWith(
        status: PrayerStatus.answered,
        answeredDate: DateTime(2024, 1, 2),
      );

      expect(copiedPrayer.id, equals(originalPrayer.id));
      expect(copiedPrayer.text, equals(originalPrayer.text));
      expect(copiedPrayer.status, equals(PrayerStatus.answered));
      expect(copiedPrayer.answeredDate, isNotNull);
    });
  });

  group('PrayerStatus Tests', () {
    test('should convert from string correctly', () {
      expect(PrayerStatus.fromString('active'), equals(PrayerStatus.active));
      expect(
          PrayerStatus.fromString('answered'), equals(PrayerStatus.answered));
      expect(PrayerStatus.fromString('invalid'),
          equals(PrayerStatus.active)); // Default fallback
    });

    test('should convert to string correctly', () {
      expect(PrayerStatus.active.toString(), equals('active'));
      expect(PrayerStatus.answered.toString(), equals('answered'));
    });

    test('should have correct display names', () {
      // Since displayName uses translation keys, test the actual implementation
      expect(PrayerStatus.active.displayName, equals('prayer.active'));
      expect(PrayerStatus.answered.displayName, equals('prayer.answered'));
    });
  });

  group('PrayerBloc Tests', () {
    blocTest<PrayerBloc, PrayerState>(
      'should start with PrayerInitial',
      build: () => PrayerBloc(),
      expect: () => [],
    );

    blocTest<PrayerBloc, PrayerState>(
      'should load empty prayers when LoadPrayers event is triggered',
      build: () => PrayerBloc(),
      setUp: () {
        SharedPreferences.setMockInitialValues({});
      },
      act: (bloc) => bloc.add(LoadPrayers()),
      expect: () => [
        PrayerLoading(),
        isA<PrayerLoaded>().having((state) => state.prayers, 'prayers', isEmpty),
      ],
    );

    blocTest<PrayerBloc, PrayerState>(
      'should add prayer correctly',
      build: () => PrayerBloc(),
      setUp: () {
        SharedPreferences.setMockInitialValues({});
      },
      act: (bloc) => bloc
        ..add(LoadPrayers())
        ..add(AddPrayer('Test prayer')),
      expect: () => [
        PrayerLoading(),
        isA<PrayerLoaded>().having((state) => state.prayers, 'prayers', isEmpty),
        isA<PrayerLoaded>()
            .having((state) => state.prayers.length, 'prayers length', 1)
            .having((state) => state.prayers.first.text, 'prayer text', 'Test prayer')
            .having((state) => state.prayers.first.isActive, 'is active', true),
      ],
    );

    blocTest<PrayerBloc, PrayerState>(
      'should not add empty prayer',
      build: () => PrayerBloc(),
      setUp: () {
        SharedPreferences.setMockInitialValues({});
      },
      act: (bloc) => bloc
        ..add(LoadPrayers())
        ..add(AddPrayer('   ')), // Only whitespace
      expect: () => [
        PrayerLoading(),
        isA<PrayerLoaded>().having((state) => state.prayers, 'prayers', isEmpty),
        isA<PrayerLoaded>()
            .having((state) => state.prayers, 'prayers', isEmpty)
            .having((state) => state.errorMessage, 'error message', isNotNull),
      ],
    );

    blocTest<PrayerBloc, PrayerState>(
      'should mark prayer as answered',
      build: () => PrayerBloc(),
      setUp: () {
        final prayer = Prayer(
          id: '1',
          text: 'Test prayer',
          createdDate: DateTime.now(),
          status: PrayerStatus.active,
        );
        SharedPreferences.setMockInitialValues({
          "prayers": json.encode([prayer.toJson()])
        });
      },
      act: (bloc) => bloc
        ..add(LoadPrayers())
        ..add(MarkPrayerAsAnswered('1')),
      expect: () => [
        PrayerLoading(),
        isA<PrayerLoaded>()
            .having((state) => state.activePrayers.length, 'active prayers length', 1),
        isA<PrayerLoaded>()
            .having((state) => state.activePrayers, 'active prayers', isEmpty)
            .having((state) => state.answeredPrayers.length, 'answered prayers length', 1)
            .having((state) => state.prayers.first.isAnswered, 'is answered', true)
            .having((state) => state.prayers.first.answeredDate, 'answered date', isNotNull),
      ],
    );

    blocTest<PrayerBloc, PrayerState>(
      'should mark prayer as active again',
      build: () => PrayerBloc(),
      setUp: () {
        final prayer = Prayer(
          id: '1',
          text: 'Test prayer',
          createdDate: DateTime.now(),
          status: PrayerStatus.answered,
          answeredDate: DateTime.now(),
        );
        SharedPreferences.setMockInitialValues({
          "prayers": json.encode([prayer.toJson()])
        });
      },
      act: (bloc) => bloc
        ..add(LoadPrayers())
        ..add(MarkPrayerAsActive('1')),
      expect: () => [
        PrayerLoading(),
        isA<PrayerLoaded>()
            .having((state) => state.answeredPrayers.length, 'answered prayers length', 1),
        isA<PrayerLoaded>()
            .having((state) => state.activePrayers.length, 'active prayers length', 1)
            .having((state) => state.answeredPrayers, 'answered prayers', isEmpty)
            .having((state) => state.prayers.first.isActive, 'is active', true)
            .having((state) => state.prayers.first.answeredDate, 'answered date', isNull),
      ],
    );

    blocTest<PrayerBloc, PrayerState>(
      'should edit prayer text',
      build: () => PrayerBloc(),
      setUp: () {
        final prayer = Prayer(
          id: '1',
          text: 'Original text',
          createdDate: DateTime.now(),
          status: PrayerStatus.active,
        );
        SharedPreferences.setMockInitialValues({
          "prayers": json.encode([prayer.toJson()])
        });
      },
      act: (bloc) => bloc
        ..add(LoadPrayers())
        ..add(EditPrayer('1', 'Edited text')),
      expect: () => [
        PrayerLoading(),
        isA<PrayerLoaded>()
            .having((state) => state.prayers.first.text, 'prayer text', 'Original text'),
        isA<PrayerLoaded>()
            .having((state) => state.prayers.first.text, 'prayer text', 'Edited text'),
      ],
    );

    blocTest<PrayerBloc, PrayerState>(
      'should delete prayer',
      build: () => PrayerBloc(),
      setUp: () {
        final prayer = Prayer(
          id: '1',
          text: 'Prayer to delete',
          createdDate: DateTime.now(),
          status: PrayerStatus.active,
        );
        SharedPreferences.setMockInitialValues({
          "prayers": json.encode([prayer.toJson()])
        });
      },
      act: (bloc) => bloc
        ..add(LoadPrayers())
        ..add(DeletePrayer('1')),
      expect: () => [
        PrayerLoading(),
        isA<PrayerLoaded>()
            .having((state) => state.prayers.length, 'prayers length', 1),
        isA<PrayerLoaded>()
            .having((state) => state.prayers, 'prayers', isEmpty),
      ],
    );

    blocTest<PrayerBloc, PrayerState>(
      'should get correct stats',
      build: () => PrayerBloc(),
      setUp: () {
        final activePrayer = Prayer(
          id: '1',
          text: 'Active prayer 1',
          createdDate: DateTime.now(),
          status: PrayerStatus.active,
        );
        final answeredPrayer = Prayer(
          id: '2',
          text: 'Answered prayer',
          createdDate: DateTime.now(),
          status: PrayerStatus.answered,
          answeredDate: DateTime.now(),
        );
        SharedPreferences.setMockInitialValues({
          "prayers": json.encode([activePrayer.toJson(), answeredPrayer.toJson()])
        });
      },
      act: (bloc) => bloc.add(LoadPrayers()),
      verify: (bloc) {
        final state = bloc.state as PrayerLoaded;
        final stats = state.getStats();
        expect(stats['total'], equals(2));
        expect(stats['active'], equals(1));
        expect(stats['answered'], equals(1));
      },
    );

    blocTest<PrayerBloc, PrayerState>(
      'should clear error message',
      build: () => PrayerBloc(),
      seed: () => PrayerLoaded(prayers: [], errorMessage: 'Some error'),
      act: (bloc) => bloc.add(ClearPrayerError()),
      expect: () => [
        isA<PrayerLoaded>()
            .having((state) => state.errorMessage, 'error message', isNull),
      ],
    );
  });
}
