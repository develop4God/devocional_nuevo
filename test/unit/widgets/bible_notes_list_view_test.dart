@Tags(['unit', 'widgets'])
library;

import 'package:devocional_nuevo/blocs/bible_note_bloc.dart';
import 'package:devocional_nuevo/blocs/bible_note_state.dart';
import 'package:devocional_nuevo/models/bible_note.dart';
import 'package:devocional_nuevo/repositories/i_bible_notes_repository.dart';
import 'package:devocional_nuevo/widgets/bible/bible_notes_list_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeBibleNotesRepository implements IBibleNotesRepository {
  @override
  Future<void> deleteNote(String noteId) async {}

  @override
  Future<List<BibleNote>> loadNotes() async => [];

  @override
  Future<void> saveNote(BibleNote note) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'filters blank notes and sorts remaining notes by most recent first',
    (tester) async {
      final bloc = BibleNoteBloc(
        bibleNotesRepository: FakeBibleNotesRepository(),
      );

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

      bloc.emit(BibleNoteLoaded(notes: [older, newer, blank]));

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
      await tester.pump();

      expect(find.text('Newer note'), findsOneWidget);
      expect(find.text('Older note'), findsOneWidget);
      expect(find.text('   '), findsNothing);

      final newerFinder = tester.getTopLeft(find.text('Newer note'));
      final olderFinder = tester.getTopLeft(find.text('Older note'));
      expect(newerFinder.dy, lessThan(olderFinder.dy));

      await bloc.close();
    },
  );
}
