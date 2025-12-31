// test/unit/chinese_language_integration_test.dart
// Comprehensive tests for Chinese language integration

import 'package:flutter_test/flutter_test.dart';
import 'package:devocional_nuevo/utils/constants.dart';
import 'package:devocional_nuevo/services/tts/bible_text_formatter.dart';

void main() {
  group('Chinese Language Integration Tests', () {
    test('Chinese is included in supported languages', () {
      expect(Constants.supportedLanguages.containsKey('zh'), isTrue);
      expect(Constants.supportedLanguages['zh'], '中文');
    });

    test('Chinese has Bible versions configured', () {
      expect(Constants.bibleVersionsByLanguage.containsKey('zh'), isTrue);
      expect(Constants.bibleVersionsByLanguage['zh'], isNotEmpty);
      expect(Constants.bibleVersionsByLanguage['zh'], contains('和合本1919'));
      expect(Constants.bibleVersionsByLanguage['zh'], contains('新译本'));
    });

    test('Chinese has default Bible version', () {
      expect(Constants.defaultVersionByLanguage.containsKey('zh'), isTrue);
      expect(Constants.defaultVersionByLanguage['zh'], '和合本1919');
    });

    test('Chinese Bible versions count is 2', () {
      expect(Constants.bibleVersionsByLanguage['zh']?.length, 2);
    });

    test('BibleTextFormatter handles Chinese book names', () {
      final result = BibleTextFormatter.formatBibleBook('约翰福音', 'zh');
      expect(result, '约翰福音');
    });

    test('BibleTextFormatter trims Chinese text', () {
      final result = BibleTextFormatter.formatBibleBook('  创世记  ', 'zh');
      expect(result, '创世记');
    });

    test('Chinese Bible versions expand correctly for TTS', () {
      final expansions = BibleTextFormatter.getBibleVersionExpansions('zh');
      expect(expansions['和合本1919'], '和合本一九一九');
      expect(expansions['新译本'], '新译本');
    });

    test('Chinese reference formatting includes chapter and verse words', () {
      final result = BibleTextFormatter.formatBibleReferences(
        '约翰福音 3:16',
        'zh',
      );
      expect(result, contains('章'));
      expect(result, contains('节'));
    });

    test('Chinese verse range uses correct connector', () {
      final result = BibleTextFormatter.formatBibleReferences(
        '诗篇 23:1-6',
        'zh',
      );
      expect(result, contains('至'));
    });

    test('Chinese TTS normalization works correctly', () {
      final result = BibleTextFormatter.normalizeTtsText(
        '约翰福音 3:16 和合本1919',
        'zh',
      );
      expect(result, contains('约翰福音'));
      expect(result, contains('和合本一九一九'));
    });

    test('Chinese supports traditional characters', () {
      final result = BibleTextFormatter.formatBibleBook('創世記', 'zh');
      expect(result, '創世記');
    });

    test('Chinese supports simplified characters', () {
      final result = BibleTextFormatter.formatBibleBook('创世记', 'zh');
      expect(result, '创世记');
    });

    test('Chinese handles mixed traditional and simplified', () {
      final simplified = BibleTextFormatter.formatBibleBook('约翰福音', 'zh');
      final traditional = BibleTextFormatter.formatBibleBook('約翰福音', 'zh');

      expect(simplified, '约翰福音');
      expect(traditional, '約翰福音');
    });

    test('All supported languages include Chinese', () {
      final languages = Constants.supportedLanguages.keys.toList();
      expect(languages, contains('zh'));
      expect(languages.length, greaterThanOrEqualTo(6));
    });

    test('Chinese language comes after Japanese in alphabetical order', () {
      final languages = Constants.supportedLanguages.keys.toList();
      final zhIndex = languages.indexOf('zh');
      final jaIndex = languages.indexOf('ja');
      expect(zhIndex, greaterThan(jaIndex));
    });

    test('Chinese Bible version keys match expected format', () {
      final versions = Constants.bibleVersionsByLanguage['zh'] ?? [];
      for (final version in versions) {
        expect(version, isNotEmpty);
        // Chinese versions should contain Chinese characters
        expect(
          version,
          matches(RegExp(r'[\u4e00-\u9fff]')),
        ); // Unicode range for Chinese
      }
    });

    test('Default Chinese version is in available versions list', () {
      final defaultVersion = Constants.defaultVersionByLanguage['zh'];
      final availableVersions = Constants.bibleVersionsByLanguage['zh'];
      expect(availableVersions, contains(defaultVersion));
    });

    test('Chinese handles empty strings correctly', () {
      final result = BibleTextFormatter.formatBibleBook('', 'zh');
      expect(result, isEmpty);
    });

    test('Chinese handles whitespace-only strings', () {
      final result = BibleTextFormatter.formatBibleBook('   ', 'zh');
      expect(result, isEmpty);
    });

    test('Chinese Bible reference formatting preserves book names', () {
      final testCases = ['约翰福音', '创世记', '诗篇', '启示录', '马太福音'];

      for (final bookName in testCases) {
        final result = BibleTextFormatter.formatBibleReferences(
          '$bookName 1:1',
          'zh',
        );
        expect(result, contains(bookName));
      }
    });

    test('Chinese supports common Bible book names', () {
      final commonBooks = [
        '创世记', // Genesis
        '出埃及记', // Exodus
        '诗篇', // Psalms
        '箴言', // Proverbs
        '马太福音', // Matthew
        '约翰福音', // John
        '使徒行传', // Acts
        '罗马书', // Romans
        '启示录', // Revelation
      ];

      for (final book in commonBooks) {
        final result = BibleTextFormatter.formatBibleBook(book, 'zh');
        expect(result, book);
      }
    });

    test('Complete Chinese reference normalization', () {
      final input = '约翰福音 3:16-17 和合本1919';
      final result = BibleTextFormatter.normalizeTtsText(input, 'zh');

      expect(result, contains('约翰福音'));
      expect(result, contains('章'));
      expect(result, contains('节'));
      expect(result, contains('至'));
      expect(result, contains('和合本一九一九'));
    });
  });

  group('Chinese Language - Edge Cases', () {
    test('Handles very long Chinese book names', () {
      final longName = '哥林多前书' * 10;
      final result = BibleTextFormatter.formatBibleBook(longName, 'zh');
      expect(result, isNotEmpty);
    });

    test('Handles Chinese with numbers in text', () {
      final result = BibleTextFormatter.formatBibleReferences(
        '约翰福音 3:16',
        'zh',
      );
      expect(result, contains('3'));
      expect(result, contains('16'));
    });

    test('Preserves Chinese punctuation', () {
      final text = '约翰福音 3:16，启示录 1:1';
      final result = BibleTextFormatter.normalizeTtsText(text, 'zh');
      expect(result, contains('，'));
    });

    test('Handles mixed Chinese and English', () {
      final text = '约翰福音 John 3:16';
      final result = BibleTextFormatter.formatBibleReferences(text, 'zh');
      expect(result, isNotEmpty);
    });
  });

  group('Chinese Language - Consistency Checks', () {
    test('All language-related maps include Chinese', () {
      expect(Constants.supportedLanguages.containsKey('zh'), isTrue);
      expect(Constants.bibleVersionsByLanguage.containsKey('zh'), isTrue);
      expect(Constants.defaultVersionByLanguage.containsKey('zh'), isTrue);
    });

    test('Chinese configuration is complete', () {
      expect(Constants.supportedLanguages['zh'], isNotNull);
      expect(Constants.bibleVersionsByLanguage['zh'], isNotNull);
      expect(Constants.defaultVersionByLanguage['zh'], isNotNull);

      expect(Constants.supportedLanguages['zh'], isNotEmpty);
      expect(Constants.bibleVersionsByLanguage['zh'], isNotEmpty);
      expect(Constants.defaultVersionByLanguage['zh'], isNotEmpty);
    });

    test('Chinese is the 6th supported language', () {
      final languages = Constants.supportedLanguages.keys.toList();
      expect(languages.length, greaterThanOrEqualTo(6));
      expect(languages, contains('zh'));
    });
  });
}
