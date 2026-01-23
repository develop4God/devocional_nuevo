import 'package:devocional_nuevo/blocs/testimony_bloc.dart';
import 'package:devocional_nuevo/blocs/testimony_event.dart';
import 'package:devocional_nuevo/blocs/testimony_state.dart';
import 'package:devocional_nuevo/models/testimony_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Testimony Integration Tests - Real User Scenarios', () {
    late TestimonyBloc bloc;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      bloc = TestimonyBloc();
    });

    tearDown(() {
      bloc.close();
    });

    test('User creates multiple testimonies and they persist', () async {
      // Scenario: User creates 3 testimonies throughout their spiritual journey

      // First testimony
      bloc.add(AddTestimony('God healed me from a difficult illness'));
      await bloc.stream.firstWhere((state) => state is TestimonyLoaded);

      // Second testimony
      await Future.delayed(const Duration(milliseconds: 10));
      bloc.add(AddTestimony('I witnessed a miracle in my family'));
      await bloc.stream.firstWhere(
        (state) => state is TestimonyLoaded && state.testimonies.length == 2,
      );

      // Third testimony
      await Future.delayed(const Duration(milliseconds: 10));
      bloc.add(AddTestimony('God provided for me in unexpected ways'));
      await bloc.stream.firstWhere(
        (state) => state is TestimonyLoaded && state.testimonies.length == 3,
      );

      final state = bloc.state as TestimonyLoaded;
      expect(state.testimonies.length, equals(3));

      // Verify order (newest first)
      expect(
        state.testimonies[0].text,
        equals('God provided for me in unexpected ways'),
      );
      expect(
        state.testimonies[1].text,
        equals('I witnessed a miracle in my family'),
      );
      expect(
        state.testimonies[2].text,
        equals('God healed me from a difficult illness'),
      );

      // Simulate app restart - create new bloc
      await bloc.close();
      final newBloc = TestimonyBloc();
      newBloc.add(LoadTestimonies());

      await expectLater(
        newBloc.stream,
        emitsInOrder([
          isA<TestimonyLoading>(),
          isA<TestimonyLoaded>().having(
            (s) => s.testimonies.length,
            'length',
            3,
          ),
        ]),
      );

      await newBloc.close();
    });

    test('User edits a testimony after creating it', () async {
      // User creates a testimony with incomplete details
      bloc.add(AddTestimony('God blessed me'));
      await bloc.stream.firstWhere((state) => state is TestimonyLoaded);

      var state = bloc.state as TestimonyLoaded;
      final testimonyId = state.testimonies[0].id;

      // User decides to add more details
      bloc.add(
        EditTestimony(
          testimonyId,
          'God blessed me with a new job after months of searching',
        ),
      );

      await expectLater(
        bloc.stream,
        emits(
          isA<TestimonyLoaded>().having(
            (s) => s.testimonies[0].text,
            'text',
            equals(
              'God blessed me with a new job after months of searching',
            ),
          ),
        ),
      );

      // Verify it persists
      final newState = bloc.state as TestimonyLoaded;
      expect(
        newState.testimonies[0].text,
        equals('God blessed me with a new job after months of searching'),
      );
      expect(newState.testimonies[0].id, equals(testimonyId));
    });

    test('User deletes a testimony', () async {
      // User creates two testimonies
      bloc.add(AddTestimony('First testimony'));
      await bloc.stream.firstWhere((state) => state is TestimonyLoaded);

      bloc.add(AddTestimony('Second testimony'));
      await bloc.stream.firstWhere(
        (state) => state is TestimonyLoaded && state.testimonies.length == 2,
      );

      var state = bloc.state as TestimonyLoaded;
      final firstTestimonyId = state.testimonies[1].id;

      // User decides to delete the first testimony
      bloc.add(DeleteTestimony(firstTestimonyId));

      await expectLater(
        bloc.stream,
        emits(
          isA<TestimonyLoaded>().having(
            (s) => s.testimonies.length,
            'length',
            1,
          ),
        ),
      );

      state = bloc.state as TestimonyLoaded;
      expect(state.testimonies.length, equals(1));
      expect(state.testimonies[0].text, equals('Second testimony'));
    });

    test('User journey: Create, Read, Update, Delete (CRUD)', () async {
      // CREATE: User adds a new testimony
      bloc.add(AddTestimony('My life changed when I accepted Christ'));
      await bloc.stream.firstWhere((state) => state is TestimonyLoaded);

      var state = bloc.state as TestimonyLoaded;
      expect(state.testimonies.length, equals(1));

      // READ: User views their testimonies
      expect(
        state.testimonies[0].text,
        equals('My life changed when I accepted Christ'),
      );
      final testimonyId = state.testimonies[0].id;

      // UPDATE: User edits to add more details
      bloc.add(
        EditTestimony(
          testimonyId,
          'My life changed when I accepted Christ and found true peace',
        ),
      );

      await bloc.stream.firstWhere(
        (state) =>
            state is TestimonyLoaded &&
            state.testimonies[0].text.contains('true peace'),
      );

      state = bloc.state as TestimonyLoaded;
      expect(
        state.testimonies[0].text,
        equals(
          'My life changed when I accepted Christ and found true peace',
        ),
      );

      // DELETE: User removes the testimony
      bloc.add(DeleteTestimony(testimonyId));

      await expectLater(
        bloc.stream,
        emits(
          isA<TestimonyLoaded>().having(
            (s) => s.testimonies.isEmpty,
            'isEmpty',
            true,
          ),
        ),
      );
    });

    test('Testimony model tracks creation date and age correctly', () async {
      bloc.add(AddTestimony('Test testimony'));
      await bloc.stream.firstWhere((state) => state is TestimonyLoaded);

      final state = bloc.state as TestimonyLoaded;
      final testimony = state.testimonies[0];

      // Verify creation date is recent (within last second)
      final now = DateTime.now();
      final diff = now.difference(testimony.createdDate);
      expect(diff.inSeconds, lessThan(2));

      // Verify daysOld is 0 for newly created testimony
      expect(testimony.daysOld, equals(0));
    });

    test('Multiple testimonies are sorted correctly by date', () async {
      // Add testimonies with small delays to ensure different timestamps
      bloc.add(AddTestimony('Oldest testimony'));
      await bloc.stream.firstWhere((state) => state is TestimonyLoaded);

      await Future.delayed(const Duration(milliseconds: 10));
      bloc.add(AddTestimony('Middle testimony'));
      await bloc.stream.firstWhere(
        (state) => state is TestimonyLoaded && state.testimonies.length == 2,
      );

      await Future.delayed(const Duration(milliseconds: 10));
      bloc.add(AddTestimony('Newest testimony'));
      await bloc.stream.firstWhere(
        (state) => state is TestimonyLoaded && state.testimonies.length == 3,
      );

      final state = bloc.state as TestimonyLoaded;

      // Verify newest is first
      expect(state.testimonies[0].text, equals('Newest testimony'));
      expect(state.testimonies[1].text, equals('Middle testimony'));
      expect(state.testimonies[2].text, equals('Oldest testimony'));

      // Verify creation dates are in descending order
      expect(
        state.testimonies[0].createdDate.isAfter(
          state.testimonies[1].createdDate,
        ),
        isTrue,
      );
      expect(
        state.testimonies[1].createdDate.isAfter(
          state.testimonies[2].createdDate,
        ),
        isTrue,
      );
    });
  });
}
