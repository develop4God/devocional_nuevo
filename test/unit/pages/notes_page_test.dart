@Tags(['unit', 'pages', 'notes'])
library;

import 'package:devocional_nuevo/blocs/bible_note_bloc.dart';
import 'package:devocional_nuevo/blocs/bible_note_event.dart';
import 'package:devocional_nuevo/blocs/note_bloc.dart';
import 'package:devocional_nuevo/blocs/note_event.dart';
import 'package:devocional_nuevo/blocs/theme/theme_bloc.dart';
import 'package:devocional_nuevo/blocs/theme/theme_state.dart';
import 'package:devocional_nuevo/extensions/string_extensions.dart';
import 'package:devocional_nuevo/models/bible_note.dart';
import 'package:devocional_nuevo/models/devotional_note.dart';
import 'package:devocional_nuevo/pages/notes_page.dart';
import 'package:devocional_nuevo/providers/devocional_provider.dart';
import 'package:devocional_nuevo/repositories/i_bible_notes_repository.dart';
import 'package:devocional_nuevo/repositories/i_notes_repository.dart';
import 'package:devocional_nuevo/widgets/app_bottom_nav_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

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

class _FakeBibleNotesRepository implements IBibleNotesRepository {
  @override
  Future<void> deleteNote(String noteId) async {}

  @override
  Future<List<BibleNote>> loadNotes() async => [];

  @override
  Future<void> saveNote(BibleNote note) async {}
}

void main() {
  setUp(() async {
    await registerTestServicesWithFakes();
  });

  Widget wrapPage({int initialIndex = 0}) {
    final noteBloc = NoteBloc(notesRepository: _FakeNotesRepository())
      ..add(LoadNotes());
    final bibleNoteBloc =
        BibleNoteBloc(bibleNotesRepository: _FakeBibleNotesRepository())
          ..add(LoadBibleNotes());

    return ChangeNotifierProvider<DevocionalProvider>(
      create: (_) => DevocionalProvider(enableAudio: false),
      child: MultiBlocProvider(
        providers: [
          BlocProvider<ThemeBloc>.value(value: _FakeThemeBloc()),
          BlocProvider<NoteBloc>.value(value: noteBloc),
          BlocProvider<BibleNoteBloc>.value(value: bibleNoteBloc),
        ],
        child: MaterialApp(home: NotesPage(initialIndex: initialIndex)),
      ),
    );
  }

  testWidgets('shows the localized tab titles and both tab views', (
    tester,
  ) async {
    await tester.pumpWidget(wrapPage());
    await tester.pumpAndSettle();

    expect(find.text('navigation.devotional'.tr()), findsOneWidget);
    expect(find.text('bible.title'.tr()), findsOneWidget);
    expect(find.byIcon(Icons.favorite_rounded), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(TabBar),
        matching: find.byIcon(Icons.auto_stories_outlined),
      ),
      findsOneWidget,
    );
  });

  testWidgets('starts on the devotional tab by default', (tester) async {
    await tester.pumpWidget(wrapPage());
    await tester.pumpAndSettle();

    final tabBar = tester.widget<TabBar>(find.byType(TabBar));
    expect(tabBar.controller?.index, 0);
  });

  testWidgets('starts on the bible tab when initialIndex is 1', (
    tester,
  ) async {
    await tester.pumpWidget(wrapPage(initialIndex: 1));
    await tester.pumpAndSettle();

    final tabBar = tester.widget<TabBar>(find.byType(TabBar));
    expect(tabBar.controller?.index, 1);
  });

  testWidgets('tapping the bible tab switches to the bible tab view', (
    tester,
  ) async {
    await tester.pumpWidget(wrapPage());
    await tester.pumpAndSettle();

    await tester.tap(find.text('bible.title'.tr()));
    await tester.pumpAndSettle();

    final tabBar = tester.widget<TabBar>(find.byType(TabBar));
    expect(tabBar.controller?.index, 1);
  });

  testWidgets('renders a bottom nav bar with no highlighted tab', (
    tester,
  ) async {
    await tester.pumpWidget(wrapPage());
    await tester.pumpAndSettle();

    final navBar = tester.widget<AppBottomNavBar>(
      find.byType(AppBottomNavBar),
    );
    expect(navBar.currentTab, isNull);
  });

  testWidgets(
    'selecting a bottom nav tab pops back to the first route without throwing',
    (tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<DevocionalProvider>(
              create: (_) => DevocionalProvider(enableAudio: false),
            ),
          ],
          child: MultiBlocProvider(
            providers: [
              BlocProvider<ThemeBloc>.value(value: _FakeThemeBloc()),
              BlocProvider<NoteBloc>.value(
                value: NoteBloc(notesRepository: _FakeNotesRepository())
                  ..add(LoadNotes()),
              ),
              BlocProvider<BibleNoteBloc>.value(
                value: BibleNoteBloc(
                  bibleNotesRepository: _FakeBibleNotesRepository(),
                )..add(LoadBibleNotes()),
              ),
            ],
            child: MaterialApp(
              home: Navigator(
                onGenerateRoute: (settings) => MaterialPageRoute(
                  builder: (_) => const NotesPage(),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.home_outlined));
      await tester.pumpAndSettle();

      expect(find.byType(NotesPage), findsOneWidget);
    },
  );
}
