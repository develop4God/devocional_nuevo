@Tags(['unit', 'utils'])
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  const requiredKeys = ['ready_title', 'ready_message', 'close'];

  final files = Directory('i18n')
      .listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith('.json'))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));

  test('i18n directory has locale files to check', () {
    expect(files, isNotEmpty);
  });

  for (final file in files) {
    final locale = file.uri.pathSegments.last;
    test('$locale defines every update.* key with a non-empty value', () {
      final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      final update = json['update'] as Map<String, dynamic>?;

      expect(update, isNotNull, reason: '$locale is missing "update"');
      for (final key in requiredKeys) {
        expect(
          (update![key] as String?)?.trim(),
          isNotEmpty,
          reason: '$locale is missing update.$key',
        );
      }
    });
  }
}
