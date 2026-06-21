class VerseRef {
  final String reference;
  final String text;
  final String? bibleVersion;

  const VerseRef({
    required this.reference,
    required this.text,
    this.bibleVersion,
  });

  factory VerseRef.fromJson(Map<String, dynamic> json) => VerseRef(
        reference: json['reference'] as String? ?? '',
        text: json['text'] as String? ?? '',
        bibleVersion: json['bible_version'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'reference': reference,
        'text': text,
        if (bibleVersion != null) 'bible_version': bibleVersion,
      };
}
