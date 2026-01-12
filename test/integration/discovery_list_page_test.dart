// test/integration/discovery_list_page_test.dart
// Integration tests for DiscoveryListPage widget

import 'package:devocional_nuevo/blocs/discovery/discovery_bloc.dart';
import 'package:devocional_nuevo/blocs/discovery/discovery_state.dart';
import 'package:devocional_nuevo/pages/discovery_list_page.dart';
import 'package:devocional_nuevo/repositories/discovery_repository.dart';
import 'package:devocional_nuevo/services/discovery_progress_tracker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockDiscoveryRepository extends Mock implements DiscoveryRepository {}

class MockDiscoveryProgressTracker extends Mock
    implements DiscoveryProgressTracker {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DiscoveryListPage Widget Tests', () {
    late MockDiscoveryRepository mockRepository;
    late MockDiscoveryProgressTracker mockProgressTracker;

    setUp(() {
      mockRepository = MockDiscoveryRepository();
      mockProgressTracker = MockDiscoveryProgressTracker();
    });

    testWidgets('Shows loading state then studies grid', (tester) async {
      when(() => mockRepository.fetchAvailableStudies())
          .thenAnswer((_) async => ['study1', 'study2']);

      final bloc = DiscoveryBloc(
        repository: mockRepository,
        progressTracker: mockProgressTracker,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<DiscoveryBloc>.value(
            value: bloc,
            child: const DiscoveryListPage(),
          ),
        ),
      );

      // Initially shows loading
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Wait for data to load
      await tester.pump();
      await tester.pumpAndSettle();

      // Now should show grid
      expect(find.byType(GridView), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);

      bloc.close();
    });

    testWidgets('Grid displays correct number of study cards', (tester) async {
      when(() => mockRepository.fetchAvailableStudies()).thenAnswer(
        (_) async => ['study1', 'study2', 'study3', 'study4'],
      );

      final bloc = DiscoveryBloc(
        repository: mockRepository,
        progressTracker: mockProgressTracker,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<DiscoveryBloc>.value(
            value: bloc,
            child: const DiscoveryListPage(),
          ),
        ),
      );

      await tester.pump();
      await tester.pumpAndSettle();

      // Should display 4 study cards
      expect(find.byType(Card), findsNWidgets(4));

      bloc.close();
    });

    testWidgets('Retry button works on error state', (tester) async {
      var callCount = 0;
      when(() => mockRepository.fetchAvailableStudies()).thenAnswer((_) async {
        callCount++;
        if (callCount == 1) {
          throw Exception('Network error');
        }
        return ['study1'];
      });

      final bloc = DiscoveryBloc(
        repository: mockRepository,
        progressTracker: mockProgressTracker,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<DiscoveryBloc>.value(
            value: bloc,
            child: const DiscoveryListPage(),
          ),
        ),
      );

      await tester.pump();
      await tester.pumpAndSettle();

      // Should show error state
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.byIcon(Icons.refresh), findsOneWidget);

      // Tap retry button
      await tester.tap(find.byIcon(Icons.refresh));
      await tester.pump();
      await tester.pumpAndSettle();

      // Should now show grid after successful retry
      expect(find.byType(GridView), findsOneWidget);
      expect(callCount, 2);

      bloc.close();
    });

    testWidgets('Empty state shows appropriate message', (tester) async {
      when(() => mockRepository.fetchAvailableStudies())
          .thenAnswer((_) async => []);

      final bloc = DiscoveryBloc(
        repository: mockRepository,
        progressTracker: mockProgressTracker,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<DiscoveryBloc>.value(
            value: bloc,
            child: const DiscoveryListPage(),
          ),
        ),
      );

      await tester.pump();
      await tester.pumpAndSettle();

      // Should show empty state with appropriate icon
      expect(find.byIcon(Icons.explore_outlined), findsOneWidget);

      bloc.close();
    });

    testWidgets('Study card tap shows snackbar', (tester) async {
      when(() => mockRepository.fetchAvailableStudies())
          .thenAnswer((_) async => ['morning_star_001']);

      final bloc = DiscoveryBloc(
        repository: mockRepository,
        progressTracker: mockProgressTracker,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<DiscoveryBloc>.value(
            value: bloc,
            child: const DiscoveryListPage(),
          ),
        ),
      );

      await tester.pump();
      await tester.pumpAndSettle();

      // Tap on the study card
      await tester.tap(find.byType(Card).first);
      await tester.pump();

      // Should show snackbar (this is a placeholder until detail page is implemented)
      expect(find.byType(SnackBar), findsOneWidget);

      bloc.close();
    });

    test('DiscoveryBloc state transitions correctly', () async {
      when(() => mockRepository.fetchAvailableStudies())
          .thenAnswer((_) async => ['study1', 'study2']);

      final bloc = DiscoveryBloc(
        repository: mockRepository,
        progressTracker: mockProgressTracker,
      );

      // Initial state
      expect(bloc.state, isA<DiscoveryInitial>());

      // Trigger load
      final states = <DiscoveryState>[];
      final subscription = bloc.stream.listen(states.add);

      bloc.add(LoadDiscoveryStudies());
      await Future.delayed(const Duration(milliseconds: 100));

      // Should transition through states
      expect(states.any((s) => s is DiscoveryLoading), isTrue);
      expect(states.any((s) => s is DiscoveryLoaded), isTrue);

      await subscription.cancel();
      bloc.close();
    });
  });
}
