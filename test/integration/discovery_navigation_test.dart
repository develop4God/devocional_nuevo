// test/integration/discovery_navigation_test.dart
// Integration tests for Discovery navigation and BLoC functionality

import 'package:devocional_nuevo/blocs/discovery/discovery_bloc.dart';
import 'package:devocional_nuevo/blocs/discovery/discovery_event.dart';
import 'package:devocional_nuevo/blocs/discovery/discovery_state.dart';
import 'package:devocional_nuevo/repositories/discovery_repository.dart';
import 'package:devocional_nuevo/services/discovery_progress_tracker.dart';
import 'package:devocional_nuevo/utils/constants.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockDiscoveryRepository extends Mock implements DiscoveryRepository {}

class MockDiscoveryProgressTracker extends Mock
    implements DiscoveryProgressTracker {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Discovery Navigation Integration Tests', () {
    late MockDiscoveryRepository mockRepository;
    late MockDiscoveryProgressTracker mockProgressTracker;

    setUp(() {
      mockRepository = MockDiscoveryRepository();
      mockProgressTracker = MockDiscoveryProgressTracker();
    });

    test('Discovery feature flag is enabled', () {
      expect(Constants.enableDiscoveryFeature, isTrue,
          reason: 'Discovery feature should be enabled');
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

    test('DiscoveryBloc transitions through loading to loaded state', () async {
      when(() => mockRepository.fetchAvailableStudies())
          .thenAnswer((_) async => ['study1']);

      final bloc = DiscoveryBloc(
        repository: mockRepository,
        progressTracker: mockProgressTracker,
      );

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

    test('DiscoveryLoaded state tracks available studies correctly', () async {
      when(() => mockRepository.fetchAvailableStudies())
          .thenAnswer((_) async => ['study1', 'study2', 'study3']);

      final bloc = DiscoveryBloc(
        repository: mockRepository,
        progressTracker: mockProgressTracker,
      );

      bloc.add(LoadDiscoveryStudies());
      await Future.delayed(const Duration(milliseconds: 100));

      final state = bloc.state as DiscoveryLoaded;
      expect(state.availableStudiesCount, 3);
      expect(state.loadedStudiesCount, 0);
      expect(state.isStudyLoaded('study1'), isFalse);

      bloc.close();
    });

    test('DiscoveryBloc starts in initial state', () {
      final bloc = DiscoveryBloc(
        repository: mockRepository,
        progressTracker: mockProgressTracker,
      );

      expect(bloc.state, isA<DiscoveryInitial>());

      bloc.close();
    });

    test('Multiple load events are handled correctly', () async {
      when(() => mockRepository.fetchAvailableStudies())
          .thenAnswer((_) async => ['study1']);

      final bloc = DiscoveryBloc(
        repository: mockRepository,
        progressTracker: mockProgressTracker,
      );

      // Send multiple load events
      bloc.add(LoadDiscoveryStudies());
      bloc.add(LoadDiscoveryStudies());
      await Future.delayed(const Duration(milliseconds: 200));

      expect(bloc.state, isA<DiscoveryLoaded>());
      
      bloc.close();
    });
  });
}
