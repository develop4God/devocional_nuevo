@Tags(['unit', 'widgets'])
library;

import 'package:devocional_nuevo/blocs/bible_note_bloc.dart';
import 'package:devocional_nuevo/blocs/bible_note_event.dart';
import 'package:devocional_nuevo/models/bible_note.dart';
import 'package:devocional_nuevo/repositories/i_bible_notes_repository.dart';
import 'package:devocional_nuevo/widgets/bible/bible_notes_list_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeBibleNotesRepository implements IBibleNotesRepository {
  final List<BibleNote> notes;

  FakeBibleNotesRepository(this.notes);

  @override
  Future<void> deleteNote(String noteId) async {}

  @override
  Future<List<BibleNote>> loadNotes() async => notes;

  @override
  Future<void> saveNote(BibleNote note) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late BibleNoteBloc bloc;

  tearDown(() async {
    await bloc.close();
  });

  testWidgets(
    'filters blank notes and sorts remaining notes by most recent first',
    (tester) async {
      final older = BibleNote(
        bookName: 'Juan',
        chapter: 3,
        startVerse: 16,
        endVerse: 16,
        text: 'Older note',
        lastModifiedDate: DateTime(2026, 1, 1),
      );
      final newer = BibleNote(
        bookName: 'Salmos',
        chapter: 23,
        startVerse: 1,
        endVerse: 1,
        text: 'Newer note',
        lastModifiedDate: DateTime(2026, 6, 1),
      );
      final blank = BibleNote(
        bookName: 'Mateo',
        chapter: 5,
        startVerse: 3,
        endVerse: 3,
        text: '   ',
        lastModifiedDate: DateTime(2026, 7, 1),
      );

      bloc = BibleNoteBloc(
        bibleNotesRepository: FakeBibleNotesRepository([older, newer, blank]),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BlocProvider.value(
              value: bloc,
              child: const BibleNotesListView(),
            ),
          ),
        ),
      );
      bloc.add(LoadBibleNotes());
      await tester.pump();
      await tester.pump();

      expect(find.text('Newer note'), findsOneWidget);
      expect(find.text('Older note'), findsOneWidget);
      expect(find.text('   '), findsNothing);

      final newerFinder = tester.getTopLeft(find.text('Newer note'));
      final olderFinder = tester.getTopLeft(find.text('Older note'));
      expect(newerFinder.dy, lessThan(olderFinder.dy));
    },
  );
}
