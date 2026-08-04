@Tags(['unit', 'widgets', 'notes'])
library;

import 'package:devocional_nuevo/blocs/note_bloc.dart';
import 'package:devocional_nuevo/blocs/note_event.dart';
import 'package:devocional_nuevo/models/devocional_model.dart';
import 'package:devocional_nuevo/models/devotional_note.dart';
import 'package:devocional_nuevo/repositories/i_notes_repository.dart';
import 'package:devocional_nuevo/services/localization_service.dart';
import 'package:devocional_nuevo/services/service_locator.dart';
import 'package:devocional_nuevo/widgets/devotional_note_icon_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeLocalizationService extends LocalizationService {
  @override
  String translate(String key, [Map<String, dynamic>? params]) => key;
}

class FakeNotesRepository implements INotesRepository {
  final List<DevotionalNote> initialNotes;
  FakeNotesRepository({this.initialNotes = const []});

  @override
  Future<void> deleteNote(String devocionalId) async {}

  @override
  Future<List<DevotionalNote>> loadNotes() async => initialNotes;

  @override
  Future<void> saveNote(DevotionalNote note) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final devocional = Devocional(
    id: 'devotional-1',
    versiculo: 'John 3:16',
    reflexion: 'Reflection',
    paraMeditar: const [],
    oracion: 'Prayer',
    date: DateTime(2026, 7, 29),
  );

  setUp(() {
    ServiceLocator().reset();
    ServiceLocator().registerSingleton<LocalizationService>(
      FakeLocalizationService(),
    );
  });

  tearDown(() {
    ServiceLocator().reset();
  });

  Widget buildWidget(NoteBloc noteBloc) {
    return MaterialApp(
      home: Scaffold(
        body: BlocProvider.value(
          value: noteBloc,
          child: DevotionalNoteIconButton(devocional: devocional),
        ),
      ),
    );
  }

  group('DevotionalNoteIconButton', () {
    testWidgets(
      'shows note_add_outlined and opens the editor when there is no note',
      (tester) async {
        final noteBloc = NoteBloc(notesRepository: FakeNotesRepository());
        addTearDown(noteBloc.close);
        await tester.pumpWidget(buildWidget(noteBloc));
        await tester.pump();

        expect(find.byIcon(Icons.note_add_outlined), findsOneWidget);
        expect(find.byIcon(Icons.chat_bubble), findsNothing);

        await tester.tap(find.byIcon(Icons.note_add_outlined));
        await tester.pumpAndSettle();

        // The editor modal's text field is shown directly (no viewer step).
        expect(find.byType(TextField), findsOneWidget);
      },
    );

    testWidgets(
      'shows chat_bubble and opens the viewer when a note exists',
      (tester) async {
        final noteBloc = NoteBloc(
          notesRepository: FakeNotesRepository(
            initialNotes: [
              DevotionalNote(
                devocionalId: devocional.id,
                text: 'Existing note',
                lastModifiedDate: DateTime(2026, 7, 29),
              ),
            ],
          ),
        )..add(LoadNotes());
        addTearDown(noteBloc.close);
        await tester.pumpWidget(buildWidget(noteBloc));
        await tester.pump();

        expect(find.byIcon(Icons.chat_bubble), findsOneWidget);
        expect(find.byIcon(Icons.note_add_outlined), findsNothing);

        await tester.tap(find.byIcon(Icons.chat_bubble));
        await tester.pumpAndSettle();

        // The read-only viewer is shown first, not the editable text field.
        expect(find.text('Existing note'), findsOneWidget);
        expect(find.byType(TextField), findsNothing);
      },
    );
  });
}
