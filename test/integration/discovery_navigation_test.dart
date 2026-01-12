// test/integration/discovery_navigation_test.dart
// Integration tests for Discovery navigation from drawer

import 'package:devocional_nuevo/blocs/discovery/discovery_bloc.dart';
import 'package:devocional_nuevo/blocs/discovery/discovery_event.dart';
import 'package:devocional_nuevo/blocs/discovery/discovery_state.dart';
import 'package:devocional_nuevo/pages/discovery_list_page.dart';
import 'package:devocional_nuevo/repositories/discovery_repository.dart';
import 'package:devocional_nuevo/services/discovery_progress_tracker.dart';
import 'package:devocional_nuevo/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';

class MockDiscoveryRepository extends Mock implements DiscoveryRepository {}

class MockDiscoveryProgressTracker extends Mock
    implements DiscoveryProgressTracker {}

class MockHttpClient extends Mock implements http.Client {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Discovery Navigation Integration Tests', () {
    late MockDiscoveryRepository mockRepository;
    late MockDiscoveryProgressTracker mockProgressTracker;

    setUp(() {
      mockRepository = MockDiscoveryRepository();
      mockProgressTracker = MockDiscoveryProgressTracker();
    });

    testWidgets('Discovery feature flag is enabled', (tester) async {
      expect(Constants.enableDiscoveryFeature, isTrue,
          reason: 'Discovery feature should be enabled');
    });

    testWidgets('DiscoveryListPage shows loading state initially',
        (tester) async {
      when(() => mockRepository.fetchAvailableStudies())
          .thenAnswer((_) async => ['study1', 'study2']);

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<DiscoveryBloc>(
            create: (_) => DiscoveryBloc(
              repository: mockRepository,
              progressTracker: mockProgressTracker,
            ),
            child: const DiscoveryListPage(),
          ),
        ),
      );

      // Initially should show loading indicator
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Wait for state to update
      await tester.pumpAndSettle();
    });

    testWidgets('DiscoveryListPage displays error state with retry button',
        (tester) async {
      when(() => mockRepository.fetchAvailableStudies())
          .thenThrow(Exception('Network error'));

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

      // Initial loading
      await tester.pump();

      // Trigger load
      bloc.add(LoadDiscoveryStudies());
      await tester.pumpAndSettle();

      // Should show error state
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.byIcon(Icons.refresh), findsOneWidget);

      bloc.close();
    });

    testWidgets('DiscoveryListPage displays grid when studies are loaded',
        (tester) async {
      when(() => mockRepository.fetchAvailableStudies())
          .thenAnswer((_) async => ['study1', 'study2', 'study3']);

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

      // Wait for initial load
      await tester.pump();
      await tester.pumpAndSettle();

      // Should show grid view with study cards
      expect(find.byType(GridView), findsOneWidget);

      bloc.close();
    });

    testWidgets('DiscoveryListPage shows empty state when no studies available',
        (tester) async {
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

      // Wait for load
      await tester.pump();
      await tester.pumpAndSettle();

      // Should show empty state
      expect(find.byIcon(Icons.explore_outlined), findsOneWidget);

      bloc.close();
    });

    test('DiscoveryBloc loads studies successfully', () async {
      when(() => mockRepository.fetchAvailableStudies())
          .thenAnswer((_) async => ['study1', 'study2']);

      final bloc = DiscoveryBloc(
        repository: mockRepository,
        progressTracker: mockProgressTracker,
      );

      bloc.add(LoadDiscoveryStudies());
      await Future.delayed(const Duration(milliseconds: 100));

      expect(bloc.state, isA<DiscoveryLoaded>());
      final state = bloc.state as DiscoveryLoaded;
      expect(state.availableStudyIds.length, 2);
      expect(state.availableStudyIds, contains('study1'));
      expect(state.availableStudyIds, contains('study2'));

      bloc.close();
    });

    test('DiscoveryBloc handles error when loading studies', () async {
      when(() => mockRepository.fetchAvailableStudies())
          .thenThrow(Exception('Network error'));

      final bloc = DiscoveryBloc(
        repository: mockRepository,
        progressTracker: mockProgressTracker,
      );

      bloc.add(LoadDiscoveryStudies());
      await Future.delayed(const Duration(milliseconds: 100));

      expect(bloc.state, isA<DiscoveryError>());
      final state = bloc.state as DiscoveryError;
      expect(state.message, contains('Error al cargar estudios Discovery'));

      bloc.close();
    });
  });
}
