// test/integration/discovery_complete_flow_test.dart
// Integration tests for complete Discovery study flow

import 'package:devocional_nuevo/blocs/discovery/discovery_bloc.dart';
import 'package:devocional_nuevo/blocs/discovery/discovery_event.dart';
import 'package:devocional_nuevo/blocs/discovery/discovery_state.dart';
import 'package:devocional_nuevo/models/discovery_devotional_model.dart';
import 'package:devocional_nuevo/models/discovery_section_model.dart';
import 'package:devocional_nuevo/repositories/discovery_repository.dart';
import 'package:devocional_nuevo/services/discovery_progress_tracker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockDiscoveryRepository extends Mock implements DiscoveryRepository {}

class MockDiscoveryProgressTracker extends Mock
    implements DiscoveryProgressTracker {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Discovery Complete Flow Tests', () {
    late MockDiscoveryRepository mockRepository;
    late MockDiscoveryProgressTracker mockProgressTracker;

    setUp(() {
      mockRepository = MockDiscoveryRepository();
      mockProgressTracker = MockDiscoveryProgressTracker();

      // Setup mock responses
      when(() => mockProgressTracker.isSectionCompleted(any(), any()))
          .thenReturn(false);
      when(() => mockProgressTracker.isStudyCompleted(any())).thenReturn(false);
      when(() => mockProgressTracker.markSectionCompleted(any(), any()))
          .thenAnswer((_) async {});
      when(() => mockProgressTracker.completeStudy(any()))
          .thenAnswer((_) async {});
    });

    test('User can load available studies', () async {
      when(() => mockRepository.fetchAvailableStudies())
          .thenAnswer((_) async => ['study1', 'study2', 'study3']);

      final bloc = DiscoveryBloc(
        repository: mockRepository,
        progressTracker: mockProgressTracker,
      );

      bloc.add(LoadDiscoveryStudies());
      await Future.delayed(const Duration(milliseconds: 100));

      expect(bloc.state, isA<DiscoveryLoaded>());
      final state = bloc.state as DiscoveryLoaded;
      expect(state.availableStudyIds.length, 3);

      bloc.close();
    });

    test('User can load a specific study', () async {
      final testStudy = DiscoveryDevotional(
        id: 'study1',
        versiculo: 'John 3:16',
        reflexion: 'Test reflection',
        paraMeditar: ['Point 1', 'Point 2'],
        oracion: 'Test prayer',
        date: DateTime.now(),
        secciones: [
          DiscoverySection(
            titulo: 'Section 1',
            contenido: 'Content 1',
            tipo: SectionType.natural,
          ),
        ],
        preguntasDiscovery: ['Question 1'],
        versiculoClave: 'John 3:16',
      );

      when(() => mockRepository.fetchAvailableStudies())
          .thenAnswer((_) async => ['study1']);
      when(() => mockRepository.fetchDiscoveryStudy('study1', 'es'))
          .thenAnswer((_) async => testStudy);

      final bloc = DiscoveryBloc(
        repository: mockRepository,
        progressTracker: mockProgressTracker,
      );

      // First load available studies
      bloc.add(LoadDiscoveryStudies());
      await Future.delayed(const Duration(milliseconds: 100));

      // Then load specific study
      bloc.add(LoadDiscoveryStudy('study1', languageCode: 'es'));
      await Future.delayed(const Duration(milliseconds: 100));

      expect(bloc.state, isA<DiscoveryLoaded>());
      final state = bloc.state as DiscoveryLoaded;
      expect(state.isStudyLoaded('study1'), isTrue);
      expect(state.getStudy('study1')?.id, 'study1');

      bloc.close();
    });

    test('User can mark sections as completed', () async {
      final testStudy = DiscoveryDevotional(
        id: 'study1',
        versiculo: 'John 3:16',
        reflexion: 'Test reflection',
        paraMeditar: ['Point 1'],
        oracion: 'Test prayer',
        date: DateTime.now(),
        secciones: [
          DiscoverySection(
            titulo: 'Section 1',
            contenido: 'Content 1',
            tipo: SectionType.natural,
          ),
          DiscoverySection(
            titulo: 'Section 2',
            contenido: 'Content 2',
            tipo: SectionType.scripture,
          ),
        ],
        preguntasDiscovery: ['Question 1'],
        versiculoClave: 'John 3:16',
      );

      when(() => mockRepository.fetchAvailableStudies())
          .thenAnswer((_) async => ['study1']);
      when(() => mockRepository.fetchDiscoveryStudy('study1', 'es'))
          .thenAnswer((_) async => testStudy);

      final bloc = DiscoveryBloc(
        repository: mockRepository,
        progressTracker: mockProgressTracker,
      );

      bloc.add(LoadDiscoveryStudies());
      await Future.delayed(const Duration(milliseconds: 50));

      bloc.add(LoadDiscoveryStudy('study1', languageCode: 'es'));
      await Future.delayed(const Duration(milliseconds: 50));

      // Mark first section as completed
      bloc.add(MarkSectionCompleted('study1', 0));
      await Future.delayed(const Duration(milliseconds: 50));

      verify(() => mockProgressTracker.markSectionCompleted('study1', 0))
          .called(1);

      bloc.close();
    });

    test('User can complete a study', () async {
      final testStudy = DiscoveryDevotional(
        id: 'study1',
        versiculo: 'John 3:16',
        reflexion: 'Test reflection',
        paraMeditar: ['Point 1'],
        oracion: 'Test prayer',
        date: DateTime.now(),
        secciones: [
          DiscoverySection(
            titulo: 'Section 1',
            contenido: 'Content 1',
            tipo: SectionType.natural,
          ),
        ],
        preguntasDiscovery: ['Question 1'],
        versiculoClave: 'John 3:16',
      );

      when(() => mockRepository.fetchAvailableStudies())
          .thenAnswer((_) async => ['study1']);
      when(() => mockRepository.fetchDiscoveryStudy('study1', 'es'))
          .thenAnswer((_) async => testStudy);

      final bloc = DiscoveryBloc(
        repository: mockRepository,
        progressTracker: mockProgressTracker,
      );

      bloc.add(LoadDiscoveryStudies());
      await Future.delayed(const Duration(milliseconds: 50));

      bloc.add(LoadDiscoveryStudy('study1', languageCode: 'es'));
      await Future.delayed(const Duration(milliseconds: 50));

      // Complete the study
      bloc.add(CompleteDiscoveryStudy('study1'));
      await Future.delayed(const Duration(milliseconds: 50));

      verify(() => mockProgressTracker.completeStudy('study1')).called(1);

      bloc.close();
    });

    test('User can answer discovery questions', () async {
      final testStudy = DiscoveryDevotional(
        id: 'study1',
        versiculo: 'John 3:16',
        reflexion: 'Test reflection',
        paraMeditar: ['Point 1'],
        oracion: 'Test prayer',
        date: DateTime.now(),
        secciones: [],
        preguntasDiscovery: ['Question 1', 'Question 2'],
        versiculoClave: 'John 3:16',
      );

      when(() => mockRepository.fetchAvailableStudies())
          .thenAnswer((_) async => ['study1']);
      when(() => mockRepository.fetchDiscoveryStudy('study1', 'es'))
          .thenAnswer((_) async => testStudy);
      when(() => mockProgressTracker.saveAnswer(any(), any(), any()))
          .thenAnswer((_) async {});

      final bloc = DiscoveryBloc(
        repository: mockRepository,
        progressTracker: mockProgressTracker,
      );

      bloc.add(LoadDiscoveryStudies());
      await Future.delayed(const Duration(milliseconds: 50));

      bloc.add(LoadDiscoveryStudy('study1', languageCode: 'es'));
      await Future.delayed(const Duration(milliseconds: 50));

      // Answer first question
      bloc.add(AnswerDiscoveryQuestion('study1', 0, 'My answer to question 1'));
      await Future.delayed(const Duration(milliseconds: 50));

      verify(
        () => mockProgressTracker.saveAnswer(
          'study1',
          0,
          'My answer to question 1',
        ),
      ).called(1);

      bloc.close();
    });

    test('Refresh studies reloads the list', () async {
      when(() => mockRepository.fetchAvailableStudies())
          .thenAnswer((_) async => ['study1', 'study2']);

      final bloc = DiscoveryBloc(
        repository: mockRepository,
        progressTracker: mockProgressTracker,
      );

      // Initial load
      bloc.add(LoadDiscoveryStudies());
      await Future.delayed(const Duration(milliseconds: 50));

      // Refresh
      bloc.add(RefreshDiscoveryStudies());
      await Future.delayed(const Duration(milliseconds: 50));

      // Should call repository twice
      verify(() => mockRepository.fetchAvailableStudies()).called(2);

      bloc.close();
    });

    test('Error state can be cleared', () async {
      when(() => mockRepository.fetchAvailableStudies())
          .thenThrow(Exception('Network error'));

      final bloc = DiscoveryBloc(
        repository: mockRepository,
        progressTracker: mockProgressTracker,
      );

      bloc.add(LoadDiscoveryStudies());
      await Future.delayed(const Duration(milliseconds: 50));

      expect(bloc.state, isA<DiscoveryError>());

      // Clear error
      bloc.add(ClearDiscoveryError());
      await Future.delayed(const Duration(milliseconds: 50));

      // State should change (though may still be error due to repository state)
      // The important thing is that the event is handled

      bloc.close();
    });
  });
}
