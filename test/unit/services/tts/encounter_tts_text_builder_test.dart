import 'package:bible_reader_core/bible_reader_core.dart';
import 'package:devocional_nuevo/models/encounter_card_model.dart';
import 'package:devocional_nuevo/services/tts/encounter_tts_text_builder.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EncounterTtsTextBuilder', () {
    test('cinematic_scene includes rendered fields only', () {
      const card = EncounterCard(
        order: 0,
        type: 'cinematic_scene',
        title: 'The Garden',
        narrative: 'It was quiet.',
        verseOverlay: VerseRef(reference: 'Gen 1:1', text: 'In the beginning'),
        revelationKey: 'God creates.',
        subtitle: 'Not rendered by this type',
      );

      final result = EncounterTtsTextBuilder.build(card);

      expect(result, contains('The Garden'));
      expect(result, contains('It was quiet.'));
      expect(result, contains('Gen 1:1'));
      expect(result, contains('In the beginning'));
      expect(result, contains('God creates.'));
      // subtitle is not in cinematic_scene's rendered-fields contract.
      expect(result, isNot(contains('Not rendered by this type')));
    });

    test('scripture_moment includes verse pair and scripture connections', () {
      const card = EncounterCard(
        order: 1,
        type: 'scripture_moment',
        title: 'A Verse',
        subtitle: 'Sub',
        verseReference: 'John 3:16',
        verseText: 'For God so loved the world',
        reflection: 'Reflect on this.',
        scriptureConnections: [
          VerseRef(reference: 'Rom 5:8', text: 'God demonstrates his love'),
        ],
        narrative: 'Not rendered by this type',
      );

      final result = EncounterTtsTextBuilder.build(card);

      expect(result, contains('John 3:16'));
      expect(result, contains('For God so loved the world'));
      expect(result, contains('Reflect on this.'));
      expect(result, contains('Rom 5:8'));
      expect(result, contains('God demonstrates his love'));
      expect(result, isNot(contains('Not rendered by this type')));
    });

    test('discovery_activation includes questions and prayer', () {
      const card = EncounterCard(
        order: 2,
        type: 'discovery_activation',
        title: 'Reflect',
        discoveryQuestions: [
          EncounterDiscoveryQuestion(category: 'faith', question: 'Why?'),
        ],
        prayer: EncounterPrayer(title: 'Prayer', content: 'Lord, help us.'),
        content: 'Not rendered by this type',
      );

      final result = EncounterTtsTextBuilder.build(card);

      expect(result, contains('Why?'));
      expect(result, contains('Prayer'));
      expect(result, contains('Lord, help us.'));
      expect(result, isNot(contains('Not rendered by this type')));
    });

    test('completion includes completion verse and reflection prompt', () {
      const card = EncounterCard(
        order: 3,
        type: 'completion',
        completionVerse: VerseRef(reference: 'Ps 23:1', text: 'The Lord is my shepherd'),
        reflectionPrompt: 'What did you learn?',
        title: 'Not rendered by this type',
      );

      final result = EncounterTtsTextBuilder.build(card);

      expect(result, contains('Ps 23:1'));
      expect(result, contains('The Lord is my shepherd'));
      expect(result, contains('What did you learn?'));
      expect(result, isNot(contains('Not rendered by this type')));
    });

    test('unknown card type throws', () {
      const card = EncounterCard(order: 0, type: 'unknown', title: 'X');

      expect(() => EncounterTtsTextBuilder.build(card), throwsStateError);
    });

    test('empty card produces empty string', () {
      const card = EncounterCard(order: 0, type: 'cinematic_scene');

      expect(EncounterTtsTextBuilder.build(card), isEmpty);
    });
  });
}
