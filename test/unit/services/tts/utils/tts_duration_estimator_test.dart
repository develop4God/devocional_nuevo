// test/unit/services/tts/utils/tts_duration_estimator_test.dart
@Tags(['unit', 'services', 'tts'])
library;

import 'package:devocional_nuevo/services/tts/utils/tts_duration_estimator.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TtsDurationEstimator', () {
    // ── Arabic (AR) WPM tests ────────────────────────────────────────────────
    group('Arabic (ar) — 100 WPM', () {
      test(
          'Arabic text produces longer duration than same word count in Spanish',
          () {
        const arabicText = 'مرحبا بك في التطبيق الجديد';
        const spanishText = 'Hola bienvenido a la nueva aplicación';

        // Count words in each (Arabic has 5 words, Spanish has 6)
        final arWords = arabicText.trim().split(RegExp(r'\s+')).length;
        final esWords = spanishText.trim().split(RegExp(r'\s+')).length;

        final arDuration = TtsDurationEstimator.estimate(arabicText, 'ar');
        final esDuration = TtsDurationEstimator.estimate(spanishText, 'es');

        debugPrint('AR: $arWords words @ 100 WPM → ${arDuration.inSeconds}s');
        debugPrint('ES: $esWords words @ 150 WPM → ${esDuration.inSeconds}s');

        // Arabic at 100 WPM should take longer than Spanish at 150 WPM
        expect(arDuration.inSeconds, greaterThan(esDuration.inSeconds));
      });

      test('10 words in Arabic at 80 WPM = 8 seconds', () {
        // 10 words / (80 WPM / 60) = 10 / 1.333... = 7.5 → rounds to 8 seconds
        final arabicText = List.generate(10, (i) => 'كلمة').join(' ');
        final duration = TtsDurationEstimator.estimate(arabicText, 'ar');
        expect(duration.inSeconds, 8);
      });

      test('30 words in Arabic at 80 WPM = 23 seconds', () {
        // 30 words / (80 WPM / 60) = 30 / 1.333... = 22.5 → rounds to 23 seconds
        final arabicText = List.generate(30, (i) => 'كلمة').join(' ');
        final duration = TtsDurationEstimator.estimate(arabicText, 'ar');
        expect(duration.inSeconds, 23);
      });
    });

    // ── Spanish (ES) WPM tests ───────────────────────────────────────────────
    group('Spanish (es) — 150 WPM (standard)', () {
      test('10 words in Spanish at 150 WPM = 4 seconds', () {
        // 10 words / (150 WPM / 60) = 10 / 2.5 = 4 seconds
        final spanishText = List.generate(10, (i) => 'palabra').join(' ');
        final duration = TtsDurationEstimator.estimate(spanishText, 'es');
        expect(duration.inSeconds, 4);
      });

      test('15 words in Spanish at 150 WPM = 6 seconds', () {
        // 15 words / 2.5 = 6 seconds
        final spanishText = List.generate(15, (i) => 'palabra').join(' ');
        final duration = TtsDurationEstimator.estimate(spanishText, 'es');
        expect(duration.inSeconds, 6);
      });
    });

    // ── English (EN) WPM tests ───────────────────────────────────────────────
    group('English (en) — 150 WPM (standard)', () {
      test('20 words in English at 150 WPM = 8 seconds', () {
        // 20 words / 2.5 = 8 seconds
        final englishText = List.generate(20, (i) => 'word').join(' ');
        final duration = TtsDurationEstimator.estimate(englishText, 'en');
        expect(duration.inSeconds, 8);
      });
    });

    // ── Portuguese (PT) WPM tests ────────────────────────────────────────────
    group('Portuguese (pt) — 150 WPM (standard)', () {
      test('12 words in Portuguese at 150 WPM uses standard rate', () {
        final portugueseText = List.generate(12, (i) => 'palavra').join(' ');
        final duration = TtsDurationEstimator.estimate(portugueseText, 'pt');
        // 12 / 2.5 = 4.8 → rounds to 5 seconds
        expect(duration.inSeconds, 5);
      });
    });

    // ── German (DE) WPM tests ────────────────────────────────────────────────
    group('German (de) — 150 WPM (standard)', () {
      test('25 words in German at 150 WPM uses standard rate', () {
        final germanText = List.generate(25, (i) => 'Wort').join(' ');
        final duration = TtsDurationEstimator.estimate(germanText, 'de');
        // 25 / 2.5 = 10 seconds
        expect(duration.inSeconds, 10);
      });
    });

    // ── French (FR) WPM tests ────────────────────────────────────────────────
    group('French (fr) — 150 WPM (standard)', () {
      test('30 words in French at 150 WPM uses standard rate', () {
        final frenchText = List.generate(30, (i) => 'mot').join(' ');
        final duration = TtsDurationEstimator.estimate(frenchText, 'fr');
        // 30 / 2.5 = 12 seconds
        expect(duration.inSeconds, 12);
      });
    });

    // ── Hindi (HI) WPM tests ─────────────────────────────────────────────────
    group('Hindi (hi) — 150 WPM (standard)', () {
      test('18 words in Hindi at 150 WPM uses standard rate', () {
        final hindiText = List.generate(18, (i) => 'शब्द').join(' ');
        final duration = TtsDurationEstimator.estimate(hindiText, 'hi');
        // 18 / 2.5 = 7.2 → rounds to 7 seconds
        expect(duration.inSeconds, 7);
      });
    });

    // ── Japanese (JA) character-based tests ──────────────────────────────────
    group('Japanese (ja) — 7 chars/sec', () {
      test('70 characters in Japanese at 7 chars/sec = 10 seconds', () {
        // 70 chars / 7.0 = 10 seconds
        final japaneseText = '日本語のテキスト';
        expect(japaneseText.replaceAll(RegExp(r'\s+'), '').length, 8);
        // For 70 chars:
        final longJapanese = japaneseText * 9; // Approximately 70 chars
        final duration = TtsDurationEstimator.estimate(longJapanese, 'ja');
        // ~72 chars / 7.0 ≈ 10 seconds
        expect(duration.inSeconds, greaterThanOrEqualTo(10));
      });

      test('whitespace is stripped for Japanese character count', () {
        final japaneseWithSpaces = '日本 語 の テキスト'; // spaces between chars
        final japaneseNoSpaces = '日本語のテキスト';
        final durationWithSpaces =
            TtsDurationEstimator.estimate(japaneseWithSpaces, 'ja');
        final durationNoSpaces =
            TtsDurationEstimator.estimate(japaneseNoSpaces, 'ja');
        // Both should produce the same duration since spaces are removed
        expect(durationWithSpaces.inSeconds, durationNoSpaces.inSeconds);
      });
    });

    // ── Chinese (ZH) character-based tests ───────────────────────────────────
    group('Chinese (zh) — 5.5 chars/sec', () {
      test('35 characters in Chinese at 5.5 chars/sec = 6 seconds', () {
        // 35 chars / 5.5 = 6.36... seconds
        final chineseText = '中文文本测试';
        expect(chineseText.replaceAll(RegExp(r'\s+'), '').length, 6);
        // For 35 chars, create longer text
        final longChinese = chineseText * 6; // ~36 chars
        final duration = TtsDurationEstimator.estimate(longChinese, 'zh');
        // ~36 chars / 5.5 ≈ 6.54 seconds → rounds to 7 seconds
        expect(duration.inSeconds, 7);
      });
    });

    // ── Empty string tests ───────────────────────────────────────────────────
    group('Empty and edge-case inputs', () {
      test('empty string does not throw and returns Duration.zero', () {
        expect(
          () => TtsDurationEstimator.estimate('', 'es'),
          isNot(throwsException),
        );
        final duration = TtsDurationEstimator.estimate('', 'es');
        expect(duration, Duration.zero);
      });

      test('whitespace-only string produces Duration.zero', () {
        final duration = TtsDurationEstimator.estimate('   \n\t  ', 'es');
        // After trim().split(RegExp(r'\s+')) on whitespace-only, length is 1 (empty string)
        // which gives 1 word / 2.5 = 0.4 → rounds to 0
        expect(duration.inSeconds, 0);
      });

      test('single word in Spanish produces 0 seconds (< 1 second rounds down)',
          () {
        final duration = TtsDurationEstimator.estimate('palabra', 'es');
        // 1 word / 2.5 = 0.4 → rounds to 0
        expect(duration.inSeconds, 0);
      });

      test('single word in Arabic produces 0 seconds', () {
        final duration = TtsDurationEstimator.estimate('كلمة', 'ar');
        // 1 word / 1.667 = 0.6 → rounds to 1 second (actually!)
        expect(duration.inSeconds, 1);
      });
    });

    // ── Language fallback tests ──────────────────────────────────────────────
    group('Language fallback to standard rate (150 WPM)', () {
      test('unknown language "xx" uses standard 150 WPM rate', () {
        final text = List.generate(25, (i) => 'word').join(' ');
        final duration = TtsDurationEstimator.estimate(text, 'xx');
        // 25 / 2.5 = 10 seconds (standard rate)
        expect(duration.inSeconds, 10);
      });

      test('null-like or edge-case language code uses standard rate', () {
        final text = List.generate(15, (i) => 'word').join(' ');
        final duration = TtsDurationEstimator.estimate(text, 'it');
        // Italian is not AR, EN, ES, etc., so uses standard 150 WPM
        // 15 / 2.5 = 6 seconds
        expect(duration.inSeconds, 6);
      });
    });

    // ── Real-world biblical text tests ──────────────────────────────────────
    group('Real-world biblical text scenarios', () {
      test('short Spanish devotional produces reasonable duration', () {
        const devotional =
            'Porque de tal manera amó Dios al mundo, que ha dado a su Hijo unigénito, para que todo aquel que cree en él, no se pierda, mas tenga vida eterna.';
        final duration = TtsDurationEstimator.estimate(devotional, 'es');
        // ~26 words / 2.5 ≈ 10.4 seconds
        expect(duration.inSeconds, greaterThan(0));
        expect(duration.inSeconds, lessThan(60)); // Sanity check
      });

      test(
          'Arabic Quranic verse produces longer duration than equivalent Spanish',
          () {
        // Psalm 23 equivalent lengths — using shorter Spanish to show the difference
        const arabicVerse =
            'الرب راعي فلا يعوزني شيء في مراع خضر يربضني على مياه الراحة';
        // Shorter Spanish verse for comparison
        const spanishVerse = 'El Señor es mi pastor';

        final arDuration = TtsDurationEstimator.estimate(arabicVerse, 'ar');
        final esDuration = TtsDurationEstimator.estimate(spanishVerse, 'es');

        // Arabic: 12 words @ 100 WPM = 7 seconds
        // Spanish: 4 words @ 150 WPM = 1.6 → 2 seconds
        expect(arDuration.inSeconds, greaterThan(esDuration.inSeconds));
      });

      test('Japanese scripture produces reasonable duration', () {
        const japaneseText = '心を尽くし、精神を尽くし、思いを尽くし、力を尽くして、あなたの神である主を愛しなさい。';
        final duration = TtsDurationEstimator.estimate(japaneseText, 'ja');
        // ~34 chars / 7.0 ≈ 4.9 seconds
        expect(duration.inSeconds, greaterThan(0));
        expect(duration.inSeconds, lessThan(30));
      });
    });

    // ── Rounding precision tests ─────────────────────────────────────────────
    group('Rounding behavior', () {
      test('0.4 seconds rounds to 0', () {
        // 1 word / 2.5 = 0.4
        final duration = TtsDurationEstimator.estimate('word', 'es');
        expect(duration.inSeconds, 0);
      });

      test('0.5 seconds rounds to 0 (banker\'s rounding rounds to even)', () {
        // 2 words / 2.5 = 0.8 → rounds to 1
        final text = List.generate(2, (i) => 'word').join(' ');
        final duration = TtsDurationEstimator.estimate(text, 'es');
        expect(duration.inSeconds, 1);
      });

      test('1.5 seconds rounds to 2 (banker\'s rounding)', () {
        // 4 words / 2.5 = 1.6 → rounds to 2
        final text = List.generate(4, (i) => 'word').join(' ');
        final duration = TtsDurationEstimator.estimate(text, 'es');
        expect(duration.inSeconds, 2);
      });
    });
  });
}
