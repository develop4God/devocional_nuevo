@Tags(['unit', 'widgets'])
library;

// test/unit/pages/favorite_devocional_detail_page_test.dart
// FavoriteDevocionalDetailPage is the destination when tapping a favorite
// from FavoritesPage. It must show the devotional content without a date
// (per product decision — hidden, not removed from the data/logic), keep
// the persistent shell bottom nav bar, and toggling favorite must give the
// same feedback as the home page.

import 'package:devocional_nuevo/blocs/theme/theme_bloc.dart';
import 'package:devocional_nuevo/blocs/theme/theme_state.dart';
import 'package:devocional_nuevo/models/devocional_model.dart';
import 'package:devocional_nuevo/pages/favorite_devocional_detail_page.dart';
import 'package:devocional_nuevo/providers/devocional_provider.dart';
import 'package:devocional_nuevo/widgets/app_bottom_nav_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mockito/mockito.dart';
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

void main() {
  group('FavoriteDevocionalDetailPage', () {
    late Devocional devocional;
    late dynamic mockDevocionalProvider;

    setUpAll(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      await initializeDateFormatting('en');
    });

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await registerTestServices();
      devocional = Devocional(
        id: 'fav-1',
        versiculo: 'Juan 3:16',
        reflexion: 'Reflexión de prueba',
        paraMeditar: const [],
        oracion: 'Oración de prueba',
        date: DateTime(2025, 1, 1),
      );
      mockDevocionalProvider = createMockDevocionalProvider();
    });

    Widget buildPage() {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider<DevocionalProvider>.value(
            value: mockDevocionalProvider,
          ),
        ],
        child: BlocProvider<ThemeBloc>.value(
          value: FakeThemeBloc(),
          child: MaterialApp(
            home: FavoriteDevocionalDetailPage(devocional: devocional),
          ),
        ),
      );
    }

    testWidgets('shows Favorites title and content without a date', (
      tester,
    ) async {
      when(mockDevocionalProvider.isFavorite(any)).thenReturn(true);

      await tester.pumpWidget(buildPage());
      await tester.pump();

      expect(find.text('favorites.title'), findsOneWidget);
      expect(find.text('Juan 3:16'), findsOneWidget);
      expect(find.text('Reflexión de prueba'), findsOneWidget);
      expect(find.text('Oración de prueba'), findsOneWidget);
      expect(find.textContaining('2025'), findsNothing);
    });

    testWidgets('shows the persistent shell bottom nav bar', (tester) async {
      when(mockDevocionalProvider.isFavorite(any)).thenReturn(true);

      await tester.pumpWidget(buildPage());
      await tester.pump();

      expect(find.byType(AppBottomNavBar), findsOneWidget);
      expect(find.byKey(const Key('bottom_appbar_home_icon')), findsOneWidget);
    });

    testWidgets('has no next/previous paging controls', (tester) async {
      when(mockDevocionalProvider.isFavorite(any)).thenReturn(true);

      await tester.pumpWidget(buildPage());
      await tester.pump();

      expect(find.byIcon(Icons.arrow_back_ios), findsNothing);
      expect(find.byIcon(Icons.arrow_forward_ios), findsNothing);
    });

    testWidgets('tapping favorite toggles it and shows feedback', (
      tester,
    ) async {
      when(mockDevocionalProvider.isFavorite(any)).thenReturn(true);
      when(
        mockDevocionalProvider.toggleFavorite(any),
      ).thenAnswer((_) async => false);

      await tester.pumpWidget(buildPage());
      await tester.pump();

      await tester.tap(find.byIcon(Icons.star_rounded));
      await tester.pump();
      await tester.pump();

      verify(mockDevocionalProvider.toggleFavorite('fav-1')).called(1);
      expect(
        find.text('devotionals_page.removed_from_favorites'),
        findsOneWidget,
      );
    });
  });
}
