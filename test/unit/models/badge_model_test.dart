@Tags(['unit', 'models'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:devocional_nuevo/models/badge_model.dart';

void main() {
  group('Badge', () {
    const badge = Badge(
      id: 'badge_streak_7',
      name: 'Week Warrior',
      description: 'Read devotionals 7 days in a row',
      verse: 'But those who hope in the LORD',
      reference: 'Isaiah 40:31',
      imageUrl: 'assets/badges/streak_7.png',
    );

    Map<String, dynamic> validJson() => <String, dynamic>{
          'id': 'badge_streak_7',
          'name': 'Week Warrior',
          'description': 'Read devotionals 7 days in a row',
          'verse': 'But those who hope in the LORD',
          'reference': 'Isaiah 40:31',
          'imageUrl': 'assets/badges/streak_7.png',
        };

    test('fromJson maps every field', () {
      final badge = Badge.fromJson(validJson());

      expect(badge.id, equals('badge_streak_7'));
      expect(badge.name, equals('Week Warrior'));
      expect(badge.description, equals('Read devotionals 7 days in a row'));
      expect(badge.verse, equals('But those who hope in the LORD'));
      expect(badge.reference, equals('Isaiah 40:31'));
      expect(badge.imageUrl, equals('assets/badges/streak_7.png'));
    });

    test('toJson serializes every field', () {
      final json = badge.toJson();

      expect(json, equals(validJson()));
    });

    test('fromJson → toJson round-trip preserves data', () {
      final restored = Badge.fromJson(badge.toJson());

      // Equality is id-based; also compare each field explicitly.
      expect(restored, equals(badge));
      expect(restored.name, equals(badge.name));
      expect(restored.description, equals(badge.description));
      expect(restored.verse, equals(badge.verse));
      expect(restored.reference, equals(badge.reference));
      expect(restored.imageUrl, equals(badge.imageUrl));
    });

    test('fromJson throws when a required key is missing', () {
      final json = validJson()..remove('reference');

      expect(() => Badge.fromJson(json), throwsA(isA<TypeError>()));
    });

    test('equality is based on id only', () {
      const sameIdDifferentContent = Badge(
        id: 'badge_streak_7',
        name: 'Renamed Badge',
        description: 'Different description',
        verse: 'Different verse',
        reference: 'Psalm 1:1',
        imageUrl: 'other.png',
      );
      const differentId = Badge(
        id: 'badge_streak_30',
        name: 'Week Warrior',
        description: 'Read devotionals 7 days in a row',
        verse: 'But those who hope in the LORD',
        reference: 'Isaiah 40:31',
        imageUrl: 'assets/badges/streak_7.png',
      );

      expect(badge, equals(sameIdDifferentContent));
      expect(badge, isNot(equals(differentId)));
      expect(badge == badge, isTrue); // identical instance
    });

    test('hashCode matches id hashCode (equal objects, equal hashes)', () {
      const twin = Badge(
        id: 'badge_streak_7',
        name: 'x',
        description: 'x',
        verse: 'x',
        reference: 'x',
        imageUrl: 'x',
      );

      expect(badge.hashCode, equals('badge_streak_7'.hashCode));
      expect(badge.hashCode, equals(twin.hashCode));
    });

    test('toString contains id, name and verse', () {
      final text = badge.toString();

      expect(text, contains('badge_streak_7'));
      expect(text, contains('Week Warrior'));
      expect(text, contains('But those who hope in the LORD'));
    });
  });

  group('BadgeConfig', () {
    List<Map<String, dynamic>> badgeJsonList() => [
          {
            'id': 'b1',
            'name': 'First',
            'description': 'd1',
            'verse': 'v1',
            'reference': 'r1',
            'imageUrl': 'i1.png',
          },
          {
            'id': 'b2',
            'name': 'Second',
            'description': 'd2',
            'verse': 'v2',
            'reference': 'r2',
            'imageUrl': 'i2.png',
          },
        ];

    Map<String, dynamic> configJson() => <String, dynamic>{
          'version': '1.2.0',
          'lastUpdated': '2026-08-24',
          'badges': badgeJsonList(),
        };

    test('fromJson parses version, lastUpdated and badges list', () {
      final config = BadgeConfig.fromJson(configJson());

      expect(config.version, equals('1.2.0'));
      expect(config.lastUpdated, equals('2026-08-24'));
      expect(config.badges, hasLength(2));
      expect(config.badges[0].id, equals('b1'));
      expect(config.badges[1].id, equals('b2'));
    });

    test('toJson round-trip preserves full config', () {
      final config = BadgeConfig.fromJson(configJson());
      final restored = BadgeConfig.fromJson(config.toJson());

      expect(restored.version, equals(config.version));
      expect(restored.lastUpdated, equals(config.lastUpdated));
      expect(restored.badges.length, equals(config.badges.length));
      for (int i = 0; i < config.badges.length; i++) {
        expect(restored.badges[i], equals(config.badges[i]));
      }
    });

    test('fromJson accepts nested dynamic lists (decoded JSON shape)', () {
      // Simulates jsonDecode output where badges is List<dynamic>.
      final decoded = <String, dynamic>{
        'version': '2.0.0',
        'lastUpdated': '2026-01-01',
        'badges': [
          {
            'id': 'x1',
            'name': 'X',
            'description': 'dx',
            'verse': 'vx',
            'reference': 'rx',
            'imageUrl': 'ix.png',
          },
        ],
      };

      final config = BadgeConfig.fromJson(decoded);

      expect(config.badges.single.id, equals('x1'));
    });
  });
}
