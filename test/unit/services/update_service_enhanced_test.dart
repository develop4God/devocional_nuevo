// test/unit/services/update_service_enhanced_test.dart

import 'package:devocional_nuevo/services/update_service.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel channel = MethodChannel('de.ffuf.in_app_update/methods');

  // Track calls
  final List<String> methodCalls = [];

  setUp(() {
    methodCalls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      methodCalls.add(methodCall.method);
      switch (methodCall.method) {
        case 'checkForUpdate':
          return {
            'updateAvailability': 2, // UpdateAvailability.updateAvailable
            'immediateAllowed': true,
            'flexibleAllowed': true,
            'availableVersionCode': 100,
            'updatePriority': 0,
            'clientVersionStalenessDays': 0,
            'installStatus': 0,
            'packageName': 'com.example.app',
          };
        case 'performImmediateUpdate':
          return null;
        case 'startFlexibleUpdate':
          return null;
        case 'completeFlexibleUpdate':
          return null;
        default:
          return null;
      }
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  group('UpdateService Real Logic Tests', () {
    test('checkForUpdate triggers immediate update when allowed', () async {
      await UpdateService.checkForUpdate();

      expect(methodCalls, contains('checkForUpdate'));
      expect(methodCalls, contains('performImmediateUpdate'));
    });

    test('checkForUpdate triggers flexible update when immediate NOT allowed',
        () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        methodCalls.add(methodCall.method);
        if (methodCall.method == 'checkForUpdate') {
          return {
            'updateAvailability': 2,
            'immediateAllowed': false,
            'flexibleAllowed': true,
            'availableVersionCode': 100,
            'updatePriority': 0,
            'clientVersionStalenessDays': 0,
            'installStatus': 0,
            'packageName': 'com.example.app',
          };
        }
        return null;
      });

      fakeAsync((async) {
        UpdateService.checkForUpdate();
        async.elapse(const Duration(seconds: 15));

        expect(methodCalls, contains('checkForUpdate'));
        expect(methodCalls, contains('startFlexibleUpdate'));
        expect(methodCalls, contains('completeFlexibleUpdate'));
      });
    });

    test('getUpdateInfo returns mapped info from platform', () async {
      final info = await UpdateService.getUpdateInfo();

      expect(info['updateAvailable'], isTrue);
      expect(info['immediateUpdateAllowed'], isTrue);
      expect(info['flexibleUpdateAllowed'], isTrue);
      expect(info['availableVersionCode'], 100);
    });

    test('completeFlexibleUpdateIfAvailable returns true on success', () async {
      final result = await UpdateService.completeFlexibleUpdateIfAvailable();

      expect(result, isTrue);
      expect(methodCalls, contains('completeFlexibleUpdate'));
    });

    test('performFlexibleUpdateWithCallback monitors progress and completes',
        () {
      fakeAsync((async) {
        final statuses = <String>[];
        UpdateService.performFlexibleUpdateWithCallback(
          onStatusChange: (s) => statuses.add(s),
        );

        async.flushMicrotasks();
        expect(statuses, contains('Iniciando actualización...'));
        expect(methodCalls, contains('startFlexibleUpdate'));

        // Advance time to trigger monitoring loop
        async.elapse(const Duration(seconds: 25));

        expect(statuses, contains('Descargando... 10%'));
        expect(statuses, contains('Descargando... 80%'));
        expect(statuses, contains('Preparando instalación...'));
        expect(statuses, contains('Actualización completada exitosamente'));
        expect(methodCalls, contains('completeFlexibleUpdate'));
      });
    });

    test('monitorFlexibleUpdateProgress handles failures after 80%', () {
      fakeAsync((async) {
        final statuses = <String>[];
        // Mock failure on completeFlexibleUpdate
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (call) async {
          methodCalls.add(call.method);
          if (call.method == 'completeFlexibleUpdate') {
            throw Exception('Not ready');
          }
          return null;
        });

        UpdateService.performFlexibleUpdateWithCallback(
          onStatusChange: (s) => statuses.add(s),
        );

        async.flushMicrotasks();
        async.elapse(const Duration(seconds: 25));

        // Should have tried multiple times and finally failed
        expect(statuses, contains('Error al completar actualización'));
      });
    });

    test('performImmediateUpdate handles error gracefully', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        if (call.method == 'performImmediateUpdate') {
          throw Exception('Update failed');
        }
        return null;
      });

      await UpdateService.performImmediateUpdate(); // Should not crash
    });

    test('handle error during check', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        if (call.method == 'checkForUpdate') {
          throw Exception('Platform error');
        }
        return null;
      });

      final info = await UpdateService.getUpdateInfo();

      expect(info['updateAvailable'], isFalse);
      expect(info['error'], contains('Platform error'));
    });
  });
}
