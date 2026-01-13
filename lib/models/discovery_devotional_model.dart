// lib/models/discovery_devotional_model.dart

import 'package:devocional_nuevo/models/devocional_model.dart';
import 'package:devocional_nuevo/models/discovery_section_model.dart';
import 'package:flutter/material.dart';

/// Modelo de datos para un devocional de tipo Discovery.
///
/// Extiende Devocional y añade campos específicos para estudios Discovery:
/// - secciones: Lista de secciones (natural/scripture)
/// - preguntasDiscovery: Preguntas para reflexionar
/// - versiculoClave: Versículo principal del estudio
class DiscoveryDevotional extends Devocional {
  final List<DiscoverySection> secciones;
  final List<String> preguntasDiscovery;
  final String versiculoClave;

  DiscoveryDevotional({
    required super.id,
    required super.versiculo,
    required super.reflexion,
    required super.paraMeditar,
    required super.oracion,
    required super.date,
    super.version,
    super.language,
    super.tags,
    required this.secciones,
    required this.preguntasDiscovery,
    required this.versiculoClave,
  });

  /// Constructor factory para crear una instancia desde JSON.
  factory DiscoveryDevotional.fromJson(Map<String, dynamic> json) {
    DateTime parsedDate;
    final String? dateString = json['fecha'] as String?;
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

    return DiscoveryDevotional(
      id: json['id'] as String? ?? UniqueKey().hashCode.toString(),
      versiculo: json['versiculo_clave'] as String? ?? '',
      reflexion: json['titulo'] as String? ?? '',
      paraMeditar: [],
      // Discovery studies don't use this field
      oracion: json['oracion'] as String? ?? '',
      date: parsedDate,
      version: json['version'] as String?,
      language: json['language'] as String?,
      tags: (json['tags'] as List<dynamic>?)
          ?.map((tag) => tag as String)
          .toList(),
      secciones: (json['secciones'] as List<dynamic>?)
              ?.map(
                (item) =>
                    DiscoverySection.fromJson(item as Map<String, dynamic>),
              )
              .toList() ??
          [],
      preguntasDiscovery: (json['preguntas_discovery'] as List<dynamic>?)
              ?.map((q) => q as String)
              .toList() ??
          [],
      versiculoClave: json['versiculo_clave'] as String? ?? '',
    );
  }

  /// Metodo toJson para serializar a JSON.
  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tipo': 'discovery',
      'fecha': date.toIso8601String().split('T').first,
      'titulo': reflexion,
      'versiculo_clave': versiculoClave,
      'secciones': secciones.map((s) => s.toJson()).toList(),
      'preguntas_discovery': preguntasDiscovery,
      'oracion': oracion,
      'version': version,
      'language': language,
      'tags': tags,
    };
  }

  /// Crea una copia del devocional Discovery con los campos actualizados.
  DiscoveryDevotional copyWith({
    String? id,
    String? versiculo,
    String? reflexion,
    List<ParaMeditar>? paraMeditar,
    String? oracion,
    DateTime? date,
    String? version,
    String? language,
    List<String>? tags,
    List<DiscoverySection>? secciones,
    List<String>? preguntasDiscovery,
    String? versiculoClave,
  }) {
    return DiscoveryDevotional(
      id: id ?? this.id,
      versiculo: versiculo ?? this.versiculo,
      reflexion: reflexion ?? this.reflexion,
      paraMeditar: paraMeditar ?? this.paraMeditar,
      oracion: oracion ?? this.oracion,
      date: date ?? this.date,
      version: version ?? this.version,
      language: language ?? this.language,
      tags: tags ?? this.tags,
      secciones: secciones ?? this.secciones,
      preguntasDiscovery: preguntasDiscovery ?? this.preguntasDiscovery,
      versiculoClave: versiculoClave ?? this.versiculoClave,
    );
  }

  /// Cuenta el total de secciones.
  int get totalSections => secciones.length;

  /// Cuenta las preguntas de reflexión.
  int get totalQuestions => preguntasDiscovery.length;
}
