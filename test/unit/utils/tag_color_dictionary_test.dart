@Tags(['unit', 'utils'])
library;

import 'package:devocional_nuevo/utils/tag_color_dictionary.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TagColorDictionary.getTagTranslation', () {
    test('translates a known tag into Spanish', () {
      expect(TagColorDictionary.getTagTranslation('luz', 'es'), 'Luz');
    });

    test('translates a known tag into English', () {
      expect(TagColorDictionary.getTagTranslation('esperanza', 'en'), 'Hope');
    });

    test('translates a known tag into Portuguese', () {
      expect(TagColorDictionary.getTagTranslation('fe', 'pt'), 'Fé');
    });

    test('translates a known tag into French', () {
      expect(TagColorDictionary.getTagTranslation('amor', 'fr'), 'Amour');
    });

    test('is case-insensitive when matching the tag', () {
      expect(TagColorDictionary.getTagTranslation('LUZ', 'es'), 'Luz');
      expect(TagColorDictionary.getTagTranslation('Esperanza', 'en'), 'Hope');
    });

    test('falls back to capitalized tag when language is unsupported', () {
      expect(
        TagColorDictionary.getTagTranslation('paz', 'de'),
        'Paz',
      );
    });

    test('falls back to capitalized tag when tag is unknown', () {
      expect(
        TagColorDictionary.getTagTranslation('desconocido', 'es'),
        'Desconocido',
      );
    });

    test('capitalizes only the first letter for an unknown tag', () {
      expect(
        TagColorDictionary.getTagTranslation('gozo', 'es'),
        'Gozo',
      );
    });
  });

  group('TagColorDictionary.getGradientForTag', () {
    test('returns the amber gradient for luz', () {
      expect(
        TagColorDictionary.getGradientForTag('luz'),
        [Colors.amber, Colors.amber.shade300],
      );
    });

    test('returns the blue gradient for esperanza', () {
      expect(
        TagColorDictionary.getGradientForTag('esperanza'),
        [Colors.blue, Colors.lightBlue],
      );
    });

    test('returns the purple gradient for fe', () {
      expect(
        TagColorDictionary.getGradientForTag('fe'),
        [Colors.purple, Colors.deepPurple],
      );
    });

    test('returns the pink/red gradient for amor', () {
      expect(
        TagColorDictionary.getGradientForTag('amor'),
        [Colors.pink, Colors.red],
      );
    });

    test('returns the green/teal gradient for paz', () {
      expect(
        TagColorDictionary.getGradientForTag('paz'),
        [Colors.green, Colors.teal],
      );
    });

    test('returns the indigo/blue gradient for gracia', () {
      expect(
        TagColorDictionary.getGradientForTag('gracia'),
        [Colors.indigo, Colors.blue],
      );
    });

    test('is case-insensitive when matching the tag', () {
      expect(
        TagColorDictionary.getGradientForTag('LUZ'),
        [Colors.amber, Colors.amber.shade300],
      );
    });

    test('returns the default blue gradient for an unknown tag', () {
      expect(
        TagColorDictionary.getGradientForTag('unknown_tag'),
        [Colors.blue, Colors.lightBlue],
      );
    });
  });
}
