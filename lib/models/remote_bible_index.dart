/// Plain Dart DTOs for the remote Bible versions index.json shape, fetched
/// from https://github.com/develop4God/bible_versions.
///
/// Only fields actually consumed by the download feature are modeled.
class RemoteBibleIndex {
  final Map<String, RemoteBibleLanguage> languages;

  RemoteBibleIndex({required this.languages});

  factory RemoteBibleIndex.fromJson(Map<String, dynamic> json) {
    final languagesJson = json['languages'] as Map<String, dynamic>? ?? {};
    return RemoteBibleIndex(
      languages: languagesJson.map(
        (code, value) => MapEntry(
          code,
          RemoteBibleLanguage.fromJson(value as Map<String, dynamic>),
        ),
      ),
    );
  }
}

class RemoteBibleLanguage {
  final Map<String, RemoteBibleVersionEntry> versions;

  RemoteBibleLanguage({required this.versions});

  factory RemoteBibleLanguage.fromJson(Map<String, dynamic> json) {
    final versionsJson = json['versions'] as Map<String, dynamic>? ?? {};
    return RemoteBibleLanguage(
      versions: versionsJson.map(
        (code, value) => MapEntry(
          code,
          RemoteBibleVersionEntry.fromJson(value as Map<String, dynamic>),
        ),
      ),
    );
  }
}

class RemoteBibleVersionEntry {
  final String name;
  final String file;
  final String url;

  RemoteBibleVersionEntry({
    required this.name,
    required this.file,
    required this.url,
  });

  factory RemoteBibleVersionEntry.fromJson(Map<String, dynamic> json) {
    return RemoteBibleVersionEntry(
      name: json['name'] as String,
      file: json['file'] as String,
      url: json['url'] as String,
    );
  }
}
