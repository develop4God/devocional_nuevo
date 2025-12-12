// test/critical_coverage/devocionales_bloc_test.dart
// High-value tests for DevocionalesBloc - devotionals viewing user flows

import 'package:flutter_test/flutter_test.dart';
import 'package:devocional_nuevo/models/devocional_model.dart';
import 'package:devocional_nuevo/blocs/devocionales/devocionales_bloc.dart';
import 'package:devocional_nuevo/blocs/devocionales/devocionales_event.dart';
import 'package:devocional_nuevo/blocs/devocionales/devocionales_state.dart';
import 'package:bloc_test/bloc_test.dart';

void main() {
  group('DevocionalesBloc - Initial State', () {
    test('initial state is DevocionalesInitial', () {
      final bloc = DevocionalesBloc();
      expect(bloc.state, isA<DevocionalesInitial>());
      bloc.close();
    });
  });

  group('DevocionalesBloc - LoadDevocionales Event', () {
    blocTest<DevocionalesBloc, DevocionalesState>(
      'emits [DevocionalesLoading, DevocionalesLoaded] when LoadDevocionales is added',
      build: () => DevocionalesBloc(),
      act: (bloc) => bloc.add(LoadDevocionales()),
      expect: () => [
        isA<DevocionalesLoading>(),
        isA<DevocionalesLoaded>(),
      ],
    );

    blocTest<DevocionalesBloc, DevocionalesState>(
      'DevocionalesLoaded contains default version RVR1960',
      build: () => DevocionalesBloc(),
      act: (bloc) => bloc.add(LoadDevocionales()),
      verify: (bloc) {
        final state = bloc.state as DevocionalesLoaded;
        expect(state.selectedVersion, 'RVR1960');
      },
    );

    blocTest<DevocionalesBloc, DevocionalesState>(
      'DevocionalesLoaded contains empty list initially',
      build: () => DevocionalesBloc(),
      act: (bloc) => bloc.add(LoadDevocionales()),
      verify: (bloc) {
        final state = bloc.state as DevocionalesLoaded;
        expect(state.devocionales, isEmpty);
      },
    );
  });

  group('DevocionalesBloc - ChangeVersion Event', () {
    blocTest<DevocionalesBloc, DevocionalesState>(
      'emits DevocionalesLoaded with new version when ChangeVersion is added',
      build: () => DevocionalesBloc(),
      seed: () => DevocionalesLoaded(
        devocionales: [],
        selectedVersion: 'RVR1960',
      ),
      act: (bloc) => bloc.add(ChangeVersion('NVI')),
      expect: () => [
        isA<DevocionalesLoaded>()
            .having((s) => s.selectedVersion, 'selectedVersion', 'NVI'),
      ],
    );

    blocTest<DevocionalesBloc, DevocionalesState>(
      'changing to same version re-emits state',
      build: () => DevocionalesBloc(),
      seed: () => DevocionalesLoaded(
        devocionales: [],
        selectedVersion: 'RVR1960',
      ),
      act: (bloc) => bloc.add(ChangeVersion('RVR1960')),
      expect: () => [
        isA<DevocionalesLoaded>()
            .having((s) => s.selectedVersion, 'selectedVersion', 'RVR1960'),
      ],
    );
  });

  group('DevocionalesBloc - ToggleFavorite Event', () {
    blocTest<DevocionalesBloc, DevocionalesState>(
      'emits DevocionalesLoaded when ToggleFavorite is added in loaded state',
      build: () => DevocionalesBloc(),
      seed: () => DevocionalesLoaded(
        devocionales: [],
        selectedVersion: 'RVR1960',
      ),
      act: (bloc) => bloc.add(ToggleFavorite('devocional-1')),
      expect: () => [
        isA<DevocionalesLoaded>(),
      ],
    );

    blocTest<DevocionalesBloc, DevocionalesState>(
      'does not emit when ToggleFavorite is added in non-loaded state',
      build: () => DevocionalesBloc(),
      act: (bloc) => bloc.add(ToggleFavorite('devocional-1')),
      expect: () => [], // No state change if not in loaded state
    );
  });

  group('DevocionalesBloc - State Transitions', () {
    blocTest<DevocionalesBloc, DevocionalesState>(
      'full flow: load -> change version -> toggle favorite',
      build: () => DevocionalesBloc(),
      act: (bloc) async {
        bloc.add(LoadDevocionales());
        await Future.delayed(const Duration(milliseconds: 100));
        bloc.add(ChangeVersion('NVI'));
        await Future.delayed(const Duration(milliseconds: 100));
        bloc.add(ToggleFavorite('devocional-1'));
      },
      expect: () => [
        isA<DevocionalesLoading>(),
        isA<DevocionalesLoaded>()
            .having((s) => s.selectedVersion, 'selectedVersion', 'RVR1960'),
        isA<DevocionalesLoaded>()
            .having((s) => s.selectedVersion, 'selectedVersion', 'NVI'),
        isA<DevocionalesLoaded>(),
      ],
    );
  });

  group('DevocionalesState - Equality and Copyability', () {
    test('DevocionalesLoaded instances with same values', () {
      final state1 = DevocionalesLoaded(
        devocionales: [],
        selectedVersion: 'RVR1960',
      );
      final state2 = DevocionalesLoaded(
        devocionales: [],
        selectedVersion: 'RVR1960',
      );

      expect(state1.selectedVersion, state2.selectedVersion);
      expect(state1.devocionales.length, state2.devocionales.length);
    });

    test('DevocionalesLoaded instances with different versions are different',
        () {
      final state1 = DevocionalesLoaded(
        devocionales: [],
        selectedVersion: 'RVR1960',
      );
      final state2 = DevocionalesLoaded(
        devocionales: [],
        selectedVersion: 'NVI',
      );

      expect(state1.selectedVersion, isNot(state2.selectedVersion));
    });

    test('DevocionalesError contains error message', () {
      final state = DevocionalesError('Test error message');
      expect(state.message, 'Test error message');
    });
  });

  group('DevocionalesEvent - Event Properties', () {
    test('LoadDevocionales event can be created', () {
      final event = LoadDevocionales();
      expect(event, isA<LoadDevocionales>());
    });

    test('ChangeVersion event has version', () {
      final event = ChangeVersion('NVI');
      expect(event.version, 'NVI');
    });

    test('ToggleFavorite event has devocionalId', () {
      final event = ToggleFavorite('devocional-123');
      expect(event.devocionalId, 'devocional-123');
    });
  });

  group('Devocional Model Tests', () {
    test('Devocional has required fields', () {
      final devocional = Devocional(
        id: '1',
        versiculo: 'John 3:16',
        reflexion: 'Test Reflection',
        oracion: 'Test Prayer',
        date: DateTime(2024, 1, 1),
        version: 'RVR1960',
        paraMeditar: [
          ParaMeditar(cita: 'John 3:16', texto: 'For God so loved')
        ],
      );

      expect(devocional.id, '1');
      expect(devocional.versiculo, 'John 3:16');
      expect(devocional.reflexion, 'Test Reflection');
      expect(devocional.version, 'RVR1960');
    });

    test('Devocional can be created with optional fields', () {
      final devocional = Devocional(
        id: '1',
        versiculo: 'John 3:16',
        reflexion: 'Reflection',
        oracion: 'Prayer',
        date: DateTime(2024, 1, 1),
        paraMeditar: [],
      );

      expect(devocional.paraMeditar, isEmpty);
    });

    test('ParaMeditar has required fields', () {
      final paraMeditar = ParaMeditar(
        cita: 'John 3:16',
        texto: 'For God so loved the world',
      );

      expect(paraMeditar.cita, 'John 3:16');
      expect(paraMeditar.texto, 'For God so loved the world');
    });

    test('Devocional can be serialized to JSON', () {
      final devocional = Devocional(
        id: '1',
        versiculo: 'John 3:16',
        reflexion: 'Test Reflection',
        oracion: 'Test Prayer',
        date: DateTime(2024, 1, 1),
        version: 'RVR1960',
        paraMeditar: [
          ParaMeditar(cita: 'John 3:16', texto: 'For God so loved')
        ],
      );

      final json = devocional.toJson();
      expect(json['id'], '1');
      expect(json['versiculo'], 'John 3:16');
    });

    test('Devocional can be deserialized from JSON', () {
      final json = {
        'id': '1',
        'versiculo': 'John 3:16',
        'reflexion': 'Test Reflection',
        'oracion': 'Test Prayer',
        'date': '2024-01-01',
        'version': 'RVR1960',
        'para_meditar': [
          {
            'cita': 'John 3:16',
            'texto': 'For God so loved',
          },
        ],
      };

      final devocional = Devocional.fromJson(json);
      expect(devocional.id, '1');
      expect(devocional.versiculo, 'John 3:16');
      expect(devocional.paraMeditar.first.cita, 'John 3:16');
    });
  });

  group('DevocionalesBloc - Error Handling', () {
    test('DevocionalesError state is created correctly', () {
      final errorState = DevocionalesError('Error loading devocionales');
      expect(errorState.message, 'Error loading devocionales');
    });
  });

  group('Bible Version Filter Tests', () {
    test('filtering by version returns matching devocionales', () {
      final allDevocionales = [
        Devocional(
            id: '1',
            versiculo: 'V1',
            reflexion: 'R1',
            oracion: 'O1',
            date: DateTime(2024, 1, 1),
            version: 'RVR1960',
            paraMeditar: []),
        Devocional(
            id: '2',
            versiculo: 'V2',
            reflexion: 'R2',
            oracion: 'O2',
            date: DateTime(2024, 1, 2),
            version: 'NVI',
            paraMeditar: []),
        Devocional(
            id: '3',
            versiculo: 'V3',
            reflexion: 'R3',
            oracion: 'O3',
            date: DateTime(2024, 1, 3),
            version: 'RVR1960',
            paraMeditar: []),
      ];

      final filtered =
          allDevocionales.where((d) => d.version == 'RVR1960').toList();
      expect(filtered, hasLength(2));
      expect(filtered.every((d) => d.version == 'RVR1960'), isTrue);
    });

    test('filtering by non-existent version returns empty list', () {
      final allDevocionales = [
        Devocional(
            id: '1',
            versiculo: 'V1',
            reflexion: 'R1',
            oracion: 'O1',
            date: DateTime(2024, 1, 1),
            version: 'RVR1960',
            paraMeditar: []),
      ];

      final filtered =
          allDevocionales.where((d) => d.version == 'UNKNOWN').toList();
      expect(filtered, isEmpty);
    });
  });
}
