@Tags(['unit', 'utils'])
library;

import 'package:bible_reader_core/src/bible_text_normalizer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BibleTextNormalizer Tests', () {
    test('should return empty string for null input', () {
      expect(BibleTextNormalizer.clean(null), '');
    });

    test('should return empty string for empty input', () {
      expect(BibleTextNormalizer.clean(''), '');
    });

    test('should remove simple bracketed references [1]', () {
      const text = 'Verse text [1] continues here';
      expect(BibleTextNormalizer.clean(text), 'Verse text  continues here');
    });

    test('should remove letter bracketed references [a]', () {
      const text = 'Verse text [a] continues here';
      expect(BibleTextNormalizer.clean(text), 'Verse text  continues here');
    });

    test(
      'should remove bracketed references with special characters [36†]',
      () {
        const text = 'Verse text [36†] continues here';
        expect(BibleTextNormalizer.clean(text), 'Verse text  continues here');
      },
    );

    test('should remove bracketed references with mixed content [a1]', () {
      const text = 'Verse text [a1] continues here';
      expect(BibleTextNormalizer.clean(text), 'Verse text  continues here');
    });

    test('should remove bracketed references with words [note]', () {
      const text = 'Verse text [note] continues here';
      expect(BibleTextNormalizer.clean(text), 'Verse text  continues here');
    });

    test('should remove multiple bracketed references', () {
      const text = 'Verse [1] text [a] continues [36†] here';
      expect(BibleTextNormalizer.clean(text), 'Verse  text  continues  here');
    });

    test('should remove HTML tags <pb/>', () {
      const text = 'Verse text<pb/>continues here';
      expect(BibleTextNormalizer.clean(text), 'Verse textcontinues here');
    });

    test('should remove HTML tags <f>', () {
      const text = 'Verse text<f>note</f>continues here';
      expect(BibleTextNormalizer.clean(text), 'Verse textnotecontinues here');
    });

    test('should remove both HTML tags and bracketed references', () {
      const text = 'Verse<pb/> text [1] continues [36†] here<f>note</f>';
      expect(
        BibleTextNormalizer.clean(text),
        'Verse text  continues  herenote',
      );
    });

    test('should trim whitespace from result', () {
      const text = '  Verse text  ';
      expect(BibleTextNormalizer.clean(text), 'Verse text');
    });

    test('should handle text with no tags or references', () {
      const text = 'Clean verse text';
      expect(BibleTextNormalizer.clean(text), 'Clean verse text');
    });

    test('should remove circled lowercase letter footnote markers ⓐ ⓑ', () {
      const text = 'Sinabi ⓐ ng Diyos: Magkaroon ng liwanag ⓑ.';
      final result = BibleTextNormalizer.clean(text);
      expect(result, isNot(contains('ⓐ')));
      expect(result, isNot(contains('ⓑ')));
      expect(result, contains('Sinabi'));
      expect(result, contains('ng Diyos'));
    });

    test('should remove circled uppercase letter markers Ⓐ Ⓑ', () {
      const text = 'God Ⓐ said let there be light Ⓑ.';
      final result = BibleTextNormalizer.clean(text);
      expect(result, isNot(contains('Ⓐ')));
      expect(result, isNot(contains('Ⓑ')));
    });

    test('should remove circled number markers ①②③', () {
      const text = 'Verse ① contains a note ② about this ③.';
      final result = BibleTextNormalizer.clean(text);
      expect(result, isNot(contains('①')));
      expect(result, isNot(contains('②')));
      expect(result, isNot(contains('③')));
    });

    test('removes footnote markers from MBB05-style Filipino verse text', () {
      // Realistic MBB05 verse with inline footnote markers
      const text = 'Sinabi ⓑ ng Diyos, "Magkaroon ng liwanag ⓐ";';
      final result = BibleTextNormalizer.clean(text);
      expect(result, isNot(contains('ⓑ')));
      expect(result, isNot(contains('ⓐ')));
      expect(result, contains('Sinabi'));
    });

    test('removes Strong\'s number tags <S>1234</S> as a single unit', () {
      const text = 'creó<S>1254</S> Dios<S>430</S> los cielos<S>8064</S>';
      final result = BibleTextNormalizer.clean(text);
      expect(result, 'creó Dios los cielos');
    });

    test(
      'cleans real RV09+ verse text with Strong\'s numbers (Genesis 1:1)',
      () {
        const text =
            'En el principio<S>7225</S> creó<S>1254</S> Dios<S>430</S> '
            'los cielos<S>8064</S> y la tierra.<S>776</S> ';
        final result = BibleTextNormalizer.clean(text);
        expect(result, 'En el principio creó Dios los cielos y la tierra.');
      },
    );

    test('removes morphology code tags <m>NCFSA</m> as a single unit', () {
      const text = 'principio<m>NCFSA</m> creó<m>VaP3MS</m> Dios<m>NCMPA</m>';
      final result = BibleTextNormalizer.clean(text);
      expect(result, 'principio creó Dios');
    });

    test(
      'cleans real LBLA verse text with Strong\'s and morphology tags '
      '(Genesis 1:1)',
      () {
        const text = '<pb/>En<m>P</m> el principio<S>7225</S><m>NCFSA</m> '
            'creó<S>1254</S><m>VaP3MS</m> Dios<S>430</S><m>NCMPA</m>'
            '<S>853</S><m>PO</m> los<m>A</m> cielos<S>8064</S><m>NCMPA</m> '
            'y<S>853</S><m>C</m><m>PO</m> la<m>A</m> '
            'tierra<S>776</S><m>NC-SA</m>.';
        final result = BibleTextNormalizer.clean(text);
        expect(result, 'En el principio creó Dios los cielos y la tierra.');
      },
    );

    test(
      'preserves real all-caps Spanish words like SEÑOR (LBLA divine name '
      'convention) instead of truncating them',
      () {
        const text = 'el SEÑOR<S>3068</S><m>NPMSA</m> dijo';
        final result = BibleTextNormalizer.clean(text);
        expect(result, 'el SEÑOR dijo');
      },
    );

    test(
      'cleans real LBLA verse text with SEÑOR and full tag markup '
      '(Genesis 31:3)',
      () {
        const text = 'Entonces<m>C</m> el SEÑOR<S>3068</S><m>NPMSA</m> '
            'dijo<S>559</S><m>VaW3MS</m> a<S>413</S><m>P</m> '
            'Jacob<S>3290</S><m>NPMSA</m>: Vuelve<S>7725</S><m>VaM2MS</m> '
            'a<S>413</S><m>P</m> la tierra<S>776</S><m>NC-SC</m> '
            'de tus<S>859</S><m>RS2MS</m> padres<S>1</S><m>NCFPC</m> '
            'y<m>C</m> a<m>P</m> tus<S>859</S><m>RS2MS</m> '
            'familiares<S>4138</S><m>NCFSC</m>, y<m>C</m> '
            'yo estaré<S>1961</S><m>Vaw1-S</m> '
            'contigo<S>5973</S><S>859</S><m>P</m><m>RS2MS</m>.';
        final result = BibleTextNormalizer.clean(text);
        expect(
          result,
          'Entonces el SEÑOR dijo a Jacob: Vuelve a la tierra de tus '
          'padres y a tus familiares, y yo estaré contigo.',
        );
      },
    );

    test('removes stray bullet markers glued into LBLA verse text', () {
      const text = 'Y fue la • tarde y fue la • manana: un día.';
      expect(
        BibleTextNormalizer.clean(text),
        'Y fue la tarde y fue la manana: un día.',
      );
    });

    test('decodes literal &quot; entity to a straight double quote', () {
      const text = '&quot;Yo soy el Dios de Betel&quot;.';
      expect(BibleTextNormalizer.clean(text), '"Yo soy el Dios de Betel".');
    });

    test(
        'cleans real LBLA verse text with tags and stray bullets (Genesis 1:5)',
        () {
      const text =
          'Y<m>C</m> llamó<S>7121</S><m>VaW3MS</m> Dios<S>430</S><m>NCMPA</m> '
          'a<S>7121</S><m>P</m> la<m>A</m> luz<S>216</S><m>NC-SA</m> '
          'día<S>3117</S><m>NC-SA</m>, y<m>C</m> a<m>P</m> las<m>A</m> '
          'tinieblas<S>2822</S><m>NC-SA</m> llamó<S>7121</S><m>VaP3MS</m> '
          'noche<S>3915</S><m>NC-SA</m>. Y<m>C</m> fue<S>1961</S><m>VaW3MS</m> '
          'la • tarde<S>6153</S><m>NC-SA</m> y<m>C</m> '
          'fue<S>1961</S><m>VaW3MS</m> la • manana<S>1242</S><m>NC-SA</m>: '
          'un<S>259</S><m>UC-SA</m> día<S>3117</S><m>NC-SA</m>.';
      final result = BibleTextNormalizer.clean(text);
      expect(result, isNot(contains('•')));
      expect(result, contains('la tarde'));
      expect(result, contains('la manana'));
    });

    test(
        'cleans real LBLA verse text with tags, bullets, and &quot; entity '
        '(Genesis 31:13)', () {
      const text =
          '&quot;Yo<S>595</S><m>RP1-S</m> soy • el<m>A</m> Dios<S>410</S>'
          '<m>NC-SA</m> <i>de</i> Betel<S>1008</S><m>NP-SA</m>, '
          'donde<S>834</S><m>CR</m> tú ungiste<S>4886</S><m>VaP2MS</m>'
          '<S>8033</S><m>D</m> un pilar<S>4676</S><m>NCFSA</m>, '
          'donde<S>834</S><m>CR</m> me<S>589</S><m>P</m><m>RS1-S</m> '
          'hiciste<S>5087</S><m>VaP2MS</m><S>8033</S><m>D</m> un '
          'voto<S>5088</S><m>NC-SA</m>. Levántate<S>6965</S><m>VaM2MS</m> '
          'ahora<S>6258</S><m>D</m>, sal<S>3318</S><m>VaM2MS</m> '
          'de<S>4480</S><m>P</m> esta<S>2063</S><m>A</m><m>RD-FS</m> '
          'tierra<S>776</S><m>A</m><m>NC-SA</m>, y<m>C</m> '
          'vuelve<S>7725</S><m>VaM2MS</m> a<S>413</S><m>P</m> '
          'la tierra<S>776</S><m>NC-SC</m> donde • '
          'naciste<S>4138</S><S>859</S><m>NCFSC</m><m>RS2MS</m>. "';
      final result = BibleTextNormalizer.clean(text);
      expect(
        result,
        '"Yo soy el Dios de Betel, donde tú ungiste un pilar, donde me '
        'hiciste un voto. Levántate ahora, sal de esta tierra, y vuelve '
        'a la tierra donde naciste. "',
      );
    });
  });

  group('BibleTextNormalizer.stripStrongTags Tests', () {
    test('removes Strong\'s tags without affecting other markup', () {
      const text = 'creó<S>1254</S> Dios<S>430</S> [1] <pb/>';
      expect(BibleTextNormalizer.stripStrongTags(text), 'creó Dios [1] <pb/>');
    });

    test('returns text unchanged when no Strong\'s tags present', () {
      const text = 'Clean verse text';
      expect(BibleTextNormalizer.stripStrongTags(text), text);
    });
  });

  group('BibleTextNormalizer.stripMorphTags Tests', () {
    test('removes morphology tags without affecting other markup', () {
      const text = 'principio<m>NCFSA</m> creó<m>VaP3MS</m> [1] <pb/>';
      expect(
        BibleTextNormalizer.stripMorphTags(text),
        'principio creó [1] <pb/>',
      );
    });

    test('returns text unchanged when no morphology tags present', () {
      const text = 'Clean verse text';
      expect(BibleTextNormalizer.stripMorphTags(text), text);
    });

    test('does not truncate all-caps words adjacent to a morph tag', () {
      const text = 'el SEÑOR<m>NPMSA</m> dijo';
      expect(BibleTextNormalizer.stripMorphTags(text), 'el SEÑOR dijo');
    });
  });
}
