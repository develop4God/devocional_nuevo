@Tags(['unit', 'utils'])
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  const removedKeys = {
    'devotionals': [
      'share_footer_title',
      'share_footer_complete_app',
      'share_footer_daily_devotionals',
      'share_footer_audio_reading',
      'share_footer_bible_studies',
      'share_footer_bible_versions',
      'share_footer_and_more',
    ],
    'discovery': [
      'share_footer_title',
      'share_footer_complete_study',
      'share_footer_greek_analysis',
      'share_footer_historical_context',
      'share_footer_biblical_connections',
      'share_footer_activation_questions',
    ],
  };
  const keptKeys = [
    'share_footer_download',
    'share_footer_benefits',
    'share_footer_developer',
  ];

  final files = Directory('i18n')
      .listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith('.json'))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));

  test('all 10 locale files are present', () {
    expect(files, hasLength(10));
  });

  for (final file in files) {
    final locale = file.uri.pathSegments.last;
    test('$locale drops the marketing footer keys and keeps download keys', () {
      final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;

      for (final section in removedKeys.keys) {
        final map = json[section] as Map<String, dynamic>;
        for (final key in removedKeys[section]!) {
          expect(map.containsKey(key), isFalse,
              reason: '$locale still has $section.$key');
        }
        for (final key in keptKeys) {
          expect((map[key] as String?)?.trim(), isNotEmpty,
              reason: '$locale is missing $section.$key');
        }
      }
    });
  }
}
