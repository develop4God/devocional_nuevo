@Tags(['unit', 'widgets', 'notes'])
library;

import 'package:devocional_nuevo/blocs/bible_note_bloc.dart';
import 'package:devocional_nuevo/blocs/bible_note_event.dart';
import 'package:devocional_nuevo/models/bible_note.dart';
import 'package:devocional_nuevo/providers/devocional_provider.dart';
import 'package:devocional_nuevo/repositories/i_bible_notes_repository.dart';
import 'package:devocional_nuevo/services/localization_service.dart';
import 'package:devocional_nuevo/services/service_locator.dart';
import 'package:devocional_nuevo/widgets/bible/bible_note_modal.dart';
import 'package:devocional_nuevo/widgets/bible/bible_note_viewer.dart';
import 'package:devocional_nuevo/widgets/bible/bible_notes_list_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import '../../helpers/test_helpers.dart';

class FakeLocalizationService extends LocalizationService {
  @override
  String translate(String key, [Map<String, dynamic>? params]) => key;
}

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

  setUp(() async {
    await registerTestServices();
    ServiceLocator().unregister<LocalizationService>();
    ServiceLocator().registerSingleton<LocalizationService>(
      FakeLocalizationService(),
    );
  });

  tearDown(() async {
    await bloc.close();
    ServiceLocator().reset();
  });

  Widget wrapWithProvider(Widget child) {
    return ChangeNotifierProvider<DevocionalProvider>(
      create: (_) => DevocionalProvider(enableAudio: false),
      child: child,
    );
  }

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
        wrapWithProvider(
          BlocProvider.value(
            value: bloc,
            child: const MaterialApp(
              home: Scaffold(body: BibleNotesListView()),
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
      expect(find.textContaining('Mateo'), findsNothing);

      final newerFinder = tester.getTopLeft(find.text('Newer note'));
      final olderFinder = tester.getTopLeft(find.text('Older note'));
      expect(newerFinder.dy, lessThan(olderFinder.dy));
    },
  );

  testWidgets('tapping the note icon opens the read-only viewer for that note',
      (
    tester,
  ) async {
    final note = BibleNote(
      bookName: 'Juan',
      chapter: 3,
      startVerse: 16,
      endVerse: 16,
      text: 'Existing reflection',
      lastModifiedDate: DateTime(2026, 1, 1),
    );

    bloc = BibleNoteBloc(
      bibleNotesRepository: FakeBibleNotesRepository([note]),
    );

    await tester.pumpWidget(
      wrapWithProvider(
        BlocProvider.value(
          value: bloc,
          child: const MaterialApp(
            home: Scaffold(body: BibleNotesListView()),
          ),
        ),
      ),
    );
    bloc.add(LoadBibleNotes());
    await tester.pump();
    await tester.pump();

    await tester.tap(find.byIcon(Icons.chat_bubble));
    await tester.pumpAndSettle();

    expect(find.byType(BibleNoteViewer), findsOneWidget);
    expect(find.byType(BibleNoteModal), findsNothing);
    expect(
      find.descendant(
        of: find.byType(BibleNoteViewer),
        matching: find.text('Existing reflection'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('tapping edit in the viewer opens the note editor for that note',
      (
    tester,
  ) async {
    final note = BibleNote(
      bookName: 'Juan',
      chapter: 3,
      startVerse: 16,
      endVerse: 16,
      text: 'Existing reflection',
      lastModifiedDate: DateTime(2026, 1, 1),
    );

    bloc = BibleNoteBloc(
      bibleNotesRepository: FakeBibleNotesRepository([note]),
    );

    await tester.pumpWidget(
      wrapWithProvider(
        BlocProvider.value(
          value: bloc,
          child: const MaterialApp(
            home: Scaffold(body: BibleNotesListView()),
          ),
        ),
      ),
    );
    bloc.add(LoadBibleNotes());
    await tester.pump();
    await tester.pump();

    await tester.tap(find.byIcon(Icons.chat_bubble));
    await tester.pumpAndSettle();

    await tester.tap(find.text('notes.edit'));
    await tester.pumpAndSettle();

    expect(find.byType(BibleNoteModal), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(BibleNoteModal),
        matching: find.text('Existing reflection'),
      ),
      findsOneWidget,
    );
  });
}
