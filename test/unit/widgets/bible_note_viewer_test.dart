@Tags(['unit', 'widgets', 'notes'])
library;

import 'package:devocional_nuevo/blocs/bible_note_bloc.dart';
import 'package:devocional_nuevo/blocs/bible_note_event.dart';
import 'package:devocional_nuevo/blocs/bible_note_state.dart';
import 'package:devocional_nuevo/models/bible_note.dart';
import 'package:devocional_nuevo/repositories/i_bible_notes_repository.dart';
import 'package:devocional_nuevo/services/localization_service.dart';
import 'package:devocional_nuevo/services/service_locator.dart';
import 'package:devocional_nuevo/widgets/bible/bible_note_viewer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeLocalizationService extends LocalizationService {
  @override
  String translate(String key, [Map<String, dynamic>? params]) => key;
}

class FakeBibleNotesRepository implements IBibleNotesRepository {
  final Map<String, BibleNote> _notes;

  FakeBibleNotesRepository(List<BibleNote> notes)
      : _notes = {for (final note in notes) note.id: note};

  @override
  Future<void> deleteNote(String noteId) async {
    _notes.remove(noteId);
  }

  @override
  Future<List<BibleNote>> loadNotes() async => _notes.values.toList();

  @override
  Future<void> saveNote(BibleNote note) async {
    _notes[note.id] = note;
  }
}

void main() {
  late BibleNoteBloc bloc;
  late FakeBibleNotesRepository repository;

  setUp(() {
    ServiceLocator().reset();
    ServiceLocator().registerSingleton<LocalizationService>(
      FakeLocalizationService(),
    );
    repository = FakeBibleNotesRepository([
      BibleNote(
        bookName: 'Juan',
        chapter: 3,
        startVerse: 16,
        endVerse: 16,
        text: 'Existing reflection',
        lastModifiedDate: DateTime(2026, 1, 1),
      ),
    ]);
    bloc = BibleNoteBloc(bibleNotesRepository: repository)
      ..add(LoadBibleNotes());
  });

  tearDown(() async {
    await bloc.close();
    ServiceLocator().reset();
  });

  Widget wrap({required VoidCallback onEdit}) {
    return BlocProvider<BibleNoteBloc>.value(
      value: bloc,
      child: MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => BibleNoteViewer.show(
                context,
                bookName: 'Juan',
                chapter: 3,
                startVerse: 16,
                endVerse: 16,
                referenceLabel: 'Juan 3:16',
                note: 'Existing reflection',
                onEdit: onEdit,
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> openViewer(WidgetTester tester,
      {required VoidCallback onEdit}) async {
    await tester.pumpWidget(wrap(onEdit: onEdit));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('shows the reference label and note text', (tester) async {
    await openViewer(tester, onEdit: () {});

    expect(find.text('Juan 3:16'), findsOneWidget);
    expect(find.text('Existing reflection'), findsOneWidget);
  });

  testWidgets('tapping close dismisses the viewer', (tester) async {
    await openViewer(tester, onEdit: () {});

    await tester.tap(find.text('notes.close'));
    await tester.pumpAndSettle();

    expect(find.byType(BibleNoteViewer), findsNothing);
  });

  testWidgets('tapping the X icon dismisses the viewer', (tester) async {
    await openViewer(tester, onEdit: () {});

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    expect(find.byType(BibleNoteViewer), findsNothing);
  });

  testWidgets('tapping edit dismisses the viewer and invokes onEdit', (
    tester,
  ) async {
    var editTapped = false;
    await openViewer(tester, onEdit: () => editTapped = true);

    await tester.tap(find.text('notes.edit'));
    await tester.pumpAndSettle();

    expect(find.byType(BibleNoteViewer), findsNothing);
    expect(editTapped, isTrue);
  });

  testWidgets('tapping delete then cancel keeps the viewer open', (
    tester,
  ) async {
    await openViewer(tester, onEdit: () {});

    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();

    expect(find.text('notes.delete_confirmation'), findsOneWidget);

    await tester.tap(find.text('notes.cancel'));
    await tester.pumpAndSettle();

    expect(find.byType(BibleNoteViewer), findsOneWidget);
  });

  testWidgets(
    'tapping delete then confirm deletes the note and closes the viewer',
    (tester) async {
      await openViewer(tester, onEdit: () {});

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();

      final deleted = expectLater(
        bloc.stream,
        emits(
          isA<BibleNoteLoaded>().having(
            (state) => state.getNoteForVerse('Juan', 3, 16),
            'deleted note',
            isNull,
          ),
        ),
      );

      await tester.tap(find.text('app.delete'));
      await tester.pumpAndSettle();
      await deleted;

      expect(find.byType(BibleNoteViewer), findsNothing);
      expect(find.text('notes.deleted_message'), findsOneWidget);
    },
  );
}
