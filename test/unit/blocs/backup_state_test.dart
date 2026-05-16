@Tags(['critical', 'unit', 'blocs'])
library;

import 'package:devocional_nuevo/blocs/backup_state.dart';
import 'package:devocional_nuevo/models/backup_content_summary.dart';
import 'package:flutter_test/flutter_test.dart';

/// Comprehensive tests for BackupState classes
/// Focuses on equality, props, immutability, and copyWith
void main() {
  group('BackupInitial', () {
    test('supports value equality', () {
      const state1 = BackupInitial();
      const state2 = BackupInitial();

      expect(state1, equals(state2));
      expect(state1.hashCode, equals(state2.hashCode));
    });

    test('props returns empty list', () {
      const state = BackupInitial();
      expect(state.props, isEmpty);
    });

    test('extends BackupState', () {
      const state = BackupInitial();
      expect(state, isA<BackupState>());
    });
  });

  group('BackupLoading', () {
    test('supports value equality', () {
      const state1 = BackupLoading();
      const state2 = BackupLoading();

      expect(state1, equals(state2));
      expect(state1.hashCode, equals(state2.hashCode));
    });

    test('props returns empty list', () {
      const state = BackupLoading();
      expect(state.props, isEmpty);
    });

    test('extends BackupState', () {
      const state = BackupLoading();
      expect(state, isA<BackupState>());
    });
  });

  group('BackupLoaded', () {
    final now = DateTime(2024, 1, 1);
    final later = DateTime(2024, 1, 2);

    test('supports value equality with same properties', () {
      final state1 = BackupLoaded(
        autoBackupEnabled: true,
        backupFrequency: 'daily',
        wifiOnlyEnabled: true,
        compressionEnabled: true,
        backupOptions: const {'favorites': true},
        lastBackupTime: now,
        nextBackupTime: later,
        estimatedSize: 1024,
        isAuthenticated: true,
        userEmail: 'test@example.com',
      );

      final state2 = BackupLoaded(
        autoBackupEnabled: true,
        backupFrequency: 'daily',
        wifiOnlyEnabled: true,
        compressionEnabled: true,
        backupOptions: const {'favorites': true},
        lastBackupTime: now,
        nextBackupTime: later,
        estimatedSize: 1024,
        isAuthenticated: true,
        userEmail: 'test@example.com',
      );

      expect(state1, equals(state2));
      expect(state1.hashCode, equals(state2.hashCode));
    });

    test('different properties are not equal', () {
      final state1 = BackupLoaded(
        autoBackupEnabled: true,
        backupFrequency: 'daily',
        wifiOnlyEnabled: true,
        compressionEnabled: true,
        backupOptions: const {},
        estimatedSize: 0,
        isAuthenticated: true,
      );

      final state2 = BackupLoaded(
        autoBackupEnabled: false,
        backupFrequency: 'weekly',
        wifiOnlyEnabled: false,
        compressionEnabled: false,
        backupOptions: const {},
        estimatedSize: 0,
        isAuthenticated: false,
      );

      expect(state1, isNot(equals(state2)));
    });

    test('props includes all properties', () {
      final state = BackupLoaded(
        autoBackupEnabled: true,
        backupFrequency: 'daily',
        wifiOnlyEnabled: true,
        compressionEnabled: true,
        backupOptions: const {'favorites': true},
        lastBackupTime: now,
        nextBackupTime: later,
        estimatedSize: 1024,
        isAuthenticated: true,
        userEmail: 'test@example.com',
      );

      expect(
        state.props,
        equals([
          true,
          'daily',
          true,
          true,
          const {'favorites': true},
          now,
          later,
          1024,
          true,
          'test@example.com',
          null, // contentSummary — nullable, not set
        ]),
      );
    });

    test('copyWith returns new instance with updated autoBackupEnabled', () {
      final state = BackupLoaded(
        autoBackupEnabled: false,
        backupFrequency: 'daily',
        wifiOnlyEnabled: false,
        compressionEnabled: false,
        backupOptions: const {},
        estimatedSize: 0,
        isAuthenticated: false,
      );

      final updated = state.copyWith(autoBackupEnabled: true);

      expect(updated.autoBackupEnabled, isTrue);
      expect(updated.backupFrequency, equals('daily'));
      expect(state.autoBackupEnabled, isFalse); // Original unchanged
    });

    test('copyWith returns new instance with updated backupFrequency', () {
      final state = BackupLoaded(
        autoBackupEnabled: false,
        backupFrequency: 'daily',
        wifiOnlyEnabled: false,
        compressionEnabled: false,
        backupOptions: const {},
        estimatedSize: 0,
        isAuthenticated: false,
      );

      final updated = state.copyWith(backupFrequency: 'weekly');

      expect(updated.backupFrequency, equals('weekly'));
      expect(updated.autoBackupEnabled, isFalse);
    });

    test('copyWith returns new instance with updated wifiOnlyEnabled', () {
      final state = BackupLoaded(
        autoBackupEnabled: false,
        backupFrequency: 'daily',
        wifiOnlyEnabled: false,
        compressionEnabled: false,
        backupOptions: const {},
        estimatedSize: 0,
        isAuthenticated: false,
      );

      final updated = state.copyWith(wifiOnlyEnabled: true);

      expect(updated.wifiOnlyEnabled, isTrue);
      expect(state.wifiOnlyEnabled, isFalse);
    });

    test('copyWith returns new instance with updated compressionEnabled', () {
      final state = BackupLoaded(
        autoBackupEnabled: false,
        backupFrequency: 'daily',
        wifiOnlyEnabled: false,
        compressionEnabled: false,
        backupOptions: const {},
        estimatedSize: 0,
        isAuthenticated: false,
      );

      final updated = state.copyWith(compressionEnabled: true);

      expect(updated.compressionEnabled, isTrue);
      expect(state.compressionEnabled, isFalse);
    });

    test('copyWith returns new instance with updated backupOptions', () {
      final state = BackupLoaded(
        autoBackupEnabled: false,
        backupFrequency: 'daily',
        wifiOnlyEnabled: false,
        compressionEnabled: false,
        backupOptions: const {},
        estimatedSize: 0,
        isAuthenticated: false,
      );

      final updated = state.copyWith(
        backupOptions: const {'favorites': true, 'settings': false},
      );

      expect(
        updated.backupOptions,
        equals({'favorites': true, 'settings': false}),
      );
      expect(state.backupOptions, isEmpty);
    });

    test('copyWith returns new instance with updated lastBackupTime', () {
      final state = BackupLoaded(
        autoBackupEnabled: false,
        backupFrequency: 'daily',
        wifiOnlyEnabled: false,
        compressionEnabled: false,
        backupOptions: const {},
        estimatedSize: 0,
        isAuthenticated: false,
      );

      final updated = state.copyWith(lastBackupTime: now);

      expect(updated.lastBackupTime, equals(now));
      expect(state.lastBackupTime, isNull);
    });

    test('copyWith returns new instance with updated nextBackupTime', () {
      final state = BackupLoaded(
        autoBackupEnabled: false,
        backupFrequency: 'daily',
        wifiOnlyEnabled: false,
        compressionEnabled: false,
        backupOptions: const {},
        estimatedSize: 0,
        isAuthenticated: false,
      );

      final updated = state.copyWith(nextBackupTime: later);

      expect(updated.nextBackupTime, equals(later));
      expect(state.nextBackupTime, isNull);
    });

    test('copyWith returns new instance with updated estimatedSize', () {
      final state = BackupLoaded(
        autoBackupEnabled: false,
        backupFrequency: 'daily',
        wifiOnlyEnabled: false,
        compressionEnabled: false,
        backupOptions: const {},
        estimatedSize: 0,
        isAuthenticated: false,
      );

      final updated = state.copyWith(estimatedSize: 2048);

      expect(updated.estimatedSize, equals(2048));
      expect(state.estimatedSize, equals(0));
    });

    test('copyWith returns new instance with updated isAuthenticated', () {
      final state = BackupLoaded(
        autoBackupEnabled: false,
        backupFrequency: 'daily',
        wifiOnlyEnabled: false,
        compressionEnabled: false,
        backupOptions: const {},
        estimatedSize: 0,
        isAuthenticated: false,
      );

      final updated = state.copyWith(isAuthenticated: true);

      expect(updated.isAuthenticated, isTrue);
      expect(state.isAuthenticated, isFalse);
    });

    test('copyWith returns new instance with updated userEmail', () {
      final state = BackupLoaded(
        autoBackupEnabled: false,
        backupFrequency: 'daily',
        wifiOnlyEnabled: false,
        compressionEnabled: false,
        backupOptions: const {},
        estimatedSize: 0,
        isAuthenticated: false,
      );

      final updated = state.copyWith(userEmail: 'new@example.com');

      expect(updated.userEmail, equals('new@example.com'));
      expect(state.userEmail, isNull);
    });

    test('copyWith with no parameters returns identical state', () {
      final state = BackupLoaded(
        autoBackupEnabled: true,
        backupFrequency: 'monthly',
        wifiOnlyEnabled: true,
        compressionEnabled: true,
        backupOptions: const {'test': true},
        lastBackupTime: now,
        nextBackupTime: later,
        estimatedSize: 512,
        isAuthenticated: true,
        userEmail: 'test@example.com',
      );

      final copied = state.copyWith();

      expect(copied, equals(state));
      expect(copied.autoBackupEnabled, equals(state.autoBackupEnabled));
      expect(copied.backupFrequency, equals(state.backupFrequency));
      expect(copied.wifiOnlyEnabled, equals(state.wifiOnlyEnabled));
      expect(copied.compressionEnabled, equals(state.compressionEnabled));
      expect(copied.backupOptions, equals(state.backupOptions));
      expect(copied.lastBackupTime, equals(state.lastBackupTime));
      expect(copied.nextBackupTime, equals(state.nextBackupTime));
      expect(copied.estimatedSize, equals(state.estimatedSize));
      expect(copied.isAuthenticated, equals(state.isAuthenticated));
      expect(copied.userEmail, equals(state.userEmail));
    });

    test('can handle null optional fields', () {
      const state = BackupLoaded(
        autoBackupEnabled: false,
        backupFrequency: 'deactivated',
        wifiOnlyEnabled: false,
        compressionEnabled: false,
        backupOptions: {},
        lastBackupTime: null,
        nextBackupTime: null,
        estimatedSize: 0,
        isAuthenticated: false,
        userEmail: null,
      );

      expect(state.lastBackupTime, isNull);
      expect(state.nextBackupTime, isNull);
      expect(state.userEmail, isNull);
    });

    test('extends BackupState', () {
      const state = BackupLoaded(
        autoBackupEnabled: false,
        backupFrequency: 'daily',
        wifiOnlyEnabled: false,
        compressionEnabled: false,
        backupOptions: {},
        estimatedSize: 0,
        isAuthenticated: false,
      );
      expect(state, isA<BackupState>());
    });
  });

  group('BackupCreating', () {
    test('supports value equality', () {
      const state1 = BackupCreating();
      const state2 = BackupCreating();

      expect(state1, equals(state2));
      expect(state1.hashCode, equals(state2.hashCode));
    });

    test('props returns empty list', () {
      const state = BackupCreating();
      expect(state.props, isEmpty);
    });

    test('extends BackupState', () {
      const state = BackupCreating();
      expect(state, isA<BackupState>());
    });
  });

  group('BackupCreated', () {
    final timestamp1 = DateTime(2024, 1, 1);
    final timestamp2 = DateTime(2024, 1, 2);

    test('supports value equality with same timestamp', () {
      final state1 = BackupCreated(timestamp1);
      final state2 = BackupCreated(timestamp1);

      expect(state1, equals(state2));
      expect(state1.hashCode, equals(state2.hashCode));
    });

    test('different timestamps are not equal', () {
      final state1 = BackupCreated(timestamp1);
      final state2 = BackupCreated(timestamp2);

      expect(state1, isNot(equals(state2)));
    });

    test('props includes timestamp', () {
      final state = BackupCreated(timestamp1);
      expect(state.props, equals([timestamp1]));
    });

    test('creates state with timestamp', () {
      final state = BackupCreated(timestamp1);
      expect(state.timestamp, equals(timestamp1));
    });

    test('extends BackupState', () {
      final state = BackupCreated(timestamp1);
      expect(state, isA<BackupState>());
    });
  });

  group('BackupSigningIn', () {
    test('supports value equality', () {
      const state1 = BackupSigningIn();
      const state2 = BackupSigningIn();

      expect(state1, equals(state2));
      expect(state1.hashCode, equals(state2.hashCode));
    });

    test('props returns empty list', () {
      const state = BackupSigningIn();
      expect(state.props, isEmpty);
    });

    test('extends BackupState', () {
      const state = BackupSigningIn();
      expect(state, isA<BackupState>());
    });
  });

  group('BackupRestoring', () {
    test('supports value equality', () {
      const state1 = BackupRestoring();
      const state2 = BackupRestoring();

      expect(state1, equals(state2));
      expect(state1.hashCode, equals(state2.hashCode));
    });

    test('props returns empty list', () {
      const state = BackupRestoring();
      expect(state.props, isEmpty);
    });

    test('extends BackupState', () {
      const state = BackupRestoring();
      expect(state, isA<BackupState>());
    });
  });

  group('BackupRestored', () {
    test('supports value equality with same restoredVersion', () {
      const state1 = BackupRestored(restoredVersion: 'v1.0');
      const state2 = BackupRestored(restoredVersion: 'v1.0');

      expect(state1, equals(state2));
      expect(state1.hashCode, equals(state2.hashCode));
    });

    test('different restoredVersions are not equal', () {
      const state1 = BackupRestored(restoredVersion: 'v1.0');
      const state2 = BackupRestored(restoredVersion: 'v2.0');

      expect(state1, isNot(equals(state2)));
    });

    test('null restoredVersion states are equal', () {
      const state1 = BackupRestored();
      const state2 = BackupRestored();

      expect(state1, equals(state2));
    });

    test('null and non-null restoredVersions are not equal', () {
      const state1 = BackupRestored();
      const state2 = BackupRestored(restoredVersion: 'v1.0');

      expect(state1, isNot(equals(state2)));
    });

    test('props includes restoredVersion', () {
      const state = BackupRestored(restoredVersion: 'v1.0');
      expect(state.props, equals(['v1.0']));
    });

    test('props includes null restoredVersion', () {
      const state = BackupRestored();
      expect(state.props, equals([null]));
    });

    test('creates state with restoredVersion', () {
      const state = BackupRestored(restoredVersion: 'v1.0');
      expect(state.restoredVersion, equals('v1.0'));
    });

    test('creates state with null restoredVersion', () {
      const state = BackupRestored();
      expect(state.restoredVersion, isNull);
    });

    test('extends BackupState', () {
      const state = BackupRestored();
      expect(state, isA<BackupState>());
    });
  });

  group('BackupError', () {
    test('supports value equality with same message', () {
      const state1 = BackupError('Error occurred');
      const state2 = BackupError('Error occurred');

      expect(state1, equals(state2));
      expect(state1.hashCode, equals(state2.hashCode));
    });

    test('different messages are not equal', () {
      const state1 = BackupError('Error 1');
      const state2 = BackupError('Error 2');

      expect(state1, isNot(equals(state2)));
    });

    test('props includes message', () {
      const state = BackupError('Test error');
      expect(state.props, equals(['Test error']));
    });

    test('creates state with message', () {
      const state = BackupError('Network error');
      expect(state.message, equals('Network error'));
    });

    test('extends BackupState', () {
      const state = BackupError('Error');
      expect(state, isA<BackupState>());
    });
  });

  group('BackupSettingsUpdated', () {
    test('supports value equality', () {
      const state1 = BackupSettingsUpdated();
      const state2 = BackupSettingsUpdated();

      expect(state1, equals(state2));
      expect(state1.hashCode, equals(state2.hashCode));
    });

    test('props returns empty list', () {
      const state = BackupSettingsUpdated();
      expect(state.props, isEmpty);
    });

    test('extends BackupState', () {
      const state = BackupSettingsUpdated();
      expect(state, isA<BackupState>());
    });
  });

  group('BackupSuccess', () {
    test('supports value equality with same title and message', () {
      const state1 = BackupSuccess('Title', 'Message');
      const state2 = BackupSuccess('Title', 'Message');

      expect(state1, equals(state2));
      expect(state1.hashCode, equals(state2.hashCode));
    });

    test('different titles are not equal', () {
      const state1 = BackupSuccess('Title 1', 'Message');
      const state2 = BackupSuccess('Title 2', 'Message');

      expect(state1, isNot(equals(state2)));
    });

    test('different messages are not equal', () {
      const state1 = BackupSuccess('Title', 'Message 1');
      const state2 = BackupSuccess('Title', 'Message 2');

      expect(state1, isNot(equals(state2)));
    });

    test('props includes title and message', () {
      const state = BackupSuccess('Success', 'Operation completed');
      expect(state.props, equals(['Success', 'Operation completed', null]));
    });

    test('creates state with title and message', () {
      const state = BackupSuccess(
        'Backup Complete',
        'Your data has been backed up',
      );
      expect(state.title, equals('Backup Complete'));
      expect(state.message, equals('Your data has been backed up'));
    });

    test('extends BackupState', () {
      const state = BackupSuccess('Title', 'Message');
      expect(state, isA<BackupState>());
    });
  });

  group('BackupState hierarchy', () {
    test('all states extend BackupState', () {
      expect(const BackupInitial(), isA<BackupState>());
      expect(const BackupLoading(), isA<BackupState>());
      expect(
        const BackupLoaded(
          autoBackupEnabled: false,
          backupFrequency: 'daily',
          wifiOnlyEnabled: false,
          compressionEnabled: false,
          backupOptions: {},
          estimatedSize: 0,
          isAuthenticated: false,
        ),
        isA<BackupState>(),
      );
      expect(const BackupCreating(), isA<BackupState>());
      expect(BackupCreated(DateTime.now()), isA<BackupState>());
      expect(const BackupSigningIn(), isA<BackupState>());
      expect(const BackupRestoring(), isA<BackupState>());
      expect(const BackupRestored(), isA<BackupState>());
      expect(const BackupError('Error'), isA<BackupState>());
      expect(const BackupSettingsUpdated(), isA<BackupState>());
      expect(const BackupSuccess('Title', 'Message'), isA<BackupState>());
    });
  });

  // ── BackupLoaded.contentSummary ─────────────────────────────────────────────
  group('BackupLoaded — contentSummary integration', () {
    const summary = BackupContentSummary(
      prayersCount: 5,
      thanksgivingsCount: 3,
      testimoniesCount: 1,
      favoritesCount: 8,
      encountersCount: 2,
      discoveryCount: 4,
      versesCount: 7,
    );

    test('contentSummary defaults to null when not provided', () {
      const state = BackupLoaded(
        autoBackupEnabled: false,
        backupFrequency: 'daily',
        wifiOnlyEnabled: false,
        compressionEnabled: false,
        backupOptions: {},
        estimatedSize: 0,
        isAuthenticated: false,
      );
      expect(state.contentSummary, isNull);
    });

    test('contentSummary holds the provided value', () {
      const state = BackupLoaded(
        autoBackupEnabled: true,
        backupFrequency: 'daily',
        wifiOnlyEnabled: false,
        compressionEnabled: false,
        backupOptions: {},
        estimatedSize: 0,
        isAuthenticated: true,
        contentSummary: summary,
      );
      expect(state.contentSummary, equals(summary));
      expect(state.contentSummary!.prayersCount, 5);
      expect(state.contentSummary!.versesCount, 7);
      expect(state.contentSummary!.totalItems, 30);
    });

    test('copyWith preserves contentSummary when not overridden', () {
      const state = BackupLoaded(
        autoBackupEnabled: true,
        backupFrequency: 'daily',
        wifiOnlyEnabled: false,
        compressionEnabled: false,
        backupOptions: {},
        estimatedSize: 0,
        isAuthenticated: true,
        contentSummary: summary,
      );
      final copied = state.copyWith(autoBackupEnabled: false);
      expect(copied.contentSummary, equals(summary));
      expect(copied.autoBackupEnabled, isFalse);
    });

    test('copyWith updates contentSummary when provided', () {
      const state = BackupLoaded(
        autoBackupEnabled: true,
        backupFrequency: 'daily',
        wifiOnlyEnabled: false,
        compressionEnabled: false,
        backupOptions: {},
        estimatedSize: 0,
        isAuthenticated: true,
      );
      const newSummary = BackupContentSummary(
        prayersCount: 10,
        thanksgivingsCount: 0,
        testimoniesCount: 0,
        favoritesCount: 0,
        encountersCount: 0,
        discoveryCount: 0,
        versesCount: 0,
      );
      final updated = state.copyWith(contentSummary: newSummary);
      expect(updated.contentSummary, equals(newSummary));
      expect(updated.contentSummary!.prayersCount, 10);
    });

    test('states with different contentSummary are not equal', () {
      const stateA = BackupLoaded(
        autoBackupEnabled: true,
        backupFrequency: 'daily',
        wifiOnlyEnabled: false,
        compressionEnabled: false,
        backupOptions: {},
        estimatedSize: 0,
        isAuthenticated: true,
        contentSummary: summary,
      );
      const stateB = BackupLoaded(
        autoBackupEnabled: true,
        backupFrequency: 'daily',
        wifiOnlyEnabled: false,
        compressionEnabled: false,
        backupOptions: {},
        estimatedSize: 0,
        isAuthenticated: true,
        // contentSummary omitted → null
      );
      expect(stateA, isNot(equals(stateB)));
    });
  });

  // ── BackupSuccess.contentSummary ────────────────────────────────────────────
  group('BackupSuccess — contentSummary integration', () {
    const summary = BackupContentSummary(
      prayersCount: 16,
      thanksgivingsCount: 4,
      testimoniesCount: 2,
      favoritesCount: 3,
      encountersCount: 2,
      discoveryCount: 0,
      versesCount: 7,
    );

    test('contentSummary defaults to null', () {
      const state = BackupSuccess('title', 'message');
      expect(state.contentSummary, isNull);
    });

    test('contentSummary holds the provided value', () {
      final state = BackupSuccess(
        'backup.sign_in_success',
        'backup.created_successfully',
        contentSummary: summary,
      );
      expect(state.contentSummary, equals(summary));
      expect(state.contentSummary!.prayersCount, 16);
      expect(state.contentSummary!.versesCount, 7);
    });

    test('props includes contentSummary in equality check', () {
      final stateWithSummary = BackupSuccess(
        'title',
        'message',
        contentSummary: summary,
      );
      const stateWithoutSummary = BackupSuccess('title', 'message');

      expect(stateWithSummary, isNot(equals(stateWithoutSummary)));
      expect(stateWithSummary.props, equals(['title', 'message', summary]));
    });

    test('two BackupSuccess with same summary are equal', () {
      final a = BackupSuccess('t', 'm', contentSummary: summary);
      final b = BackupSuccess('t', 'm', contentSummary: summary);
      expect(a, equals(b));
    });
  });
}
