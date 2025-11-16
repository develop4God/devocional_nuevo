import 'package:devocional_nuevo/blocs/thanksgiving_bloc.dart';
import 'package:devocional_nuevo/blocs/thanksgiving_event.dart';
import 'package:devocional_nuevo/blocs/thanksgiving_state.dart';
import 'package:devocional_nuevo/models/thanksgiving_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('ThanksgivingBloc Tests', () {
    late ThanksgivingBloc bloc;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      bloc = ThanksgivingBloc();
    });

    tearDown(() {
      bloc.close();
    });

    test('initial state should be ThanksgivingInitial', () {
      expect(bloc.state, isA<ThanksgivingInitial>());
    });

    test('should load empty list when no thanksgivings exist', () async {
      bloc.add(LoadThanksgivings());

      await expectLater(
        bloc.stream,
        emitsInOrder([
          isA<ThanksgivingLoading>(),
          isA<ThanksgivingLoaded>()
              .having((s) => s.thanksgivings.isEmpty, 'isEmpty', true),
        ]),
      );
    });

    test('should add a new thanksgiving', () async {
      bloc.add(AddThanksgiving('Gracias por tu amor'));

      await expectLater(
        bloc.stream,
        emitsInOrder([
          isA<ThanksgivingLoaded>().having(
            (s) => s.thanksgivings.length,
            'length',
            1,
          ),
        ]),
      );

      final state = bloc.state as ThanksgivingLoaded;
      expect(state.thanksgivings[0].text, equals('Gracias por tu amor'));
    });

    test('should not add thanksgiving with empty text', () async {
      // Load initial state first
      bloc.add(LoadThanksgivings());
      await bloc.stream.firstWhere((state) => state is ThanksgivingLoaded);

      // Try to add empty text
      bloc.add(AddThanksgiving(''));

      // Should not emit a new state or should emit error
      await expectLater(
        bloc.stream,
        emits(
          isA<ThanksgivingLoaded>().having(
            (s) => s.errorMessage,
            'errorMessage',
            isNotNull,
          ),
        ),
      );
    });

    test('should edit an existing thanksgiving', () async {
      // First add a thanksgiving
      bloc.add(AddThanksgiving('Original text'));

      await bloc.stream.firstWhere((state) => state is ThanksgivingLoaded);

      final state = bloc.state as ThanksgivingLoaded;
      final thanksgivingId = state.thanksgivings[0].id;

      // Now edit it
      bloc.add(EditThanksgiving(thanksgivingId, 'Updated text'));

      await expectLater(
        bloc.stream,
        emits(
          isA<ThanksgivingLoaded>().having(
            (s) => s.thanksgivings[0].text,
            'text',
            equals('Updated text'),
          ),
        ),
      );
    });

    test('should delete a thanksgiving', () async {
      // First add a thanksgiving
      bloc.add(AddThanksgiving('To be deleted'));

      await bloc.stream.firstWhere((state) => state is ThanksgivingLoaded);

      final state = bloc.state as ThanksgivingLoaded;
      final thanksgivingId = state.thanksgivings[0].id;

      // Now delete it
      bloc.add(DeleteThanksgiving(thanksgivingId));

      await expectLater(
        bloc.stream,
        emits(
          isA<ThanksgivingLoaded>().having(
            (s) => s.thanksgivings.isEmpty,
            'isEmpty',
            true,
          ),
        ),
      );
    });

    test('should refresh thanksgivings', () async {
      // Add a thanksgiving first
      bloc.add(AddThanksgiving('Test thanksgiving'));

      await bloc.stream.firstWhere((state) => state is ThanksgivingLoaded);

      // Now refresh
      bloc.add(RefreshThanksgivings());

      await expectLater(
        bloc.stream,
        emits(
          isA<ThanksgivingLoaded>().having(
            (s) => s.thanksgivings.length,
            'length',
            1,
          ),
        ),
      );
    });

    test('should clear error message', () async {
      // Load initial state first
      bloc.add(LoadThanksgivings());
      await bloc.stream.firstWhere((state) => state is ThanksgivingLoaded);

      // First cause an error (empty text)
      bloc.add(AddThanksgiving(''));

      await bloc.stream.firstWhere(
          (state) => state is ThanksgivingLoaded && state.errorMessage != null);

      // Now clear the error
      bloc.add(ClearThanksgivingError());

      await expectLater(
        bloc.stream,
        emits(
          isA<ThanksgivingLoaded>().having(
            (s) => s.errorMessage,
            'errorMessage',
            isNull,
          ),
        ),
      );
    });

    test('should sort thanksgivings by creation date (newest first)', () async {
      // Add multiple thanksgivings
      bloc.add(AddThanksgiving('First thanksgiving'));

      await bloc.stream.firstWhere((state) => state is ThanksgivingLoaded);

      // Wait a bit to ensure different timestamps
      await Future.delayed(const Duration(milliseconds: 10));

      bloc.add(AddThanksgiving('Second thanksgiving'));

      await bloc.stream.firstWhere(
        (state) =>
            state is ThanksgivingLoaded && state.thanksgivings.length == 2,
      );

      final state = bloc.state as ThanksgivingLoaded;
      
      // The most recent should be first
      expect(state.thanksgivings[0].text, equals('Second thanksgiving'));
      expect(state.thanksgivings[1].text, equals('First thanksgiving'));
    });

    test('should persist thanksgivings to storage', () async {
      bloc.add(AddThanksgiving('Persistent thanksgiving'));

      await bloc.stream.firstWhere((state) => state is ThanksgivingLoaded);

      // Create a new bloc instance
      final newBloc = ThanksgivingBloc();
      newBloc.add(LoadThanksgivings());

      await expectLater(
        newBloc.stream,
        emitsInOrder([
          isA<ThanksgivingLoading>(),
          isA<ThanksgivingLoaded>().having(
            (s) => s.thanksgivings.length,
            'length',
            1,
          ),
        ]),
      );

      await newBloc.close();
    });
  });
}
