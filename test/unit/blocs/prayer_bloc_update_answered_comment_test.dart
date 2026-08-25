@Tags(['unit', 'blocs'])
library;

// test/unit/blocs/prayer_bloc_update_answered_comment_test.dart

import 'dart:convert';

import 'package:devocional_nuevo/blocs/prayer_bloc.dart';
import 'package:devocional_nuevo/blocs/prayer_event.dart';
import 'package:devocional_nuevo/blocs/prayer_state.dart';
import 'package:devocional_nuevo/models/prayer_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/test_helpers.dart';

void main() {
  group('PrayerBloc - UpdateAnsweredComment handler', () {
    setUp(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      await registerTestServices();
    });

    Prayer answeredPrayer({String? answeredComment}) {
      final now = DateTime(2026, 1, 1);
      return Prayer(
        id: 'prayer-1',
        text: 'Sample prayer',
        createdDate: now,
        status: PrayerStatus.answered,
        answeredDate: now,
        answeredComment: answeredComment,
      );
    }

    test('sets a new answered comment on the matching prayer', () async {
      final prayer = answeredPrayer(answeredComment: 'Old comment');
      SharedPreferences.setMockInitialValues({
        'prayers': json.encode([prayer.toJson()]),
      });

      final bloc = PrayerBloc(statsService: FakeSpiritualStatsService());
      bloc.add(LoadPrayers());
      await bloc.stream.firstWhere((state) => state is PrayerLoaded);

      bloc.add(UpdateAnsweredComment('prayer-1', comment: 'Updated comment'));
      final loaded = await bloc.stream.firstWhere(
        (state) => state is PrayerLoaded,
      ) as PrayerLoaded;

      expect(loaded.prayers.first.answeredComment, 'Updated comment');
    });

    test('a null comment clears an existing answered comment', () async {
      // Regression test: PrayerBloc._onUpdateAnsweredComment used to call
      // prayer.copyWith(answeredComment: event.comment) without
      // clearAnsweredComment, so Prayer.copyWith's `?? this.answeredComment`
      // fallback silently kept the old comment instead of clearing it —
      // the "clear comment" path of EditAnsweredCommentModal was a no-op.
      final prayer = answeredPrayer(answeredComment: 'Old comment');
      SharedPreferences.setMockInitialValues({
        'prayers': json.encode([prayer.toJson()]),
      });

      final bloc = PrayerBloc(statsService: FakeSpiritualStatsService());
      bloc.add(LoadPrayers());
      await bloc.stream.firstWhere((state) => state is PrayerLoaded);

      bloc.add(UpdateAnsweredComment('prayer-1', comment: null));
      final loaded = await bloc.stream.firstWhere(
        (state) => state is PrayerLoaded,
      ) as PrayerLoaded;

      expect(loaded.prayers.first.answeredComment, isNull);
    });
  });

  group('PrayerBloc - UpdateAnsweredComment Event', () {
    test('UpdateAnsweredComment event should exist and be callable', () {
      // Arrange & Act
      final event = UpdateAnsweredComment('test-id', comment: 'Test comment');

      // Assert
      expect(event, isA<PrayerEvent>());
      expect(event.prayerId, equals('test-id'));
      expect(event.comment, equals('Test comment'));
    });

    test('UpdateAnsweredComment with null comment should work', () {
      // Arrange & Act
      final event = UpdateAnsweredComment('test-id', comment: null);

      // Assert
      expect(event, isA<PrayerEvent>());
      expect(event.prayerId, equals('test-id'));
      expect(event.comment, isNull);
    });

    test('UpdateAnsweredComment with empty comment should work', () {
      // Arrange & Act
      final event = UpdateAnsweredComment('test-id', comment: '');

      // Assert
      expect(event, isA<PrayerEvent>());
      expect(event.prayerId, equals('test-id'));
      expect(event.comment, equals(''));
    });
  });
}
