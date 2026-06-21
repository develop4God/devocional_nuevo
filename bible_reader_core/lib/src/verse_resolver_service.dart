import 'package:flutter/foundation.dart';

import 'bible_db_service.dart';
import 'bible_reference_parser.dart';
import 'bible_text_normalizer.dart';
import 'bible_version.dart';
import 'bible_version_registry.dart';
import 'i_verse_resolver_service.dart';

class VerseResolverService implements IVerseResolverService {
  @override
  Future<String?> resolveVerseText({
    required String reference,
    required String versionCode,
  }) async {
    try {
      final allVersions = await BibleVersionRegistry.getAllVersions();
      BibleVersion? match;
      for (final v in allVersions) {
        if (v.dbFileName.startsWith(versionCode)) {
          match = v;
          break;
        }
      }
      if (match == null) {
        debugPrint(
            '📵 [VerseResolver] no DB match for versionCode: $versionCode');
        return null;
      }

      match.service ??= BibleDbService();
      await match.service!.initDb(match.assetPath, match.dbFileName);

      final rangeMatch = RegExp(r'^(.*\d+:\d+)-(\d+)$').firstMatch(reference);
      final normalizedRef = rangeMatch?.group(1) ?? reference;
      final endVerseOverride =
          rangeMatch != null ? int.tryParse(rangeMatch.group(2)!) : null;
      debugPrint(
          '🔍 [VerseResolver] reference: "$reference" → normalized: "$normalizedRef"');

      final parsed = BibleReferenceParser.parse(normalizedRef);
      if (parsed == null) {
        debugPrint('❌ [VerseResolver] parse failed for ref: "$normalizedRef"');
        return null;
      }
      final verseNumber = parsed['verse'] as int?;
      if (verseNumber == null) {
        debugPrint(
            '❌ [VerseResolver] no verse number in ref: "$normalizedRef"');
        return null;
      }

      final book = await match.service!.findBookByName(
        parsed['bookName'] as String,
      );
      if (book == null) {
        debugPrint(
            '📕 [VerseResolver] book not found: "${parsed['bookName']}"');
        return null;
      }

      final endVerse = endVerseOverride ?? verseNumber;
      final texts = <String>[];
      for (var v = verseNumber; v <= endVerse; v++) {
        final row = await match.service!.getVerse(
          bookNumber: book['book_number'] as int,
          chapter: parsed['chapter'] as int,
          verse: v,
        );
        final text = row?['text'] as String?;
        if (text == null) {
          debugPrint(
              '⚠️ [VerseResolver] verse row not found for "${parsed['bookName']} ${parsed['chapter']}:$v"');
          return null; // partial range = unsafe, fall back to JSON
        }
        texts.add(BibleTextNormalizer.clean(text));
      }
      debugPrint(
          '✅ [VerseResolver] resolved "$reference" → ${texts.length} verse(s)');
      return texts.join(' ');
    } catch (e, stack) {
      debugPrint('💥 [VerseResolver] exception: $e');
      debugPrint('💥 [VerseResolver] stack: $stack');
      return null;
    }
  }
}
