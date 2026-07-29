import 'package:equatable/equatable.dart';

/// A personal note associated with a devotional.
class DevotionalNote extends Equatable {
  final String devocionalId;
  final String text;
  final DateTime lastModifiedDate;

  const DevotionalNote({
    required this.devocionalId,
    required this.text,
    required this.lastModifiedDate,
  });

  factory DevotionalNote.fromJson(Map<String, dynamic> json) {
    return DevotionalNote(
      devocionalId: json['devocionalId'] ?? '',
      text: json['text'] ?? '',
      lastModifiedDate: DateTime.parse(json['lastModifiedDate']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'devocionalId': devocionalId,
      'text': text,
      'lastModifiedDate': lastModifiedDate.toIso8601String(),
    };
  }

  DevotionalNote copyWith({
    String? devocionalId,
    String? text,
    DateTime? lastModifiedDate,
  }) {
    return DevotionalNote(
      devocionalId: devocionalId ?? this.devocionalId,
      text: text ?? this.text,
      lastModifiedDate: lastModifiedDate ?? this.lastModifiedDate,
    );
  }

  @override
  List<Object?> get props => [devocionalId, text, lastModifiedDate];
}
