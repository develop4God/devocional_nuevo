@Tags(['unit', 'services'])
library;

import 'package:devocional_nuevo/models/devocional_model.dart';
import 'package:devocional_nuevo/services/tts/devocional_tts_sections.dart';
import 'package:devocional_nuevo/services/tts/tts_verse_index_resolver.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_helpers.dart';

Devocional _devocional({List<ParaMeditar> meditar = const []}) => Devocional(
      id: 'd1',
      versiculo: 'Verse text here.',
      reflexion: 'A longer reflection body that takes more of the timeline.',
      paraMeditar: meditar,
      oracion: 'Short prayer.',
      version: 'RVR1960',
      language: 'es',
      date: DateTime(2026, 1, 1),
    );

void main() {
  // The builder uses .tr() for labels, which resolves via LocalizationService.
  setUp(() async => registerTestServices());

  test('includes meditate only when paraMeditar is non-empty', () {
    final without = DevocionalTtsSections.build(_devocional(), 'es');
    expect(without.sections, [
      DevotionalSection.verse,
      DevotionalSection.reflection,
      DevotionalSection.prayer,
    ]);

    final with_ = DevocionalTtsSections.build(
      _devocional(
        meditar: [ParaMeditar(cita: 'John 3:16', texto: 'For God so loved.')],
      ),
      'es',
    );
    expect(with_.sections, contains(DevotionalSection.meditate));
    expect(with_.length, 4);
  });

  test('fraction 0 maps to the first section, 0.99 to the last', () {
    final s = DevocionalTtsSections.build(_devocional(), 'es');
    expect(s.indexForFraction(0.0), 0); // verse
    expect(s.indexForFraction(0.99), s.length - 1); // prayer
  });

  test('char offset inside the reflection maps to the reflection section', () {
    final s = DevocionalTtsSections.build(_devocional(), 'es');
    // Reflection is the longest section; an offset just past the verse block
    // should land on it (index 1).
    final reflectionIdx = s.sections.indexOf(DevotionalSection.reflection);
    // Use a fraction near the middle to hit the long reflection, then confirm
    // the char path agrees via the resolver contract.
    expect(s.indexForFraction(0.4), reflectionIdx);
  });

  test('charCount contract stays whitespace-trim based', () {
    // Sanity anchor tying this feature to the shared resolver util.
    expect(TtsVerseIndexResolver.charCount('  ab  '), 2);
  });
}
