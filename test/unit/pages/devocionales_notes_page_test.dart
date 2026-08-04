@Tags(['unit', 'pages', 'notes'])
library;

import 'package:devocional_nuevo/blocs/note_bloc.dart';
import 'package:devocional_nuevo/blocs/note_state.dart';
import 'package:devocional_nuevo/blocs/theme/theme_bloc.dart';
import 'package:devocional_nuevo/blocs/theme/theme_state.dart';
import 'package:devocional_nuevo/extensions/string_extensions.dart';
import 'package:devocional_nuevo/models/devotional_note.dart';
import 'package:devocional_nuevo/models/devocional_model.dart';
import 'package:devocional_nuevo/pages/devocionales_notes_page.dart';
import 'package:devocional_nuevo/pages/favorite_devocional_detail_page.dart';
import 'package:devocional_nuevo/providers/devocional_provider.dart';
import 'package:devocional_nuevo/repositories/i_notes_repository.dart';
import 'package:devocional_nuevo/widgets/devotional_note_viewer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/test_helpers.dart';

class _FakeThemeBloc extends Fake implements ThemeBloc {
  @override
  Stream<ThemeState> get stream => Stream.value(_state);

  final ThemeLoaded _state = ThemeLoaded.withThemeData(
    themeFamily: 'Deep Purple',
    brightness: Brightness.light,
  );

  @override
  ThemeState get state => _state;

  @override
  void add(event) {}

  @override
  Future<void> close() async {}
}

class _FakeNotesRepository implements INotesRepository {
  @override
  Future<void> deleteNote(String devocionalId) async {}

  @override
  Future<List<DevotionalNote>> loadNotes() async => [];

  @override
  Future<void> saveNote(DevotionalNote note) async {}
}

class _TestNoteBloc extends NoteBloc {
  _TestNoteBloc() : super(notesRepository: _FakeNotesRepository());

  void setTestState(NoteState state) => emit(state);
}

class _FakeDevocionalProvider extends DevocionalProvider {
  _FakeDevocionalProvider(this._devotionals);

  final List<Devocional> _devotionals;
  String? toggledFavoriteId;

  @override
  List<Devocional> get allDevocionalesForCurrentLanguage => _devotionals;

  @override
  bool isFavorite(Devocional devocional) => false;

  @override
  Future<bool> toggleFavorite(String devocionalId) async {
    toggledFavoriteId = devocionalId;
    return true;
  }
}

void main() {
  late DevocionalProvider devocionalProvider;
  late Devocional devotionalWithNote;
  late Devocional devotionalWithoutNote;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await registerTestServices();
    await initializeDateFormatting('en');
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    devotionalWithNote = Devocional(
      id: 'with-note',
      versiculo: 'John 3:16',
      reflexion: 'Reflection with a saved note',
      paraMeditar: const [],
      oracion: 'Prayer',
      date: DateTime(2025, 1, 1),
    );
    devotionalWithoutNote = Devocional(
      id: 'without-note',
      versiculo: 'Psalm 23:1',
      reflexion: 'Reflection without a note',
      paraMeditar: const [],
      oracion: 'Prayer',
      date: DateTime(2025, 1, 2),
    );
    devocionalProvider = _FakeDevocionalProvider([
      devotionalWithNote,
      devotionalWithoutNote,
    ]);
  });

  Future<void> pumpPage(
    WidgetTester tester,
    NoteState state, {
    bool settle = true,
  }) async {
    final noteBloc = _TestNoteBloc()..setTestState(state);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<DevocionalProvider>.value(
            value: devocionalProvider,
          ),
        ],
        child: MultiBlocProvider(
          providers: [
            BlocProvider<ThemeBloc>.value(value: _FakeThemeBloc()),
            BlocProvider<NoteBloc>.value(value: noteBloc),
          ],
          child: const MaterialApp(home: DevocionalesNotesPage()),
        ),
      ),
    );
    if (settle) {
      await tester.pumpAndSettle();
    } else {
      await tester.pump();
    }
  }

  testWidgets('shows the localized empty state when there are no notes', (
    tester,
  ) async {
    await pumpPage(tester, NoteLoaded(notes: []));

    expect(find.text('notes.empty_title'.tr()), findsOneWidget);
    expect(find.text('notes.empty_description'.tr()), findsOneWidget);
  });

  testWidgets('shows a loading indicator while notes are loading or initial', (
    tester,
  ) async {
    await pumpPage(tester, NoteInitial(), settle: false);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await pumpPage(tester, NoteLoading(), settle: false);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('treats blank notes as empty', (tester) async {
    await pumpPage(
      tester,
      NoteLoaded(
        notes: [
          DevotionalNote(
            devocionalId: devotionalWithNote.id,
            text: '   ',
            lastModifiedDate: DateTime(2025, 1, 1),
          ),
        ],
      ),
    );

    expect(find.text('notes.empty_title'.tr()), findsOneWidget);
    expect(find.text(devotionalWithNote.versiculo), findsNothing);
  });

  testWidgets('shows the NoteBloc error message', (tester) async {
    const errorMessage = 'Unable to load your saved notes.';
    await pumpPage(tester, NoteError(errorMessage));

    expect(find.text(errorMessage), findsOneWidget);
  });

  testWidgets('shows only devotionals with saved notes', (tester) async {
    await pumpPage(
      tester,
      NoteLoaded(
        notes: [
          DevotionalNote(
            devocionalId: devotionalWithNote.id,
            text: 'My saved reflection',
            lastModifiedDate: DateTime(2025, 1, 1),
          ),
        ],
      ),
    );

    expect(find.text(devotionalWithNote.versiculo), findsOneWidget);
    expect(find.text(devotionalWithoutNote.versiculo), findsNothing);
  });

  testWidgets('opens the devotional detail page with the notes title', (
    tester,
  ) async {
    await pumpPage(
      tester,
      NoteLoaded(
        notes: [
          DevotionalNote(
            devocionalId: devotionalWithNote.id,
            text: 'My saved reflection',
            lastModifiedDate: DateTime(2025, 1, 1),
          ),
        ],
      ),
    );

    await tester.tap(find.text(devotionalWithNote.versiculo));
    await tester.pumpAndSettle();

    final detailPage = tester.widget<FavoriteDevocionalDetailPage>(
      find.byType(FavoriteDevocionalDetailPage),
    );
    expect(detailPage.titleKey, 'drawer.my_notes');
  });

  testWidgets('opens the saved note viewer from the note icon', (tester) async {
    const savedNote = 'My saved reflection';
    await pumpPage(
      tester,
      NoteLoaded(
        notes: [
          DevotionalNote(
            devocionalId: devotionalWithNote.id,
            text: savedNote,
            lastModifiedDate: DateTime(2025, 1, 1),
          ),
        ],
      ),
    );

    await tester.tap(find.byIcon(Icons.chat_bubble));
    await tester.pumpAndSettle();

    expect(find.byType(DevotionalNoteViewer), findsOneWidget);
    expect(find.text(savedNote), findsOneWidget);
  });

  testWidgets('toggles the favorite for the selected devotional',
      (tester) async {
    await pumpPage(
      tester,
      NoteLoaded(
        notes: [
          DevotionalNote(
            devocionalId: devotionalWithNote.id,
            text: 'My saved reflection',
            lastModifiedDate: DateTime(2025, 1, 1),
          ),
        ],
      ),
    );

    await tester.tap(find.byIcon(Icons.favorite_border_rounded));
    await tester.pump();

    expect(
      (devocionalProvider as _FakeDevocionalProvider).toggledFavoriteId,
      devotionalWithNote.id,
    );
  });
}
