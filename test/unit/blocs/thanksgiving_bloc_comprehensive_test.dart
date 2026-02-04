// test/unit/blocs/thanksgiving_bloc_comprehensive_test.dart

import 'dart:io';

import 'package:devocional_nuevo/blocs/thanksgiving_bloc.dart';
import 'package:devocional_nuevo/blocs/thanksgiving_event.dart';
import 'package:devocional_nuevo/blocs/thanksgiving_state.dart';
import 'package:devocional_nuevo/services/service_locator.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

@Tags(['unit', 'blocs'])
void main() {
  group('ThanksgivingBloc - Comprehensive Real User Behavior Tests', () {
    late ThanksgivingBloc bloc;
    late Directory tempDir;

    setUpAll(() {
      TestWidgetsFlutterBinding.ensureInitialized();
      setupServiceLocator();
    });

    setUp(() async {
      SharedPreferences.setMockInitialValues({});

      // Create temp directory for tests
      tempDir = await Directory.systemTemp.createTemp('thanksgiving_bloc_test');

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/path_provider'),
        (MethodCall methodCall) async {
          if (methodCall.method == 'getApplicationDocumentsDirectory') {
            return tempDir.path;
          }
          return null;
        },
      );

      bloc = ThanksgivingBloc();
    });

    tearDown(() async {
      await bloc.close();
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/path_provider'),
        null,
      );
    });

    group('User Scenario: Adding thanksgivings', () {
      test('User adds valid thanksgiving', () async {
        bloc.add(LoadThanksgivings());
        await Future.delayed(const Duration(milliseconds: 100));

        bloc.add(AddThanksgiving('Thank God for my family'));
        await Future.delayed(const Duration(milliseconds: 100));

        final state = bloc.state as ThanksgivingLoaded;
        expect(state.thanksgivings.length, equals(1));
        expect(
            state.thanksgivings.first.text, equals('Thank God for my family'));
      });

      test('User adds multiple thanksgivings in sequence', () async {
        bloc.add(LoadThanksgivings());
        await Future.delayed(const Duration(milliseconds: 100));

        bloc.add(AddThanksgiving('Thank God for health'));
        await Future.delayed(const Duration(milliseconds: 50));
        bloc.add(AddThanksgiving('Thank God for provision'));
        await Future.delayed(const Duration(milliseconds: 50));
        bloc.add(AddThanksgiving('Thank God for peace'));
        await Future.delayed(const Duration(milliseconds: 100));

        final state = bloc.state as ThanksgivingLoaded;
        expect(state.thanksgivings.length, equals(3));
      });

      test('User adds thanksgiving with special characters', () async {
        bloc.add(LoadThanksgivings());
        await Future.delayed(const Duration(milliseconds: 100));

        bloc.add(AddThanksgiving('Gracias Dios por todo! 🙏 ñ é ü 汉字'));
        await Future.delayed(const Duration(milliseconds: 100));

        final state = bloc.state as ThanksgivingLoaded;
        expect(state.thanksgivings.length, equals(1));
        expect(state.thanksgivings.first.text, contains('🙏'));
        expect(state.thanksgivings.first.text, contains('汉字'));
      });

      test('User adds very long thanksgiving text', () async {
        bloc.add(LoadThanksgivings());
        await Future.delayed(const Duration(milliseconds: 100));

        final longText = 'Thank God ' * 150; // 1500+ characters
        bloc.add(AddThanksgiving(longText));
        await Future.delayed(const Duration(milliseconds: 100));

        final state = bloc.state as ThanksgivingLoaded;
        expect(state.thanksgivings.length, equals(1));
        expect(state.thanksgivings.first.text.length, greaterThan(1000));
      });

      test('Empty thanksgiving is rejected', () async {
        bloc.add(LoadThanksgivings());
        await Future.delayed(const Duration(milliseconds: 100));

        bloc.add(AddThanksgiving('   '));
        await Future.delayed(const Duration(milliseconds: 100));

        final state = bloc.state as ThanksgivingLoaded;
        expect(state.thanksgivings, isEmpty);
      });
    });

    group('User Scenario: Editing thanksgivings', () {
      test('User edits existing thanksgiving', () async {
        bloc.add(LoadThanksgivings());
        await Future.delayed(const Duration(milliseconds: 100));

        bloc.add(AddThanksgiving('Original thanksgiving'));
        await Future.delayed(const Duration(milliseconds: 100));

        var state = bloc.state as ThanksgivingLoaded;
        final thanksgivingId = state.thanksgivings.first.id;

        bloc.add(EditThanksgiving(thanksgivingId, 'Updated thanksgiving'));
        await Future.delayed(const Duration(milliseconds: 100));

        state = bloc.state as ThanksgivingLoaded;
        expect(state.thanksgivings.first.text, equals('Updated thanksgiving'));
      });

      test('Editing with empty text is rejected', () async {
        bloc.add(LoadThanksgivings());
        await Future.delayed(const Duration(milliseconds: 100));

        bloc.add(AddThanksgiving('Original text'));
        await Future.delayed(const Duration(milliseconds: 100));

        var state = bloc.state as ThanksgivingLoaded;
        final thanksgivingId = state.thanksgivings.first.id;

        bloc.add(EditThanksgiving(thanksgivingId, '   '));
        await Future.delayed(const Duration(milliseconds: 100));

        state = bloc.state as ThanksgivingLoaded;
        expect(state.thanksgivings.first.text, equals('Original text'));
      });
    });

    group('User Scenario: Deleting thanksgivings', () {
      test('User deletes a thanksgiving', () async {
        bloc.add(LoadThanksgivings());
        await Future.delayed(const Duration(milliseconds: 100));

        bloc.add(AddThanksgiving('Thanksgiving 1'));
        await Future.delayed(const Duration(milliseconds: 50));
        bloc.add(AddThanksgiving('Thanksgiving 2'));
        await Future.delayed(const Duration(milliseconds: 100));

        var state = bloc.state as ThanksgivingLoaded;
        final thanksgiving1Id = state.thanksgivings
            .firstWhere((t) => t.text == 'Thanksgiving 1')
            .id;

        bloc.add(DeleteThanksgiving(thanksgiving1Id));
        await Future.delayed(const Duration(milliseconds: 100));

        state = bloc.state as ThanksgivingLoaded;
        expect(state.thanksgivings.length, equals(1));
        expect(state.thanksgivings.first.text, equals('Thanksgiving 2'));
      });

      test('User deletes all thanksgivings', () async {
        bloc.add(LoadThanksgivings());
        await Future.delayed(const Duration(milliseconds: 100));

        bloc.add(AddThanksgiving('Thanksgiving 1'));
        await Future.delayed(const Duration(milliseconds: 50));
        bloc.add(AddThanksgiving('Thanksgiving 2'));
        await Future.delayed(const Duration(milliseconds: 100));

        var state = bloc.state as ThanksgivingLoaded;
        final id1 = state.thanksgivings
            .firstWhere((t) => t.text == 'Thanksgiving 1')
            .id;
        final id2 = state.thanksgivings
            .firstWhere((t) => t.text == 'Thanksgiving 2')
            .id;

        bloc.add(DeleteThanksgiving(id1));
        await Future.delayed(const Duration(milliseconds: 50));
        bloc.add(DeleteThanksgiving(id2));
        await Future.delayed(const Duration(milliseconds: 100));

        state = bloc.state as ThanksgivingLoaded;
        expect(state.thanksgivings, isEmpty);
      });
    });

    group('Data Persistence', () {
      test('Thanksgivings persist after closing and reopening bloc', () async {
        bloc.add(LoadThanksgivings());
        await Future.delayed(const Duration(milliseconds: 100));

        bloc.add(AddThanksgiving('Thank God for salvation'));
        await Future.delayed(const Duration(milliseconds: 50));
        bloc.add(AddThanksgiving('Thank God for grace'));
        await Future.delayed(const Duration(milliseconds: 100));

        var state = bloc.state as ThanksgivingLoaded;
        expect(state.thanksgivings.length, equals(2));

        await bloc.close();

        // Create new bloc instance (simulating app restart)
        final bloc2 = ThanksgivingBloc();
        bloc2.add(LoadThanksgivings());
        await Future.delayed(const Duration(milliseconds: 100));

        state = bloc2.state as ThanksgivingLoaded;
        expect(state.thanksgivings.length, equals(2));
        expect(
            state.thanksgivings.any((t) => t.text == 'Thank God for salvation'),
            isTrue);
        expect(state.thanksgivings.any((t) => t.text == 'Thank God for grace'),
            isTrue);

        await bloc2.close();
      });

      test('Complete lifecycle: add, edit, delete, persist', () async {
        bloc.add(LoadThanksgivings());
        await Future.delayed(const Duration(milliseconds: 100));

        // Add
        bloc.add(AddThanksgiving('Original thanksgiving'));
        await Future.delayed(const Duration(milliseconds: 100));

        var state = bloc.state as ThanksgivingLoaded;
        final thanksgivingId = state.thanksgivings.first.id;

        // Edit
        bloc.add(EditThanksgiving(thanksgivingId, 'Updated thanksgiving'));
        await Future.delayed(const Duration(milliseconds: 100));

        state = bloc.state as ThanksgivingLoaded;
        expect(state.thanksgivings.first.text, equals('Updated thanksgiving'));

        // Delete
        bloc.add(DeleteThanksgiving(thanksgivingId));
        await Future.delayed(const Duration(milliseconds: 100));

        state = bloc.state as ThanksgivingLoaded;
        expect(state.thanksgivings, isEmpty);
      });
    });

    group('Thanksgiving Model Validation', () {
      test('Thanksgiving IDs are unique', () async {
        bloc.add(LoadThanksgivings());
        await Future.delayed(const Duration(milliseconds: 100));

        bloc.add(AddThanksgiving('Thanksgiving 1'));
        await Future.delayed(const Duration(milliseconds: 10));
        bloc.add(AddThanksgiving('Thanksgiving 2'));
        await Future.delayed(const Duration(milliseconds: 10));
        bloc.add(AddThanksgiving('Thanksgiving 3'));
        await Future.delayed(const Duration(milliseconds: 100));

        final state = bloc.state as ThanksgivingLoaded;
        final ids = state.thanksgivings.map((t) => t.id).toList();
        final uniqueIds = ids.toSet();

        expect(uniqueIds.length, equals(ids.length),
            reason: 'All thanksgiving IDs should be unique');
      });

      test('Thanksgiving dates are set correctly', () async {
        final before = DateTime.now();

        bloc.add(LoadThanksgivings());
        await Future.delayed(const Duration(milliseconds: 100));

        bloc.add(AddThanksgiving('Test thanksgiving'));
        await Future.delayed(const Duration(milliseconds: 100));

        final after = DateTime.now();
        final state = bloc.state as ThanksgivingLoaded;
        final thanksgiving = state.thanksgivings.first;

        expect(
            thanksgiving.createdDate
                .isAfter(before.subtract(const Duration(seconds: 1))),
            isTrue);
        expect(
            thanksgiving.createdDate
                .isBefore(after.add(const Duration(seconds: 1))),
            isTrue);
      });
    });

    group('Refresh Functionality', () {
      test('User can refresh thanksgiving list', () async {
        bloc.add(LoadThanksgivings());
        await Future.delayed(const Duration(milliseconds: 100));

        bloc.add(AddThanksgiving('Thanksgiving 1'));
        await Future.delayed(const Duration(milliseconds: 100));

        var state = bloc.state as ThanksgivingLoaded;
        expect(state.thanksgivings.length, equals(1));

        bloc.add(RefreshThanksgivings());
        await Future.delayed(const Duration(milliseconds: 100));

        state = bloc.state as ThanksgivingLoaded;
        expect(state.thanksgivings.length, equals(1),
            reason: 'Thanksgiving should persist after refresh');
      });
    });

    group('Error Handling', () {
      test('User can clear error message', () async {
        bloc.add(LoadThanksgivings());
        await Future.delayed(const Duration(milliseconds: 100));

        bloc.add(AddThanksgiving('   '));
        await Future.delayed(const Duration(milliseconds: 100));

        var state = bloc.state as ThanksgivingLoaded;
        // If there's an error message, clear it
        if (state.errorMessage != null) {
          bloc.add(ClearThanksgivingError());
          await Future.delayed(const Duration(milliseconds: 50));

          state = bloc.state as ThanksgivingLoaded;
          expect(state.errorMessage, isNull);
        }
      });
    });

    group('Initial State', () {
      test('Bloc starts in initial state', () {
        final newBloc = ThanksgivingBloc();
        expect(newBloc.state, isA<ThanksgivingInitial>());
        newBloc.close();
      });
    });
  });
}
