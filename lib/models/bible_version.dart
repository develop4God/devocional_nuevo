import '../services/bible_db_service.dart';

class BibleVersion {
  final String name;
  final String language;
  final String languageCode;
  final String assetPath;
  final String dbFileName;
  final bool isDownloaded;
  BibleDbService? service;

  BibleVersion({
    required this.name,
    required this.language,
    required this.languageCode,
    required this.assetPath,
    required this.dbFileName,
    this.isDownloaded = true,
    this.service,
  });
}
