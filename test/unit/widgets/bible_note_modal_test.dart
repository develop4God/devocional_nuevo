@Tags(['unit', 'widgets', 'notes'])
library;

import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:devocional_nuevo/blocs/bible_note_bloc.dart';
import 'package:devocional_nuevo/blocs/bible_note_event.dart';
import 'package:devocional_nuevo/blocs/bible_note_state.dart';
import 'package:devocional_nuevo/models/bible_note.dart';
import 'package:devocional_nuevo/repositories/i_bible_notes_repository.dart';
import 'package:devocional_nuevo/services/localization_service.dart';
import 'package:devocional_nuevo/services/service_locator.dart';
import 'package:devocional_nuevo/widgets/bible/bible_note_modal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class FakeLocalizationService extends LocalizationService {
  @override
  String translate(String key, [Map<String, dynamic>? params]) => key;
}

class MockBibleNoteBloc extends MockBloc<BibleNoteEvent, BibleNoteState>
    implements BibleNoteBloc {}

class FakeBibleNoteEvent extends Fake implements BibleNoteEvent {}

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

  setUpAll(() {
    registerFallbackValue(FakeBibleNoteEvent());
  });

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

    Widget buildWidget({String? initialNote, BibleNoteBloc? bloc}) {
      return MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                builder: (_) => BlocProvider.value(
                  value: bloc ?? bibleNoteBloc,
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
              child: const Text('open'),
            ),
          ),
        ),
      );
    }

    Future<void> openModal(WidgetTester tester) async {
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();
    }

    testWidgets('rejects notes shorter than 10 trimmed characters', (
      tester,
    ) async {
      await tester.pumpWidget(buildWidget());
      await openModal(tester);

      await tester.enterText(find.byType(TextField), ' short ');
      await tester.tap(find.byType(ElevatedButton).last);
      await tester.pump();

      expect(find.text('notes.note_min_length_error'), findsOneWidget);
      expect(repository.saveCalls, 0);
    });

    testWidgets('saves a valid note through the BibleNoteBloc', (
      tester,
    ) async {
      await tester.pumpWidget(buildWidget());
      await openModal(tester);

      await tester.enterText(
        find.byType(TextField),
        'A reflection long enough',
      );
      await tester.tap(find.byType(ElevatedButton).last);
      await tester.pump();

      expect(repository.saveCalls, 1);
    });

    testWidgets('deletes the note when confirmed', (tester) async {
      await tester.pumpWidget(buildWidget(initialNote: 'Existing note'));
      await openModal(tester);

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();
      await tester.tap(find.text('app.delete'));
      await tester.pump();

      expect(repository.deleteCalls, 1);
    });

    testWidgets('shows the "added" message when saving a brand-new note', (
      tester,
    ) async {
      final mockBloc = MockBibleNoteBloc();
      final stateController = StreamController<BibleNoteState>.broadcast();
      whenListen(
        mockBloc,
        stateController.stream,
        initialState: BibleNoteInitial(),
      );
      when(() => mockBloc.add(any())).thenAnswer((_) {});

      await tester.pumpWidget(buildWidget(bloc: mockBloc));
      await openModal(tester);

      await tester.enterText(
        find.byType(TextField),
        'A reflection long enough',
      );
      await tester.tap(find.byType(ElevatedButton).last);
      await tester.pump();

      stateController.add(BibleNoteLoaded(notes: const []));
      await tester.pump();

      expect(find.text('notes.added_message'), findsOneWidget);
      expect(find.text('notes.saved_message'), findsNothing);

      await stateController.close();
    });

    testWidgets('shows the "saved" message when editing an existing note', (
      tester,
    ) async {
      final mockBloc = MockBibleNoteBloc();
      final stateController = StreamController<BibleNoteState>.broadcast();
      whenListen(
        mockBloc,
        stateController.stream,
        initialState: BibleNoteInitial(),
      );
      when(() => mockBloc.add(any())).thenAnswer((_) {});

      await tester.pumpWidget(
        buildWidget(initialNote: 'Existing note', bloc: mockBloc),
      );
      await openModal(tester);

      await tester.enterText(
        find.byType(TextField),
        'This note has been edited',
      );
      await tester.tap(find.byType(ElevatedButton).last);
      await tester.pump();

      stateController.add(BibleNoteLoaded(notes: const []));
      await tester.pump();

      expect(find.text('notes.saved_message'), findsOneWidget);
      expect(find.text('notes.added_message'), findsNothing);

      await stateController.close();
    });
  });
}
