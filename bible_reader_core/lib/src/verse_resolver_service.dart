import 'bible_db_service.dart';
import 'bible_reference_parser.dart';
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
      if (match == null) return null;

      match.service ??= BibleDbService();
      await match.service!.initDb(match.assetPath, match.dbFileName);

      final parsed = BibleReferenceParser.parse(reference);
      if (parsed == null) return null;
      final verseNumber = parsed['verse'] as int?;
      if (verseNumber == null) return null;

      final book = await match.service!.findBookByName(
        parsed['bookName'] as String,
      );
      if (book == null) return null;

      final row = await match.service!.getVerse(
        bookNumber: book['book_number'] as int,
        chapter: parsed['chapter'] as int,
        verse: verseNumber,
      );
      return row?['text'] as String?;
    } catch (_) {
      return null;
    }
  }
}
