@Tags(['integration'])
library;

import 'dart:convert';

import 'package:devocional_nuevo/models/remote_bible_index.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

/// Hits the real bible_versions index.json on GitHub to confirm
/// RemoteBibleIndex still parses its production shape — including the
/// per-version "hash" fingerprint field added for update detection — since
/// the unit tests in bible_version_repository_test.dart use hand-built
/// minimal JSON fixtures that wouldn't catch schema drift in the real file.
void main() {
  test('parses the real production index.json and every version has a hash',
      () async {
    final response = await http.get(
      Uri.parse(
        'https://raw.githubusercontent.com/develop4God/bible_versions/main/index.json',
      ),
    );
    expect(response.statusCode, 200);

    final index = RemoteBibleIndex.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );

    expect(index.languages, isNotEmpty);
    for (final language in index.languages.values) {
      for (final entry in language.versions.values) {
        expect(
          entry.hash,
          isNotNull,
          reason: '${entry.file} is missing a hash in the live index',
        );
        expect(entry.hash!.length, 16);
      }
    }
  });
}
