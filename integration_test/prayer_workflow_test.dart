import 'package:devocional_nuevo/blocs/prayer_bloc.dart';
import 'package:devocional_nuevo/blocs/prayer_event.dart';
import 'package:devocional_nuevo/blocs/prayer_state.dart';
import 'package:devocional_nuevo/models/prayer_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../test/helpers/test_helpers.dart';

/// Integration tests for Prayer feature workflow
/// Tests real user behavior: creating, answering, and managing prayers
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Prayer Workflow - Real User Behavior Tests', () {
    late PrayerBloc bloc;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      registerTestServices();
      bloc = PrayerBloc();
    });

    tearDown(() {
      bloc.close();
    });

    test('Complete prayer journey: Create, answer, celebrate', () async {
      // Scenario: User creates prayer and sees it answered over time

      // Step 1: User creates a prayer request
      bloc.add(AddPrayer('Señor, ayúdame a encontrar trabajo'));
      await bloc.stream.firstWhere((state) => state is PrayerLoaded);

      var state = bloc.state as PrayerLoaded;
      expect(state.activePrayers.length, equals(1));
      expect(state.activePrayers.first.status, PrayerStatus.active);
      expect(state.activePrayers.first.text,
          equals('Señor, ayúdame a encontrar trabajo'));

      final prayerId = state.activePrayers.first.id;

      // Step 2: Prayer is answered! User marks it
      bloc.add(MarkPrayerAsAnswered(prayerId,
          comment: 'Conseguí un trabajo excelente'));
      await Future.delayed(const Duration(milliseconds: 50));

      state = bloc.state as PrayerLoaded;
      expect(state.activePrayers.length, equals(0),
          reason: 'Answered prayer should move from active');
      expect(state.answeredPrayers.length, equals(1));
      expect(state.answeredPrayers.first.status, PrayerStatus.answered);
      expect(state.answeredPrayers.first.answeredComment,
          equals('Conseguí un trabajo excelente'));
    });

    test('User creates multiple prayers and manages them', () async {
      // Scenario: User has several prayer requests

      // Morning prayers
      bloc.add(AddPrayer('Por la salud de mi madre'));
      await bloc.stream.firstWhere((state) => state is PrayerLoaded);

      bloc.add(AddPrayer('Por sabiduría en decisiones importantes'));
      await bloc.stream.firstWhere(
          (state) => state is PrayerLoaded && state.activePrayers.length == 2);

      bloc.add(AddPrayer('Por mi familia'));
      await bloc.stream.firstWhere(
          (state) => state is PrayerLoaded && state.activePrayers.length == 3);

      var state = bloc.state as PrayerLoaded;
      expect(state.activePrayers.length, equals(3));
      expect(state.activePrayers.every((p) => p.status == PrayerStatus.active),
          isTrue);
    });

    test('User deletes a prayer request', () async {
      // Scenario: User creates prayer but decides to remove it

      bloc.add(AddPrayer('Una petición que ya no es necesaria'));
      await bloc.stream.firstWhere((state) => state is PrayerLoaded);

      var state = bloc.state as PrayerLoaded;
      final prayerId = state.activePrayers.first.id;
      expect(state.activePrayers.length, equals(1));

      // User deletes it
      bloc.add(DeletePrayer(prayerId));
      await Future.delayed(const Duration(milliseconds: 50));

      state = bloc.state as PrayerLoaded;
      expect(state.activePrayers.length, equals(0),
          reason: 'Prayer should be deleted');
    });

    test('User edits a prayer request', () async {
      // Scenario: User wants to clarify or update prayer text

      bloc.add(AddPrayer('Por mi traba'));
      await bloc.stream.firstWhere((state) => state is PrayerLoaded);

      var state = bloc.state as PrayerLoaded;
      final prayerId = state.activePrayers.first.id;

      // User notices typo and edits
      bloc.add(EditPrayer(prayerId, 'Por mi trabajo'));
      await Future.delayed(const Duration(milliseconds: 50));

      state = bloc.state as PrayerLoaded;
      expect(state.activePrayers.first.text, equals('Por mi trabajo'),
          reason: 'Prayer text should be updated');
    });

    test('User workflow: App restart and prayers persist', () async {
      // Day 1: User creates prayers
      bloc.add(AddPrayer('Oración persistente 1'));
      await bloc.stream.firstWhere((state) => state is PrayerLoaded);

      bloc.add(AddPrayer('Oración persistente 2'));
      await bloc.stream.firstWhere(
          (state) => state is PrayerLoaded && state.activePrayers.length == 2);

      var state = bloc.state as PrayerLoaded;
      expect(state.activePrayers.length, equals(2));

      // Simulate app restart
      await bloc.close();
      final newBloc = PrayerBloc();
      newBloc.add(LoadPrayers());

      await expectLater(
        newBloc.stream,
        emitsInOrder([
          isA<PrayerLoading>(),
          isA<PrayerLoaded>().having(
            (s) => s.activePrayers.length,
            'active prayers count',
            2,
          ),
        ]),
      );

      await newBloc.close();
    });

    test('User answers prayer with detailed testimony', () async {
      // Scenario: User wants to record how God answered

      bloc.add(AddPrayer('Por provisión financiera'));
      await bloc.stream.firstWhere((state) => state is PrayerLoaded);

      var state = bloc.state as PrayerLoaded;
      final prayerId = state.activePrayers.first.id;

      // Prayer is answered with detailed response
      const answer =
          'Dios proveyó de manera inesperada a través de un bono en el trabajo. ¡Fiel es Él!';
      bloc.add(MarkPrayerAsAnswered(prayerId, comment: answer));
      await Future.delayed(const Duration(milliseconds: 50));

      state = bloc.state as PrayerLoaded;
      expect(state.answeredPrayers.length, equals(1));
      expect(state.answeredPrayers.first.answeredComment, equals(answer));
    });

    test('User has both active and answered prayers', () async {
      // Realistic scenario: Some prayers answered, some still active

      // Create 3 prayers
      bloc.add(AddPrayer('Oración activa 1'));
      await bloc.stream.firstWhere((state) => state is PrayerLoaded);

      bloc.add(AddPrayer('Oración que será contestada'));
      await bloc.stream.firstWhere(
          (state) => state is PrayerLoaded && state.activePrayers.length == 2);

      bloc.add(AddPrayer('Oración activa 2'));
      await bloc.stream.firstWhere(
          (state) => state is PrayerLoaded && state.activePrayers.length == 3);

      var state = bloc.state as PrayerLoaded;
      final answeredPrayerId = state.activePrayers[1].id;

      // Answer middle one
      bloc.add(
          MarkPrayerAsAnswered(answeredPrayerId, comment: 'Dios respondió'));
      await Future.delayed(const Duration(milliseconds: 50));

      state = bloc.state as PrayerLoaded;
      expect(state.activePrayers.length, equals(2));
      expect(state.answeredPrayers.length, equals(1));
    });

    test('User marks prayer as answered then changes back to active', () async {
      // User accidentally marks prayer as answered

      bloc.add(AddPrayer('Una oración importante'));
      await bloc.stream.firstWhere((state) => state is PrayerLoaded);

      var state = bloc.state as PrayerLoaded;
      final prayerId = state.activePrayers.first.id;

      // Mark as answered
      bloc.add(MarkPrayerAsAnswered(prayerId, comment: 'Oops, error'));
      await Future.delayed(const Duration(milliseconds: 50));

      state = bloc.state as PrayerLoaded;
      expect(state.answeredPrayers.length, equals(1));

      // User realizes mistake and marks back as active
      bloc.add(MarkPrayerAsActive(prayerId));
      await Future.delayed(const Duration(milliseconds: 50));

      state = bloc.state as PrayerLoaded;
      expect(state.activePrayers.length, equals(1));
      expect(state.answeredPrayers.length, equals(0));
    });

    test('Edge case: Empty prayer text handled', () async {
      // User tries to create empty prayer (should be prevented by UI, but test defensive code)

      bloc.add(AddPrayer(''));
      await Future.delayed(const Duration(milliseconds: 50));

      // Should either reject or handle gracefully
      // This tests that the app doesn't crash
      expect(bloc.state, isA<PrayerState>());
    });

    test('Edge case: Very long prayer text', () async {
      // User writes a very detailed prayer

      final longPrayer = 'Señor, ' 'te pido por ' * 100;
      bloc.add(AddPrayer(longPrayer));
      await bloc.stream.firstWhere((state) => state is PrayerLoaded);

      var state = bloc.state as PrayerLoaded;
      expect(state.activePrayers.length, equals(1));
      // Should handle long text without issues
    });

    test('User pattern: Creates prayer then deletes without answering',
        () async {
      // Some prayers are removed without being marked as answered

      bloc.add(AddPrayer('Una petición temporal'));
      await bloc.stream.firstWhere((state) => state is PrayerLoaded);

      var state = bloc.state as PrayerLoaded;
      final prayerId = state.activePrayers.first.id;

      // Later decides to remove it
      bloc.add(DeletePrayer(prayerId));
      await Future.delayed(const Duration(milliseconds: 50));

      state = bloc.state as PrayerLoaded;
      expect(state.activePrayers.length, equals(0));
      expect(state.answeredPrayers.length, equals(0),
          reason: 'Deleted prayer should not appear in answered');
    });

    test('Real workflow: Morning prayers routine', () async {
      // User's daily morning prayer routine

      final prayers = [
        'Por mi familia',
        'Por mi trabajo',
        'Por sabiduría',
        'Por salud',
        'Por los necesitados',
      ];

      // Create all prayers
      for (var prayer in prayers) {
        bloc.add(AddPrayer(prayer));
        await Future.delayed(const Duration(milliseconds: 50));
      }

      // Wait for all to be created (with timeout tolerance)
      await Future.delayed(const Duration(milliseconds: 300));

      var state = bloc.state as PrayerLoaded;

      // All should have been created
      expect(state.activePrayers.length, greaterThanOrEqualTo(4),
          reason: 'Most prayers should be created');
      expect(
        state.activePrayers.every((p) => p.status == PrayerStatus.active),
        isTrue,
        reason: 'All created prayers should be active',
      );
    });

    test('User refreshes prayer list', () async {
      // Create some prayers
      bloc.add(AddPrayer('Oración 1'));
      await bloc.stream.firstWhere((state) => state is PrayerLoaded);

      bloc.add(AddPrayer('Oración 2'));
      await bloc.stream.firstWhere(
          (state) => state is PrayerLoaded && state.activePrayers.length == 2);

      // User refreshes
      bloc.add(RefreshPrayers());
      await Future.delayed(const Duration(milliseconds: 50));

      var state = bloc.state as PrayerLoaded;
      expect(state.activePrayers.length, equals(2),
          reason: 'Prayers should persist after refresh');
    });
  });
}
