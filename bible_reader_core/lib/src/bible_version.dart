import 'bible_db_service.dart';

class BibleVersion {
  final String name;
  final String language;
  final String languageCode;
  final String assetPath;
  final String dbFileName;
  final bool isDownloaded;
  final String? remoteUrl;

  /// Copyright/licensing disclaimer for remote versions whose text isn't
  /// covered by `CopyrightUtils`'s bundled-version lookup. Null for all
  /// bundled/asset versions.
  final String? disclaimer;

  /// True when this version is already downloaded but the remote index's
  /// content hash for it no longer matches the hash stored at download
  /// time — i.e. a newer file is available to re-download.
  final bool hasUpdate;

  /// Content fingerprint of this version's remote .gz file, as reported by
  /// the index at fetch/download time. Used to detect future updates by
  /// comparison; null for bundled/asset versions or an index that predates
  /// this field.
  final String? remoteHash;
  BibleDbService? service;

  BibleVersion({
    required this.name,
    required this.language,
    required this.languageCode,
    required this.assetPath,
    required this.dbFileName,
    this.isDownloaded = true,
    this.remoteUrl,
    this.disclaimer,
    this.hasUpdate = false,
    this.remoteHash,
    this.service,
  });

  /// True when this version is downloadable from a remote source (not a
  /// bundled app asset). Null [remoteUrl] means the version ships as an
  /// asset.
  bool get isRemote => remoteUrl != null;

  BibleVersion copyWith({
    String? name,
    String? language,
    String? languageCode,
    String? assetPath,
    String? dbFileName,
    bool? isDownloaded,
    String? remoteUrl,
    String? disclaimer,
    bool? hasUpdate,
    String? remoteHash,
    BibleDbService? service,
  }) {
    return BibleVersion(
      name: name ?? this.name,
      language: language ?? this.language,
      languageCode: languageCode ?? this.languageCode,
      assetPath: assetPath ?? this.assetPath,
      dbFileName: dbFileName ?? this.dbFileName,
      isDownloaded: isDownloaded ?? this.isDownloaded,
      remoteUrl: remoteUrl ?? this.remoteUrl,
      disclaimer: disclaimer ?? this.disclaimer,
      hasUpdate: hasUpdate ?? this.hasUpdate,
      remoteHash: remoteHash ?? this.remoteHash,
      service: service ?? this.service,
    );
  }
}
