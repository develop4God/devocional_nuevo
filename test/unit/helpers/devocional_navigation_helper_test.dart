import 'package:devocional_nuevo/blocs/devocionales/devocionales_navigation_bloc.dart';
import 'package:devocional_nuevo/blocs/devocionales/devocionales_navigation_event.dart';
import 'package:devocional_nuevo/blocs/devocionales/devocionales_navigation_state.dart';
import 'package:devocional_nuevo/helpers/devocional_navigation_helper.dart';
import 'package:devocional_nuevo/models/devocional_model.dart';
import 'package:devocional_nuevo/repositories/devocional_repository_impl.dart';
import 'package:devocional_nuevo/repositories/navigation_repository_impl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../../helpers/flutter_tts_mock.dart';
import '../../helpers/test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DevocionalNavigationHelper', () {
    late DevocionalesNavigationBloc bloc;
    late ScrollController scrollController;
    late FlutterTts flutterTts;
    late DevocionalNavigationHelper helper;

    final testDevocionales = List.generate(
      5,
      (i) => Devocional(
        id: 'dev-$i',
        versiculo: 'Verse $i',
        reflexion: 'Reflection $i',
        paraMeditar: [],
        oracion: 'Prayer $i',
        date: DateTime(2025, 1, i + 1),
      ),
    );

    setUp(() {
      registerTestServicesWithFakes();
      FlutterTtsMock.setup();
      flutterTts = FlutterTts();
      scrollController = ScrollController();
      bloc = DevocionalesNavigationBloc(
        navigationRepository: NavigationRepositoryImpl(),
        devocionalRepository: DevocionalRepositoryImpl(),
      );
      helper = DevocionalNavigationHelper(
        getBloc: () => bloc,
        getAudioController: () => null,
        flutterTts: flutterTts,
        scrollController: scrollController,
      );
    });

    tearDown(() {
      scrollController.dispose();
      bloc.close();
    });

    test('returns false when BLoC is not in NavigationReady state', () async {
      // BLoC starts in NavigationInitial, not NavigationReady
      final result = await helper.navigate(
        direction: DevocionalNavigationDirection.next,
        isMounted: () => true,
      );
      expect(result, isFalse);
    });

    test('returns false when widget is not mounted after audio stop', () async {
      bloc.add(InitializeNavigation(
        initialIndex: 0,
        devocionales: testDevocionales,
      ));
      await Future.delayed(const Duration(milliseconds: 50));

      expect(bloc.state, isA<NavigationReady>());

      final result = await helper.navigate(
        direction: DevocionalNavigationDirection.next,
        isMounted: () => false,
      );
      expect(result, isFalse);
    });

    test('calls onPostNavigation callback after successful next navigation',
        () async {
      bloc.add(InitializeNavigation(
        initialIndex: 0,
        devocionales: testDevocionales,
      ));
      await Future.delayed(const Duration(milliseconds: 50));

      bool callbackCalled = false;

      await helper.navigate(
        direction: DevocionalNavigationDirection.next,
        isMounted: () => true,
        onPostNavigation: () {
          callbackCalled = true;
        },
      );

      expect(callbackCalled, isTrue);
    });

    test('calls onPostNavigation callback after successful previous navigation',
        () async {
      bloc.add(InitializeNavigation(
        initialIndex: 2,
        devocionales: testDevocionales,
      ));
      await Future.delayed(const Duration(milliseconds: 50));

      bool callbackCalled = false;

      await helper.navigate(
        direction: DevocionalNavigationDirection.previous,
        isMounted: () => true,
        onPostNavigation: () {
          callbackCalled = true;
        },
      );

      expect(callbackCalled, isTrue);
    });

    test('DevocionalNavigationDirection has next and previous values', () {
      expect(DevocionalNavigationDirection.values.length, 2);
      expect(DevocionalNavigationDirection.values,
          contains(DevocionalNavigationDirection.next));
      expect(DevocionalNavigationDirection.values,
          contains(DevocionalNavigationDirection.previous));
    });
  });
}
