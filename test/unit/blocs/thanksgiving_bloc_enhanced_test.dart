@Tags(['critical', 'unit', 'blocs'])
library;

// test/critical_coverage/thanksgiving_bloc_enhanced_test.dart
// Enhanced BLoC tests for Thanksgiving - concurrent operations, batch operations, edge cases

import 'package:devocional_nuevo/blocs/thanksgiving_bloc.dart';
import 'package:devocional_nuevo/blocs/thanksgiving_event.dart';
import 'package:devocional_nuevo/blocs/thanksgiving_state.dart';
import 'package:devocional_nuevo/models/thanksgiving_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ThanksgivingBloc Enhanced Coverage Tests', () {
    late ThanksgivingBloc bloc;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      bloc = ThanksgivingBloc();
    });

    tearDown(() {
      bloc.close();
    });

    group('Concurrent Operations', () {
      test('handles multiple LoadThanksgivings events in rapid succession',
          () async {
        bloc.add(LoadThanksgivings());
        bloc.add(LoadThanksgivings());
        bloc.add(LoadThanksgivings());

        await Future.delayed(const Duration(milliseconds: 100));

        // Should handle gracefully and end in loaded state
        expect(bloc.state, isA<ThanksgivingLoaded>());
      });

      test('handles refresh while loading', () async {
        bloc.add(LoadThanksgivings());
        bloc.add(RefreshThanksgivings());

        await Future.delayed(const Duration(milliseconds: 100));

        // Should handle gracefully and end in loaded state
        expect(bloc.state, isA<ThanksgivingLoaded>());
      });

      test('handles clear error during operations', () async {
        bloc.add(LoadThanksgivings());
        await Future.delayed(const Duration(milliseconds: 50));
        bloc.add(ClearThanksgivingError());

        await Future.delayed(const Duration(milliseconds: 100));

        // Should handle gracefully
        expect(bloc.state, isA<ThanksgivingLoaded>());
      });

      test('handles rapid add operations', () async {
        // Add multiple thanksgivings rapidly
        bloc.add(AddThanksgiving('Thanks 1'));
        bloc.add(AddThanksgiving('Thanks 2'));
        bloc.add(AddThanksgiving('Thanks 3'));

        // Wait for processing
        await Future.delayed(const Duration(milliseconds: 200));

        expect(bloc.state, isA<ThanksgivingLoaded>());
        final state = bloc.state as ThanksgivingLoaded;
        expect(state.thanksgivings.length, greaterThanOrEqualTo(1));
      });
    });

    group('Batch Operations', () {
      test('can add multiple thanksgivings sequentially', () async {
        // Add first thanksgiving
        bloc.add(AddThanksgiving('First thanks'));
        await bloc.stream.firstWhere((s) => s is ThanksgivingLoaded);

        // Add second thanksgiving
        bloc.add(AddThanksgiving('Second thanks'));
        await bloc.stream.firstWhere(
          (s) => s is ThanksgivingLoaded && s.thanksgivings.length == 2,
        );

        // Add third thanksgiving
        bloc.add(AddThanksgiving('Third thanks'));
        await bloc.stream.firstWhere(
          (s) => s is ThanksgivingLoaded && s.thanksgivings.length == 3,
        );

        final state = bloc.state as ThanksgivingLoaded;
        expect(state.thanksgivings.length, equals(3));
      });

      test('can edit and delete in sequence', () async {
        // Add thanksgiving
        bloc.add(AddThanksgiving('To edit and delete'));
        await bloc.stream.firstWhere((s) => s is ThanksgivingLoaded);

        final state1 = bloc.state as ThanksgivingLoaded;
        final thanksId = state1.thanksgivings[0].id;

        // Edit it
        bloc.add(EditThanksgiving(thanksId, 'Edited text'));
        await bloc.stream.firstWhere(
          (s) =>
              s is ThanksgivingLoaded &&
              s.thanksgivings[0].text == 'Edited text',
        );

        // Delete it
        bloc.add(DeleteThanksgiving(thanksId));
        await bloc.stream.firstWhere(
          (s) => s is ThanksgivingLoaded && s.thanksgivings.isEmpty,
        );

        final finalState = bloc.state as ThanksgivingLoaded;
        expect(finalState.thanksgivings, isEmpty);
      });
    });

    group('Edge Cases - Thanksgiving Text Validation', () {
      test('handles whitespace-only text', () {
        final thanksgiving = Thanksgiving(
          id: 'whitespace',
          text: '   ',
          createdDate: DateTime.now(),
        );

        expect(thanksgiving.text, equals('   '));
      });

      test('handles text with special line breaks and tabs', () {
        final thanksgiving = Thanksgiving(
          id: 'special-chars',
          text: 'Line 1\nLine 2\tTabbed\r\nCRLF',
          createdDate: DateTime.now(),
        );

        final json = thanksgiving.toJson();
        final restored = Thanksgiving.fromJson(json);

        expect(restored.text, contains('\n'));
        expect(restored.text, contains('\t'));
      });

      test('handles text with emojis and unicode', () {
        final thanksgiving = Thanksgiving(
          id: 'emoji-test',
          text: 'Thank you 🙏 for blessings 🎁 日本語 ñ é',
          createdDate: DateTime.now(),
        );

        final json = thanksgiving.toJson();
        final restored = Thanksgiving.fromJson(json);

        expect(restored.text, contains('🙏'));
        expect(restored.text, contains('🎁'));
        expect(restored.text, contains('日本語'));
      });

      test('handles extremely long text', () {
        final longText = 'Thank you God ' * 1000;
        final thanksgiving = Thanksgiving(
          id: 'long',
          text: longText,
          createdDate: DateTime.now(),
        );

        expect(thanksgiving.text.length, greaterThan(10000));

        final json = thanksgiving.toJson();
        final restored = Thanksgiving.fromJson(json);
        expect(restored.text, equals(longText));
      });
    });

    group('Edge Cases - Date Handling', () {
      test('handles thanksgivings created in the future (clock skew)', () {
        final futureThanks = Thanksgiving(
          id: 'future',
          text: 'Future thanks',
          createdDate: DateTime.now().add(const Duration(days: 1)),
        );

        // Future thanksgivings should have non-positive daysOld
        expect(futureThanks.daysOld, lessThanOrEqualTo(0));
      });

      test('handles very old thanksgivings', () {
        final oldThanks = Thanksgiving(
          id: 'ancient',
          text: 'Very old thanks',
          createdDate: DateTime(2000, 1, 1),
        );

        expect(oldThanks.daysOld, greaterThan(9000));
      });

      test('handles leap year dates correctly', () {
        final leapYearThanks = Thanksgiving(
          id: 'leap',
          text: 'Leap year thanks',
          createdDate: DateTime(2024, 2, 29, 12, 0, 0),
        );

        final json = leapYearThanks.toJson();
        final restored = Thanksgiving.fromJson(json);

        expect(restored.createdDate.month, equals(2));
        expect(restored.createdDate.day, equals(29));
      });

      test('handles thanksgiving at midnight', () {
        final midnight = Thanksgiving(
          id: 'midnight',
          text: 'Midnight thanks',
          createdDate: DateTime(2025, 1, 1, 0, 0, 0),
        );

        final json = midnight.toJson();
        final restored = Thanksgiving.fromJson(json);

        expect(restored.createdDate.hour, equals(0));
        expect(restored.createdDate.minute, equals(0));
      });
    });

    group('Edge Cases - Lists and Filtering', () {
      test('handles empty thanksgiving list', () {
        final state = ThanksgivingLoaded(thanksgivings: []);

        expect(state.thanksgivings, isEmpty);
      });

      test('handles large thanksgiving list efficiently', () {
        final thanksgivings = List.generate(
          1000,
          (i) => Thanksgiving(
            id: 'thanks-$i',
            text: 'Thanksgiving $i',
            createdDate: DateTime.now().subtract(Duration(days: i)),
          ),
        );

        final state = ThanksgivingLoaded(thanksgivings: thanksgivings);

        expect(state.thanksgivings.length, equals(1000));
      });

      test('preserves thanksgiving order in state', () {
        final thanksgivings = [
          Thanksgiving(
            id: 'first',
            text: 'First',
            createdDate: DateTime.now(),
          ),
          Thanksgiving(
            id: 'second',
            text: 'Second',
            createdDate: DateTime.now(),
          ),
          Thanksgiving(
            id: 'third',
            text: 'Third',
            createdDate: DateTime.now(),
          ),
        ];

        final state = ThanksgivingLoaded(thanksgivings: thanksgivings);

        expect(state.thanksgivings[0].id, equals('first'));
        expect(state.thanksgivings[1].id, equals('second'));
        expect(state.thanksgivings[2].id, equals('third'));
      });
    });

    group('Boundary Conditions', () {
      test('handles thanksgiving with ID containing special characters', () {
        final thanksgiving = Thanksgiving(
          id: 'thanks-@#\$%-123',
          text: 'Test',
          createdDate: DateTime.now(),
        );

        final json = thanksgiving.toJson();
        final restored = Thanksgiving.fromJson(json);

        expect(restored.id, equals('thanks-@#\$%-123'));
      });

      test('handles thanksgiving with minimum valid date', () {
        final minDateThanks = Thanksgiving(
          id: 'min-date',
          text: 'Min date thanks',
          createdDate: DateTime(1970, 1, 1),
        );

        final json = minDateThanks.toJson();
        final restored = Thanksgiving.fromJson(json);

        expect(restored.createdDate.year, equals(1970));
      });

      test('copyWith with all null parameters returns identical thanksgiving',
          () {
        final original = Thanksgiving(
          id: 'original',
          text: 'Original text',
          createdDate: DateTime(2025, 1, 1),
        );

        final copy = original.copyWith();

        expect(copy.id, equals(original.id));
        expect(copy.text, equals(original.text));
        expect(copy.createdDate, equals(original.createdDate));
      });

      test('handles thanksgiving with same text but different IDs', () {
        final thanks1 = Thanksgiving(
          id: 'thanks-1',
          text: 'Same text',
          createdDate: DateTime.now(),
        );

        final thanks2 = Thanksgiving(
          id: 'thanks-2',
          text: 'Same text',
          createdDate: DateTime.now(),
        );

        expect(thanks1.text, equals(thanks2.text));
        expect(thanks1.id, isNot(equals(thanks2.id)));
      });
    });

    group('State Persistence Verification', () {
      test('state preserves all thanksgiving properties', () {
        final thanksgivings = [
          Thanksgiving(
            id: '1',
            text: 'T1',
            createdDate: DateTime.now(),
          ),
          Thanksgiving(
            id: '2',
            text: 'T2',
            createdDate: DateTime.now(),
          ),
        ];

        final state = ThanksgivingLoaded(thanksgivings: thanksgivings);

        expect(state.thanksgivings, hasLength(2));
        expect(state.thanksgivings[0].id, equals('1'));
        expect(state.thanksgivings[1].id, equals('2'));
      });

      test('new bloc instance can load persisted thanksgivings', () async {
        // Add thanksgiving with first bloc
        bloc.add(AddThanksgiving('Persisted thanksgiving'));
        await bloc.stream.firstWhere((s) => s is ThanksgivingLoaded);

        // Create new bloc instance
        final newBloc = ThanksgivingBloc();
        newBloc.add(LoadThanksgivings());

        await expectLater(
          newBloc.stream,
          emitsInOrder([
            isA<ThanksgivingLoading>(),
            isA<ThanksgivingLoaded>().having(
              (s) => s.thanksgivings.isNotEmpty,
              'has thanksgivings',
              isTrue,
            ),
          ]),
        );

        await newBloc.close();
      });
    });

    group('Error Handling', () {
      test('handles error state gracefully', () async {
        bloc.add(LoadThanksgivings());
        await bloc.stream.firstWhere((s) => s is ThanksgivingLoaded);

        // Try to add empty text (should trigger error)
        bloc.add(AddThanksgiving(''));

        await expectLater(
          bloc.stream,
          emits(
            isA<ThanksgivingLoaded>().having(
              (s) => s.errorMessage,
              'has error',
              isNotNull,
            ),
          ),
        );
      });

      test('can clear error message', () async {
        bloc.add(LoadThanksgivings());
        await bloc.stream.firstWhere((s) => s is ThanksgivingLoaded);

        // Trigger error
        bloc.add(AddThanksgiving(''));
        await bloc.stream.firstWhere(
          (s) => s is ThanksgivingLoaded && s.errorMessage != null,
        );

        // Clear error
        bloc.add(ClearThanksgivingError());

        await expectLater(
          bloc.stream,
          emits(
            isA<ThanksgivingLoaded>().having(
              (s) => s.errorMessage,
              'no error',
              isNull,
            ),
          ),
        );
      });
    });

    group('Data Integrity', () {
      test('toJson and fromJson maintain data integrity', () {
        final original = Thanksgiving(
          id: 'integrity-test',
          text: 'Special chars: @#\$% ñé 日本語 🙏',
          createdDate: DateTime(2025, 3, 15, 8, 30, 45),
        );

        final json = original.toJson();
        final restored = Thanksgiving.fromJson(json);

        expect(restored.id, equals(original.id));
        expect(restored.text, equals(original.text));
      });

      test('handles malformed JSON gracefully', () {
        final json = {
          'id': null,
          'text': null,
          'createdDate': 'invalid-date',
        };

        final thanksgiving = Thanksgiving.fromJson(json);

        expect(thanksgiving.id, isNotEmpty);
        expect(thanksgiving.text, equals(''));
        expect(thanksgiving.createdDate, isA<DateTime>());
      });
    });
  });
}
