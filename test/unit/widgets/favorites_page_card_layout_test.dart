@Tags(['unit', 'widgets'])
library;

// test/unit/widgets/favorites_page_card_layout_test.dart
// Favorite devotional card must show the verse and a snippet of the
// devotional reflection stacked vertically, with the note/heart actions
// beside that whole text block -- not squeezed next to the verse alone.

import 'package:devocional_nuevo/blocs/discovery/discovery_bloc.dart';
import 'package:devocional_nuevo/blocs/note_bloc.dart';
import 'package:devocional_nuevo/blocs/theme/theme_bloc.dart';
import 'package:devocional_nuevo/blocs/theme/theme_state.dart';
import 'package:devocional_nuevo/models/devocional_model.dart';
import 'package:devocional_nuevo/models/devotional_note.dart';
import 'package:devocional_nuevo/pages/favorites_page.dart';
import 'package:devocional_nuevo/providers/devocional_provider.dart';
import 'package:devocional_nuevo/repositories/i_notes_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/bloc_test_helper.dart';
import '../../helpers/test_helpers.dart';

class FakeThemeBloc extends Fake implements ThemeBloc {
  @override
  Stream<ThemeState> get stream => Stream.value(
        ThemeLoaded.withThemeData(
          themeFamily: 'Deep Purple',
          brightness: Brightness.light,
        ),
      );

  @override
  ThemeState get state => ThemeLoaded.withThemeData(
        themeFamily: 'Deep Purple',
        brightness: Brightness.light,
      );

  @override
  void add(event) {}

  @override
  Future<void> close() async {}
}

class FakeNotesRepository implements INotesRepository {
  @override
  Future<void> deleteNote(String devocionalId) async {}

  @override
  Future<List<DevotionalNote>> loadNotes() async => [];

  @override
  Future<void> saveNote(DevotionalNote note) async {}
}

void main() {
  group('FavoritesPage devotional card layout', () {
    late DiscoveryBlocTestBase testBase;

    setUpAll(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      await initializeDateFormatting('es');
      await initializeDateFormatting('en');
    });

    setUp(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      SharedPreferences.setMockInitialValues({});
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('flutter_tts'),
        (call) async => null,
      );
      await registerTestServices();
      testBase = DiscoveryBlocTestBase();
      testBase.setupMocks();
      testBase.mockEmptyIndexFetch();
    });

    testWidgets(
      'shows verse and reflection snippet stacked, with actions beside the text block',
      (WidgetTester tester) async {
        final devocional = Devocional(
          id: 'dev_1',
          versiculo: 'Test verse text',
          reflexion: 'Test reflection snippet body',
          paraMeditar: const [],
          oracion: '',
          date: DateTime(2025, 1, 1),
        );
        final mockDevocionalProvider = createMockDevocionalProvider(
          favoriteDevocionales: [devocional],
        );
        final discoveryBloc = DiscoveryBloc(
          repository: testBase.mockRepository,
          progressTracker: testBase.mockProgressTracker,
          favoritesService: testBase.mockFavoritesService,
        );
        final themeBloc = FakeThemeBloc();

        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<DevocionalProvider>.value(
                value: mockDevocionalProvider,
              ),
            ],
            child: MultiBlocProvider(
              providers: [
                BlocProvider<ThemeBloc>.value(value: themeBloc),
                BlocProvider(
                  create: (_) =>
                      NoteBloc(notesRepository: FakeNotesRepository()),
                ),
              ],
              child: MaterialApp(
                home: BlocProvider.value(
                  value: discoveryBloc,
                  child: const FavoritesPage(),
                ),
              ),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.text('Test verse text'), findsOneWidget);
        expect(find.text('Test reflection snippet body'), findsOneWidget);

        // Verse and reflection are stacked vertically (same x, different y)
        // in the card's leading text column, not laid out side by side.
        final verseTopLeft = tester.getTopLeft(find.text('Test verse text'));
        final reflectionTopLeft = tester.getTopLeft(
          find.text('Test reflection snippet body'),
        );
        expect(reflectionTopLeft.dx, equals(verseTopLeft.dx));
        expect(reflectionTopLeft.dy, greaterThan(verseTopLeft.dy));

        // Action icons (note + heart) sit to the right of the text block.
        final heartIcon = find.descendant(
          of: find.byType(Card),
          matching: find.byIcon(Icons.favorite_rounded),
        );
        expect(heartIcon, findsOneWidget);
        final heartLeft = tester.getTopLeft(heartIcon).dx;
        expect(heartLeft, greaterThan(reflectionTopLeft.dx));
      },
    );
  });
}
