@Tags(['unit', 'widgets', 'notes'])
library;

import 'package:devocional_nuevo/blocs/note_bloc.dart';
import 'package:devocional_nuevo/models/devocional_model.dart';
import 'package:devocional_nuevo/models/devotional_note.dart';
import 'package:devocional_nuevo/repositories/i_notes_repository.dart';
import 'package:devocional_nuevo/widgets/devotional_note_viewer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/test_helpers.dart';

class FakeNotesRepository implements INotesRepository {
  final List<DevotionalNote> notes;
  String? deletedDevocionalId;

  FakeNotesRepository({List<DevotionalNote>? initialNotes})
      : notes = List.of(initialNotes ?? []);

  @override
  Future<List<DevotionalNote>> loadNotes() async => List.of(notes);

  @override
  Future<void> saveNote(DevotionalNote note) async {
    notes.removeWhere((n) => n.devocionalId == note.devocionalId);
    notes.add(note);
  }

  @override
  Future<void> deleteNote(String devocionalId) async {
    deletedDevocionalId = devocionalId;
    notes.removeWhere((n) => n.devocionalId == devocionalId);
  }
}

void main() {
  late FakeNotesRepository repository;
  late NoteBloc noteBloc;
  late Devocional devocional;

  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await registerTestServices();

    devocional = Devocional(
      id: 'dev-1',
      versiculo: 'Juan 3:16',
      reflexion: 'Reflexión',
      paraMeditar: const [],
      oracion: 'Oración',
      date: DateTime(2026, 1, 1),
    );
    repository = FakeNotesRepository(
      initialNotes: [
        DevotionalNote(
          devocionalId: 'dev-1',
          text: 'My saved note',
          lastModifiedDate: DateTime(2026, 1, 1),
        ),
      ],
    );
    noteBloc = NoteBloc(notesRepository: repository);
  });

  tearDown(() {
    noteBloc.close();
  });

  Future<void> pumpViewer(
    WidgetTester tester, {
    required VoidCallback onEdit,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<NoteBloc>.value(
          value: noteBloc,
          child: Scaffold(
            body: DevotionalNoteViewer(
              devocional: devocional,
              note: 'My saved note',
              onEdit: onEdit,
            ),
          ),
        ),
      ),
    );
  }

  group('DevotionalNoteViewer', () {
    testWidgets('displays the note text and title', (tester) async {
      await pumpViewer(tester, onEdit: () {});
      await tester.pumpAndSettle();

      expect(find.text('My saved note'), findsOneWidget);
      expect(find.text('notes.title'), findsOneWidget);
    });

    testWidgets('tapping the edit icon closes the sheet and calls onEdit', (
      tester,
    ) async {
      var editCalled = false;
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<NoteBloc>.value(
            value: noteBloc,
            child: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => showModalBottomSheet(
                    context: context,
                    builder: (_) => DevotionalNoteViewer(
                      devocional: devocional,
                      note: 'My saved note',
                      onEdit: () => editCalled = true,
                    ),
                  ),
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.edit_rounded));
      await tester.pumpAndSettle();

      expect(editCalled, isTrue);
      expect(find.text('My saved note'), findsNothing);
    });

    testWidgets('tapping delete shows a confirmation dialog', (tester) async {
      await pumpViewer(tester, onEdit: () {});
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();

      expect(find.text('notes.delete_confirmation'), findsOneWidget);
      expect(find.text('app.delete'), findsOneWidget);
      expect(find.text('notes.cancel'), findsOneWidget);
    });

    testWidgets('cancelling the delete confirmation keeps the note', (
      tester,
    ) async {
      await pumpViewer(tester, onEdit: () {});
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();
      await tester.tap(find.text('notes.cancel'));
      await tester.pumpAndSettle();

      expect(find.text('My saved note'), findsOneWidget);
      expect(repository.deletedDevocionalId, isNull);
    });

    testWidgets(
      'confirming delete removes the note through the repository',
      (tester) async {
        await pumpViewer(tester, onEdit: () {});
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.delete_outline));
        await tester.pumpAndSettle();
        await tester.tap(find.text('app.delete'));
        await tester.pumpAndSettle();

        expect(repository.deletedDevocionalId, 'dev-1');
      },
    );

    testWidgets('closing via the close icon dismisses without deleting', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<NoteBloc>.value(
            value: noteBloc,
            child: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => showModalBottomSheet(
                    context: context,
                    builder: (_) => DevotionalNoteViewer(
                      devocional: devocional,
                      note: 'My saved note',
                      onEdit: () {},
                    ),
                  ),
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(find.text('My saved note'), findsNothing);
      expect(repository.deletedDevocionalId, isNull);
    });
  });
}
