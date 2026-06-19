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

      final normalizedRef = reference.replaceAll(RegExp(r'-\d+$'), '');
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

      final row = await match.service!.getVerse(
        bookNumber: book['book_number'] as int,
        chapter: parsed['chapter'] as int,
        verse: verseNumber,
      );
      final raw = row?['text'] as String?;
      debugPrint(raw != null
          ? '✅ [VerseResolver] resolved "$reference" → "${raw.substring(0, raw.length.clamp(0, 40))}…"'
          : '⚠️ [VerseResolver] verse row not found for "$normalizedRef"');
      return raw == null ? null : BibleTextNormalizer.clean(raw);
    } catch (e, stack) {
      debugPrint('💥 [VerseResolver] exception: $e');
      debugPrint('💥 [VerseResolver] stack: $stack');
      return null;
    }
  }
}
