// test/integration/navigation_analytics_fallback_test.dart
// Tests for Navigation BLoC Analytics integration and fallback scenarios

import 'package:flutter_test/flutter_test.dart';
import 'package:devocional_nuevo/blocs/devocionales/devocionales_navigation_bloc.dart';
import 'package:devocional_nuevo/blocs/devocionales/devocionales_navigation_event.dart';
import 'package:devocional_nuevo/blocs/devocionales/devocionales_navigation_state.dart';
import 'package:devocional_nuevo/models/devocional_model.dart';
import 'package:devocional_nuevo/repositories/navigation_repository.dart';
import 'package:devocional_nuevo/repositories/devocional_repository.dart';
import 'package:mocktail/mocktail.dart';

// Mock classes for testing
class MockNavigationRepository extends Mock implements NavigationRepository {}

class MockDevocionalRepository extends Mock implements DevocionalRepository {}

// Helper function to create test devotionals
List<Devocional> createTestDevocionales(int count) {
  return List.generate(
    count,
    (index) => Devocional(
      id: 'dev_$index',
      versiculo: 'Verse $index',
      reflexion: 'Reflection $index',
      oracion: 'Prayer $index',
      date: DateTime(2025, 1, index + 1),
      paraMeditar: [],
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockNavigationRepository mockNavigationRepository;
  late MockDevocionalRepository mockDevocionalRepository;

  setUp(() {
    mockNavigationRepository = MockNavigationRepository();
    mockDevocionalRepository = MockDevocionalRepository();

    // Default stub for saveCurrentIndex to prevent errors
    when(() => mockNavigationRepository.saveCurrentIndex(any()))
        .thenAnswer((_) async => {});
    when(() => mockNavigationRepository.loadCurrentIndex())
        .thenAnswer((_) async => 0);
    when(() => mockDevocionalRepository.findFirstUnreadDevocionalIndex(
          any(),
          any(),
        )).thenReturn(0);
  });

  group('Navigation BLoC - Analytics State Integration', () {
    test('BLoC emits correct state after navigation for analytics tracking',
        () async {
      // Arrange
      final devocionales = createTestDevocionales(10);
      final bloc = DevocionalesNavigationBloc(
        navigationRepository: mockNavigationRepository,
        devocionalRepository: mockDevocionalRepository,
      );

      // Act
      bloc.add(InitializeNavigation(
        initialIndex: 0,
        devocionales: devocionales,
      ));

      await Future.delayed(const Duration(milliseconds: 100));

      // Assert initial state
      expect(bloc.state, isA<NavigationReady>());
      final initialState = bloc.state as NavigationReady;
      expect(initialState.currentIndex, 0);
      expect(initialState.totalDevocionales, 10);

      // Navigate next
      bloc.add(const NavigateToNext());
      await Future.delayed(const Duration(milliseconds: 100));

      // Assert new state provides analytics data
      final newState = bloc.state as NavigationReady;
      expect(newState.currentIndex, 1);
      expect(newState.currentDevocional.id, 'dev_1');

      bloc.close();
    });

    test('BLoC state provides necessary data for analytics parameters',
        () async {
      // Arrange
      final devocionales = createTestDevocionales(100);
      final bloc = DevocionalesNavigationBloc(
        navigationRepository: mockNavigationRepository,
        devocionalRepository: mockDevocionalRepository,
      );

      // Act
      bloc.add(InitializeNavigation(
        initialIndex: 42,
        devocionales: devocionales,
      ));

      await Future.delayed(const Duration(milliseconds: 100));

      // Assert state contains analytics-relevant data
      final state = bloc.state as NavigationReady;
      expect(state.currentIndex, 42);
      expect(state.totalDevocionales, 100);
      expect(state.currentDevocional.id, 'dev_42');
      expect(state.canNavigateNext, true);
      expect(state.canNavigatePrevious, true);

      bloc.close();
    });

    test('BLoC handles rapid navigation for analytics event buffering',
        () async {
      // Arrange
      final devocionales = createTestDevocionales(20);
      final bloc = DevocionalesNavigationBloc(
        navigationRepository: mockNavigationRepository,
        devocionalRepository: mockDevocionalRepository,
      );

      bloc.add(InitializeNavigation(
        initialIndex: 0,
        devocionales: devocionales,
      ));

      await Future.delayed(const Duration(milliseconds: 100));

      // Act - rapid navigation (analytics should handle buffering)
      bloc.add(const NavigateToNext());
      bloc.add(const NavigateToNext());
      bloc.add(const NavigateToNext());

      await Future.delayed(const Duration(milliseconds: 200));

      // Assert final state is correct
      final state = bloc.state as NavigationReady;
      expect(state.currentIndex, 3);
      expect(state.currentDevocional.id, 'dev_3');

      bloc.close();
    });

    test('BLoC state can be read for fallback to legacy navigation', () async {
      // Arrange
      final devocionales = createTestDevocionales(20);
      final bloc = DevocionalesNavigationBloc(
        navigationRepository: mockNavigationRepository,
        devocionalRepository: mockDevocionalRepository,
      );

      // Initialize
      bloc.add(InitializeNavigation(
        initialIndex: 5,
        devocionales: devocionales,
      ));

      await Future.delayed(const Duration(milliseconds: 100));

      // Act - Test that BLoC state can be read for fallback
      final state = bloc.state;
      expect(state, isA<NavigationReady>());

      final readyState = state as NavigationReady;

      // Assert - State provides all data needed for legacy fallback
      expect(readyState.currentIndex, 5);
      expect(readyState.totalDevocionales, 20);
      expect(readyState.canNavigateNext, true);
      expect(readyState.canNavigatePrevious, true);
      expect(readyState.currentDevocional.id, 'dev_5');

      bloc.close();
    });

    test('BLoC provides error context for Crashlytics reporting', () async {
      // Arrange
      final devocionales = createTestDevocionales(50);
      final bloc = DevocionalesNavigationBloc(
        navigationRepository: mockNavigationRepository,
        devocionalRepository: mockDevocionalRepository,
      );

      // Act
      bloc.add(InitializeNavigation(
        initialIndex: 25,
        devocionales: devocionales,
      ));

      await Future.delayed(const Duration(milliseconds: 100));

      // Assert - State provides error context for Crashlytics
      final state = bloc.state as NavigationReady;
      final errorContext = {
        'current_index': state.currentIndex,
        'total_devotionals': state.totalDevocionales,
        'can_navigate_next': state.canNavigateNext,
        'can_navigate_previous': state.canNavigatePrevious,
        'current_devotional_id': state.currentDevocional.id,
      };

      // Verify all error context data is available
      expect(errorContext['current_index'], 25);
      expect(errorContext['total_devotionals'], 50);
      expect(errorContext['can_navigate_next'], true);
      expect(errorContext['can_navigate_previous'], true);
      expect(errorContext['current_devotional_id'], 'dev_25');

      bloc.close();
    });
  });
}
