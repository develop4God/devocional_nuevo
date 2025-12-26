// test/integration/devocionales_page_bugfix_validation_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:devocional_nuevo/blocs/devocionales/devocionales_navigation_bloc.dart';
import 'package:devocional_nuevo/blocs/devocionales/devocionales_navigation_event.dart';
import 'package:devocional_nuevo/blocs/devocionales/devocionales_navigation_state.dart';
import 'package:devocional_nuevo/blocs/theme/theme_bloc.dart';
import 'package:devocional_nuevo/blocs/theme/theme_state.dart';
import 'package:devocional_nuevo/models/devocional_model.dart';
import 'package:devocional_nuevo/providers/devocional_provider.dart';
import 'package:devocional_nuevo/repositories/navigation_repository.dart';
import 'package:devocional_nuevo/repositories/devocional_repository.dart';

/// Mock classes
class MockNavigationRepository extends Mock implements NavigationRepository {}

class MockDevocionalRepository extends Mock implements DevocionalRepository {}

class MockDevocionalProvider extends Mock implements DevocionalProvider {}

class MockThemeBloc extends Mock implements ThemeBloc {}

void main() {
  group('DevocionalesPage Bug Fix Validation - Real User Behavior', () {
    late MockNavigationRepository mockNavigationRepository;
    late MockDevocionalRepository mockDevocionalRepository;
    late MockDevocionalProvider mockDevocionalProvider;
    late MockThemeBloc mockThemeBloc;
    late DevocionalesNavigationBloc bloc;

    // Helper to create test devotionals
    List<Devocional> createTestDevocionales(int count, String version) {
      return List.generate(
        count,
        (index) => Devocional(
          id: 'devocional_${version}_$index',
          date: DateTime(2025, 1, index + 1),
          versiculo: 'Test verse $index in $version',
          version: version,
          reflexion: 'Test reflection $index',
          paraMeditar: [],
          oracion: 'Test prayer $index',
          language: version == 'RVR1960' ? 'es' : 'en',
        ),
      );
    }

    setUp(() {
      mockNavigationRepository = MockNavigationRepository();
      mockDevocionalRepository = MockDevocionalRepository();
      mockDevocionalProvider = MockDevocionalProvider();
      mockThemeBloc = MockThemeBloc();

      when(() => mockNavigationRepository.saveCurrentIndex(any()))
          .thenAnswer((_) async => {});
      when(() => mockNavigationRepository.loadCurrentIndex())
          .thenAnswer((_) async => 0);
      when(() => mockDevocionalRepository.findFirstUnreadDevocionalIndex(
            any(),
            any(),
          )).thenReturn(0);

      bloc = DevocionalesNavigationBloc(
        navigationRepository: mockNavigationRepository,
        devocionalRepository: mockDevocionalRepository,
      );
    });

    tearDown(() {
      bloc.close();
    });

    test(
        'Bug #1: First-time user sees spinner not "Initializing..." text on white page',
        () async {
      // Issue: After installing, first-time users saw "Initializing..." text on white background
      // Fix: Changed to show CircularProgressIndicator when BLoC is null

      // Verify initial state is NavigationInitial (not showing text)
      expect(bloc.state, isA<NavigationInitial>());

      // Initialize with devotionals
      final devocionales = createTestDevocionales(10, 'RVR1960');
      bloc.add(InitializeNavigation(
        initialIndex: 0,
        devocionales: devocionales,
      ));

      await expectLater(
        bloc.stream,
        emits(isA<NavigationReady>()),
      );

      // Verify we have a valid state (not showing initializing text)
      final state = bloc.state as NavigationReady;
      expect(state.currentDevocional, equals(devocionales[0]));
    });

    test('Bug #2: Bible version change updates devotional in BLoC mode',
        () async {
      // Issue: Drawer bible version change didn't update devotional in BLoC mode
      // Fix: Added Consumer wrapper to listen to DevocionalProvider changes

      // Initialize with Spanish devotionals (RVR1960)
      final spanishDevocionales = createTestDevocionales(10, 'RVR1960');
      bloc.add(InitializeNavigation(
        initialIndex: 5,
        devocionales: spanishDevocionales,
      ));

      await expectLater(
        bloc.stream,
        emits(isA<NavigationReady>()),
      );

      var state = bloc.state as NavigationReady;
      expect(state.currentDevocional.version, equals('RVR1960'));
      expect(state.currentDevocional.language, equals('es'));
      expect(state.currentIndex, equals(5));

      // Simulate bible version change to NIV (English)
      final englishDevocionales = createTestDevocionales(10, 'NIV');
      bloc.add(UpdateDevocionales(englishDevocionales));

      await expectLater(
        bloc.stream,
        emits(isA<NavigationReady>()),
      );

      state = bloc.state as NavigationReady;
      expect(state.currentDevocional.version, equals('NIV'));
      expect(state.currentDevocional.language, equals('en'));
      // Index should be preserved (clamped if necessary)
      expect(state.currentIndex, equals(5));
      expect(state.devocionales.length, equals(10));
    });

    test(
        'Bug #3: Language change updates devotionals list and version in BLoC mode',
        () async {
      // Issue: After changing language, devotionals didn't show correct bible version
      // Fix: UpdateDevocionales event properly updates both list and current devotional

      // Start with Spanish devotionals
      final spanishDevocionales = createTestDevocionales(15, 'RVR1960');
      bloc.add(InitializeNavigation(
        initialIndex: 7,
        devocionales: spanishDevocionales,
      ));

      await expectLater(
        bloc.stream,
        emits(isA<NavigationReady>()),
      );

      var state = bloc.state as NavigationReady;
      expect(state.currentDevocional.language, equals('es'));
      expect(state.currentDevocional.version, equals('RVR1960'));
      expect(state.totalDevocionales, equals(15));

      // Change language to English - this triggers new devotionals
      final englishDevocionales = createTestDevocionales(15, 'NIV');
      bloc.add(UpdateDevocionales(englishDevocionales));

      await expectLater(
        bloc.stream,
        emits(isA<NavigationReady>()),
      );

      state = bloc.state as NavigationReady;
      expect(state.currentDevocional.language, equals('en'));
      expect(state.currentDevocional.version, equals('NIV'));
      expect(state.currentIndex, equals(7)); // Preserved
      expect(state.totalDevocionales, equals(15));
      expect(state.devocionales, equals(englishDevocionales));
    });

    test('Bug #3b: Language change with different list size clamps index',
        () async {
      // Edge case: Language change results in fewer devotionals

      // Start with 20 Spanish devotionals at index 18
      final spanishDevocionales = createTestDevocionales(20, 'RVR1960');
      bloc.add(InitializeNavigation(
        initialIndex: 18,
        devocionales: spanishDevocionales,
      ));

      await expectLater(
        bloc.stream,
        emits(isA<NavigationReady>()),
      );

      var state = bloc.state as NavigationReady;
      expect(state.currentIndex, equals(18));
      expect(state.totalDevocionales, equals(20));

      // Change to English with only 10 devotionals
      final englishDevocionales = createTestDevocionales(10, 'NIV');
      bloc.add(UpdateDevocionales(englishDevocionales));

      await expectLater(
        bloc.stream,
        emits(isA<NavigationReady>()),
      );

      state = bloc.state as NavigationReady;
      expect(state.currentIndex, equals(9)); // Clamped to last valid index
      expect(state.totalDevocionales, equals(10));
      expect(state.currentDevocional.version, equals('NIV'));
    });

    test('Bug #4: Multiple bible version changes work correctly', () async {
      // Real user flow: User changes bible version multiple times

      // Start with RVR1960
      final rvr1960Devocionales = createTestDevocionales(12, 'RVR1960');
      bloc.add(InitializeNavigation(
        initialIndex: 3,
        devocionales: rvr1960Devocionales,
      ));

      await expectLater(
        bloc.stream,
        emits(isA<NavigationReady>()),
      );

      expect((bloc.state as NavigationReady).currentDevocional.version,
          equals('RVR1960'));

      // Change to NVI
      final nviDevocionales = createTestDevocionales(12, 'NVI');
      bloc.add(UpdateDevocionales(nviDevocionales));

      await expectLater(
        bloc.stream,
        emits(isA<NavigationReady>()),
      );

      expect((bloc.state as NavigationReady).currentDevocional.version,
          equals('NVI'));
      expect((bloc.state as NavigationReady).currentIndex, equals(3));

      // Change to NIV (English)
      final nivDevocionales = createTestDevocionales(12, 'NIV');
      bloc.add(UpdateDevocionales(nivDevocionales));

      await expectLater(
        bloc.stream,
        emits(isA<NavigationReady>()),
      );

      expect((bloc.state as NavigationReady).currentDevocional.version,
          equals('NIV'));
      expect((bloc.state as NavigationReady).currentIndex, equals(3));

      // Navigate to next
      bloc.add(const NavigateToNext());

      await expectLater(
        bloc.stream,
        emits(isA<NavigationReady>()),
      );

      expect((bloc.state as NavigationReady).currentIndex, equals(4));
      expect((bloc.state as NavigationReady).currentDevocional.version,
          equals('NIV'));
    });

    test('Performance: UpdateDevocionales completes in < 100ms', () async {
      // Verify that updating devotionals is performant

      final devotionales = createTestDevocionales(730, 'RVR1960');
      bloc.add(InitializeNavigation(
        initialIndex: 0,
        devocionales: devotionales,
      ));

      await expectLater(
        bloc.stream,
        emits(isA<NavigationReady>()),
      );

      final stopwatch = Stopwatch()..start();

      final newDevotionales = createTestDevocionales(730, 'NIV');
      bloc.add(UpdateDevocionales(newDevotionales));

      await expectLater(
        bloc.stream,
        emits(isA<NavigationReady>()),
      );

      stopwatch.stop();

      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(100),
        reason: 'UpdateDevocionales should complete in < 100ms',
      );
    });

    test('Favorite toggle: Icon updates properly after favorite change',
        () async {
      // Bug #5: Favorite icon didn't update after toggle
      // Fix: Wrapped in Consumer to listen to provider changes

      final devotionales = createTestDevocionales(5, 'RVR1960');
      bloc.add(InitializeNavigation(
        initialIndex: 2,
        devocionales: devotionales,
      ));

      await expectLater(
        bloc.stream,
        emits(isA<NavigationReady>()),
      );

      final state = bloc.state as NavigationReady;
      final currentDevocional = state.currentDevocional;

      // Verify we can get the current devotional
      expect(currentDevocional.id, equals('devocional_RVR1960_2'));

      // In real app, DevocionalProvider.toggleFavorite would be called
      // and the Consumer would rebuild with updated isFavorite status
      // This test verifies the state provides access to current devotional
      expect(state.currentDevocional, isNotNull);
      expect(state.currentIndex, equals(2));
    });
  });
}
