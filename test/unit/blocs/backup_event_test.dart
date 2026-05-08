@Tags(['critical', 'unit', 'blocs'])
library;

import 'package:devocional_nuevo/blocs/backup_event.dart';
import 'package:flutter_test/flutter_test.dart';

/// Comprehensive tests for BackupEvent classes
/// Focuses on equality, props, and immutability
void main() {
  group('LoadBackupSettings', () {
    test('supports value equality', () {
      const event1 = LoadBackupSettings();
      const event2 = LoadBackupSettings();

      expect(event1, equals(event2));
      expect(event1.hashCode, equals(event2.hashCode));
    });

    test('props returns empty list', () {
      const event = LoadBackupSettings();
      expect(event.props, isEmpty);
    });
  });

  group('ToggleAutoBackup', () {
    test('supports value equality with same enabled value', () {
      const event1 = ToggleAutoBackup(true);
      const event2 = ToggleAutoBackup(true);

      expect(event1, equals(event2));
      expect(event1.hashCode, equals(event2.hashCode));
    });

    test('different enabled values are not equal', () {
      const event1 = ToggleAutoBackup(true);
      const event2 = ToggleAutoBackup(false);

      expect(event1, isNot(equals(event2)));
    });

    test('props includes enabled value', () {
      const event = ToggleAutoBackup(true);
      expect(event.props, equals([true]));
    });

    test('creates event with enabled true', () {
      const event = ToggleAutoBackup(true);
      expect(event.enabled, isTrue);
    });

    test('creates event with enabled false', () {
      const event = ToggleAutoBackup(false);
      expect(event.enabled, isFalse);
    });
  });

  group('ChangeBackupFrequency', () {
    test('supports value equality with same frequency', () {
      const event1 = ChangeBackupFrequency('daily');
      const event2 = ChangeBackupFrequency('daily');

      expect(event1, equals(event2));
      expect(event1.hashCode, equals(event2.hashCode));
    });

    test('different frequencies are not equal', () {
      const event1 = ChangeBackupFrequency('daily');
      const event2 = ChangeBackupFrequency('weekly');

      expect(event1, isNot(equals(event2)));
    });

    test('props includes frequency value', () {
      const event = ChangeBackupFrequency('monthly');
      expect(event.props, equals(['monthly']));
    });

    test('creates event with daily frequency', () {
      const event = ChangeBackupFrequency('daily');
      expect(event.frequency, equals('daily'));
    });

    test('creates event with weekly frequency', () {
      const event = ChangeBackupFrequency('weekly');
      expect(event.frequency, equals('weekly'));
    });

    test('creates event with monthly frequency', () {
      const event = ChangeBackupFrequency('monthly');
      expect(event.frequency, equals('monthly'));
    });

    test('creates event with deactivated frequency', () {
      const event = ChangeBackupFrequency('deactivated');
      expect(event.frequency, equals('deactivated'));
    });
  });

  group('ToggleWifiOnly', () {
    test('supports value equality with same enabled value', () {
      const event1 = ToggleWifiOnly(true);
      const event2 = ToggleWifiOnly(true);

      expect(event1, equals(event2));
      expect(event1.hashCode, equals(event2.hashCode));
    });

    test('different enabled values are not equal', () {
      const event1 = ToggleWifiOnly(true);
      const event2 = ToggleWifiOnly(false);

      expect(event1, isNot(equals(event2)));
    });

    test('props includes enabled value', () {
      const event = ToggleWifiOnly(true);
      expect(event.props, equals([true]));
    });

    test('creates event with enabled true', () {
      const event = ToggleWifiOnly(true);
      expect(event.enabled, isTrue);
    });

    test('creates event with enabled false', () {
      const event = ToggleWifiOnly(false);
      expect(event.enabled, isFalse);
    });
  });

  group('ToggleCompression', () {
    test('supports value equality with same enabled value', () {
      const event1 = ToggleCompression(true);
      const event2 = ToggleCompression(true);

      expect(event1, equals(event2));
      expect(event1.hashCode, equals(event2.hashCode));
    });

    test('different enabled values are not equal', () {
      const event1 = ToggleCompression(true);
      const event2 = ToggleCompression(false);

      expect(event1, isNot(equals(event2)));
    });

    test('props includes enabled value', () {
      const event = ToggleCompression(false);
      expect(event.props, equals([false]));
    });

    test('creates event with enabled true', () {
      const event = ToggleCompression(true);
      expect(event.enabled, isTrue);
    });

    test('creates event with enabled false', () {
      const event = ToggleCompression(false);
      expect(event.enabled, isFalse);
    });
  });

  group('UpdateBackupOptions', () {
    test('supports value equality with same options', () {
      const options = {'favorites': true, 'settings': false};
      const event1 = UpdateBackupOptions(options);
      const event2 = UpdateBackupOptions(options);

      expect(event1, equals(event2));
      expect(event1.hashCode, equals(event2.hashCode));
    });

    test('different options are not equal', () {
      const event1 = UpdateBackupOptions({'favorites': true});
      const event2 = UpdateBackupOptions({'favorites': false});

      expect(event1, isNot(equals(event2)));
    });

    test('props includes options map', () {
      const options = {'favorites': true, 'settings': true};
      const event = UpdateBackupOptions(options);
      expect(event.props, equals([options]));
    });

    test('creates event with empty options', () {
      const event = UpdateBackupOptions({});
      expect(event.options, isEmpty);
    });

    test('creates event with multiple options', () {
      const options = {
        'favorites': true,
        'settings': true,
        'progress': false,
      };
      const event = UpdateBackupOptions(options);
      expect(event.options, equals(options));
    });
  });

  group('CreateManualBackup', () {
    test('supports value equality', () {
      const event1 = CreateManualBackup();
      const event2 = CreateManualBackup();

      expect(event1, equals(event2));
      expect(event1.hashCode, equals(event2.hashCode));
    });

    test('props returns empty list', () {
      const event = CreateManualBackup();
      expect(event.props, isEmpty);
    });
  });

  group('RefreshBackupStatus', () {
    test('supports value equality', () {
      const event1 = RefreshBackupStatus();
      const event2 = RefreshBackupStatus();

      expect(event1, equals(event2));
      expect(event1.hashCode, equals(event2.hashCode));
    });

    test('props returns empty list', () {
      const event = RefreshBackupStatus();
      expect(event.props, isEmpty);
    });
  });

  group('SignInToGoogleDrive', () {
    test('supports value equality', () {
      const event1 = SignInToGoogleDrive();
      const event2 = SignInToGoogleDrive();

      expect(event1, equals(event2));
      expect(event1.hashCode, equals(event2.hashCode));
    });

    test('props returns empty list', () {
      const event = SignInToGoogleDrive();
      expect(event.props, isEmpty);
    });
  });

  group('SignOutFromGoogleDrive', () {
    test('supports value equality', () {
      const event1 = SignOutFromGoogleDrive();
      const event2 = SignOutFromGoogleDrive();

      expect(event1, equals(event2));
      expect(event1.hashCode, equals(event2.hashCode));
    });

    test('props returns empty list', () {
      const event = SignOutFromGoogleDrive();
      expect(event.props, isEmpty);
    });
  });

  group('CheckStartupBackup', () {
    test('supports value equality with same forceBypass', () {
      const event1 = CheckStartupBackup(forceBypass: false);
      const event2 = CheckStartupBackup(forceBypass: false);

      expect(event1, equals(event2));
      expect(event1.hashCode, equals(event2.hashCode));
    });

    test('different forceBypass values are not equal', () {
      const event1 = CheckStartupBackup(forceBypass: true);
      const event2 = CheckStartupBackup(forceBypass: false);

      expect(event1, isNot(equals(event2)));
    });

    test('default forceBypass is false', () {
      const event = CheckStartupBackup();
      expect(event.forceBypass, isFalse);
    });

    test('creates event with forceBypass true', () {
      const event = CheckStartupBackup(forceBypass: true);
      expect(event.forceBypass, isTrue);
    });

    test('creates event with forceBypass false', () {
      const event = CheckStartupBackup(forceBypass: false);
      expect(event.forceBypass, isFalse);
    });
  });

  group('BackupEvent hierarchy', () {
    test('all events extend BackupEvent', () {
      expect(const LoadBackupSettings(), isA<BackupEvent>());
      expect(const ToggleAutoBackup(true), isA<BackupEvent>());
      expect(const ChangeBackupFrequency('daily'), isA<BackupEvent>());
      expect(const ToggleWifiOnly(true), isA<BackupEvent>());
      expect(const ToggleCompression(true), isA<BackupEvent>());
      expect(const UpdateBackupOptions({}), isA<BackupEvent>());
      expect(const CreateManualBackup(), isA<BackupEvent>());
      expect(const RefreshBackupStatus(), isA<BackupEvent>());
      expect(const SignInToGoogleDrive(), isA<BackupEvent>());
      expect(const SignOutFromGoogleDrive(), isA<BackupEvent>());
      expect(const CheckStartupBackup(), isA<BackupEvent>());
    });
  });
}
