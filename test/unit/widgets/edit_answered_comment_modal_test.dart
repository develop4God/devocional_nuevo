@Tags(['unit', 'widgets'])
library;

// test/unit/widgets/edit_answered_comment_modal_test.dart
//
// High-value behavior tests for EditAnsweredCommentModal.
// Uses a real PrayerBloc backed by SharedPreferences mock values (same
// pattern as test/unit/widgets/answer_prayer_modal_test.dart) for read-only
// scenarios. Update-button tests use a _SpyPrayerBloc instead: the real
// UpdateAnsweredComment handler triggers a genuine async storage write
// (SharedPreferences + file I/O) that this widget harness can't reliably
// await — pumpAndSettle's frame-based settling doesn't consistently outlast
// it. That save behavior (including the clearAnsweredComment fix) is
// covered directly at the bloc level in prayer_bloc_test.dart; here we only
// assert the modal dispatches the right event and closes.

import 'dart:convert';

import 'package:devocional_nuevo/blocs/prayer_bloc.dart';
import 'package:devocional_nuevo/blocs/prayer_event.dart';
import 'package:devocional_nuevo/blocs/prayer_state.dart';
import 'package:devocional_nuevo/extensions/string_extensions.dart';
import 'package:devocional_nuevo/models/prayer_model.dart';
import 'package:devocional_nuevo/widgets/edit_answered_comment_modal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/test_helpers.dart';

/// Records dispatched events without running their storage side effects,
/// so tests can assert what the modal sends the bloc without racing real
/// file I/O.
class _SpyPrayerBloc extends PrayerBloc {
  _SpyPrayerBloc({required super.statsService});

  final List<PrayerEvent> dispatched = [];

  @override
  void add(PrayerEvent event) {
    dispatched.add(event);
    super.add(event);
  }
}

void main() {
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

  Future<PrayerBloc> pumpModal(
    WidgetTester tester, {
    required Prayer prayer,
  }) async {
    SharedPreferences.setMockInitialValues({
      'prayers': json.encode([prayer.toJson()]),
    });

    final bloc = PrayerBloc(statsService: FakeSpiritualStatsService());
    bloc.add(LoadPrayers());
    await bloc.stream.firstWhere((state) => state is PrayerLoaded);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BlocProvider<PrayerBloc>.value(
            value: bloc,
            child: EditAnsweredCommentModal(prayer: prayer),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return bloc;
  }

  /// Pumps the modal with a [_SpyPrayerBloc] so update-button tests can
  /// assert what gets dispatched without racing the real storage write
  /// PrayerBloc triggers on UpdateAnsweredComment (SharedPreferences + file
  /// I/O — a real async gap this widget harness can't reliably await; that
  /// save behavior is covered directly at the bloc level instead).
  Future<_SpyPrayerBloc> pumpModalWithSpy(
    WidgetTester tester, {
    required Prayer prayer,
  }) async {
    SharedPreferences.setMockInitialValues({
      'prayers': json.encode([prayer.toJson()]),
    });

    final bloc = _SpyPrayerBloc(statsService: FakeSpiritualStatsService());
    bloc.add(LoadPrayers());
    await bloc.stream.firstWhere((state) => state is PrayerLoaded);
    bloc.dispatched.clear();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BlocProvider<PrayerBloc>.value(
            value: bloc,
            child: EditAnsweredCommentModal(prayer: prayer),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return bloc;
  }

  testWidgets('pre-fills the text field with the existing answered comment',
      (tester) async {
    await pumpModal(
      tester,
      prayer: answeredPrayer(answeredComment: 'God answered this prayer'),
    );

    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller!.text, 'God answered this prayer');
  });

  testWidgets('shows an empty field when there is no existing comment',
      (tester) async {
    await pumpModal(tester, prayer: answeredPrayer());

    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller!.text, isEmpty);
  });

  testWidgets('caps input at 400 characters', (tester) async {
    await pumpModal(tester, prayer: answeredPrayer());

    final finder = find.byType(TextField);
    final long450 = List.filled(450, 'a').join();
    await tester.enterText(finder, long450);
    await tester.pump();

    final field = tester.widget<TextField>(finder);
    expect(field.controller!.text.length, 400);
    expect(find.text('400/400'), findsOneWidget);
  });

  testWidgets(
      'tapping update sends the edited comment to the bloc and closes the modal',
      (tester) async {
    final prayer = answeredPrayer(answeredComment: 'Old comment');
    final bloc = await pumpModalWithSpy(tester, prayer: prayer);

    await tester.enterText(find.byType(TextField), 'Updated comment');
    await tester.pump();

    await tester.tap(find.text('prayer.update_prayer'.tr()));
    await tester.pumpAndSettle();

    expect(find.byType(EditAnsweredCommentModal), findsNothing);
    final event = bloc.dispatched.single as UpdateAnsweredComment;
    expect(event.prayerId, 'prayer-1');
    expect(event.comment, 'Updated comment');
  });

  testWidgets(
      'clearing the field and tapping update sends a null comment to the bloc',
      (tester) async {
    final prayer = answeredPrayer(answeredComment: 'Old comment');
    final bloc = await pumpModalWithSpy(tester, prayer: prayer);

    await tester.enterText(find.byType(TextField), '');
    await tester.pump();

    await tester.tap(find.text('prayer.update_prayer'.tr()));
    await tester.pumpAndSettle();

    expect(find.byType(EditAnsweredCommentModal), findsNothing);
    final event = bloc.dispatched.single as UpdateAnsweredComment;
    expect(event.prayerId, 'prayer-1');
    expect(event.comment, isNull);
  });

  testWidgets('cancel button closes the modal without saving', (tester) async {
    final prayer = answeredPrayer(answeredComment: 'Old comment');
    final bloc = await pumpModal(tester, prayer: prayer);

    await tester.enterText(find.byType(TextField), 'Discarded edit');
    await tester.pump();

    await tester.tap(find.text('prayer.cancel'.tr()));
    await tester.pumpAndSettle();

    expect(find.byType(EditAnsweredCommentModal), findsNothing);
    final loaded = bloc.state as PrayerLoaded;
    expect(loaded.prayers.first.answeredComment, 'Old comment');
  });

  testWidgets('close icon closes the modal without saving', (tester) async {
    final prayer = answeredPrayer(answeredComment: 'Old comment');
    final bloc = await pumpModal(tester, prayer: prayer);

    await tester.enterText(find.byType(TextField), 'Discarded edit');
    await tester.pump();

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    expect(find.byType(EditAnsweredCommentModal), findsNothing);
    final loaded = bloc.state as PrayerLoaded;
    expect(loaded.prayers.first.answeredComment, 'Old comment');
  });
}
