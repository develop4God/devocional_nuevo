@Tags(['unit', 'services', 'backup'])
library;

import 'package:devocional_nuevo/services/backup/backup_settings_service.dart';
import 'package:devocional_nuevo/services/backup/i_backup_settings_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late BackupSettingsService service;

  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    service = BackupSettingsService();
  });

  group('BackupSettingsService — auto backup flag', () {
    test('defaults to disabled when nothing is stored', () async {
      SharedPreferences.setMockInitialValues({});

      expect(await service.isAutoBackupEnabled(), isFalse);
    });

    test('persists enabled state across reads', () async {
      SharedPreferences.setMockInitialValues({});

      await service.setAutoBackupEnabled(true);

      expect(await service.isAutoBackupEnabled(), isTrue);
    });

    test('persists disabled state after being enabled', () async {
      SharedPreferences.setMockInitialValues({});

      await service.setAutoBackupEnabled(true);
      await service.setAutoBackupEnabled(false);

      expect(await service.isAutoBackupEnabled(), isFalse);
    });
  });

  group('BackupSettingsService — backup frequency', () {
    test('defaults to daily when nothing is stored', () async {
      SharedPreferences.setMockInitialValues({});

      expect(
        await service.getBackupFrequency(),
        IBackupSettingsService.frequencyDaily,
      );
    });

    test('persists a custom frequency', () async {
      SharedPreferences.setMockInitialValues({});

      await service.setBackupFrequency(IBackupSettingsService.frequencyManual);

      expect(
        await service.getBackupFrequency(),
        IBackupSettingsService.frequencyManual,
      );
    });
  });

  group('BackupSettingsService — wifi-only flag', () {
    test('defaults to enabled when nothing is stored', () async {
      SharedPreferences.setMockInitialValues({});

      expect(await service.isWifiOnlyEnabled(), isTrue);
    });

    test('persists disabled state', () async {
      SharedPreferences.setMockInitialValues({});

      await service.setWifiOnlyEnabled(false);

      expect(await service.isWifiOnlyEnabled(), isFalse);
    });
  });

  group('BackupSettingsService — compression flag', () {
    test('defaults to enabled when nothing is stored', () async {
      SharedPreferences.setMockInitialValues({});

      expect(await service.isCompressionEnabled(), isTrue);
    });

    test('persists disabled state', () async {
      SharedPreferences.setMockInitialValues({});

      await service.setCompressionEnabled(false);

      expect(await service.isCompressionEnabled(), isFalse);
    });
  });

  group('BackupSettingsService — last backup time', () {
    test('returns null when nothing is stored', () async {
      SharedPreferences.setMockInitialValues({});

      expect(await service.getLastBackupTime(), isNull);
    });

    test('round-trips a stored time', () async {
      SharedPreferences.setMockInitialValues({});
      final time = DateTime(2026, 3, 5, 10, 30);

      await service.setLastBackupTime(time);

      expect(await service.getLastBackupTime(), time);
    });
  });

  group('BackupSettingsService — next backup time', () {
    test('returns null when frequency is deactivated', () async {
      SharedPreferences.setMockInitialValues({});
      await service.setBackupFrequency(
        IBackupSettingsService.frequencyDeactivated,
      );
      await service.setAutoBackupEnabled(true);

      expect(await service.getNextBackupTime(), isNull);
    });

    test('returns null when frequency is manual', () async {
      SharedPreferences.setMockInitialValues({});
      await service.setBackupFrequency(IBackupSettingsService.frequencyManual);
      await service.setAutoBackupEnabled(true);

      expect(await service.getNextBackupTime(), isNull);
    });

    test('returns null when auto backup is disabled', () async {
      SharedPreferences.setMockInitialValues({});
      await service.setBackupFrequency(IBackupSettingsService.frequencyDaily);
      await service.setAutoBackupEnabled(false);

      expect(await service.getNextBackupTime(), isNull);
    });

    test('returns now-ish when auto backup is on but no prior backup exists',
        () async {
      SharedPreferences.setMockInitialValues({});
      await service.setBackupFrequency(IBackupSettingsService.frequencyDaily);
      await service.setAutoBackupEnabled(true);

      final before = DateTime.now();
      final next = await service.getNextBackupTime();
      final after = DateTime.now();

      expect(next, isNotNull);
      expect(
        next!.isAfter(before.subtract(const Duration(seconds: 1))),
        isTrue,
      );
      expect(next.isBefore(after.add(const Duration(seconds: 1))), isTrue);
    });

    test('returns last backup time plus 24 hours for daily frequency',
        () async {
      SharedPreferences.setMockInitialValues({});
      final lastBackup = DateTime(2026, 3, 5, 8, 0);
      await service.setBackupFrequency(IBackupSettingsService.frequencyDaily);
      await service.setAutoBackupEnabled(true);
      await service.setLastBackupTime(lastBackup);

      final next = await service.getNextBackupTime();

      expect(next, lastBackup.add(const Duration(hours: 24)));
    });
  });
}
