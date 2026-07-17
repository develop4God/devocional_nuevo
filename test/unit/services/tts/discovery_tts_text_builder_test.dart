import 'package:devocional_nuevo/models/discovery_card_model.dart';
import 'package:devocional_nuevo/services/tts/discovery_tts_text_builder.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DiscoveryTtsTextBuilder', () {
    test('natural_revelation includes title, subtitle, content, revelation key',
        () {
      final card = DiscoveryCard(
        order: 0,
        type: 'natural_revelation',
        title: 'The Sky',
        subtitle: 'Declares glory',
        content: 'Observe the heavens.',
        revelationKey: 'God is majestic.',
      );

      final result = DiscoveryTtsTextBuilder.build(card);

      expect(result, contains('The Sky'));
      expect(result, contains('Declares glory'));
      expect(result, contains('Observe the heavens.'));
      expect(result, contains('God is majestic.'));
    });

    test('greek_exegesis includes greek word, meaning, and revelation', () {
      final card = DiscoveryCard(
        order: 1,
        type: 'greek_exegesis',
        title: 'Agape',
        greekWords: [
          GreekWord(
            word: 'ἀγάπη',
            reference: '1 Cor 13:4',
            meaning: 'unconditional love',
            revelation: 'God loves without condition.',
            application: 'Love others.',
          ),
        ],
      );

      final result = DiscoveryTtsTextBuilder.build(card);

      expect(result, contains('ἀγάπη'));
      expect(result, contains('unconditional love'));
      expect(result, contains('God loves without condition.'));
    });

    test('prophetic_promise includes scripture anchor', () {
      final card = DiscoveryCard(
        order: 2,
        type: 'prophetic_promise',
        title: 'A Promise',
        scriptureAnchor: ScriptureAnchor(
          reference: 'Jer 29:11',
          text: 'For I know the plans I have for you.',
        ),
      );

      final result = DiscoveryTtsTextBuilder.build(card);

      expect(result, contains('Jer 29:11'));
      expect(result, contains('For I know the plans I have for you.'));
    });

    test('discovery_activation includes questions and prayer', () {
      final card = DiscoveryCard(
        order: 3,
        type: 'discovery_activation',
        title: 'Reflect',
        discoveryQuestions: [
          DiscoveryQuestion(
              category: 'faith', question: 'What does this mean to you?'),
        ],
        prayer: Prayer(title: 'Prayer', content: 'Lord, guide us.'),
      );

      final result = DiscoveryTtsTextBuilder.build(card);

      expect(result, contains('What does this mean to you?'));
      expect(result, contains('Lord, guide us.'));
    });

    test('empty card produces empty string', () {
      final card =
          DiscoveryCard(order: 0, type: 'natural_revelation', title: '');

      expect(DiscoveryTtsTextBuilder.build(card), isEmpty);
    });
  });
}
