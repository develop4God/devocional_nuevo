@Tags(['integration'])
library;

import 'package:devocional_nuevo/blocs/devocionales/devocionales_navigation_bloc.dart';
import 'package:devocional_nuevo/blocs/devocionales/devocionales_navigation_event.dart';
import 'package:devocional_nuevo/blocs/devocionales/devocionales_navigation_state.dart';
import 'package:devocional_nuevo/models/devocional_model.dart';
import 'package:devocional_nuevo/repositories/devocional_repository_impl.dart';
import 'package:devocional_nuevo/repositories/navigation_repository_impl.dart';
// test/integration/navigation_bloc_integration_test.dart
// Integration tests for Navigation BLoC with feature flag parity verification

import 'package:flutter_test/flutter_test.dart';

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

  group('Integration Tests - Navigation BLoC Parity', () {
    test(
      'Parity: Navigate next 5 times shows same index in both systems',
      () async {
        final devocionales = createTestDevocionales(10);

        // BLoC system
        final bloc = DevocionalesNavigationBloc(
          navigationRepository: NavigationRepositoryImpl(),
          devocionalRepository: DevocionalRepositoryImpl(),
        );

        bloc.add(
          InitializeNavigation(initialIndex: 0, devocionales: devocionales),
        );
        await Future.delayed(const Duration(milliseconds: 50));

        // Navigate next 5 times
        for (int i = 0; i < 5; i++) {
          bloc.add(const NavigateToNext());
          await Future.delayed(const Duration(milliseconds: 10));
        }

        // Verify final state
        expect(bloc.state, isA<NavigationReady>());
        final state = bloc.state as NavigationReady;
        expect(state.currentIndex, 5);
        expect(state.currentDevocional.id, 'dev_5');

        bloc.close();
      },
    );

    test('Parity: Navigate previous 3 times shows same index', () async {
      final devocionales = createTestDevocionales(10);

      final bloc = DevocionalesNavigationBloc(
        navigationRepository: NavigationRepositoryImpl(),
        devocionalRepository: DevocionalRepositoryImpl(),
      );

      bloc.add(
        InitializeNavigation(initialIndex: 5, devocionales: devocionales),
      );
      await Future.delayed(const Duration(milliseconds: 50));

      // Navigate previous 3 times
      for (int i = 0; i < 3; i++) {
        bloc.add(const NavigateToPrevious());
        await Future.delayed(const Duration(milliseconds: 10));
      }

      final state = bloc.state as NavigationReady;
      expect(state.currentIndex, 2);
      expect(state.currentDevocional.id, 'dev_2');

      bloc.close();
    });

    test('Parity: Navigate to first unread goes to same index', () async {
      final devocionales = createTestDevocionales(10);
      final readIds = ['dev_0', 'dev_1', 'dev_2'];

      final bloc = DevocionalesNavigationBloc(
        navigationRepository: NavigationRepositoryImpl(),
        devocionalRepository: DevocionalRepositoryImpl(),
      );

      final firstUnreadIndex = bloc.findFirstUnreadDevocionalIndex(
        devocionales,
        readIds,
      );

      expect(firstUnreadIndex, 3); // First unread should be at index 3

      bloc.add(
        InitializeNavigation(
          initialIndex: firstUnreadIndex,
          devocionales: devocionales,
        ),
      );
      await Future.delayed(const Duration(milliseconds: 50));

      final state = bloc.state as NavigationReady;
      expect(state.currentIndex, 3);
      expect(state.currentDevocional.id, 'dev_3');

      bloc.close();
    });

    test('Edge case: Navigate next at last devotional stays at last', () async {
      final devocionales = createTestDevocionales(10);

      final bloc = DevocionalesNavigationBloc(
        navigationRepository: NavigationRepositoryImpl(),
        devocionalRepository: DevocionalRepositoryImpl(),
      );

      bloc.add(
        InitializeNavigation(initialIndex: 9, devocionales: devocionales),
      );
      await Future.delayed(const Duration(milliseconds: 50));

      bloc.add(const NavigateToNext());
      await Future.delayed(const Duration(milliseconds: 10));

      final state = bloc.state as NavigationReady;
      expect(state.currentIndex, 9); // Should stay at 9
      expect(state.canNavigateNext, false);

      bloc.close();
    });

    test(
      'Edge case: Navigate previous at first devotional stays at first',
      () async {
        final devocionales = createTestDevocionales(10);

        final bloc = DevocionalesNavigationBloc(
          navigationRepository: NavigationRepositoryImpl(),
          devocionalRepository: DevocionalRepositoryImpl(),
        );

        bloc.add(
          InitializeNavigation(initialIndex: 0, devocionales: devocionales),
        );
        await Future.delayed(const Duration(milliseconds: 50));

        bloc.add(const NavigateToPrevious());
        await Future.delayed(const Duration(milliseconds: 10));

        final state = bloc.state as NavigationReady;
        expect(state.currentIndex, 0); // Should stay at 0
        expect(state.canNavigatePrevious, false);

        bloc.close();
      },
    );
  });

  group('Integration Tests - BLoC-Specific Behavior', () {
    test('State starts as NavigationInitial', () {
      final bloc = DevocionalesNavigationBloc(
        navigationRepository: NavigationRepositoryImpl(),
        devocionalRepository: DevocionalRepositoryImpl(),
      );

      expect(bloc.state, isA<NavigationInitial>());

      bloc.close();
    });

    test(
      'After initialization emits NavigationReady with correct devotional',
      () async {
        final devocionales = createTestDevocionales(10);

        final bloc = DevocionalesNavigationBloc(
          navigationRepository: NavigationRepositoryImpl(),
          devocionalRepository: DevocionalRepositoryImpl(),
        );

        bloc.add(
          InitializeNavigation(initialIndex: 3, devocionales: devocionales),
        );
        await Future.delayed(const Duration(milliseconds: 50));

        expect(bloc.state, isA<NavigationReady>());
        final state = bloc.state as NavigationReady;
        expect(state.currentIndex, 3);
        expect(state.currentDevocional.id, 'dev_3');
        expect(state.totalDevocionales, 10);

        bloc.close();
      },
    );

    test('Navigate next changes currentDevocional.id correctly', () async {
      final devocionales = createTestDevocionales(10);

      final bloc = DevocionalesNavigationBloc(
        navigationRepository: NavigationRepositoryImpl(),
        devocionalRepository: DevocionalRepositoryImpl(),
      );

      bloc.add(
        InitializeNavigation(initialIndex: 0, devocionales: devocionales),
      );
      await Future.delayed(const Duration(milliseconds: 50));

      var state = bloc.state as NavigationReady;
      expect(state.currentDevocional.id, 'dev_0');

      bloc.add(const NavigateToNext());
      await Future.delayed(const Duration(milliseconds: 10));

      state = bloc.state as NavigationReady;
      expect(state.currentDevocional.id, 'dev_1');

      bloc.close();
    });

    test('Empty devotionals list emits NavigationError', () async {
      final bloc = DevocionalesNavigationBloc(
        navigationRepository: NavigationRepositoryImpl(),
        devocionalRepository: DevocionalRepositoryImpl(),
      );

      bloc.add(const InitializeNavigation(initialIndex: 0, devocionales: []));
      await Future.delayed(const Duration(milliseconds: 50));

      expect(bloc.state, isA<NavigationError>());
      final state = bloc.state as NavigationError;
      expect(state.message, contains('No devotionals available'));

      bloc.close();
    });

    test('Index out of bounds is clamped to valid range', () async {
      final devocionales = createTestDevocionales(10);

      final bloc = DevocionalesNavigationBloc(
        navigationRepository: NavigationRepositoryImpl(),
        devocionalRepository: DevocionalRepositoryImpl(),
      );

      // Initialize with invalid high index
      bloc.add(
        InitializeNavigation(initialIndex: 100, devocionales: devocionales),
      );
      await Future.delayed(const Duration(milliseconds: 50));

      final state = bloc.state as NavigationReady;
      expect(state.currentIndex, 9); // Clamped to last valid index

      bloc.close();
    });
  });

  group('Integration Tests - Real User Flows', () {
    test('Scenario 1: First-time user flow', () async {
      final devocionales = createTestDevocionales(20);

      final bloc = DevocionalesNavigationBloc(
        navigationRepository: NavigationRepositoryImpl(),
        devocionalRepository: DevocionalRepositoryImpl(),
      );

      // First-time user: starts at first unread (index 0)
      final firstUnread = bloc.findFirstUnreadDevocionalIndex(devocionales, []);
      expect(firstUnread, 0);

      bloc.add(
        InitializeNavigation(
          initialIndex: firstUnread,
          devocionales: devocionales,
        ),
      );
      await Future.delayed(const Duration(milliseconds: 50));

      var state = bloc.state as NavigationReady;
      expect(state.currentIndex, 0);

      // Navigate next 10 times
      for (int i = 0; i < 10; i++) {
        bloc.add(const NavigateToNext());
        await Future.delayed(const Duration(milliseconds: 5));
      }

      state = bloc.state as NavigationReady;
      expect(state.currentIndex, 10);

      bloc.close();
    });

    test('Scenario 2: Returning user with 500 read devotionals', () async {
      final devocionales = createTestDevocionales(730);
      final readIds = List.generate(500, (i) => 'dev_$i');

      final bloc = DevocionalesNavigationBloc(
        navigationRepository: NavigationRepositoryImpl(),
        devocionalRepository: DevocionalRepositoryImpl(),
      );

      // Should start at index 500 (first unread)
      final firstUnread = bloc.findFirstUnreadDevocionalIndex(
        devocionales,
        readIds,
      );
      expect(firstUnread, 500);

      bloc.add(
        InitializeNavigation(
          initialIndex: firstUnread,
          devocionales: devocionales,
        ),
      );
      await Future.delayed(const Duration(milliseconds: 50));

      var state = bloc.state as NavigationReady;
      expect(state.currentIndex, 500);

      // Navigate next
      bloc.add(const NavigateToNext());
      await Future.delayed(const Duration(milliseconds: 10));

      state = bloc.state as NavigationReady;
      expect(state.currentIndex, 501);

      bloc.close();
    });

    test('Scenario 3: All devotionals read', () async {
      final devocionales = createTestDevocionales(730);
      final readIds = List.generate(730, (i) => 'dev_$i');

      final bloc = DevocionalesNavigationBloc(
        navigationRepository: NavigationRepositoryImpl(),
        devocionalRepository: DevocionalRepositoryImpl(),
      );

      // When all read, should return to index 0
      final firstUnread = bloc.findFirstUnreadDevocionalIndex(
        devocionales,
        readIds,
      );
      expect(firstUnread, 0);

      bloc.add(
        InitializeNavigation(
          initialIndex: firstUnread,
          devocionales: devocionales,
        ),
      );
      await Future.delayed(const Duration(milliseconds: 50));

      final state = bloc.state as NavigationReady;
      expect(state.currentIndex, 0);

      bloc.close();
    });
  });

  group('Integration Tests - Edge Cases', () {
    test('Single devotional list - buttons disabled', () async {
      final devocionales = createTestDevocionales(1);

      final bloc = DevocionalesNavigationBloc(
        navigationRepository: NavigationRepositoryImpl(),
        devocionalRepository: DevocionalRepositoryImpl(),
      );

      bloc.add(
        InitializeNavigation(initialIndex: 0, devocionales: devocionales),
      );
      await Future.delayed(const Duration(milliseconds: 50));

      final state = bloc.state as NavigationReady;
      expect(state.currentIndex, 0);
      expect(state.canNavigateNext, false);
      expect(state.canNavigatePrevious, false);
      expect(state.totalDevocionales, 1);

      bloc.close();
    });

    test('Index 729 - navigate next stays at 729', () async {
      final devocionales = createTestDevocionales(730);

      final bloc = DevocionalesNavigationBloc(
        navigationRepository: NavigationRepositoryImpl(),
        devocionalRepository: DevocionalRepositoryImpl(),
      );

      bloc.add(
        InitializeNavigation(initialIndex: 729, devocionales: devocionales),
      );
      await Future.delayed(const Duration(milliseconds: 50));

      var state = bloc.state as NavigationReady;
      expect(state.currentIndex, 729);
      expect(state.canNavigateNext, false);

      bloc.add(const NavigateToNext());
      await Future.delayed(const Duration(milliseconds: 10));

      state = bloc.state as NavigationReady;
      expect(state.currentIndex, 729); // Should stay at 729

      bloc.close();
    });

    test('Index 0 - navigate previous stays at 0', () async {
      final devocionales = createTestDevocionales(730);

      final bloc = DevocionalesNavigationBloc(
        navigationRepository: NavigationRepositoryImpl(),
        devocionalRepository: DevocionalRepositoryImpl(),
      );

      bloc.add(
        InitializeNavigation(initialIndex: 0, devocionales: devocionales),
      );
      await Future.delayed(const Duration(milliseconds: 50));

      var state = bloc.state as NavigationReady;
      expect(state.currentIndex, 0);
      expect(state.canNavigatePrevious, false);

      bloc.add(const NavigateToPrevious());
      await Future.delayed(const Duration(milliseconds: 10));

      state = bloc.state as NavigationReady;
      expect(state.currentIndex, 0); // Should stay at 0

      bloc.close();
    });

    test(
      '730 devotionals - performance < 100ms for first unread lookup',
      () async {
        final devocionales = createTestDevocionales(730);
        final readIds = List.generate(500, (i) => 'dev_$i');

        final bloc = DevocionalesNavigationBloc(
          navigationRepository: NavigationRepositoryImpl(),
          devocionalRepository: DevocionalRepositoryImpl(),
        );

        final stopwatch = Stopwatch()..start();
        final firstUnread = bloc.findFirstUnreadDevocionalIndex(
          devocionales,
          readIds,
        );
        stopwatch.stop();

        expect(firstUnread, 500);
        expect(
          stopwatch.elapsedMilliseconds,
          lessThan(100),
          reason: 'Performance should be < 100ms with optimized Set lookup',
        );

        bloc.close();
      },
    );

    test('Two devotional list - navigation works correctly at start', () async {
      final devocionales = createTestDevocionales(2);

      final bloc = DevocionalesNavigationBloc(
        navigationRepository: NavigationRepositoryImpl(),
        devocionalRepository: DevocionalRepositoryImpl(),
      );

      bloc.add(
        InitializeNavigation(initialIndex: 0, devocionales: devocionales),
      );
      await Future.delayed(const Duration(milliseconds: 50));

      var state = bloc.state as NavigationReady;
      expect(state.currentIndex, 0);
      expect(state.canNavigateNext, true);
      expect(state.canNavigatePrevious, false);

      bloc.add(const NavigateToNext());
      await Future.delayed(const Duration(milliseconds: 10));

      state = bloc.state as NavigationReady;
      expect(state.currentIndex, 1);
      expect(state.canNavigateNext, false);
      expect(state.canNavigatePrevious, true);

      bloc.close();
    });

    test('Update devotionals list maintains valid index', () async {
      final devocionales = createTestDevocionales(20);

      final bloc = DevocionalesNavigationBloc(
        navigationRepository: NavigationRepositoryImpl(),
        devocionalRepository: DevocionalRepositoryImpl(),
      );

      bloc.add(
        InitializeNavigation(initialIndex: 15, devocionales: devocionales),
      );
      await Future.delayed(const Duration(milliseconds: 50));

      var state = bloc.state as NavigationReady;
      expect(state.currentIndex, 15);

      // Update with smaller list - mark first 9 as read to get index 9
      final readIds = List.generate(9, (i) => 'dev_$i');
      final newDevocionales = createTestDevocionales(10);
      bloc.add(UpdateDevocionales(newDevocionales, readIds));
      await Future.delayed(const Duration(milliseconds: 10));

      state = bloc.state as NavigationReady;
      expect(state.currentIndex, 9); // At first unread (last item)
      expect(state.totalDevocionales, 10);

      bloc.close();
    });
  });
}
