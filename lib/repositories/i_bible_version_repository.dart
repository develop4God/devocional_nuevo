import 'package:bible_reader_core/bible_reader_core.dart';

/// Repository contract for browsing and downloading additional Bible
/// versions from the remote bible_versions index.
abstract class IBibleVersionRepository {
  /// Fetches the remote versions available for [languageCode], excluding
  /// versions already bundled as app assets and versions not on the
  /// remote-download allowlist.
  Future<List<BibleVersion>> fetchRemoteVersions(String languageCode);

  /// Downloads and installs [version]'s remote database.
  ///
  /// [onProgress] is called with a value in `[0.0, 1.0]` as bytes arrive
  /// when the response's content length is known, or with `null` once to
  /// signal an indeterminate (unknown-length) download.
  Future<void> downloadVersion(
    BibleVersion version, {
    void Function(double? progress)? onProgress,
  });
}
