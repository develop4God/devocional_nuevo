@Tags(['unit', 'models'])
library;

import 'package:devocional_nuevo/models/encounter_card_model.dart';
import 'package:devocional_nuevo/models/encounter_index_entry.dart';
import 'package:devocional_nuevo/models/encounter_study.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // ── EncounterIndexEntry ────────────────────────────────────────────────────

  group('EncounterIndexEntry.fromJson', () {
    test('parses all fields from valid JSON', () {
      final json = {
        'id': 'peter_water_001',
        'version': '1.0',
        'emoji': '🌊',
        'status': 'published',
        'mood_primary': 'tense',
        'accent_color': '#0f1828',
        'has_interactive': false,
        'testament': 'new',
        'character': 'Peter',
        'files': {
          'en': 'peter_water_001_en.json',
          'es': 'peter_water_001_es.json'
        },
        'titles': {
          'en': 'Peter Walks on Water',
          'es': 'Pedro Camina sobre el Agua'
        },
        'subtitles': {
          'en': 'Faith Beyond the Storm',
          'es': 'Fe Más Allá de la Tormenta'
        },
        'scripture_reference': {'en': 'Matthew 14:22-33'},
        'estimated_reading_minutes': {'en': 10, 'es': 12},
      };

      final entry = EncounterIndexEntry.fromJson(json);

      expect(entry.id, equals('peter_water_001'));
      expect(entry.version, equals('1.0'));
      expect(entry.emoji, equals('🌊'));
      expect(entry.status, equals('published'));
      expect(entry.moodPrimary, equals('tense'));
      expect(entry.accentColor, equals('#0f1828'));
      expect(entry.hasInteractive, isFalse);
      expect(entry.testament, equals('new'));
      expect(entry.character, equals('Peter'));
      expect(entry.files['en'], equals('peter_water_001_en.json'));
      expect(entry.titles['en'], equals('Peter Walks on Water'));
      expect(entry.subtitles['en'], equals('Faith Beyond the Storm'));
      expect(entry.scriptureReference['en'], equals('Matthew 14:22-33'));
      expect(entry.estimatedReadingMinutes['en'], equals(10));
    });

    test('missing optional fields do not throw', () {
      final json = {'id': 'minimal_001'};
      expect(() => EncounterIndexEntry.fromJson(json), returnsNormally);
      final entry = EncounterIndexEntry.fromJson(json);
      expect(entry.id, equals('minimal_001'));
      expect(entry.status, equals('coming_soon')); // default
      expect(entry.emoji, isNull);
    });

    test('status defaults to coming_soon when missing', () {
      final json = {'id': 'no_status'};
      final entry = EncounterIndexEntry.fromJson(json);
      expect(entry.status, equals('coming_soon'));
      expect(entry.isPublished, isFalse);
    });

    test('isPublished returns true for published status', () {
      final entry = EncounterIndexEntry.fromJson({
        'id': 'x',
        'status': 'published',
        'files': {},
        'titles': {},
        'subtitles': {},
        'scripture_reference': {},
        'estimated_reading_minutes': {}
      });
      expect(entry.isPublished, isTrue);
    });

    test('titleFor falls back to en then first available', () {
      final entry = EncounterIndexEntry(
        id: 'x',
        version: '1.0',
        status: 'published',
        files: {},
        titles: {'es': 'Título'},
        subtitles: {},
        scriptureReference: {},
        estimatedReadingMinutes: {},
      );
      expect(entry.titleFor('fr'), equals('Título')); // no fr, no en → first
    });

    test('readingMinutesFor returns default 5 when missing', () {
      final entry = EncounterIndexEntry(
        id: 'x',
        version: '1.0',
        status: 'published',
        files: {},
        titles: {},
        subtitles: {},
        scriptureReference: {},
        estimatedReadingMinutes: {},
      );
      expect(entry.readingMinutesFor('en'), equals(5));
    });
  });

  // ── EncounterCard ──────────────────────────────────────────────────────────

  group('EncounterCard.fromJson', () {
    test('parses cinematic_scene card', () {
      final json = {
        'order': 1,
        'type': 'cinematic_scene',
        'mood': 'tense',
        'title': 'The Storm',
        'narrative': 'Dark waves...',
        'image_url': 'https://example.com/img.jpg',
        'verse_overlay': {'reference': 'Matt 14:24', 'text': 'buffeted'},
        'revelation_key': 'Faith first.',
      };
      final card = EncounterCard.fromJson(json, encounterId: 'peter_water_001');
      expect(card.order, 1);
      expect(card.type, 'cinematic_scene');
      expect(card.mood, 'tense');
      expect(card.imageUrl, 'https://example.com/img.jpg');
      expect(card.verseOverlay?.reference, 'Matt 14:24');
      expect(card.revelationKey, 'Faith first.');
    });

    test('parses discovery_activation card with questions and prayer', () {
      final json = {
        'order': 5,
        'type': 'discovery_activation',
        'title': 'Living It Out',
        'discovery_questions': [
          {'category': 'Reflect', 'question': 'What storm?'},
          {'category': 'Apply', 'question': 'What step?'},
        ],
        'prayer': {'title': 'Prayer', 'content': 'Lord, help me...'},
      };
      final card = EncounterCard.fromJson(json, encounterId: 'peter_water_001');
      expect(card.type, 'discovery_activation');
      expect(card.discoveryQuestions?.length, 2);
      expect(card.prayer?.content, 'Lord, help me...');
    });

    test('parses completion card with completion_verse', () {
      final json = {
        'order': 6,
        'type': 'completion',
        'title': 'Done',
        'reflection_prompt': 'How did this change you?',
        'completion_verse': {'reference': 'Matt 14:33', 'text': 'Son of God'},
      };
      final card = EncounterCard.fromJson(json, encounterId: 'peter_water_001');
      expect(card.type, 'completion');
      expect(card.completionVerse?.reference, 'Matt 14:33');
      expect(card.reflectionPrompt, 'How did this change you?');
    });

    test('unknown card type returns type=unknown', () {
      final json = {
        'order': 1,
        'type': 'some_future_unknown_type',
        'title': 'Future card',
      };
      final card = EncounterCard.fromJson(json, encounterId: 'peter_water_001');
      expect(card.type, equals('unknown'));
    });

    test('all optional fields are nullable — does not crash with nulls', () {
      final json = {'order': 1, 'type': 'cinematic_scene'};
      expect(() => EncounterCard.fromJson(json, encounterId: 'peter_water_001'),
          returnsNormally);
      final card = EncounterCard.fromJson(json, encounterId: 'peter_water_001');
      expect(card.mood, isNull);
      expect(card.imageUrl, isNull);
      expect(card.verseOverlay, isNull);
    });

    test('imageUrl resolves bare filename using encounterId path', () {
      final json = {'order': 1, 'type': 'cinematic_scene', 'image_url': 'peter_intro.jpg'};
      final card = EncounterCard.fromJson(json, encounterId: 'peter_water_001');
      expect(card.imageUrl,
        'https://raw.githubusercontent.com/develop4God/Devocionales-assets/main/images/encounters/peter_water_001/peter_intro.jpg');
    });

    test('imageUrl passes through absolute URL unchanged', () {
      final json = {'order': 1, 'type': 'cinematic_scene', 'image_url': 'https://example.com/img.jpg'};
      final card = EncounterCard.fromJson(json, encounterId: 'peter_water_001');
      expect(card.imageUrl, 'https://example.com/img.jpg');
    });

    test('all 7 known card types parse without error', () {
      const types = [
        'cinematic_scene',
        'scripture_moment',
        'character_moment',
        'theological_depth',
        'discovery_activation',
        'completion',
        'interactive_moment',
      ];
      for (final type in types) {
        final json = {'order': 1, 'type': type};
        expect(
            () => EncounterCard.fromJson(json, encounterId: 'peter_water_001'),
            returnsNormally,
            reason: 'Type $type should not throw');
      }
    });
  });

  // ── EncounterStudy ─────────────────────────────────────────────────────────

  group('EncounterStudy.fromJson', () {
    test('parses full study JSON', () {
      final json = {
        'id': 'peter_water_001',
        'type': 'encounter',
        'schema_version': '1.0',
        'language': 'en',
        'bible_version': 'NIV',
        'version': '1.0',
        'estimated_reading_minutes': 10,
        'meta': {'author': 'test'},
        'key_verse': {'reference': 'Matthew 14:29', 'text': 'Come.'},
        'cards': [
          {'order': 1, 'type': 'cinematic_scene', 'title': 'The Storm'},
          {'order': 2, 'type': 'completion', 'title': 'Done'},
        ],
      };

      final study = EncounterStudy.fromJson(json);
      expect(study.id, 'peter_water_001');
      expect(study.language, 'en');
      expect(study.estimatedReadingMinutes, 10);
      expect(study.keyVerse?.reference, 'Matthew 14:29');
      expect(study.cards.length, 2);
      expect(study.cardCount, 2);
    });

    test('missing fields do not throw', () {
      final json = {'id': 'minimal'};
      expect(() => EncounterStudy.fromJson(json), returnsNormally);
      final study = EncounterStudy.fromJson(json);
      expect(study.cards, isEmpty);
    });
  });

  // ── Sub-models ─────────────────────────────────────────────────────────────

  group('EncounterKeyVerse.fromJson', () {
    test('parses reference and text', () {
      final kv = EncounterKeyVerse.fromJson(
          {'reference': 'John 3:16', 'text': 'For God so loved...'});
      expect(kv.reference, 'John 3:16');
      expect(kv.text, 'For God so loved...');
    });

    test('defaults to empty string on missing fields', () {
      final kv = EncounterKeyVerse.fromJson({});
      expect(kv.reference, isEmpty);
      expect(kv.text, isEmpty);
    });
  });
}
