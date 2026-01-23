@Tags(['critical', 'bloc'])
library;

// test/critical_coverage/testimony_bloc_enhanced_test.dart
// Enhanced BLoC tests for Testimony - concurrent operations, batch operations, edge cases

import 'package:devocional_nuevo/blocs/testimony_bloc.dart';
import 'package:devocional_nuevo/blocs/testimony_event.dart';
import 'package:devocional_nuevo/blocs/testimony_state.dart';
import 'package:devocional_nuevo/models/testimony_model.dart';
import 'package:devocional_nuevo/services/localization_service.dart';
import 'package:devocional_nuevo/services/service_locator.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockLocalizationService extends Mock implements LocalizationService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TestimonyBloc Enhanced Coverage Tests', () {
    late TestimonyBloc bloc;
    late MockLocalizationService mockLocalizationService;
    late ServiceLocator locator;

    setUp(() {
      SharedPreferences.setMockInitialValues({});

      locator = ServiceLocator();
      locator.reset();

      mockLocalizationService = MockLocalizationService();
      when(() => mockLocalizationService.translate(any()))
          .thenReturn('Mocked error message');

      locator.registerSingleton<LocalizationService>(mockLocalizationService);

      bloc = TestimonyBloc();
    });

    tearDown(() {
      bloc.close();
      locator.reset();
    });

    group('Concurrent Operations', () {
      test('handles multiple LoadTestimonies events in rapid succession',
          () async {
        bloc.add(LoadTestimonies());
        bloc.add(LoadTestimonies());
        bloc.add(LoadTestimonies());

        await Future.delayed(const Duration(milliseconds: 100));

        // Should handle gracefully and end in loaded state
        expect(bloc.state, isA<TestimonyLoaded>());
      });

      test('handles refresh while loading', () async {
        bloc.add(LoadTestimonies());
        bloc.add(RefreshTestimonies());

        await Future.delayed(const Duration(milliseconds: 100));

        // Should handle gracefully and end in loaded state
        expect(bloc.state, isA<TestimonyLoaded>());
      });

      test('handles clear error during operations', () async {
        bloc.add(LoadTestimonies());
        await Future.delayed(const Duration(milliseconds: 50));
        bloc.add(ClearTestimonyError());

        await Future.delayed(const Duration(milliseconds: 100));

        // Should handle gracefully
        expect(bloc.state, isA<TestimonyLoaded>());
      });

      test('handles rapid add operations', () async {
        bloc.add(AddTestimony('Testimony 1'));
        bloc.add(AddTestimony('Testimony 2'));
        bloc.add(AddTestimony('Testimony 3'));

        await Future.delayed(const Duration(milliseconds: 200));

        expect(bloc.state, isA<TestimonyLoaded>());
        final state = bloc.state as TestimonyLoaded;
        expect(state.testimonies.length, greaterThanOrEqualTo(1));
      });
    });

    group('Batch Operations', () {
      test('can add multiple testimonies sequentially', () async {
        bloc.add(AddTestimony('First testimony'));
        await bloc.stream.firstWhere((s) => s is TestimonyLoaded);

        bloc.add(AddTestimony('Second testimony'));
        await bloc.stream.firstWhere(
          (s) => s is TestimonyLoaded && s.testimonies.length == 2,
        );

        bloc.add(AddTestimony('Third testimony'));
        await bloc.stream.firstWhere(
          (s) => s is TestimonyLoaded && s.testimonies.length == 3,
        );

        final state = bloc.state as TestimonyLoaded;
        expect(state.testimonies.length, equals(3));
      });

      test('can edit and delete in sequence', () async {
        bloc.add(AddTestimony('To edit and delete'));
        await bloc.stream.firstWhere((s) => s is TestimonyLoaded);

        final state1 = bloc.state as TestimonyLoaded;
        final testimonyId = state1.testimonies[0].id;

        bloc.add(EditTestimony(testimonyId, 'Edited testimony'));
        await bloc.stream.firstWhere(
          (s) =>
              s is TestimonyLoaded &&
              s.testimonies[0].text == 'Edited testimony',
        );

        bloc.add(DeleteTestimony(testimonyId));
        await bloc.stream.firstWhere(
          (s) => s is TestimonyLoaded && s.testimonies.isEmpty,
        );

        final finalState = bloc.state as TestimonyLoaded;
        expect(finalState.testimonies, isEmpty);
      });

      test('can perform multiple edits on same testimony', () async {
        bloc.add(AddTestimony('Original'));
        await bloc.stream.firstWhere((s) => s is TestimonyLoaded);

        final state1 = bloc.state as TestimonyLoaded;
        final testimonyId = state1.testimonies[0].id;

        bloc.add(EditTestimony(testimonyId, 'First edit'));
        await bloc.stream.firstWhere(
          (s) => s is TestimonyLoaded && s.testimonies[0].text == 'First edit',
        );

        bloc.add(EditTestimony(testimonyId, 'Second edit'));
        await bloc.stream.firstWhere(
          (s) => s is TestimonyLoaded && s.testimonies[0].text == 'Second edit',
        );

        bloc.add(EditTestimony(testimonyId, 'Final edit'));
        await bloc.stream.firstWhere(
          (s) => s is TestimonyLoaded && s.testimonies[0].text == 'Final edit',
        );

        final finalState = bloc.state as TestimonyLoaded;
        expect(finalState.testimonies[0].text, equals('Final edit'));
      });
    });

    group('Edge Cases - Testimony Text Validation', () {
      test('handles whitespace-only text', () {
        final testimony = Testimony(
          id: 'whitespace',
          text: '   ',
          createdDate: DateTime.now(),
        );

        expect(testimony.text, equals('   '));
      });

      test('handles text with special line breaks and tabs', () {
        final testimony = Testimony(
          id: 'special-chars',
          text: 'Line 1\nLine 2\tTabbed\r\nCRLF',
          createdDate: DateTime.now(),
        );

        final json = testimony.toJson();
        final restored = Testimony.fromJson(json);

        expect(restored.text, contains('\n'));
        expect(restored.text, contains('\t'));
      });

      test('handles text with emojis and unicode', () {
        final testimony = Testimony(
          id: 'emoji-test',
          text: 'God blessed me 🙏 with healing 🙌 日本語 ñ é',
          createdDate: DateTime.now(),
        );

        final json = testimony.toJson();
        final restored = Testimony.fromJson(json);

        expect(restored.text, contains('🙏'));
        expect(restored.text, contains('🙌'));
        expect(restored.text, contains('日本語'));
      });

      test('handles extremely long text', () {
        final longText = 'God has blessed me ' * 1000;
        final testimony = Testimony(
          id: 'long',
          text: longText,
          createdDate: DateTime.now(),
        );

        expect(testimony.text.length, greaterThan(15000));

        final json = testimony.toJson();
        final restored = Testimony.fromJson(json);
        expect(restored.text, equals(longText));
      });

      test('handles text with quotes and special punctuation', () {
        final testimony = Testimony(
          id: 'quotes',
          text: 'He said "God is good!" and I said \'Amen!\' (truly!)',
          createdDate: DateTime.now(),
        );

        final json = testimony.toJson();
        final restored = Testimony.fromJson(json);

        expect(restored.text, contains('"'));
        expect(restored.text, contains("'"));
        expect(restored.text, contains('('));
      });
    });

    group('Edge Cases - Date Handling', () {
      test('handles testimonies created in the future (clock skew)', () {
        final futureTestimony = Testimony(
          id: 'future',
          text: 'Future testimony',
          createdDate: DateTime.now().add(const Duration(days: 1)),
        );

        // Future testimonies should have non-positive daysOld
        expect(futureTestimony.daysOld, lessThanOrEqualTo(0));
      });

      test('handles very old testimonies', () {
        final oldTestimony = Testimony(
          id: 'ancient',
          text: 'Very old testimony',
          createdDate: DateTime(2000, 1, 1),
        );

        expect(oldTestimony.daysOld, greaterThan(9000));
      });

      test('handles leap year dates correctly', () {
        final leapYearTestimony = Testimony(
          id: 'leap',
          text: 'Leap year testimony',
          createdDate: DateTime(2024, 2, 29, 12, 0, 0),
        );

        final json = leapYearTestimony.toJson();
        final restored = Testimony.fromJson(json);

        expect(restored.createdDate.month, equals(2));
        expect(restored.createdDate.day, equals(29));
      });

      test('handles testimony at midnight', () {
        final midnight = Testimony(
          id: 'midnight',
          text: 'Midnight testimony',
          createdDate: DateTime(2025, 1, 1, 0, 0, 0),
        );

        final json = midnight.toJson();
        final restored = Testimony.fromJson(json);

        expect(restored.createdDate.hour, equals(0));
      });

      test('handles testimony at end of day', () {
        final endOfDay = Testimony(
          id: 'eod',
          text: 'End of day testimony',
          createdDate: DateTime(2025, 12, 31, 23, 59, 59),
        );

        final json = endOfDay.toJson();
        final restored = Testimony.fromJson(json);

        expect(restored.createdDate.hour, equals(23));
        expect(restored.createdDate.minute, equals(59));
      });
    });

    group('Edge Cases - Lists and Filtering', () {
      test('handles empty testimony list', () {
        final state = TestimonyLoaded(testimonies: []);

        expect(state.testimonies, isEmpty);
      });

      test('handles large testimony list efficiently', () {
        final testimonies = List.generate(
          1000,
          (i) => Testimony(
            id: 'testimony-$i',
            text: 'Testimony $i',
            createdDate: DateTime.now().subtract(Duration(days: i)),
          ),
        );

        final state = TestimonyLoaded(testimonies: testimonies);

        expect(state.testimonies.length, equals(1000));
      });

      test('preserves testimony order in state', () {
        final testimonies = [
          Testimony(
            id: 'first',
            text: 'First',
            createdDate: DateTime.now(),
          ),
          Testimony(
            id: 'second',
            text: 'Second',
            createdDate: DateTime.now(),
          ),
          Testimony(
            id: 'third',
            text: 'Third',
            createdDate: DateTime.now(),
          ),
        ];

        final state = TestimonyLoaded(testimonies: testimonies);

        expect(state.testimonies[0].id, equals('first'));
        expect(state.testimonies[1].id, equals('second'));
        expect(state.testimonies[2].id, equals('third'));
      });

      test('handles list with duplicate texts but different IDs', () {
        final testimonies = [
          Testimony(
            id: 'id-1',
            text: 'Same testimony',
            createdDate: DateTime.now(),
          ),
          Testimony(
            id: 'id-2',
            text: 'Same testimony',
            createdDate: DateTime.now(),
          ),
          Testimony(
            id: 'id-3',
            text: 'Same testimony',
            createdDate: DateTime.now(),
          ),
        ];

        final state = TestimonyLoaded(testimonies: testimonies);

        expect(state.testimonies.length, equals(3));
        expect(
          state.testimonies.map((t) => t.id).toSet().length,
          equals(3),
        );
      });
    });

    group('Boundary Conditions', () {
      test('handles testimony with ID containing special characters', () {
        final testimony = Testimony(
          id: 'testimony-@#\$%-123',
          text: 'Test',
          createdDate: DateTime.now(),
        );

        final json = testimony.toJson();
        final restored = Testimony.fromJson(json);

        expect(restored.id, equals('testimony-@#\$%-123'));
      });

      test('handles testimony with minimum valid date', () {
        final minDateTestimony = Testimony(
          id: 'min-date',
          text: 'Min date testimony',
          createdDate: DateTime(1970, 1, 1),
        );

        final json = minDateTestimony.toJson();
        final restored = Testimony.fromJson(json);

        expect(restored.createdDate.year, equals(1970));
      });

      test('copyWith with all null parameters returns identical testimony', () {
        final original = Testimony(
          id: 'original',
          text: 'Original text',
          createdDate: DateTime(2025, 1, 1),
        );

        final copy = original.copyWith();

        expect(copy.id, equals(original.id));
        expect(copy.text, equals(original.text));
        expect(copy.createdDate, equals(original.createdDate));
      });

      test('handles testimony with single character text', () {
        final testimony = Testimony(
          id: 'single-char',
          text: 'A',
          createdDate: DateTime.now(),
        );

        final json = testimony.toJson();
        final restored = Testimony.fromJson(json);

        expect(restored.text, equals('A'));
      });
    });

    group('State Persistence Verification', () {
      test('state preserves all testimony properties', () {
        final testimonies = [
          Testimony(
            id: '1',
            text: 'T1',
            createdDate: DateTime.now(),
          ),
          Testimony(
            id: '2',
            text: 'T2',
            createdDate: DateTime.now(),
          ),
        ];

        final state = TestimonyLoaded(testimonies: testimonies);

        expect(state.testimonies, hasLength(2));
        expect(state.testimonies[0].id, equals('1'));
        expect(state.testimonies[1].id, equals('2'));
      });

      test('new bloc instance can load persisted testimonies', () async {
        bloc.add(AddTestimony('Persisted testimony'));
        await bloc.stream.firstWhere((s) => s is TestimonyLoaded);

        final newBloc = TestimonyBloc();
        newBloc.add(LoadTestimonies());

        await expectLater(
          newBloc.stream,
          emitsInOrder([
            isA<TestimonyLoading>(),
            isA<TestimonyLoaded>().having(
              (s) => s.testimonies.isNotEmpty,
              'has testimonies',
              isTrue,
            ),
          ]),
        );

        await newBloc.close();
      });
    });

    group('Error Handling', () {
      test('handles error state gracefully', () async {
        bloc.add(LoadTestimonies());
        await bloc.stream.firstWhere((s) => s is TestimonyLoaded);

        bloc.add(AddTestimony(''));

        await expectLater(
          bloc.stream,
          emits(
            isA<TestimonyLoaded>().having(
              (s) => s.errorMessage,
              'has error',
              isNotNull,
            ),
          ),
        );
      });

      test('can clear error message', () async {
        bloc.add(LoadTestimonies());
        await bloc.stream.firstWhere((s) => s is TestimonyLoaded);

        bloc.add(AddTestimony(''));
        await bloc.stream.firstWhere(
          (s) => s is TestimonyLoaded && s.errorMessage != null,
        );

        bloc.add(ClearTestimonyError());

        await expectLater(
          bloc.stream,
          emits(
            isA<TestimonyLoaded>().having(
              (s) => s.errorMessage,
              'no error',
              isNull,
            ),
          ),
        );
      });

      test('handles edit with non-existent ID gracefully', () async {
        bloc.add(LoadTestimonies());
        await bloc.stream.firstWhere((s) => s is TestimonyLoaded);

        bloc.add(EditTestimony('non-existent-id', 'New text'));

        await Future.delayed(const Duration(milliseconds: 100));

        expect(bloc.state, isA<TestimonyLoaded>());
      });

      test('handles delete with non-existent ID gracefully', () async {
        bloc.add(LoadTestimonies());
        await bloc.stream.firstWhere((s) => s is TestimonyLoaded);

        bloc.add(DeleteTestimony('non-existent-id'));

        await Future.delayed(const Duration(milliseconds: 100));

        expect(bloc.state, isA<TestimonyLoaded>());
      });
    });

    group('Data Integrity', () {
      test('toJson and fromJson maintain data integrity', () {
        final original = Testimony(
          id: 'integrity-test',
          text: 'Special chars: @#\$% ñé 日本語 🙏',
          createdDate: DateTime(2025, 3, 15, 8, 30, 45),
        );

        final json = original.toJson();
        final restored = Testimony.fromJson(json);

        expect(restored.id, equals(original.id));
        expect(restored.text, equals(original.text));
      });

      test('handles malformed JSON gracefully', () {
        final json = {
          'id': null,
          'text': null,
          'createdDate': 'invalid-date',
        };

        final testimony = Testimony.fromJson(json);

        expect(testimony.id, isNotEmpty);
        expect(testimony.text, equals(''));
        expect(testimony.createdDate, isA<DateTime>());
      });

      test('handles JSON with missing fields', () {
        final json = <String, dynamic>{};

        final testimony = Testimony.fromJson(json);

        expect(testimony.id, isNotEmpty);
        expect(testimony.text, equals(''));
        expect(testimony.createdDate, isA<DateTime>());
      });
    });
  });
}
