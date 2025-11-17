import 'package:devocional_nuevo/blocs/thanksgiving_bloc.dart';
import 'package:devocional_nuevo/blocs/thanksgiving_event.dart';
import 'package:devocional_nuevo/blocs/thanksgiving_state.dart';
import 'package:devocional_nuevo/models/thanksgiving_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('Thanksgiving Integration Tests - Real User Scenarios', () {
    late ThanksgivingBloc bloc;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      bloc = ThanksgivingBloc();
    });

    tearDown(() {
      bloc.close();
    });

    test('User creates multiple thanksgivings and they persist', () async {
      // Scenario: User creates 3 thanksgivings throughout the day

      // Morning thanksgiving
      bloc.add(AddThanksgiving('Gracias por un nuevo día'));
      await bloc.stream.firstWhere((state) => state is ThanksgivingLoaded);

      // Afternoon thanksgiving
      await Future.delayed(const Duration(milliseconds: 10));
      bloc.add(AddThanksgiving('Gracias por mi familia'));
      await bloc.stream.firstWhere(
        (state) =>
            state is ThanksgivingLoaded && state.thanksgivings.length == 2,
      );

      // Evening thanksgiving
      await Future.delayed(const Duration(milliseconds: 10));
      bloc.add(AddThanksgiving('Gracias por tu protección'));
      await bloc.stream.firstWhere(
        (state) =>
            state is ThanksgivingLoaded && state.thanksgivings.length == 3,
      );

      final state = bloc.state as ThanksgivingLoaded;
      expect(state.thanksgivings.length, equals(3));

      // Verify order (newest first)
      expect(
        state.thanksgivings[0].text,
        equals('Gracias por tu protección'),
      );
      expect(state.thanksgivings[1].text, equals('Gracias por mi familia'));
      expect(state.thanksgivings[2].text, equals('Gracias por un nuevo día'));

      // Simulate app restart - create new bloc
      await bloc.close();
      final newBloc = ThanksgivingBloc();
      newBloc.add(LoadThanksgivings());

      await expectLater(
        newBloc.stream,
        emitsInOrder([
          isA<ThanksgivingLoading>(),
          isA<ThanksgivingLoaded>().having(
            (s) => s.thanksgivings.length,
            'length',
            3,
          ),
        ]),
      );

      await newBloc.close();
    });

    test('User edits a thanksgiving after creating it', () async {
      // User creates a thanksgiving with a typo
      bloc.add(AddThanksgiving('Gracias por my familia'));
      await bloc.stream.firstWhere((state) => state is ThanksgivingLoaded);

      var state = bloc.state as ThanksgivingLoaded;
      final thanksgivingId = state.thanksgivings[0].id;

      // User realizes the typo and edits it
      bloc.add(EditThanksgiving(thanksgivingId, 'Gracias por mi familia'));
      await bloc.stream.firstWhere(
        (state) =>
            state is ThanksgivingLoaded &&
            state.thanksgivings[0].text == 'Gracias por mi familia',
      );

      state = bloc.state as ThanksgivingLoaded;
      expect(state.thanksgivings[0].text, equals('Gracias por mi familia'));
      expect(state.thanksgivings[0].id, equals(thanksgivingId)); // Same ID
    });

    test('User deletes an old thanksgiving', () async {
      // User has 3 thanksgivings
      bloc.add(AddThanksgiving('Thanksgiving 1'));
      await bloc.stream.firstWhere((state) => state is ThanksgivingLoaded);

      await Future.delayed(const Duration(milliseconds: 10));
      bloc.add(AddThanksgiving('Thanksgiving 2'));
      await bloc.stream.firstWhere(
        (state) =>
            state is ThanksgivingLoaded && state.thanksgivings.length == 2,
      );

      await Future.delayed(const Duration(milliseconds: 10));
      bloc.add(AddThanksgiving('Thanksgiving 3'));
      await bloc.stream.firstWhere(
        (state) =>
            state is ThanksgivingLoaded && state.thanksgivings.length == 3,
      );

      var state = bloc.state as ThanksgivingLoaded;
      final secondThanksgivingId = state.thanksgivings[1].id;

      // User deletes the second thanksgiving
      bloc.add(DeleteThanksgiving(secondThanksgivingId));
      await bloc.stream.firstWhere(
        (state) =>
            state is ThanksgivingLoaded && state.thanksgivings.length == 2,
      );

      state = bloc.state as ThanksgivingLoaded;
      expect(state.thanksgivings.length, equals(2));
      expect(
        state.thanksgivings.any((t) => t.id == secondThanksgivingId),
        isFalse,
      );
    });

    test('User tries to create empty thanksgiving and sees error', () async {
      // First load thanksgivings to get into ThanksgivingLoaded state
      bloc.add(LoadThanksgivings());
      await bloc.stream.firstWhere((state) => state is ThanksgivingLoaded);

      // User accidentally taps create without entering text
      bloc.add(AddThanksgiving(''));

      // Wait for error message in loaded state
      final state = await bloc.stream.firstWhere(
        (state) => state is ThanksgivingLoaded && state.errorMessage != null,
        orElse: () => bloc.state,
      );

      // Check that error is present
      expect(state, isA<ThanksgivingLoaded>());
      final loadedState = state as ThanksgivingLoaded;
      expect(loadedState.errorMessage, isNotNull);
      expect(loadedState.thanksgivings.isEmpty, isTrue);
    }, timeout: const Timeout(Duration(seconds: 10)));

    test('User refreshes their thanksgiving list', () async {
      // User has some thanksgivings
      bloc.add(AddThanksgiving('First thanksgiving'));
      await bloc.stream.firstWhere((state) => state is ThanksgivingLoaded);

      bloc.add(AddThanksgiving('Second thanksgiving'));
      await bloc.stream.firstWhere(
        (state) =>
            state is ThanksgivingLoaded && state.thanksgivings.length == 2,
      );

      // User pulls to refresh
      bloc.add(RefreshThanksgivings());
      await bloc.stream.firstWhere(
        (state) => state is ThanksgivingLoaded,
      );

      final state = bloc.state as ThanksgivingLoaded;
      expect(state.thanksgivings.length, equals(2));
    });

    test('User journey: create, view, edit, then delete', () async {
      // Day 1: User creates a thanksgiving
      bloc.add(AddThanksgiving('Gracias por este día hermoso'));
      await bloc.stream.firstWhere((state) => state is ThanksgivingLoaded);

      var state = bloc.state as ThanksgivingLoaded;
      expect(state.thanksgivings.length, equals(1));
      final thanksgivingId = state.thanksgivings[0].id;

      // Day 2: User adds more context
      bloc.add(
        EditThanksgiving(
          thanksgivingId,
          'Gracias por este día hermoso y por la salud de mi familia',
        ),
      );
      await bloc.stream.firstWhere(
        (state) =>
            state is ThanksgivingLoaded &&
            state.thanksgivings[0].text.contains('salud'),
      );

      state = bloc.state as ThanksgivingLoaded;
      expect(
        state.thanksgivings[0].text,
        contains('salud de mi familia'),
      );

      // Week later: User decides to clean up old thanksgivings
      bloc.add(DeleteThanksgiving(thanksgivingId));
      await bloc.stream.firstWhere(
        (state) => state is ThanksgivingLoaded && state.thanksgivings.isEmpty,
      );

      state = bloc.state as ThanksgivingLoaded;
      expect(state.thanksgivings.isEmpty, isTrue);
    });

    test('Multiple users scenario - data isolation', () async {
      // User 1 creates thanksgivings
      bloc.add(AddThanksgiving('User 1 thanksgiving'));
      await bloc.stream.firstWhere((state) => state is ThanksgivingLoaded);

      final state = bloc.state as ThanksgivingLoaded;
      expect(state.thanksgivings.length, equals(1));

      // Simulate logout/login (new bloc instance)
      await bloc.close();

      // User 2 logs in with fresh storage
      SharedPreferences.setMockInitialValues({});
      final user2Bloc = ThanksgivingBloc();
      user2Bloc.add(LoadThanksgivings());

      await expectLater(
        user2Bloc.stream,
        emitsInOrder([
          isA<ThanksgivingLoading>(),
          isA<ThanksgivingLoaded>().having(
            (s) => s.thanksgivings.isEmpty,
            'isEmpty',
            true,
          ),
        ]),
      );

      await user2Bloc.close();
    });

    test('Heavy usage scenario - 20 thanksgivings', () async {
      // User is very grateful and creates many thanksgivings
      for (int i = 1; i <= 20; i++) {
        bloc.add(AddThanksgiving('Thanksgiving number $i'));
        // Wait for each one to be added
        await bloc.stream.firstWhere(
          (state) =>
              state is ThanksgivingLoaded && state.thanksgivings.length >= i,
          orElse: () => bloc.state,
        );
      }

      final state = bloc.state as ThanksgivingLoaded;
      expect(state.thanksgivings.length, equals(20));

      // Verify they're sorted correctly (newest first)
      expect(state.thanksgivings[0].text, equals('Thanksgiving number 20'));
      expect(state.thanksgivings[19].text, equals('Thanksgiving number 1'));
    }, timeout: const Timeout(Duration(seconds: 60)));

    test('Days old calculation changes over time', () async {
      // Create a thanksgiving
      final createdDate = DateTime.now().subtract(const Duration(days: 5));
      final thanksgiving = Thanksgiving(
        id: 'test_thanksgiving',
        text: 'Test',
        createdDate: createdDate,
      );

      expect(thanksgiving.daysOld, equals(5));
    });
  });
}
