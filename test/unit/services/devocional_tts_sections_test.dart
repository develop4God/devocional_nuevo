@Tags(['unit', 'services'])
library;

import 'package:devocional_nuevo/models/devocional_model.dart';
import 'package:devocional_nuevo/services/tts/devocional_tts_sections.dart';
import 'package:devocional_nuevo/services/tts/tts_verse_index_resolver.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_helpers.dart';

Devocional _devocional({
  String reflexion = 'First sentence here. Second one follows. Third and last.',
  List<ParaMeditar> meditar = const [],
}) =>
    Devocional(
      id: 'd1',
      versiculo: 'Filipenses 2:3-4: "Nada hagáis por vanagloria."',
      reflexion: reflexion,
      paraMeditar: meditar,
      oracion: 'Padre, gracias. Ayúdame hoy.',
      version: 'RVR1960',
      language: 'es',
      date: DateTime(2026, 1, 1),
    );

void main() {
  setUp(() async => registerTestServices());

  group('splitSentences', () {
    test('splits on . ! ? followed by whitespace', () {
      final s = TtsVerseIndexResolver.splitSentences(
        'Uno. Dos! Tres? Cuatro.',
      );
      expect(s, ['Uno.', 'Dos!', 'Tres?', 'Cuatro.']);
    });

    test('does not split a verse reference like 2:3-4 (dot inside token)', () {
      final s = TtsVerseIndexResolver.splitSentences(
        'El pasaje de Fil 2.3-4 nos llama. Y sigue.',
      );
      // "2.3-4" has no space after the dot, so it is not a boundary.
      expect(s, ['El pasaje de Fil 2.3-4 nos llama.', 'Y sigue.']);
    });

    test('returns single element when nothing to split', () {
      expect(TtsVerseIndexResolver.splitSentences('One only'), ['One only']);
      expect(TtsVerseIndexResolver.splitSentences('   '), isEmpty);
    });
  });

  group('unit list', () {
    test('produces verse + reflection sentences + prayer sentences', () {
      final s = DevocionalTtsSections.build(_devocional(), 'es');
      final kinds = s.units.map((u) => u.kind).toList();

      // verse, label(reflection), 3 sentences, label(prayer), 2 sentences
      expect(kinds.first, DevotionalUnitKind.verse);
      expect(
        kinds.where((k) => k == DevotionalUnitKind.sentence).length,
        5, // 3 reflection + 2 prayer
      );
      expect(
        kinds.where((k) => k == DevotionalUnitKind.label).length,
        2, // reflection + prayer (no meditate)
      );
    });

    test('includes meditate item units only when present', () {
      final without = DevocionalTtsSections.build(_devocional(), 'es');
      expect(
        without.units.any((u) => u.kind == DevotionalUnitKind.meditateItem),
        isFalse,
      );

      final with_ = DevocionalTtsSections.build(
        _devocional(
          meditar: [
            ParaMeditar(cita: 'Rom 12:10', texto: 'Amaos.'),
            ParaMeditar(cita: '1 Cor 13:4', texto: 'El amor es sufrido.'),
          ],
        ),
        'es',
      );
      expect(
        with_.units
            .where((u) => u.kind == DevotionalUnitKind.meditateItem)
            .length,
        2,
      );
    });

    test('maps a fraction to a unit index across the whole devotional', () {
      final s = DevocionalTtsSections.build(_devocional(), 'es');
      expect(s.indexForFraction(0.0), 0); // verse
      expect(s.indexForFraction(0.99), s.length - 1); // last prayer sentence
    });

    test('a mid-devotional offset resolves past the verse to a later unit', () {
      final s = DevocionalTtsSections.build(_devocional(), 'es');
      final idx = s.indexForFraction(0.5);
      expect(idx, isNotNull);
      // Past the verse (index 0) — i.e. into the reflection/prayer region.
      expect(idx! > 0, isTrue);
    });

    test('reflection sentences are distinct consecutive units', () {
      final s = DevocionalTtsSections.build(_devocional(), 'es');
      final sentenceIdxs = [
        for (var i = 0; i < s.units.length; i++)
          if (s.units[i].kind == DevotionalUnitKind.sentence) i,
      ];
      // 5 sentence units total (3 reflection + 2 prayer), all distinct.
      expect(sentenceIdxs.length, 5);
      expect(sentenceIdxs.toSet().length, 5);
    });
  });
}
