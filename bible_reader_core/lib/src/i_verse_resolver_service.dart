abstract class IVerseResolverService {
  Future<String?> resolveVerseText({
    required String reference,
    required String versionCode,
  });
}
