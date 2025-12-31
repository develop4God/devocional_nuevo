// lib/models/devocional_model.dart

import 'package:flutter/material.dart';

/// Modelo de datos para un devocional.
///
/// Contiene el ID, versículo, reflexión, puntos para meditar, una oración y la fecha.
class Devocional {
  final String id;
  final String versiculo;
  final String reflexion;
  final List<ParaMeditar> paraMeditar; // << CAMBIO: Ahora es List<ParaMeditar>
  final String oracion;
  final DateTime date;

  // Nuevos campos que se han detectado en el JSON.
  // Los hacemos nulos (String?, List<String>?) para que no sean obligatorios
  // en caso de que no siempre estén presentes en todos los devocionales.
  final String? version;
  final String? language;
  final List<String>? tags;

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
  });

  /// Constructor factory para crear una instancia de [Devocional] desde un JSON.
  ///
  /// Proporciona valores por defecto si algún campo es nulo en el JSON.
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
        parsedDate = DateTime.now(); // Fallback to current date
      }
    } else {
      parsedDate = DateTime.now(); // Fallback if date is null or empty
    }

    String rawVersiculo = json['versiculo'] ?? '';

    return Devocional(
      id: json['id'] as String? ?? UniqueKey().hashCode.toString(),
      versiculo: rawVersiculo,
      // Se usa el valor directo del JSON
      reflexion: json['reflexion'] ?? '',
      paraMeditar: (json['para_meditar']
                  as List<dynamic>?) // << CAMBIO: Mapeo a ParaMeditar.fromJson
              ?.map(
                (item) => ParaMeditar.fromJson(item as Map<String, dynamic>),
              )
              .toList() ??
          [],
      oracion: json['oracion'] ?? '',
      date: parsedDate,
      // Mapeo de los nuevos campos
      version: json['version'] as String?,
      language: json['language'] as String?,
      tags: (json['tags'] as List<dynamic>?)
          ?.map((tag) => tag as String)
          .toList(),
    );
  }

  // Metodo toJson para serializar a JSON (útil para guardar favoritos)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'versiculo': versiculo,
      'reflexion': reflexion,
      'para_meditar': paraMeditar
          .map((e) => e.toJson())
          .toList(), // << CAMBIO: Serializa cada ParaMeditar
      'oracion': oracion,
      'date': date
          .toIso8601String()
          .split('T')
          .first, // Guarda solo la fecha (yyyy-MM-dd)
      // Incluir los nuevos campos en toJson
      'version': version,
      'language': language,
      'tags': tags,
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
