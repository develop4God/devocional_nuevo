@Tags(['unit', 'widgets'])
library;

import 'package:devocional_nuevo/blocs/bible_note_bloc.dart';
import 'package:devocional_nuevo/models/bible_note.dart';
import 'package:devocional_nuevo/repositories/i_bible_notes_repository.dart';
import 'package:devocional_nuevo/services/localization_service.dart';
import 'package:devocional_nuevo/services/service_locator.dart';
import 'package:devocional_nuevo/widgets/bible/bible_note_modal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeLocalizationService extends LocalizationService {
  @override
  String translate(String key, [Map<String, dynamic>? params]) => key;
}

class FakeBibleNotesRepository implements IBibleNotesRepository {
  int saveCalls = 0;
  int deleteCalls = 0;

  @override
  Future<void> deleteNote(String noteId) async {
    deleteCalls++;
  }

  @override
  Future<List<BibleNote>> loadNotes() async => [];

  @override
  Future<void> saveNote(BibleNote note) async {
    saveCalls++;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('BibleNoteModal', () {
    late FakeBibleNotesRepository repository;
    late BibleNoteBloc bibleNoteBloc;

    setUp(() {
      ServiceLocator().reset();
      ServiceLocator().registerSingleton<LocalizationService>(
        FakeLocalizationService(),
      );
      repository = FakeBibleNotesRepository();
      bibleNoteBloc = BibleNoteBloc(bibleNotesRepository: repository);
    });

    tearDown(() async {
      await bibleNoteBloc.close();
      ServiceLocator().reset();
    });

    Widget buildWidget({String? initialNote}) {
      return MaterialApp(
        home: Scaffold(
          body: BlocProvider.value(
            value: bibleNoteBloc,
            child: BibleNoteModal(
              bookName: 'Juan',
              chapter: 3,
              startVerse: 16,
              endVerse: 16,
              referenceLabel: 'Juan 3:16',
              initialNote: initialNote,
            ),
          ),
        ),
      );
    }

    testWidgets('rejects notes shorter than 10 trimmed characters', (
      tester,
    ) async {
      await tester.pumpWidget(buildWidget());

      await tester.enterText(find.byType(TextField), ' short ');
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      expect(find.text('notes.note_min_length_error'), findsOneWidget);
      expect(repository.saveCalls, 0);
    });

    testWidgets('saves a valid note through the BibleNoteBloc', (
      tester,
    ) async {
      await tester.pumpWidget(buildWidget());

      await tester.enterText(
        find.byType(TextField),
        'A reflection long enough',
      );
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      expect(repository.saveCalls, 1);
    });

    testWidgets('deletes the note when confirmed', (tester) async {
      await tester.pumpWidget(buildWidget(initialNote: 'Existing note'));

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();
      await tester.tap(find.text('app.delete'));
      await tester.pump();

      expect(repository.deleteCalls, 1);
    });
  });
}
