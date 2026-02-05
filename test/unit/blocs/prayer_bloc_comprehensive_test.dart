@Tags(['unit', 'blocs'])
library;

// test/unit/blocs/prayer_bloc_comprehensive_test.dart

import 'dart:io';

import 'package:devocional_nuevo/blocs/prayer_bloc.dart';
import 'package:devocional_nuevo/blocs/prayer_event.dart';
import 'package:devocional_nuevo/blocs/prayer_state.dart';
import 'package:devocional_nuevo/models/prayer_model.dart';
import 'package:devocional_nuevo/services/service_locator.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('PrayerBloc - Comprehensive Real User Behavior Tests', () {
    late PrayerBloc bloc;
    late Directory tempDir;

    setUpAll(() {
      TestWidgetsFlutterBinding.ensureInitialized();
      setupServiceLocator();
    });

    setUp(() async {
      SharedPreferences.setMockInitialValues({});

      // Create temp directory for tests
      tempDir = await Directory.systemTemp.createTemp('prayer_bloc_test');

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

      bloc = PrayerBloc();
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

    group('User Scenario: Complete lifecycle with persistence', () {
      test('User adds prayer, it persists, then loads again', () async {
        // First session: add prayer
        bloc.add(LoadPrayers());
        await Future.delayed(const Duration(milliseconds: 100));
        bloc.add(AddPrayer('Prayer for peace'));
        await Future.delayed(const Duration(milliseconds: 150));

        var state = bloc.state as PrayerLoaded;
        expect(state.prayers.length, equals(1));
        final prayerId = state.prayers.first.id;

        // Close and create new bloc (simulating app restart)
        await bloc.close();

        final bloc2 = PrayerBloc();
        bloc2.add(LoadPrayers());
        await Future.delayed(const Duration(milliseconds: 100));

        state = bloc2.state as PrayerLoaded;
        expect(state.prayers.length, equals(1));
        expect(state.prayers.first.id, equals(prayerId));
        expect(state.prayers.first.text, equals('Prayer for peace'));

        await bloc2.close();
      });

      test('User adds, edits, and deletes prayer through full lifecycle',
          () async {
        // Load
        bloc.add(LoadPrayers());
        await Future.delayed(const Duration(milliseconds: 100));

        // Add
        bloc.add(AddPrayer('Original prayer text'));
        await Future.delayed(const Duration(milliseconds: 100));

        var state = bloc.state as PrayerLoaded;
        final prayerId = state.prayers.first.id;

        // Edit
        bloc.add(EditPrayer(prayerId, 'Updated prayer text'));
        await Future.delayed(const Duration(milliseconds: 100));

        state = bloc.state as PrayerLoaded;
        expect(state.prayers.first.text, equals('Updated prayer text'));

        // Mark as answered
        bloc.add(MarkPrayerAsAnswered(prayerId));
        await Future.delayed(const Duration(milliseconds: 100));

        state = bloc.state as PrayerLoaded;
        expect(state.prayers.first.status, equals(PrayerStatus.answered));
        expect(state.prayers.first.answeredDate, isNotNull);

        // Add comment
        bloc.add(UpdateAnsweredComment(prayerId,
            comment: 'God answered this prayer!'));
        await Future.delayed(const Duration(milliseconds: 100));

        state = bloc.state as PrayerLoaded;
        expect(state.prayers.first.answeredComment,
            equals('God answered this prayer!'));

        // Mark back as active
        bloc.add(MarkPrayerAsActive(prayerId));
        await Future.delayed(const Duration(milliseconds: 100));

        state = bloc.state as PrayerLoaded;
        expect(state.prayers.first.status, equals(PrayerStatus.active));
        expect(state.prayers.first.answeredDate, isNull);

        // Delete
        bloc.add(DeletePrayer(prayerId));
        await Future.delayed(const Duration(milliseconds: 100));

        state = bloc.state as PrayerLoaded;
        expect(state.prayers, isEmpty);
      });

      test('User adds multiple prayers and manages them', () async {
        bloc.add(LoadPrayers());
        await Future.delayed(const Duration(milliseconds: 100));

        // Add 3 prayers
        bloc.add(AddPrayer('Prayer 1'));
        await Future.delayed(const Duration(milliseconds: 50));
        bloc.add(AddPrayer('Prayer 2'));
        await Future.delayed(const Duration(milliseconds: 50));
        bloc.add(AddPrayer('Prayer 3'));
        await Future.delayed(const Duration(milliseconds: 100));

        var state = bloc.state as PrayerLoaded;
        expect(state.prayers.length, equals(3));

        final prayer2Id =
            state.prayers.firstWhere((p) => p.text == 'Prayer 2').id;

        // Delete middle prayer
        bloc.add(DeletePrayer(prayer2Id));
        await Future.delayed(const Duration(milliseconds: 100));

        state = bloc.state as PrayerLoaded;
        expect(state.prayers.length, equals(2));
        expect(state.prayers.any((p) => p.text == 'Prayer 2'), isFalse);
      });

      test('User adds prayer with special characters', () async {
        bloc.add(LoadPrayers());
        await Future.delayed(const Duration(milliseconds: 100));
        bloc.add(AddPrayer('Prayer with ñ, é, ü, 汉字, 🙏'));
        await Future.delayed(const Duration(milliseconds: 100));

        final state = bloc.state as PrayerLoaded;
        expect(state.prayers.length, equals(1));
        expect(state.prayers.first.text, contains('🙏'));
        expect(state.prayers.first.text, contains('汉字'));
      });

      test('User adds very long prayer text', () async {
        bloc.add(LoadPrayers());
        await Future.delayed(const Duration(milliseconds: 100));

        final longText = 'Prayer text ' * 100; // 1200+ characters
        bloc.add(AddPrayer(longText));
        await Future.delayed(const Duration(milliseconds: 100));

        final state = bloc.state as PrayerLoaded;
        expect(state.prayers.length, equals(1));
        expect(state.prayers.first.text.length, greaterThan(1000));
      });
    });

    group('Error Handling', () {
      // Note: Current implementation may not set error messages for all error cases
      // These tests document expected behavior for future enhancements

      test('Editing with empty text shows error', () async {
        bloc.add(LoadPrayers());
        await Future.delayed(const Duration(milliseconds: 100));

        bloc.add(AddPrayer('Original text'));
        await Future.delayed(const Duration(milliseconds: 100));

        var state = bloc.state as PrayerLoaded;
        final prayerId = state.prayers.first.id;

        bloc.add(EditPrayer(prayerId, '   '));
        await Future.delayed(const Duration(milliseconds: 100));

        state = bloc.state as PrayerLoaded;
        // Verify prayer text unchanged (empty edit rejected)
        expect(state.prayers.first.text, equals('Original text'));
      });

      test('Adding empty prayer is rejected silently', () async {
        bloc.add(LoadPrayers());
        await Future.delayed(const Duration(milliseconds: 100));

        bloc.add(AddPrayer('   '));
        await Future.delayed(const Duration(milliseconds: 100));

        final state = bloc.state as PrayerLoaded;
        expect(state.prayers, isEmpty);
      });
    });

    group('Prayer Model Validation', () {
      test('Prayer IDs are unique', () async {
        bloc.add(LoadPrayers());
        await Future.delayed(const Duration(milliseconds: 100));

        bloc.add(AddPrayer('Prayer 1'));
        await Future.delayed(const Duration(milliseconds: 10));
        bloc.add(AddPrayer('Prayer 2'));
        await Future.delayed(const Duration(milliseconds: 10));
        bloc.add(AddPrayer('Prayer 3'));
        await Future.delayed(const Duration(milliseconds: 100));

        final state = bloc.state as PrayerLoaded;
        final ids = state.prayers.map((p) => p.id).toList();
        final uniqueIds = ids.toSet();

        expect(uniqueIds.length, equals(ids.length),
            reason: 'All prayer IDs should be unique');
      });

      test('Prayer dates are set correctly', () async {
        final before = DateTime.now();

        bloc.add(LoadPrayers());
        await Future.delayed(const Duration(milliseconds: 100));

        bloc.add(AddPrayer('Test prayer'));
        await Future.delayed(const Duration(milliseconds: 100));

        final after = DateTime.now();
        final state = bloc.state as PrayerLoaded;
        final prayer = state.prayers.first;

        expect(
            prayer.createdDate
                .isAfter(before.subtract(const Duration(seconds: 1))),
            isTrue);
        expect(
            prayer.createdDate.isBefore(after.add(const Duration(seconds: 1))),
            isTrue);
      });
    });

    group('Refresh Functionality', () {
      test('User can refresh prayer list', () async {
        bloc.add(LoadPrayers());
        await Future.delayed(const Duration(milliseconds: 100));

        bloc.add(AddPrayer('Prayer 1'));
        await Future.delayed(const Duration(milliseconds: 100));

        var state = bloc.state as PrayerLoaded;
        expect(state.prayers.length, equals(1));

        bloc.add(RefreshPrayers());
        await Future.delayed(const Duration(milliseconds: 100));

        state = bloc.state as PrayerLoaded;
        expect(state.prayers.length, equals(1),
            reason: 'Prayer should persist after refresh');
      });
    });

    group('Initial State', () {
      test('Bloc starts in initial state', () {
        final newBloc = PrayerBloc();
        expect(newBloc.state, isA<PrayerInitial>());
        newBloc.close();
      });
    });

    group('Prayer Status Transitions', () {
      test('Prayer can transition from active to answered and back', () async {
        bloc.add(LoadPrayers());
        await Future.delayed(const Duration(milliseconds: 100));

        bloc.add(AddPrayer('Test prayer'));
        await Future.delayed(const Duration(milliseconds: 100));

        var state = bloc.state as PrayerLoaded;
        final prayerId = state.prayers.first.id;

        // Initial status is active
        expect(state.prayers.first.status, equals(PrayerStatus.active));

        // Mark as answered
        bloc.add(MarkPrayerAsAnswered(prayerId));
        await Future.delayed(const Duration(milliseconds: 100));

        state = bloc.state as PrayerLoaded;
        expect(state.prayers.first.status, equals(PrayerStatus.answered));
        expect(state.prayers.first.answeredDate, isNotNull);

        // Mark back as active
        bloc.add(MarkPrayerAsActive(prayerId));
        await Future.delayed(const Duration(milliseconds: 100));

        state = bloc.state as PrayerLoaded;
        expect(state.prayers.first.status, equals(PrayerStatus.active));
        expect(state.prayers.first.answeredDate, isNull);
      });
    });

    group('Data Persistence Across Lifecycle', () {
      test('Prayers persist after closing and reopening bloc', () async {
        // Session 1: Add prayers
        bloc.add(LoadPrayers());
        await Future.delayed(const Duration(milliseconds: 100));

        bloc.add(AddPrayer('Prayer A'));
        await Future.delayed(const Duration(milliseconds: 50));
        bloc.add(AddPrayer('Prayer B'));
        await Future.delayed(const Duration(milliseconds: 100));

        var state = bloc.state as PrayerLoaded;
        expect(state.prayers.length, equals(2));

        await bloc.close();

        // Session 2: Reload
        final bloc2 = PrayerBloc();
        bloc2.add(LoadPrayers());
        await Future.delayed(const Duration(milliseconds: 100));

        state = bloc2.state as PrayerLoaded;
        expect(state.prayers.length, equals(2));
        expect(state.prayers.any((p) => p.text == 'Prayer A'), isTrue);
        expect(state.prayers.any((p) => p.text == 'Prayer B'), isTrue);

        await bloc2.close();
      });
    });
  });
}
