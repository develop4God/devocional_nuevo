// test/critical_coverage/devocionales_navigation_bloc_test.dart
// High-value tests for DevocionalesNavigationBloc - navigation user flows

import 'package:flutter_test/flutter_test.dart';
import 'package:devocional_nuevo/blocs/devocionales/devocionales_navigation_bloc.dart';
import 'package:devocional_nuevo/blocs/devocionales/devocionales_navigation_event.dart';
import 'package:devocional_nuevo/blocs/devocionales/devocionales_navigation_state.dart';
import 'package:devocional_nuevo/models/devocional_model.dart';
import 'package:devocional_nuevo/repositories/navigation_repository.dart';
import 'package:devocional_nuevo/repositories/devocional_repository.dart';
import 'package:bloc_test/bloc_test.dart';
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
      date: DateTime(2024, 1, index + 1),
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
  });

  group('DevocionalesNavigationBloc - Initial State', () {
    test('initial state is NavigationInitial', () {
      final bloc = DevocionalesNavigationBloc(
        navigationRepository: mockNavigationRepository,
        devocionalRepository: mockDevocionalRepository,
      );
      expect(bloc.state, isA<NavigationInitial>());
      bloc.close();
    });
  });

  group('DevocionalesNavigationBloc - Initialize Navigation', () {
    blocTest<DevocionalesNavigationBloc, DevocionalesNavigationState>(
      'emits NavigationReady when initialized with valid values',
      build: () => DevocionalesNavigationBloc(
        navigationRepository: mockNavigationRepository,
        devocionalRepository: mockDevocionalRepository,
      ),
      act: (bloc) {
        final devocionales = createTestDevocionales(10);
        return bloc.add(
          InitializeNavigation(initialIndex: 0, devocionales: devocionales),
        );
      },
      expect: () => [
        isA<NavigationReady>()
            .having((s) => s.currentIndex, 'currentIndex', 0)
            .having((s) => s.totalDevocionales, 'totalDevocionales', 10)
            .having(
                (s) => s.currentDevocional.id, 'currentDevocional.id', 'dev_0')
            .having((s) => s.devocionales.length, 'devocionales.length', 10)
            .having((s) => s.canNavigateNext, 'canNavigateNext', true)
            .having((s) => s.canNavigatePrevious, 'canNavigatePrevious', false),
      ],
      verify: (_) {
        verify(() => mockNavigationRepository.saveCurrentIndex(0)).called(1);
      },
    );

    blocTest<DevocionalesNavigationBloc, DevocionalesNavigationState>(
      'emits NavigationError when initialized with empty list',
      build: () => DevocionalesNavigationBloc(
        navigationRepository: mockNavigationRepository,
        devocionalRepository: mockDevocionalRepository,
      ),
      act: (bloc) => bloc.add(
        const InitializeNavigation(initialIndex: 0, devocionales: []),
      ),
      expect: () => [
        isA<NavigationError>().having(
          (s) => s.message,
          'message',
          'No devotionals available',
        ),
      ],
      verify: (_) {
        verifyNever(() => mockNavigationRepository.saveCurrentIndex(any()));
      },
    );

    blocTest<DevocionalesNavigationBloc, DevocionalesNavigationState>(
      'clamps initial index to valid range when too high',
      build: () => DevocionalesNavigationBloc(
        navigationRepository: mockNavigationRepository,
        devocionalRepository: mockDevocionalRepository,
      ),
      act: (bloc) {
        final devocionales = createTestDevocionales(10);
        return bloc.add(
          InitializeNavigation(initialIndex: 100, devocionales: devocionales),
        );
      },
      expect: () => [
        isA<NavigationReady>()
            .having((s) => s.currentIndex, 'currentIndex', 9) // Clamped to last
            .having((s) => s.totalDevocionales, 'totalDevocionales', 10)
            .having(
                (s) => s.currentDevocional.id, 'currentDevocional.id', 'dev_9'),
      ],
      verify: (_) {
        verify(() => mockNavigationRepository.saveCurrentIndex(9)).called(1);
      },
    );

    blocTest<DevocionalesNavigationBloc, DevocionalesNavigationState>(
      'clamps initial index to valid range when negative',
      build: () => DevocionalesNavigationBloc(
        navigationRepository: mockNavigationRepository,
        devocionalRepository: mockDevocionalRepository,
      ),
      act: (bloc) {
        final devocionales = createTestDevocionales(10);
        return bloc.add(
          InitializeNavigation(initialIndex: -5, devocionales: devocionales),
        );
      },
      expect: () => [
        isA<NavigationReady>()
            .having(
                (s) => s.currentIndex, 'currentIndex', 0) // Clamped to first
            .having((s) => s.totalDevocionales, 'totalDevocionales', 10)
            .having(
                (s) => s.currentDevocional.id, 'currentDevocional.id', 'dev_0'),
      ],
      verify: (_) {
        verify(() => mockNavigationRepository.saveCurrentIndex(0)).called(1);
      },
    );

    blocTest<DevocionalesNavigationBloc, DevocionalesNavigationState>(
      'initializes at middle index correctly',
      build: () => DevocionalesNavigationBloc(
        navigationRepository: mockNavigationRepository,
        devocionalRepository: mockDevocionalRepository,
      ),
      act: (bloc) {
        final devocionales = createTestDevocionales(10);
        return bloc.add(
          InitializeNavigation(initialIndex: 5, devocionales: devocionales),
        );
      },
      expect: () => [
        isA<NavigationReady>()
            .having((s) => s.currentIndex, 'currentIndex', 5)
            .having(
                (s) => s.currentDevocional.id, 'currentDevocional.id', 'dev_5')
            .having((s) => s.canNavigateNext, 'canNavigateNext', true)
            .having((s) => s.canNavigatePrevious, 'canNavigatePrevious', true),
      ],
      verify: (_) {
        verify(() => mockNavigationRepository.saveCurrentIndex(5)).called(1);
      },
    );
  });

  group('DevocionalesNavigationBloc - Navigate Next', () {
    blocTest<DevocionalesNavigationBloc, DevocionalesNavigationState>(
      'navigates to next devotional successfully',
      build: () => DevocionalesNavigationBloc(
        navigationRepository: mockNavigationRepository,
        devocionalRepository: mockDevocionalRepository,
      ),
      seed: () {
        final devocionales = createTestDevocionales(10);
        return NavigationReady.calculate(
          currentIndex: 5,
          devocionales: devocionales,
        );
      },
      act: (bloc) => bloc.add(const NavigateToNext()),
      expect: () => [
        isA<NavigationReady>()
            .having((s) => s.currentIndex, 'currentIndex', 6)
            .having(
                (s) => s.currentDevocional.id, 'currentDevocional.id', 'dev_6')
            .having((s) => s.totalDevocionales, 'totalDevocionales', 10),
      ],
      verify: (_) {
        verify(() => mockNavigationRepository.saveCurrentIndex(6)).called(1);
      },
    );

    blocTest<DevocionalesNavigationBloc, DevocionalesNavigationState>(
      'does not navigate next when at last devotional',
      build: () => DevocionalesNavigationBloc(
        navigationRepository: mockNavigationRepository,
        devocionalRepository: mockDevocionalRepository,
      ),
      seed: () {
        final devocionales = createTestDevocionales(10);
        return NavigationReady.calculate(
          currentIndex: 9,
          devocionales: devocionales,
        );
      },
      act: (bloc) => bloc.add(const NavigateToNext()),
      expect: () => [], // No state change
      verify: (_) {
        verifyNever(() => mockNavigationRepository.saveCurrentIndex(any()));
      },
    );

    blocTest<DevocionalesNavigationBloc, DevocionalesNavigationState>(
      'updates navigation capabilities when moving from first to second',
      build: () => DevocionalesNavigationBloc(
        navigationRepository: mockNavigationRepository,
        devocionalRepository: mockDevocionalRepository,
      ),
      seed: () {
        final devocionales = createTestDevocionales(10);
        return NavigationReady.calculate(
          currentIndex: 0,
          devocionales: devocionales,
        );
      },
      act: (bloc) => bloc.add(const NavigateToNext()),
      expect: () => [
        isA<NavigationReady>()
            .having((s) => s.currentIndex, 'currentIndex', 1)
            .having(
                (s) => s.currentDevocional.id, 'currentDevocional.id', 'dev_1')
            .having((s) => s.canNavigateNext, 'canNavigateNext', true)
            .having((s) => s.canNavigatePrevious, 'canNavigatePrevious', true),
      ],
      verify: (_) {
        verify(() => mockNavigationRepository.saveCurrentIndex(1)).called(1);
      },
    );

    blocTest<DevocionalesNavigationBloc, DevocionalesNavigationState>(
      'does not emit when not in NavigationReady state',
      build: () => DevocionalesNavigationBloc(
        navigationRepository: mockNavigationRepository,
        devocionalRepository: mockDevocionalRepository,
      ),
      act: (bloc) => bloc.add(const NavigateToNext()),
      expect: () => [], // No state change from Initial
      verify: (_) {
        verifyNever(() => mockNavigationRepository.saveCurrentIndex(any()));
      },
    );
  });

  group('DevocionalesNavigationBloc - Navigate Previous', () {
    blocTest<DevocionalesNavigationBloc, DevocionalesNavigationState>(
      'navigates to previous devotional successfully',
      build: () => DevocionalesNavigationBloc(
        navigationRepository: mockNavigationRepository,
        devocionalRepository: mockDevocionalRepository,
      ),
      seed: () {
        final devocionales = createTestDevocionales(10);
        return NavigationReady.calculate(
          currentIndex: 5,
          devocionales: devocionales,
        );
      },
      act: (bloc) => bloc.add(const NavigateToPrevious()),
      expect: () => [
        isA<NavigationReady>()
            .having((s) => s.currentIndex, 'currentIndex', 4)
            .having(
                (s) => s.currentDevocional.id, 'currentDevocional.id', 'dev_4')
            .having((s) => s.totalDevocionales, 'totalDevocionales', 10),
      ],
      verify: (_) {
        verify(() => mockNavigationRepository.saveCurrentIndex(4)).called(1);
      },
    );

    blocTest<DevocionalesNavigationBloc, DevocionalesNavigationState>(
      'does not navigate previous when at first devotional',
      build: () => DevocionalesNavigationBloc(
        navigationRepository: mockNavigationRepository,
        devocionalRepository: mockDevocionalRepository,
      ),
      seed: () {
        final devocionales = createTestDevocionales(10);
        return NavigationReady.calculate(
          currentIndex: 0,
          devocionales: devocionales,
        );
      },
      act: (bloc) => bloc.add(const NavigateToPrevious()),
      expect: () => [], // No state change
      verify: (_) {
        verifyNever(() => mockNavigationRepository.saveCurrentIndex(any()));
      },
    );

    blocTest<DevocionalesNavigationBloc, DevocionalesNavigationState>(
      'updates navigation capabilities when moving from last to second-to-last',
      build: () => DevocionalesNavigationBloc(
        navigationRepository: mockNavigationRepository,
        devocionalRepository: mockDevocionalRepository,
      ),
      seed: () {
        final devocionales = createTestDevocionales(10);
        return NavigationReady.calculate(
          currentIndex: 9,
          devocionales: devocionales,
        );
      },
      act: (bloc) => bloc.add(const NavigateToPrevious()),
      expect: () => [
        isA<NavigationReady>()
            .having((s) => s.currentIndex, 'currentIndex', 8)
            .having(
                (s) => s.currentDevocional.id, 'currentDevocional.id', 'dev_8')
            .having((s) => s.canNavigateNext, 'canNavigateNext', true)
            .having((s) => s.canNavigatePrevious, 'canNavigatePrevious', true),
      ],
      verify: (_) {
        verify(() => mockNavigationRepository.saveCurrentIndex(8)).called(1);
      },
    );
  });

  group('DevocionalesNavigationBloc - Navigate to Specific Index', () {
    blocTest<DevocionalesNavigationBloc, DevocionalesNavigationState>(
      'navigates to specific valid index',
      build: () => DevocionalesNavigationBloc(
        navigationRepository: mockNavigationRepository,
        devocionalRepository: mockDevocionalRepository,
      ),
      seed: () {
        final devocionales = createTestDevocionales(10);
        return NavigationReady.calculate(
          currentIndex: 0,
          devocionales: devocionales,
        );
      },
      act: (bloc) => bloc.add(const NavigateToIndex(7)),
      expect: () => [
        isA<NavigationReady>()
            .having((s) => s.currentIndex, 'currentIndex', 7)
            .having(
                (s) => s.currentDevocional.id, 'currentDevocional.id', 'dev_7')
            .having((s) => s.totalDevocionales, 'totalDevocionales', 10),
      ],
      verify: (_) {
        verify(() => mockNavigationRepository.saveCurrentIndex(7)).called(1);
      },
    );

    blocTest<DevocionalesNavigationBloc, DevocionalesNavigationState>(
      'clamps index when navigating to invalid high index',
      build: () => DevocionalesNavigationBloc(
        navigationRepository: mockNavigationRepository,
        devocionalRepository: mockDevocionalRepository,
      ),
      seed: () {
        final devocionales = createTestDevocionales(10);
        return NavigationReady.calculate(
          currentIndex: 0,
          devocionales: devocionales,
        );
      },
      act: (bloc) => bloc.add(const NavigateToIndex(100)),
      expect: () => [
        isA<NavigationReady>()
            .having((s) => s.currentIndex, 'currentIndex', 9) // Clamped to last
            .having(
                (s) => s.currentDevocional.id, 'currentDevocional.id', 'dev_9')
            .having((s) => s.totalDevocionales, 'totalDevocionales', 10),
      ],
      verify: (_) {
        verify(() => mockNavigationRepository.saveCurrentIndex(9)).called(1);
      },
    );

    blocTest<DevocionalesNavigationBloc, DevocionalesNavigationState>(
      'clamps index when navigating to negative index',
      build: () => DevocionalesNavigationBloc(
        navigationRepository: mockNavigationRepository,
        devocionalRepository: mockDevocionalRepository,
      ),
      seed: () {
        final devocionales = createTestDevocionales(10);
        return NavigationReady.calculate(
          currentIndex: 5,
          devocionales: devocionales,
        );
      },
      act: (bloc) => bloc.add(const NavigateToIndex(-1)),
      expect: () => [
        isA<NavigationReady>()
            .having(
                (s) => s.currentIndex, 'currentIndex', 0) // Clamped to first
            .having(
                (s) => s.currentDevocional.id, 'currentDevocional.id', 'dev_0')
            .having((s) => s.totalDevocionales, 'totalDevocionales', 10),
      ],
      verify: (_) {
        verify(() => mockNavigationRepository.saveCurrentIndex(0)).called(1);
      },
    );

    blocTest<DevocionalesNavigationBloc, DevocionalesNavigationState>(
      'does not emit when navigating to same index',
      build: () => DevocionalesNavigationBloc(
        navigationRepository: mockNavigationRepository,
        devocionalRepository: mockDevocionalRepository,
      ),
      seed: () {
        final devocionales = createTestDevocionales(10);
        return NavigationReady.calculate(
          currentIndex: 5,
          devocionales: devocionales,
        );
      },
      act: (bloc) => bloc.add(const NavigateToIndex(5)),
      expect: () => [], // No state change
      verify: (_) {
        verifyNever(() => mockNavigationRepository.saveCurrentIndex(any()));
      },
    );
  });

  group('DevocionalesNavigationBloc - Navigate to First Unread', () {
    blocTest<DevocionalesNavigationBloc, DevocionalesNavigationState>(
      'navigates to first unread devotional',
      build: () => DevocionalesNavigationBloc(
        navigationRepository: mockNavigationRepository,
        devocionalRepository: mockDevocionalRepository,
      ),
      setUp: () {
        when(() => mockDevocionalRepository.findFirstUnreadDevocionalIndex(
              any(),
              any(),
            )).thenReturn(3);
      },
      seed: () {
        final devocionales = createTestDevocionales(10);
        return NavigationReady.calculate(
          currentIndex: 0,
          devocionales: devocionales,
        );
      },
      act: (bloc) =>
          bloc.add(const NavigateToFirstUnread(['dev_0', 'dev_1', 'dev_2'])),
      expect: () => [
        isA<NavigationReady>()
            .having((s) => s.currentIndex, 'currentIndex', 3)
            .having(
                (s) => s.currentDevocional.id, 'currentDevocional.id', 'dev_3'),
      ],
      verify: (_) {
        verify(() => mockNavigationRepository.saveCurrentIndex(3)).called(1);
        verify(() => mockDevocionalRepository.findFirstUnreadDevocionalIndex(
              any(),
              ['dev_0', 'dev_1', 'dev_2'],
            )).called(1);
      },
    );

    blocTest<DevocionalesNavigationBloc, DevocionalesNavigationState>(
      'does not emit when already at first unread',
      build: () => DevocionalesNavigationBloc(
        navigationRepository: mockNavigationRepository,
        devocionalRepository: mockDevocionalRepository,
      ),
      setUp: () {
        when(() => mockDevocionalRepository.findFirstUnreadDevocionalIndex(
              any(),
              any(),
            )).thenReturn(3);
      },
      seed: () {
        final devocionales = createTestDevocionales(10);
        return NavigationReady.calculate(
          currentIndex: 3,
          devocionales: devocionales,
        );
      },
      act: (bloc) =>
          bloc.add(const NavigateToFirstUnread(['dev_0', 'dev_1', 'dev_2'])),
      expect: () => [], // No state change
      verify: (_) {
        verifyNever(() => mockNavigationRepository.saveCurrentIndex(any()));
        verify(() => mockDevocionalRepository.findFirstUnreadDevocionalIndex(
              any(),
              ['dev_0', 'dev_1', 'dev_2'],
            )).called(1);
      },
    );
  });

  group('DevocionalesNavigationBloc - Update Devotionals', () {
    blocTest<DevocionalesNavigationBloc, DevocionalesNavigationState>(
      'updates devotionals list successfully when current index is still valid',
      build: () => DevocionalesNavigationBloc(
        navigationRepository: mockNavigationRepository,
        devocionalRepository: mockDevocionalRepository,
      ),
      seed: () {
        final devocionales = createTestDevocionales(10);
        return NavigationReady.calculate(
          currentIndex: 5,
          devocionales: devocionales,
        );
      },
      act: (bloc) {
        final newDevocionales = createTestDevocionales(20);
        return bloc.add(UpdateDevocionales(newDevocionales));
      },
      expect: () => [
        isA<NavigationReady>()
            .having((s) => s.currentIndex, 'currentIndex', 5)
            .having((s) => s.totalDevocionales, 'totalDevocionales', 20),
      ],
      verify: (_) {
        verifyNever(() => mockNavigationRepository.saveCurrentIndex(any()));
      },
    );

    blocTest<DevocionalesNavigationBloc, DevocionalesNavigationState>(
      'clamps current index when devotionals list decreases',
      build: () => DevocionalesNavigationBloc(
        navigationRepository: mockNavigationRepository,
        devocionalRepository: mockDevocionalRepository,
      ),
      seed: () {
        final devocionales = createTestDevocionales(10);
        return NavigationReady.calculate(
          currentIndex: 8,
          devocionales: devocionales,
        );
      },
      act: (bloc) {
        final newDevocionales = createTestDevocionales(5);
        return bloc.add(UpdateDevocionales(newDevocionales));
      },
      expect: () => [
        isA<NavigationReady>()
            .having(
                (s) => s.currentIndex, 'currentIndex', 4) // Clamped to new last
            .having((s) => s.totalDevocionales, 'totalDevocionales', 5)
            .having(
                (s) => s.currentDevocional.id, 'currentDevocional.id', 'dev_4'),
      ],
      verify: (_) {
        verify(() => mockNavigationRepository.saveCurrentIndex(4)).called(1);
      },
    );

    blocTest<DevocionalesNavigationBloc, DevocionalesNavigationState>(
      'emits error when devotionals list becomes empty',
      build: () => DevocionalesNavigationBloc(
        navigationRepository: mockNavigationRepository,
        devocionalRepository: mockDevocionalRepository,
      ),
      seed: () {
        final devocionales = createTestDevocionales(10);
        return NavigationReady.calculate(
          currentIndex: 5,
          devocionales: devocionales,
        );
      },
      act: (bloc) => bloc.add(const UpdateDevocionales([])),
      expect: () => [
        isA<NavigationError>().having(
          (s) => s.message,
          'message',
          'No devotionals available',
        ),
      ],
      verify: (_) {
        verifyNever(() => mockNavigationRepository.saveCurrentIndex(any()));
      },
    );
  });

  group('DevocionalesNavigationBloc - Full User Flows', () {
    blocTest<DevocionalesNavigationBloc, DevocionalesNavigationState>(
      'complete flow: initialize -> next -> next -> previous',
      build: () => DevocionalesNavigationBloc(
        navigationRepository: mockNavigationRepository,
        devocionalRepository: mockDevocionalRepository,
      ),
      act: (bloc) async {
        final devocionales = createTestDevocionales(10);
        bloc.add(
            InitializeNavigation(initialIndex: 0, devocionales: devocionales));
        await Future.delayed(const Duration(milliseconds: 50));
        bloc.add(const NavigateToNext());
        await Future.delayed(const Duration(milliseconds: 50));
        bloc.add(const NavigateToNext());
        await Future.delayed(const Duration(milliseconds: 50));
        bloc.add(const NavigateToPrevious());
      },
      expect: () => [
        isA<NavigationReady>()
            .having((s) => s.currentIndex, 'currentIndex', 0)
            .having(
                (s) => s.currentDevocional.id, 'currentDevocional.id', 'dev_0'),
        isA<NavigationReady>()
            .having((s) => s.currentIndex, 'currentIndex', 1)
            .having(
                (s) => s.currentDevocional.id, 'currentDevocional.id', 'dev_1'),
        isA<NavigationReady>()
            .having((s) => s.currentIndex, 'currentIndex', 2)
            .having(
                (s) => s.currentDevocional.id, 'currentDevocional.id', 'dev_2'),
        isA<NavigationReady>()
            .having((s) => s.currentIndex, 'currentIndex', 1)
            .having(
                (s) => s.currentDevocional.id, 'currentDevocional.id', 'dev_1'),
      ],
    );

    blocTest<DevocionalesNavigationBloc, DevocionalesNavigationState>(
      'user quickly navigates to end and back to start',
      build: () => DevocionalesNavigationBloc(
        navigationRepository: mockNavigationRepository,
        devocionalRepository: mockDevocionalRepository,
      ),
      act: (bloc) async {
        final devocionales = createTestDevocionales(5);
        bloc.add(
            InitializeNavigation(initialIndex: 0, devocionales: devocionales));
        await Future.delayed(const Duration(milliseconds: 50));
        bloc.add(const NavigateToIndex(4)); // Jump to last
        await Future.delayed(const Duration(milliseconds: 50));
        bloc.add(const NavigateToNext()); // Try to go beyond (should not emit)
        await Future.delayed(const Duration(milliseconds: 50));
        bloc.add(const NavigateToIndex(0)); // Back to first
      },
      expect: () => [
        isA<NavigationReady>()
            .having((s) => s.currentIndex, 'currentIndex', 0)
            .having(
                (s) => s.currentDevocional.id, 'currentDevocional.id', 'dev_0'),
        isA<NavigationReady>()
            .having((s) => s.currentIndex, 'currentIndex', 4)
            .having(
                (s) => s.currentDevocional.id, 'currentDevocional.id', 'dev_4'),
        isA<NavigationReady>()
            .having((s) => s.currentIndex, 'currentIndex', 0)
            .having(
                (s) => s.currentDevocional.id, 'currentDevocional.id', 'dev_0'),
      ],
    );

    blocTest<DevocionalesNavigationBloc, DevocionalesNavigationState>(
      'navigation boundaries are respected (next at end)',
      build: () => DevocionalesNavigationBloc(
        navigationRepository: mockNavigationRepository,
        devocionalRepository: mockDevocionalRepository,
      ),
      act: (bloc) async {
        final devocionales = createTestDevocionales(10);
        bloc.add(
            InitializeNavigation(initialIndex: 9, devocionales: devocionales));
        await Future.delayed(const Duration(milliseconds: 50));
        bloc.add(const NavigateToNext()); // At last, should not emit
        await Future.delayed(const Duration(milliseconds: 50));
        bloc.add(const NavigateToNext()); // Still at last, should not emit
      },
      expect: () => [
        isA<NavigationReady>()
            .having((s) => s.currentIndex, 'currentIndex', 9)
            .having((s) => s.canNavigateNext, 'canNavigateNext', false),
      ],
    );

    blocTest<DevocionalesNavigationBloc, DevocionalesNavigationState>(
      'navigation boundaries are respected (previous at start)',
      build: () => DevocionalesNavigationBloc(
        navigationRepository: mockNavigationRepository,
        devocionalRepository: mockDevocionalRepository,
      ),
      act: (bloc) async {
        final devocionales = createTestDevocionales(10);
        bloc.add(
            InitializeNavigation(initialIndex: 0, devocionales: devocionales));
        await Future.delayed(const Duration(milliseconds: 50));
        bloc.add(const NavigateToPrevious()); // At first, should not emit
        await Future.delayed(const Duration(milliseconds: 50));
        bloc.add(const NavigateToPrevious()); // Still at first, should not emit
      },
      expect: () => [
        isA<NavigationReady>()
            .having((s) => s.currentIndex, 'currentIndex', 0)
            .having((s) => s.canNavigatePrevious, 'canNavigatePrevious', false),
      ],
    );
  });

  group('DevocionalesNavigationBloc - Edge Cases', () {
    blocTest<DevocionalesNavigationBloc, DevocionalesNavigationState>(
      'handles single devotional list correctly',
      build: () => DevocionalesNavigationBloc(
        navigationRepository: mockNavigationRepository,
        devocionalRepository: mockDevocionalRepository,
      ),
      act: (bloc) {
        final devocionales = createTestDevocionales(1);
        return bloc.add(
          InitializeNavigation(initialIndex: 0, devocionales: devocionales),
        );
      },
      expect: () => [
        isA<NavigationReady>()
            .having((s) => s.currentIndex, 'currentIndex', 0)
            .having((s) => s.totalDevocionales, 'totalDevocionales', 1)
            .having((s) => s.canNavigateNext, 'canNavigateNext', false)
            .having((s) => s.canNavigatePrevious, 'canNavigatePrevious', false),
      ],
    );

    blocTest<DevocionalesNavigationBloc, DevocionalesNavigationState>(
      'handles two devotional list correctly at start',
      build: () => DevocionalesNavigationBloc(
        navigationRepository: mockNavigationRepository,
        devocionalRepository: mockDevocionalRepository,
      ),
      act: (bloc) {
        final devocionales = createTestDevocionales(2);
        return bloc.add(
          InitializeNavigation(initialIndex: 0, devocionales: devocionales),
        );
      },
      expect: () => [
        isA<NavigationReady>()
            .having((s) => s.currentIndex, 'currentIndex', 0)
            .having((s) => s.canNavigateNext, 'canNavigateNext', true)
            .having((s) => s.canNavigatePrevious, 'canNavigatePrevious', false),
      ],
    );

    blocTest<DevocionalesNavigationBloc, DevocionalesNavigationState>(
      'handles two devotional list correctly at end',
      build: () => DevocionalesNavigationBloc(
        navigationRepository: mockNavigationRepository,
        devocionalRepository: mockDevocionalRepository,
      ),
      act: (bloc) {
        final devocionales = createTestDevocionales(2);
        return bloc.add(
          InitializeNavigation(initialIndex: 1, devocionales: devocionales),
        );
      },
      expect: () => [
        isA<NavigationReady>()
            .having((s) => s.currentIndex, 'currentIndex', 1)
            .having((s) => s.canNavigateNext, 'canNavigateNext', false)
            .having((s) => s.canNavigatePrevious, 'canNavigatePrevious', true),
      ],
    );
  });

  group('DevocionalesNavigationBloc - State Equality and Copyability', () {
    test('NavigationReady copyWith creates new instance with updated values',
        () {
      final devocionales = createTestDevocionales(10);
      final original = NavigationReady.calculate(
        currentIndex: 5,
        devocionales: devocionales,
      );

      final copied = original.copyWith(currentIndex: 6);

      expect(copied.currentIndex, 6);
      expect(copied.totalDevocionales, 10);
      expect(copied.canNavigateNext, original.canNavigateNext);
      expect(copied.canNavigatePrevious, original.canNavigatePrevious);
    });

    test('NavigationReady.calculate sets navigation capabilities correctly',
        () {
      final devocionales = createTestDevocionales(10);

      // At start
      final atStart = NavigationReady.calculate(
        currentIndex: 0,
        devocionales: devocionales,
      );
      expect(atStart.canNavigateNext, true);
      expect(atStart.canNavigatePrevious, false);
      expect(atStart.currentDevocional.id, 'dev_0');

      // In middle
      final inMiddle = NavigationReady.calculate(
        currentIndex: 5,
        devocionales: devocionales,
      );
      expect(inMiddle.canNavigateNext, true);
      expect(inMiddle.canNavigatePrevious, true);
      expect(inMiddle.currentDevocional.id, 'dev_5');

      // At end
      final atEnd = NavigationReady.calculate(
        currentIndex: 9,
        devocionales: devocionales,
      );
      expect(atEnd.canNavigateNext, false);
      expect(atEnd.canNavigatePrevious, true);
      expect(atEnd.currentDevocional.id, 'dev_9');
    });

    test('NavigationError contains error message', () {
      const state = NavigationError('Test error');
      expect(state.message, 'Test error');
    });
  });

  group('DevocionalesNavigationBloc - Event Equality', () {
    test('NavigateToNext events are equal', () {
      const event1 = NavigateToNext();
      const event2 = NavigateToNext();
      expect(event1.props, event2.props);
    });

    test('NavigateToIndex events with same index are equal', () {
      const event1 = NavigateToIndex(5);
      const event2 = NavigateToIndex(5);
      expect(event1.props, event2.props);
    });

    test('NavigateToIndex events with different indices are not equal', () {
      const event1 = NavigateToIndex(5);
      const event2 = NavigateToIndex(6);
      expect(event1.props, isNot(event2.props));
    });
  });

  group('DevocionalesNavigationBloc - Repository Integration', () {
    test('saveCurrentIndex is called through repository', () async {
      when(() => mockNavigationRepository.saveCurrentIndex(any()))
          .thenAnswer((_) async => {});

      final bloc = DevocionalesNavigationBloc(
        navigationRepository: mockNavigationRepository,
        devocionalRepository: mockDevocionalRepository,
      );

      final devocionales = createTestDevocionales(10);
      bloc.add(
          InitializeNavigation(initialIndex: 3, devocionales: devocionales));
      await Future.delayed(const Duration(milliseconds: 100));

      verify(() => mockNavigationRepository.saveCurrentIndex(3)).called(1);

      bloc.close();
    });

    test('loadCurrentIndex returns value from repository', () async {
      when(() => mockNavigationRepository.loadCurrentIndex())
          .thenAnswer((_) async => 5);

      final index = await mockNavigationRepository.loadCurrentIndex();
      expect(index, 5);
      verify(() => mockNavigationRepository.loadCurrentIndex()).called(1);
    });

    test('loadCurrentIndex returns 0 when no saved index', () async {
      when(() => mockNavigationRepository.loadCurrentIndex())
          .thenAnswer((_) async => 0);

      final index = await mockNavigationRepository.loadCurrentIndex();
      expect(index, 0);
      verify(() => mockNavigationRepository.loadCurrentIndex()).called(1);
    });
  });

  group('DevocionalesNavigationBloc - findFirstUnreadDevocionalIndex', () {
    test('returns 0 when all devotionals are unread', () {
      final devocionales = createTestDevocionales(2);

      when(() => mockDevocionalRepository.findFirstUnreadDevocionalIndex(
            devocionales,
            [],
          )).thenReturn(0);

      final bloc = DevocionalesNavigationBloc(
        navigationRepository: mockNavigationRepository,
        devocionalRepository: mockDevocionalRepository,
      );

      final index = bloc.findFirstUnreadDevocionalIndex(
        devocionales,
        [],
      );
      expect(index, 0);
      verify(() => mockDevocionalRepository.findFirstUnreadDevocionalIndex(
            devocionales,
            [],
          )).called(1);
      bloc.close();
    });

    test('returns first unread index when some are read', () {
      final devocionales = createTestDevocionales(3);

      when(() => mockDevocionalRepository.findFirstUnreadDevocionalIndex(
            devocionales,
            ['dev_0', 'dev_1'],
          )).thenReturn(2);

      final bloc = DevocionalesNavigationBloc(
        navigationRepository: mockNavigationRepository,
        devocionalRepository: mockDevocionalRepository,
      );

      final index = bloc.findFirstUnreadDevocionalIndex(
        devocionales,
        ['dev_0', 'dev_1'],
      );
      expect(index, 2);
      verify(() => mockDevocionalRepository.findFirstUnreadDevocionalIndex(
            devocionales,
            ['dev_0', 'dev_1'],
          )).called(1);
      bloc.close();
    });

    test('returns 0 when all devotionals are read', () {
      final devocionales = createTestDevocionales(2);

      when(() => mockDevocionalRepository.findFirstUnreadDevocionalIndex(
            devocionales,
            ['dev_0', 'dev_1'],
          )).thenReturn(0);

      final bloc = DevocionalesNavigationBloc(
        navigationRepository: mockNavigationRepository,
        devocionalRepository: mockDevocionalRepository,
      );

      final index = bloc.findFirstUnreadDevocionalIndex(
        devocionales,
        ['dev_0', 'dev_1'],
      );
      expect(index, 0);
      verify(() => mockDevocionalRepository.findFirstUnreadDevocionalIndex(
            devocionales,
            ['dev_0', 'dev_1'],
          )).called(1);
      bloc.close();
    });

    test('returns 0 when devotionals list is empty', () {
      when(() => mockDevocionalRepository.findFirstUnreadDevocionalIndex(
            [],
            [],
          )).thenReturn(0);

      final bloc = DevocionalesNavigationBloc(
        navigationRepository: mockNavigationRepository,
        devocionalRepository: mockDevocionalRepository,
      );

      final index = bloc.findFirstUnreadDevocionalIndex(
        [],
        [],
      );
      expect(index, 0);
      verify(() => mockDevocionalRepository.findFirstUnreadDevocionalIndex(
            [],
            [],
          )).called(1);
      bloc.close();
    });
  });
}
