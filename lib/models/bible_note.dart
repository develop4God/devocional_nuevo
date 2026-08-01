import 'package:equatable/equatable.dart';

/// A personal note associated with a range of Bible verses.
class BibleNote extends Equatable {
  final String bookName;
  final int chapter;
  final int startVerse;
  final int endVerse;
  final String text;
  final DateTime lastModifiedDate;

  const BibleNote({
    required this.bookName,
    required this.chapter,
    required this.startVerse,
    required this.endVerse,
    required this.text,
    required this.lastModifiedDate,
  });

  /// Unique key identifying the verse range this note covers.
  String get id => '$bookName|$chapter|$startVerse-$endVerse';

  /// Whether this note's range includes [verse] in [bookName]/[chapter].
  bool coversVerse(String bookName, int chapter, int verse) {
    return this.bookName == bookName &&
        this.chapter == chapter &&
        verse >= startVerse &&
        verse <= endVerse;
  }

  factory BibleNote.fromJson(Map<String, dynamic> json) {
    final rawDate = json['lastModifiedDate'] as String?;
    return BibleNote(
      bookName: json['bookName'] ?? '',
      chapter: json['chapter'] ?? 0,
      startVerse: json['startVerse'] ?? 0,
      endVerse: json['endVerse'] ?? 0,
      text: json['text'] ?? '',
      lastModifiedDate:
          rawDate != null ? DateTime.parse(rawDate) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bookName': bookName,
      'chapter': chapter,
      'startVerse': startVerse,
      'endVerse': endVerse,
      'text': text,
      'lastModifiedDate': lastModifiedDate.toIso8601String(),
    };
  }

  BibleNote copyWith({
    String? bookName,
    int? chapter,
    int? startVerse,
    int? endVerse,
    String? text,
    DateTime? lastModifiedDate,
  }) {
    return BibleNote(
      bookName: bookName ?? this.bookName,
      chapter: chapter ?? this.chapter,
      startVerse: startVerse ?? this.startVerse,
      endVerse: endVerse ?? this.endVerse,
      text: text ?? this.text,
      lastModifiedDate: lastModifiedDate ?? this.lastModifiedDate,
    );
  }

  @override
  List<Object?> get props =>
      [bookName, chapter, startVerse, endVerse, text, lastModifiedDate];
}
