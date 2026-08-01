@Tags(['unit', 'widgets'])
library;

import 'package:devocional_nuevo/blocs/note_bloc.dart';
import 'package:devocional_nuevo/models/devocional_model.dart';
import 'package:devocional_nuevo/models/devotional_note.dart';
import 'package:devocional_nuevo/repositories/i_notes_repository.dart';
import 'package:devocional_nuevo/services/localization_service.dart';
import 'package:devocional_nuevo/services/service_locator.dart';
import 'package:devocional_nuevo/widgets/devotional_notes_modal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeLocalizationService extends LocalizationService {
  @override
  String translate(String key, [Map<String, dynamic>? params]) => key;
}

class FakeNotesRepository implements INotesRepository {
  int saveCalls = 0;
  int deleteCalls = 0;

  @override
  Future<void> deleteNote(String devocionalId) async {
    deleteCalls++;
  }

  @override
  Future<List<DevotionalNote>> loadNotes() async => [];

  @override
  Future<void> saveNote(DevotionalNote note) async {
    saveCalls++;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DevotionalNotesModal', () {
    late FakeNotesRepository repository;
    late NoteBloc noteBloc;

    setUp(() {
      ServiceLocator().reset();
      ServiceLocator().registerSingleton<LocalizationService>(
        FakeLocalizationService(),
      );
      repository = FakeNotesRepository();
      noteBloc = NoteBloc(notesRepository: repository);
    });

    tearDown(() async {
      await noteBloc.close();
      ServiceLocator().reset();
    });

    Widget buildWidget({String? initialNote}) {
      return MaterialApp(
        home: Scaffold(
          body: BlocProvider.value(
            value: noteBloc,
            child: DevotionalNotesModal(
              devocional: Devocional(
                id: 'devotional-1',
                versiculo: 'John 3:16',
                reflexion: 'Reflection',
                paraMeditar: const [],
                oracion: 'Prayer',
                date: DateTime(2026, 7, 29),
              ),
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

    testWidgets('shows a delete confirmation snackbar when confirmed', (
      tester,
    ) async {
      await tester.pumpWidget(buildWidget(initialNote: 'Existing note'));

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();
      await tester.tap(find.text('app.delete'));
      await tester.pump();

      expect(repository.deleteCalls, 1);
      expect(find.text('notes.deleted_message'), findsOneWidget);
    });
  });
}
