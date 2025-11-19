import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'dart:io';

void main() {
  group('Drawer Translation Tests', () {
    test('Spanish drawer label should say "Oraciones y agradecimientos"',
        () async {
      final file = File('i18n/es.json');
      final content = await file.readAsString();
      final json = jsonDecode(content) as Map<String, dynamic>;

      final drawer = json['drawer'] as Map<String, dynamic>;
      expect(drawer['my_prayers'], equals('Oraciones y agradecimientos'),
          reason: 'Spanish drawer should include prayers and thanksgivings');
    });

    test('English drawer label should say "Prayers and thanksgivings"',
        () async {
      final file = File('i18n/en.json');
      final content = await file.readAsString();
      final json = jsonDecode(content) as Map<String, dynamic>;

      final drawer = json['drawer'] as Map<String, dynamic>;
      expect(drawer['my_prayers'], equals('Prayers and thanksgivings'),
          reason: 'English drawer should include prayers and thanksgivings');
    });

    test('French drawer label should say "Prières et remerciements"', () async {
      final file = File('i18n/fr.json');
      final content = await file.readAsString();
      final json = jsonDecode(content) as Map<String, dynamic>;

      final drawer = json['drawer'] as Map<String, dynamic>;
      expect(drawer['my_prayers'], equals('Prières et remerciements'),
          reason: 'French drawer should include prayers and thanksgivings');
    });

    test('Portuguese drawer label should say "Orações e agradecimentos"',
        () async {
      final file = File('i18n/pt.json');
      final content = await file.readAsString();
      final json = jsonDecode(content) as Map<String, dynamic>;

      final drawer = json['drawer'] as Map<String, dynamic>;
      expect(drawer['my_prayers'], equals('Orações e agradecimentos'),
          reason: 'Portuguese drawer should include prayers and thanksgivings');
    });

    test('Japanese drawer label should say "祈りと感謝"', () async {
      final file = File('i18n/ja.json');
      final content = await file.readAsString();
      final json = jsonDecode(content) as Map<String, dynamic>;

      final drawer = json['drawer'] as Map<String, dynamic>;
      expect(drawer['my_prayers'], equals('祈りと感謝'),
          reason: 'Japanese drawer should include prayers and thanksgivings');
    });

    test('All 5 languages have updated drawer labels', () async {
      final languages = ['es', 'en', 'fr', 'pt', 'ja'];
      final expectedLabels = {
        'es': 'Oraciones y agradecimientos',
        'en': 'Prayers and thanksgivings',
        'fr': 'Prières et remerciements',
        'pt': 'Orações e agradecimentos',
        'ja': '祈りと感謝',
      };

      for (final lang in languages) {
        final file = File('i18n/$lang.json');
        final content = await file.readAsString();
        final json = jsonDecode(content) as Map<String, dynamic>;
        final drawer = json['drawer'] as Map<String, dynamic>;

        expect(drawer['my_prayers'], equals(expectedLabels[lang]),
            reason: '$lang drawer label should be updated');
      }
    });
  });

  group('Website URL Tests', () {
    test('About page should have correct website URL without trailing slash',
        () async {
      final file = File('lib/pages/about_page.dart');
      final content = await file.readAsString();

      // Check that the URL exists and doesn't have trailing slash
      expect(content.contains('https://www.develop4God.com'), isTrue,
          reason: 'Should have website URL without trailing slash');
      expect(content.contains('https://www.develop4God.com/'), isFalse,
          reason: 'Should not have trailing slash in URL');
    });

    test('Website URL appears in both display text and launchURL call',
        () async {
      final file = File('lib/pages/about_page.dart');
      final content = await file.readAsString();

      // Count occurrences of the correct URL
      final urlPattern = RegExp(r'https://www\.develop4God\.com(?![/\w])');
      final matches = urlPattern.allMatches(content);

      expect(matches.length >= 2, isTrue,
          reason:
              'URL should appear at least twice (in display text and launchURL)');
    });
  });
}
