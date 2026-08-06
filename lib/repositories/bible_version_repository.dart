// lib/repositories/bible_version_repository.dart

import 'dart:convert';
import 'dart:io';

import 'package:bible_reader_core/bible_reader_core.dart';
import 'package:devocional_nuevo/debug/debug_flags.dart';
import 'package:devocional_nuevo/models/remote_bible_index.dart';
import 'package:devocional_nuevo/repositories/i_bible_version_repository.dart';
import 'package:devocional_nuevo/utils/constants/constants.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// The kind of failure a [BibleVersionDownloadException] represents.
enum BibleVersionDownloadErrorKind { network, corrupt, storage }

/// Thrown by [BibleVersionRepository.downloadVersion] on failure.
class BibleVersionDownloadException implements Exception {
  final BibleVersionDownloadErrorKind kind;
  final String message;

  BibleVersionDownloadException(this.kind, this.message);

  @override
  String toString() => 'BibleVersionDownloadException($kind): $message';
}

/// Repository for browsing and downloading additional Bible versions from
/// the remote bible_versions GitHub repo.
class BibleVersionRepository implements IBibleVersionRepository {
  final http.Client httpClient;
  static const String _indexCacheKeyPrefix = 'bible_versions_index_cache_';
  static const String _indexEtagKeyPrefix = 'bible_versions_index_etag_';

  /// Must match [BibleVersionRegistry]'s private
  /// `_remoteVersionNamesPrefKey` — the registry reads what this repository
  /// writes.
  static const String _remoteVersionNamesPrefKey = 'bible_remote_version_names';

  BibleVersionRepository({required this.httpClient});

  @override
  Future<List<BibleVersion>> fetchRemoteVersions(String languageCode) async {
    final branch = kDebugMode ? DebugFlags.debugBibleVersionsBranch : 'main';
    final index = await _fetchIndex(branch);
    debugPrint(
      '[BibleVersionRepository] fetchRemoteVersions($languageCode) '
      'branch=$branch languagesInIndex=${index.languages.keys.toList()}',
    );

    final language = index.languages[languageCode];
    if (language == null) {
      debugPrint(
        '[BibleVersionRepository] no "$languageCode" entry in index — '
        'returning []',
      );
      return [];
    }
    debugPrint(
      '[BibleVersionRepository] index versions for $languageCode: '
      '${language.versions.keys.toList()}',
    );

    final bundledVersions =
        await BibleVersionRegistry.getVersionsForLanguage(languageCode);
    final bundledCodes =
        bundledVersions.map((v) => v.dbFileName.split('_').first).toSet();
    debugPrint(
      '[BibleVersionRepository] bundled/downloaded codes for '
      '$languageCode: $bundledCodes',
    );

    final onMain = branch == 'main';
    final List<BibleVersion> result = [];

    for (final entry in language.versions.entries) {
      final code = entry.key;
      final versionEntry = entry.value;

      if (bundledCodes.contains(code)) {
        debugPrint(
          '[BibleVersionRepository] skipping $code — already bundled/downloaded',
        );
        continue;
      }

      // A debug-branch index still points its own `url` field at `main`, so
      // when testing a debug branch the download URL must be built from the
      // branch-aware URL builder instead of trusting the index's `url`.
      final url = onMain
          ? versionEntry.url
          : Constants.getBibleVersionDownloadUrl(
              languageCode,
              versionEntry.file,
            );

      result.add(
        BibleVersion(
          name: versionEntry.name,
          language: BibleVersionRegistry.getLanguageName(languageCode),
          languageCode: languageCode,
          assetPath: '',
          dbFileName: versionEntry.file.replaceAll('.gz', ''),
          isDownloaded: false,
          remoteUrl: url,
          disclaimer: versionEntry.disclaimer,
        ),
      );
    }

    debugPrint(
      '[BibleVersionRepository] fetchRemoteVersions($languageCode) '
      'returning ${result.map((v) => v.dbFileName).toList()}',
    );
    return result;
  }

  @override
  Future<void> downloadVersion(
    BibleVersion version, {
    void Function(double? progress)? onProgress,
  }) async {
    final url = version.remoteUrl;
    if (url == null) {
      throw BibleVersionDownloadException(
        BibleVersionDownloadErrorKind.network,
        'Version has no remoteUrl',
      );
    }

    late final http.StreamedResponse response;
    try {
      final request = http.Request('GET', Uri.parse(url));
      response = await httpClient.send(request);
    } catch (e) {
      throw BibleVersionDownloadException(
        BibleVersionDownloadErrorKind.network,
        'Failed to start download: $e',
      );
    }

    if (response.statusCode != 200) {
      throw BibleVersionDownloadException(
        BibleVersionDownloadErrorKind.network,
        'Server returned status ${response.statusCode}',
      );
    }

    final contentLength = response.contentLength;
    final bytes = <int>[];
    int received = 0;

    try {
      await for (final chunk in response.stream) {
        bytes.addAll(chunk);
        received += chunk.length;
        if (contentLength != null && contentLength > 0) {
          onProgress?.call(received / contentLength);
        } else {
          onProgress?.call(null);
        }
      }
    } catch (e) {
      throw BibleVersionDownloadException(
        BibleVersionDownloadErrorKind.network,
        'Download stream failed: $e',
      );
    }

    try {
      await BibleDbService.installFromGzipBytes(bytes, version.dbFileName);
    } on FileSystemException catch (e) {
      throw BibleVersionDownloadException(
        BibleVersionDownloadErrorKind.storage,
        'Failed to write database file: $e',
      );
    } catch (e) {
      throw BibleVersionDownloadException(
        BibleVersionDownloadErrorKind.corrupt,
        'Failed to decompress downloaded file: $e',
      );
    }

    await _saveDownloadedVersionName(
      version.dbFileName,
      version.name,
      version.disclaimer,
    );

    if (contentLength != null && contentLength > 0) {
      onProgress?.call(1.0);
    }
  }

  /// Persists the display name (and optional copyright disclaimer) for a
  /// downloaded remote version, keyed by its dbFileName, in the
  /// `bible_remote_version_names` SharedPreferences map.
  /// [BibleVersionRegistry.getDownloadedRemoteVersionsForLanguage] reads
  /// this map to label downloaded remote versions — this repository owns
  /// writing it, since it owns the download side-effect that produces the
  /// file in the first place (SRP).
  ///
  /// Existing entries were plain `dbFileName: displayName` strings; new
  /// entries are stored as `{"name": ..., "disclaimer": ...}` so old data
  /// keeps parsing without migration.
  Future<void> _saveDownloadedVersionName(
    String dbFileName,
    String displayName,
    String? disclaimer,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final existingJson = prefs.getString(_remoteVersionNamesPrefKey);
    final Map<String, dynamic> names = existingJson != null
        ? jsonDecode(existingJson) as Map<String, dynamic>
        : {};
    names[dbFileName] = {
      'name': displayName,
      if (disclaimer != null) 'disclaimer': disclaimer,
    };
    await prefs.setString(_remoteVersionNamesPrefKey, jsonEncode(names));
  }

  /// Fetches the index, always hitting the network with a conditional
  /// request rather than trusting a same-session flag: a stale local cache
  /// must never suppress a newer index (e.g. a newly added version) for the
  /// rest of the app session or across restarts. An ETag makes repeat calls
  /// cheap — the server returns 304 with no body when nothing changed, so
  /// this is not a full re-download on every drawer open.
  Future<RemoteBibleIndex> _fetchIndex(String branch) async {
    final prefs = await SharedPreferences.getInstance();
    final cacheKey = '$_indexCacheKeyPrefix$branch';
    final etagKey = '$_indexEtagKeyPrefix$branch';
    final cachedEtag = prefs.getString(etagKey);

    try {
      final url = Constants.getBibleVersionsIndexUrl();
      final request = http.Request('GET', Uri.parse(url));
      if (cachedEtag != null) {
        request.headers['If-None-Match'] = cachedEtag;
      }
      final streamedResponse = await httpClient.send(request);
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 304) {
        debugPrint(
            '[BibleVersionRepository] index unchanged (304), using cache');
        final cached = prefs.getString(cacheKey);
        if (cached != null) {
          return RemoteBibleIndex.fromJson(
            jsonDecode(cached) as Map<String, dynamic>,
          );
        }
        // No cached body despite a cached ETag — fall through to error path.
        throw Exception('304 received but no cached body for $cacheKey');
      }

      if (response.statusCode == 200) {
        await prefs.setString(cacheKey, response.body);
        final newEtag = response.headers['etag'];
        if (newEtag != null) {
          await prefs.setString(etagKey, newEtag);
        } else {
          await prefs.remove(etagKey);
        }
        debugPrint('[BibleVersionRepository] index fetched fresh (200)');
        return RemoteBibleIndex.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>,
        );
      }

      throw Exception('Server error: ${response.statusCode}');
    } catch (e) {
      debugPrint(
          '[BibleVersionRepository] index fetch failed: $e — falling back to cache');
      final cached = prefs.getString(cacheKey);
      if (cached != null) {
        return RemoteBibleIndex.fromJson(
          jsonDecode(cached) as Map<String, dynamic>,
        );
      }
      rethrow;
    }
  }
}
