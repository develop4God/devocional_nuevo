@Tags(['critical', 'unit', 'blocs'])
library;

import 'package:devocional_nuevo/blocs/testimony_bloc.dart';
import 'package:devocional_nuevo/blocs/testimony_event.dart';
import 'package:devocional_nuevo/blocs/testimony_state.dart';
import 'package:devocional_nuevo/services/localization_service.dart';
import 'package:devocional_nuevo/services/service_locator.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Mock LocalizationService for testing
class MockLocalizationService extends Mock implements LocalizationService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TestimonyBloc Tests', () {
    late TestimonyBloc bloc;
    late MockLocalizationService mockLocalizationService;
    late ServiceLocator locator;

    setUp(() {
      SharedPreferences.setMockInitialValues({});

      // Set up service locator and mock localization service
      locator = ServiceLocator();
      locator.reset();

      mockLocalizationService = MockLocalizationService();
      when(() => mockLocalizationService.translate(any()))
          .thenReturn('Mocked error message');

      // Register the mock service in the service locator
      locator.registerSingleton<LocalizationService>(mockLocalizationService);

      bloc = TestimonyBloc();
    });

    tearDown(() {
      bloc.close();
      locator.reset();
    });

    test('initial state should be TestimonyInitial', () {
      expect(bloc.state, isA<TestimonyInitial>());
    });

    test('should load empty list when no testimonies exist', () async {
      bloc.add(LoadTestimonies());

      await expectLater(
        bloc.stream,
        emitsInOrder([
          isA<TestimonyLoading>(),
          isA<TestimonyLoaded>().having(
            (s) => s.testimonies.isEmpty,
            'isEmpty',
            true,
          ),
        ]),
      );
    });

    test('should add a new testimony', () async {
      bloc.add(AddTestimony('God has blessed me greatly'));

      await expectLater(
        bloc.stream,
        emitsInOrder([
          isA<TestimonyLoaded>().having(
            (s) => s.testimonies.length,
            'length',
            1,
          ),
        ]),
      );

      final state = bloc.state as TestimonyLoaded;
      expect(state.testimonies[0].text, equals('God has blessed me greatly'));
    });

    test('should not add testimony with empty text', () async {
      // Load initial state first
      bloc.add(LoadTestimonies());
      await bloc.stream.firstWhere((state) => state is TestimonyLoaded);

      // Try to add empty text
      bloc.add(AddTestimony(''));

      // Should not emit a new state or should emit error
      await expectLater(
        bloc.stream,
        emits(
          isA<TestimonyLoaded>().having(
            (s) => s.errorMessage,
            'errorMessage',
            isNotNull,
          ),
        ),
      );
    });

    test('should edit an existing testimony', () async {
      // First add a testimony
      bloc.add(AddTestimony('Original testimony text'));

      await bloc.stream.firstWhere((state) => state is TestimonyLoaded);

      final state = bloc.state as TestimonyLoaded;
      final testimonyId = state.testimonies[0].id;

      // Now edit it
      bloc.add(EditTestimony(testimonyId, 'Updated testimony text'));

      await expectLater(
        bloc.stream,
        emits(
          isA<TestimonyLoaded>().having(
            (s) => s.testimonies[0].text,
            'text',
            equals('Updated testimony text'),
          ),
        ),
      );
    });

    test('should delete a testimony', () async {
      // First add a testimony
      bloc.add(AddTestimony('To be deleted'));

      await bloc.stream.firstWhere((state) => state is TestimonyLoaded);

      final state = bloc.state as TestimonyLoaded;
      final testimonyId = state.testimonies[0].id;

      // Now delete it
      bloc.add(DeleteTestimony(testimonyId));

      await expectLater(
        bloc.stream,
        emits(
          isA<TestimonyLoaded>().having(
            (s) => s.testimonies.isEmpty,
            'isEmpty',
            true,
          ),
        ),
      );
    });

    test('should refresh testimonies', () async {
      // Add a testimony first
      bloc.add(AddTestimony('Test testimony'));

      await bloc.stream.firstWhere((state) => state is TestimonyLoaded);

      // Now refresh
      bloc.add(RefreshTestimonies());

      await expectLater(
        bloc.stream,
        emits(
          isA<TestimonyLoaded>().having(
            (s) => s.testimonies.length,
            'length',
            1,
          ),
        ),
      );
    });

    test('should clear error message', () async {
      // Load initial state first
      bloc.add(LoadTestimonies());
      await bloc.stream.firstWhere((state) => state is TestimonyLoaded);

      // First cause an error (empty text)
      bloc.add(AddTestimony(''));

      await bloc.stream.firstWhere(
        (state) => state is TestimonyLoaded && state.errorMessage != null,
      );

      // Now clear the error
      bloc.add(ClearTestimonyError());

      await expectLater(
        bloc.stream,
        emits(
          isA<TestimonyLoaded>().having(
            (s) => s.errorMessage,
            'errorMessage',
            isNull,
          ),
        ),
      );
    });

    test('should sort testimonies by creation date (newest first)', () async {
      // Add multiple testimonies
      bloc.add(AddTestimony('First testimony'));

      await bloc.stream.firstWhere((state) => state is TestimonyLoaded);

      // Wait a bit to ensure different timestamps
      await Future.delayed(const Duration(milliseconds: 10));

      bloc.add(AddTestimony('Second testimony'));

      await bloc.stream.firstWhere(
        (state) => state is TestimonyLoaded && state.testimonies.length == 2,
      );

      final state = bloc.state as TestimonyLoaded;

      // The most recent should be first
      expect(state.testimonies[0].text, equals('Second testimony'));
      expect(state.testimonies[1].text, equals('First testimony'));
    });

    test('should persist testimonies to storage', () async {
      bloc.add(AddTestimony('Persistent testimony'));

      await bloc.stream.firstWhere((state) => state is TestimonyLoaded);

      // Create a new bloc instance
      final newBloc = TestimonyBloc();
      newBloc.add(LoadTestimonies());

      await expectLater(
        newBloc.stream,
        emitsInOrder([
          isA<TestimonyLoading>(),
          isA<TestimonyLoaded>().having(
            (s) => s.testimonies.length,
            'length',
            1,
          ),
        ]),
      );

      await newBloc.close();
    });
  });
}
