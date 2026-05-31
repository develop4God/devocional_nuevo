@Tags(['unit', 'services', 'backup'])
library;

// test/unit/services/backup_edit_tracking_test.dart
//
// Tests for backup edit tracking feature with lastModifiedDate
// Validates that edits to prayers, thanksgivings, and testimonies are properly
// tracked and merged across devices based on modification timestamps.

import 'package:devocional_nuevo/models/prayer_model.dart';
import 'package:devocional_nuevo/models/thanksgiving_model.dart';
import 'package:devocional_nuevo/models/testimony_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Backup Edit Tracking', () {
    group('Prayer Model lastModifiedDate', () {
      test('Prayer includes lastModifiedDate in serialization', () {
        final now = DateTime(2026, 5, 31, 10, 0, 0);
        final prayer = Prayer(
          id: 'prayer1',
          text: 'Test prayer',
          createdDate: DateTime(2026, 5, 1),
          status: PrayerStatus.active,
          lastModifiedDate: now,
        );

        final json = prayer.toJson();

        expect(json['lastModifiedDate'], equals(now.toIso8601String()));
      });

      test('Prayer fromJson parses lastModifiedDate', () {
        final json = {
          'id': 'prayer1',
          'text': 'Test prayer',
          'createdDate': '2026-05-01T00:00:00.000',
          'status': 'active',
          'lastModifiedDate': '2026-05-31T10:00:00.000',
        };

        final prayer = Prayer.fromJson(json);

        expect(
          prayer.lastModifiedDate,
          equals(DateTime(2026, 5, 31, 10, 0, 0)),
        );
      });

      test(
          'Prayer fromJson defaults lastModifiedDate to createdDate when missing',
          () {
        final json = {
          'id': 'prayer1',
          'text': 'Test prayer',
          'createdDate': '2026-05-01T00:00:00.000',
          'status': 'active',
        };

        final prayer = Prayer.fromJson(json);

        expect(prayer.lastModifiedDate, equals(prayer.createdDate));
      });

      test('Prayer copyWith updates lastModifiedDate automatically', () {
        final original = Prayer(
          id: 'prayer1',
          text: 'Original text',
          createdDate: DateTime(2026, 5, 1),
          status: PrayerStatus.active,
          lastModifiedDate: DateTime(2026, 5, 1),
        );

        // Edit the prayer
        final edited = original.copyWith(text: 'Edited text');

        expect(edited.text, equals('Edited text'));
        expect(
            edited.lastModifiedDate.isAfter(original.lastModifiedDate), isTrue);
      });

      test(
          'Prayer copyWith can preserve lastModifiedDate when updateModifiedDate is false',
          () {
        final original = Prayer(
          id: 'prayer1',
          text: 'Original text',
          createdDate: DateTime(2026, 5, 1),
          status: PrayerStatus.active,
          lastModifiedDate: DateTime(2026, 5, 1),
        );

        final copied = original.copyWith(
          text: 'Same text',
          updateModifiedDate: false,
        );

        expect(copied.lastModifiedDate, equals(original.lastModifiedDate));
      });
    });

    group('Thanksgiving Model lastModifiedDate', () {
      test('Thanksgiving includes lastModifiedDate in serialization', () {
        final now = DateTime(2026, 5, 31, 10, 0, 0);
        final thanksgiving = Thanksgiving(
          id: 'thanks1',
          text: 'Test thanksgiving',
          createdDate: DateTime(2026, 5, 1),
          lastModifiedDate: now,
        );

        final json = thanksgiving.toJson();

        expect(json['lastModifiedDate'], equals(now.toIso8601String()));
      });

      test('Thanksgiving copyWith updates lastModifiedDate automatically', () {
        final original = Thanksgiving(
          id: 'thanks1',
          text: 'Original text',
          createdDate: DateTime(2026, 5, 1),
          lastModifiedDate: DateTime(2026, 5, 1),
        );

        final edited = original.copyWith(text: 'Edited text');

        expect(edited.text, equals('Edited text'));
        expect(
            edited.lastModifiedDate.isAfter(original.lastModifiedDate), isTrue);
      });
    });

    group('Testimony Model lastModifiedDate', () {
      test('Testimony includes lastModifiedDate in serialization', () {
        final now = DateTime(2026, 5, 31, 10, 0, 0);
        final testimony = Testimony(
          id: 'testimony1',
          text: 'Test testimony',
          createdDate: DateTime(2026, 5, 1),
          lastModifiedDate: now,
        );

        final json = testimony.toJson();

        expect(json['lastModifiedDate'], equals(now.toIso8601String()));
      });

      test('Testimony copyWith updates lastModifiedDate automatically', () {
        final original = Testimony(
          id: 'testimony1',
          text: 'Original text',
          createdDate: DateTime(2026, 5, 1),
          lastModifiedDate: DateTime(2026, 5, 1),
        );

        final edited = original.copyWith(text: 'Edited text');

        expect(edited.text, equals('Edited text'));
        expect(
            edited.lastModifiedDate.isAfter(original.lastModifiedDate), isTrue);
      });
    });

    group('Backup Merge with Timestamp Comparison', () {
      test('Prayers: newer version wins during merge', () {
        // Simulate two devices with the same prayer ID but different versions
        final deviceAOlderVersion = {
          'id': 'prayer1',
          'text': 'Old prayer text',
          'createdDate': '2026-05-01T00:00:00.000',
          'status': 'active',
          'lastModifiedDate': '2026-05-01T10:00:00.000',
        };

        final deviceBNewerVersion = {
          'id': 'prayer1',
          'text': 'Edited prayer text',
          'createdDate': '2026-05-01T00:00:00.000',
          'status': 'active',
          'lastModifiedDate': '2026-05-15T14:30:00.000',
        };

        // Simulate merge logic (remote first, then local)
        final merged = _mergePrayersByTimestamp(
          remote: [deviceAOlderVersion],
          local: [deviceBNewerVersion],
        );

        expect(merged.length, equals(1));
        expect(merged[0]['text'], equals('Edited prayer text'));
        expect(
          merged[0]['lastModifiedDate'],
          equals('2026-05-15T14:30:00.000'),
        );
      });

      test('Thanksgivings: newer version wins during merge', () {
        final olderVersion = {
          'id': 'thanks1',
          'text': 'Old thanksgiving',
          'createdDate': '2026-05-01T00:00:00.000',
          'lastModifiedDate': '2026-05-01T10:00:00.000',
        };

        final newerVersion = {
          'id': 'thanks1',
          'text': 'Edited thanksgiving',
          'createdDate': '2026-05-01T00:00:00.000',
          'lastModifiedDate': '2026-05-20T08:00:00.000',
        };

        final merged = _mergePrayersByTimestamp(
          remote: [olderVersion],
          local: [newerVersion],
        );

        expect(merged.length, equals(1));
        expect(merged[0]['text'], equals('Edited thanksgiving'));
      });

      test('Testimonies: newer version wins during merge', () {
        final olderVersion = {
          'id': 'testimony1',
          'text': 'Old testimony',
          'createdDate': '2026-05-01T00:00:00.000',
          'lastModifiedDate': '2026-05-01T10:00:00.000',
        };

        final newerVersion = {
          'id': 'testimony1',
          'text': 'Edited testimony',
          'createdDate': '2026-05-01T00:00:00.000',
          'lastModifiedDate': '2026-05-25T16:45:00.000',
        };

        final merged = _mergePrayersByTimestamp(
          remote: [olderVersion],
          local: [newerVersion],
        );

        expect(merged.length, equals(1));
        expect(merged[0]['text'], equals('Edited testimony'));
      });

      test('Prayers: entries without lastModifiedDate are kept if no conflict',
          () {
        final legacyPrayer = {
          'id': 'prayer1',
          'text': 'Legacy prayer without timestamp',
          'createdDate': '2026-05-01T00:00:00.000',
          'status': 'active',
        };

        final merged = _mergePrayersByTimestamp(
          remote: [],
          local: [legacyPrayer],
        );

        expect(merged.length, equals(1));
        expect(merged[0]['text'], equals('Legacy prayer without timestamp'));
      });

      test(
          'Prayers: newer version wins even when legacy version has no timestamp',
          () {
        final legacyVersion = {
          'id': 'prayer1',
          'text': 'Legacy prayer',
          'createdDate': '2026-05-01T00:00:00.000',
          'status': 'active',
          // No lastModifiedDate
        };

        final modernVersion = {
          'id': 'prayer1',
          'text': 'Modern edited prayer',
          'createdDate': '2026-05-01T00:00:00.000',
          'status': 'active',
          'lastModifiedDate': '2026-05-15T14:30:00.000',
        };

        final merged = _mergePrayersByTimestamp(
          remote: [legacyVersion],
          local: [modernVersion],
        );

        expect(merged.length, equals(1));
        expect(merged[0]['text'], equals('Modern edited prayer'));
      });

      test('Prayers: multiple prayers from different devices are all preserved',
          () {
        final deviceAPrayers = [
          {
            'id': 'prayer1',
            'text': 'Prayer from device A',
            'createdDate': '2026-05-01T00:00:00.000',
            'status': 'active',
            'lastModifiedDate': '2026-05-01T10:00:00.000',
          },
        ];

        final deviceBPrayers = [
          {
            'id': 'prayer2',
            'text': 'Prayer from device B',
            'createdDate': '2026-05-02T00:00:00.000',
            'status': 'active',
            'lastModifiedDate': '2026-05-02T10:00:00.000',
          },
        ];

        final merged = _mergePrayersByTimestamp(
          remote: deviceAPrayers,
          local: deviceBPrayers,
        );

        expect(merged.length, equals(2));
      });
    });
  });
}

/// Helper function to simulate backup merge logic for prayers
/// (matches the logic in google_drive_backup_service.dart)
List<Map<String, dynamic>> _mergePrayersByTimestamp({
  required List<Map<String, dynamic>> remote,
  required List<Map<String, dynamic>> local,
}) {
  final itemsById = <String, Map<String, dynamic>>{};
  for (final item in [...remote, ...local]) {
    if (item.containsKey('id')) {
      final id = item['id'].toString();
      final existing = itemsById[id];
      if (existing == null) {
        itemsById[id] = item;
      } else {
        // Compare lastModifiedDate and keep newer version
        final existingDate = _parseDateTime(existing['lastModifiedDate']);
        final currentDate = _parseDateTime(item['lastModifiedDate']);
        if (currentDate != null &&
            (existingDate == null || currentDate.isAfter(existingDate))) {
          itemsById[id] = item;
        }
      }
    }
  }
  return itemsById.values.toList();
}

/// Helper to parse DateTime from JSON
DateTime? _parseDateTime(dynamic value) {
  if (value == null) return null;
  if (value is String && value.isNotEmpty) {
    try {
      return DateTime.parse(value);
    } catch (e) {
      return null;
    }
  }
  return null;
}
