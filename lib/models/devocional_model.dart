// lib/models/devocional_model.dart

import 'package:flutter/material.dart';

/// Modelo de datos para un devocional.
///
/// Contiene el ID, versículo, reflexión, puntos para meditar, una oración y la fecha.
class Devocional {
  final String id;
  final String versiculo;
  final String reflexion;
  final List<ParaMeditar> paraMeditar;
  final String oracion;
  final DateTime date;

  // Nuevos campos que se han detectado en el JSON.
  final String? version;
  final String? language;
  final List<String>? tags;
  final String? imageUrl;
  final String? emoji; // << NEW FIELD

  Devocional({
    required this.id,
    required this.versiculo,
    required this.reflexion,
    required this.paraMeditar,
    required this.oracion,
    required this.date,
    this.version,
    this.language,
    this.tags,
    this.imageUrl,
    this.emoji, // << NEW FIELD
  });

  /// Constructor factory para crear una instancia de [Devocional] desde un JSON.
  factory Devocional.fromJson(Map<String, dynamic> json) {
    DateTime parsedDate;
    final String? dateString = json['date'] as String?;
    if (dateString != null && dateString.isNotEmpty) {
      try {
        parsedDate = DateTime.parse(dateString);
      } catch (e) {
        debugPrint(
          'Error parsing date: $dateString, using DateTime.now(). Error: $e',
        );
        parsedDate = DateTime.now();
      }
    } else {
      parsedDate = DateTime.now();
    }

    String rawVersiculo = json['versiculo'] ?? '';

    return Devocional(
      id: json['id'] as String? ?? UniqueKey().hashCode.toString(),
      versiculo: rawVersiculo,
      reflexion: json['reflexion'] ?? '',
      paraMeditar: (json['para_meditar'] as List<dynamic>?)
              ?.map(
                (item) => ParaMeditar.fromJson(item as Map<String, dynamic>),
              )
              .toList() ??
          [],
      oracion: json['oracion'] ?? '',
      date: parsedDate,
      version: json['version'] as String?,
      language: json['language'] as String?,
      tags: (json['tags'] as List<dynamic>?)
          ?.map((tag) => tag as String)
          .toList(),
      imageUrl: json['imageUrl'] as String?,
      emoji: json['emoji'] as String?, // << MAPPING NEW FIELD
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'versiculo': versiculo,
      'reflexion': reflexion,
      'para_meditar': paraMeditar.map((e) => e.toJson()).toList(),
      'oracion': oracion,
      'date': date.toIso8601String().split('T').first,
      'version': version,
      'language': language,
      'tags': tags,
      'imageUrl': imageUrl,
      'emoji': emoji, // << SERIALIZING NEW FIELD
    };
  }
}

/// Modelo de datos para los puntos de "Para Meditar".
class ParaMeditar {
  final String cita;
  final String texto;

  ParaMeditar({required this.cita, required this.texto});

  factory ParaMeditar.fromJson(Map<String, dynamic> json) {
    return ParaMeditar(
      cita: json['cita'] as String? ?? '',
      texto: json['texto'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'cita': cita, 'texto': texto};
  }
}
