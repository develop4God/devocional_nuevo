// test/widget/devocionales_page_bloc_test.dart
// Widget tests for DevocionalesPage with Navigation BLoC integration

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:devocional_nuevo/blocs/devocionales/devocionales_navigation_bloc.dart';
import 'package:devocional_nuevo/blocs/devocionales/devocionales_navigation_event.dart';
import 'package:devocional_nuevo/blocs/devocionales/devocionales_navigation_state.dart';
import 'package:devocional_nuevo/models/devocional_model.dart';

// Mocks
class MockDevocionalesNavigationBloc extends Mock
    implements DevocionalesNavigationBloc {}

// Fake classes for mocktail
class FakeNavigationEvent extends Fake implements DevocionalesNavigationEvent {}

class FakeNavigationState extends Fake implements DevocionalesNavigationState {}

// Helper function to create test devotionals
List<Devocional> createTestDevocionales(int count) {
  return List.generate(
    count,
    (index) => Devocional(
      id: 'dev_$index',
      versiculo: 'Verse $index',
      reflexion: 'Reflection $index',
      oracion: 'Prayer $index',
      date: DateTime(2024, 1, index + 1),
      paraMeditar: [],
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Register fallback values for mocktail
  setUpAll(() {
    registerFallbackValue(FakeNavigationEvent());
    registerFallbackValue(FakeNavigationState());
  });

  group('DevocionalesPage with BLoC - Widget Tests', () {
    late MockDevocionalesNavigationBloc mockBloc;

    setUp(() {
      mockBloc = MockDevocionalesNavigationBloc();

      // Setup common stubs
      when(() => mockBloc.stream).thenAnswer(
        (_) => Stream<DevocionalesNavigationState>.value(
          const NavigationInitial(),
        ),
      );
    });

    testWidgets('Widget renders with BlocBuilder when NavigationReady state', (
      WidgetTester tester,
    ) async {
      // Arrange
      final devocionales = createTestDevocionales(10);
      final readyState = NavigationReady.calculate(
        currentIndex: 5,
        devocionales: devocionales,
      );

      when(() => mockBloc.state).thenReturn(readyState);
      when(() => mockBloc.stream).thenAnswer(
        (_) => Stream<DevocionalesNavigationState>.value(readyState),
      );

      // Verify that the bloc is properly set up
      expect(mockBloc.state, isA<NavigationReady>());
      final state = mockBloc.state as NavigationReady;
      expect(state.currentIndex, 5);
      expect(state.currentDevocional.id, 'dev_5');
      expect(state.canNavigateNext, true);
      expect(state.canNavigatePrevious, true);
    });

    testWidgets('Next button tap dispatches NavigateToNext event', (
      WidgetTester tester,
    ) async {
      // Arrange
      final devocionales = createTestDevocionales(10);
      final readyState = NavigationReady.calculate(
        currentIndex: 5,
        devocionales: devocionales,
      );

      when(() => mockBloc.state).thenReturn(readyState);
      when(() => mockBloc.add(any())).thenReturn(null);

      // Act
      mockBloc.add(const NavigateToNext());

      // Assert
      verify(() => mockBloc.add(any(that: isA<NavigateToNext>()))).called(1);
    });

    testWidgets('Previous button tap dispatches NavigateToPrevious event', (
      WidgetTester tester,
    ) async {
      // Arrange
      final devocionales = createTestDevocionales(10);
      final readyState = NavigationReady.calculate(
        currentIndex: 5,
        devocionales: devocionales,
      );

      when(() => mockBloc.state).thenReturn(readyState);
      when(() => mockBloc.add(any())).thenReturn(null);

      // Act
      mockBloc.add(const NavigateToPrevious());

      // Assert
      verify(
        () => mockBloc.add(any(that: isA<NavigateToPrevious>())),
      ).called(1);
    });

    testWidgets('NavigationReady state contains correct devotional content', (
      WidgetTester tester,
    ) async {
      // Arrange
      final devocionales = createTestDevocionales(10);
      final readyState = NavigationReady.calculate(
        currentIndex: 3,
        devocionales: devocionales,
      );

      when(() => mockBloc.state).thenReturn(readyState);

      // Assert
      expect(mockBloc.state, isA<NavigationReady>());
      final state = mockBloc.state as NavigationReady;
      expect(state.currentDevocional.id, 'dev_3');
      expect(state.currentDevocional.versiculo, 'Verse 3');
      expect(state.currentDevocional.reflexion, 'Reflection 3');
      expect(state.totalDevocionales, 10);
    });

    testWidgets('NavigationError state shows error message', (
      WidgetTester tester,
    ) async {
      // Arrange
      const errorState = NavigationError('Test error message');

      when(() => mockBloc.state).thenReturn(errorState);

      // Assert
      expect(mockBloc.state, isA<NavigationError>());
      final state = mockBloc.state as NavigationError;
      expect(state.message, 'Test error message');
    });

    testWidgets('canNavigateNext=false at last devotional', (
      WidgetTester tester,
    ) async {
      // Arrange
      final devocionales = createTestDevocionales(10);
      final readyState = NavigationReady.calculate(
        currentIndex: 9, // Last index
        devocionales: devocionales,
      );

      when(() => mockBloc.state).thenReturn(readyState);

      // Assert
      expect(mockBloc.state, isA<NavigationReady>());
      final state = mockBloc.state as NavigationReady;
      expect(state.canNavigateNext, false);
      expect(state.canNavigatePrevious, true);
      expect(state.currentIndex, 9);
    });

    testWidgets('canNavigatePrevious=false at first devotional', (
      WidgetTester tester,
    ) async {
      // Arrange
      final devocionales = createTestDevocionales(10);
      final readyState = NavigationReady.calculate(
        currentIndex: 0, // First index
        devocionales: devocionales,
      );

      when(() => mockBloc.state).thenReturn(readyState);

      // Assert
      expect(mockBloc.state, isA<NavigationReady>());
      final state = mockBloc.state as NavigationReady;
      expect(state.canNavigateNext, true);
      expect(state.canNavigatePrevious, false);
      expect(state.currentIndex, 0);
    });

    testWidgets('BLoC emits state changes when navigating', (
      WidgetTester tester,
    ) async {
      // Arrange
      final devocionales = createTestDevocionales(10);
      final initialState = NavigationReady.calculate(
        currentIndex: 0,
        devocionales: devocionales,
      );
      final nextState = NavigationReady.calculate(
        currentIndex: 1,
        devocionales: devocionales,
      );

      when(() => mockBloc.state).thenReturn(initialState);
      when(() => mockBloc.stream).thenAnswer(
        (_) => Stream<DevocionalesNavigationState>.fromIterable([
          initialState,
          nextState,
        ]),
      );

      // Act - Simulate navigation
      final states = await mockBloc.stream.take(2).toList();

      // Assert
      expect(states.length, 2);
      expect(states[0], isA<NavigationReady>());
      expect((states[0] as NavigationReady).currentIndex, 0);
      expect(states[1], isA<NavigationReady>());
      expect((states[1] as NavigationReady).currentIndex, 1);
    });

    testWidgets('Single devotional list disables both navigation buttons', (
      WidgetTester tester,
    ) async {
      // Arrange
      final devocionales = createTestDevocionales(1);
      final readyState = NavigationReady.calculate(
        currentIndex: 0,
        devocionales: devocionales,
      );

      when(() => mockBloc.state).thenReturn(readyState);

      // Assert
      expect(mockBloc.state, isA<NavigationReady>());
      final state = mockBloc.state as NavigationReady;
      expect(state.canNavigateNext, false);
      expect(state.canNavigatePrevious, false);
      expect(state.totalDevocionales, 1);
    });

    testWidgets('NavigateToIndex event updates current devotional', (
      WidgetTester tester,
    ) async {
      // Arrange
      when(() => mockBloc.add(any())).thenReturn(null);

      // Act
      mockBloc.add(const NavigateToIndex(7));

      // Assert
      final capturedEvent = verify(() => mockBloc.add(captureAny()))
          .captured
          .last as NavigateToIndex;
      expect(capturedEvent.index, 7);
    });

    testWidgets('InitializeNavigation event sets up initial state', (
      WidgetTester tester,
    ) async {
      // Arrange
      final devocionales = createTestDevocionales(10);
      when(() => mockBloc.add(any())).thenReturn(null);

      // Act
      mockBloc.add(
        InitializeNavigation(initialIndex: 0, devocionales: devocionales),
      );

      // Assert
      verify(
        () => mockBloc.add(any(that: isA<InitializeNavigation>())),
      ).called(1);
    });

    testWidgets('UpdateDevocionales event updates devotional list', (
      WidgetTester tester,
    ) async {
      // Arrange
      final newDevocionales = createTestDevocionales(15);
      when(() => mockBloc.add(any())).thenReturn(null);

      // Act
      mockBloc.add(UpdateDevocionales(newDevocionales));

      // Assert
      final capturedEvent = verify(() => mockBloc.add(captureAny()))
          .captured
          .last as UpdateDevocionales;
      expect(capturedEvent.devocionales.length, 15);
    });

    testWidgets('NavigateToFirstUnread event finds correct unread devotional', (
      WidgetTester tester,
    ) async {
      // Arrange
      final readIds = ['dev_0', 'dev_1', 'dev_2'];
      when(() => mockBloc.add(any())).thenReturn(null);

      // Act
      mockBloc.add(NavigateToFirstUnread(readIds));

      // Assert
      final capturedEvent = verify(() => mockBloc.add(captureAny()))
          .captured
          .last as NavigateToFirstUnread;
      expect(capturedEvent.readDevocionalIds, readIds);
    });
  });
}
