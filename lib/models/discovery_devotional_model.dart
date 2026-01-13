// lib/models/discovery_devotional_model.dart

import 'package:devocional_nuevo/models/devocional_model.dart';
import 'package:devocional_nuevo/models/discovery_card_model.dart';
import 'package:devocional_nuevo/models/discovery_section_model.dart';
import 'package:flutter/material.dart';

/// Modelo de datos para un devocional de tipo Discovery.
///
/// Extiende Devocional y añade campos específicos para estudios Discovery:
/// - cards: Lista de tarjetas del estudio (reemplaza secciones)
/// - subtitle: Subtítulo del estudio
/// - estimatedReadingMinutes: Tiempo estimado de lectura
/// - keyVerse: Versículo clave con referencia y texto
/// - metadata: Metadatos adicionales del estudio
///
/// BACKWARD COMPATIBILITY: También soporta el formato antiguo con secciones
class DiscoveryDevotional extends Devocional {
  final String? subtitle;
  final int? estimatedReadingMinutes;
  final KeyVerse? keyVerse;
  final List<DiscoveryCard> cards;
  final Map<String, dynamic>? metadata;

  // Campos legacy para compatibilidad hacia atrás
  final List<DiscoverySection>? secciones;
  final List<String>? preguntasDiscovery;
  final String? versiculoClave;

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
    this.subtitle,
    this.estimatedReadingMinutes,
    this.keyVerse,
    required this.cards,
    this.metadata,
    // Legacy fields
    this.secciones,
    this.preguntasDiscovery,
    this.versiculoClave,
  });

  /// Constructor factory para crear una instancia desde JSON.
  /// Soporta tanto el nuevo formato (cards) como el antiguo (secciones).
  factory DiscoveryDevotional.fromJson(Map<String, dynamic> json) {
    final parsedDate = _parseDate(json['date'] ?? json['fecha']);

    // Detectar si es el nuevo formato (cards) o el antiguo (secciones)
    final hasCards = json['cards'] != null;

    if (hasCards) {
      // Nuevo formato con cards
      return DiscoveryDevotional(
        id: json['id'] as String? ?? UniqueKey().hashCode.toString(),
        versiculo: json['key_verse']?['text'] as String? ?? '',
        reflexion: json['title'] as String? ?? '',
        paraMeditar: [],
        oracion: _extractPrayer(json['cards']),
        date: parsedDate,
        version: json['version'] as String?,
        language: json['language'] as String?,
        tags: (json['tags'] as List<dynamic>?)
            ?.map((tag) => tag as String)
            .toList(),
        subtitle: json['subtitle'] as String?,
        estimatedReadingMinutes: json['estimated_reading_minutes'] as int?,
        keyVerse: json['key_verse'] != null
            ? KeyVerse.fromJson(json['key_verse'] as Map<String, dynamic>)
            : null,
        cards: (json['cards'] as List<dynamic>?)
                ?.map(
                  (item) =>
                      DiscoveryCard.fromJson(item as Map<String, dynamic>),
                )
                .toList() ??
            [],
        metadata: json['metadata'] as Map<String, dynamic>?,
      );
    } else {
      // Formato antiguo con secciones (backward compatibility)
      return DiscoveryDevotional(
        id: json['id'] as String? ?? UniqueKey().hashCode.toString(),
        versiculo: json['versiculo_clave'] as String? ?? '',
        reflexion: json['titulo'] as String? ?? '',
        paraMeditar: [],
        oracion: json['oracion'] as String? ?? '',
        date: parsedDate,
        version: json['version'] as String?,
        language: json['language'] as String?,
        tags: (json['tags'] as List<dynamic>?)
            ?.map((tag) => tag as String)
            .toList(),
        cards: [],
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
  }

  /// Extrae la oración de las tarjetas (último card de tipo discovery_activation).
  static String _extractPrayer(List<dynamic>? cards) {
    if (cards == null || cards.isEmpty) return '';

    // Buscar la tarjeta discovery_activation
    for (final card in cards) {
      if (card is Map<String, dynamic> &&
          card['type'] == 'discovery_activation') {
        return card['prayer']?['content'] as String? ?? '';
      }
    }

    return '';
  }

  /// Parsea la fecha desde diferentes formatos.
  static DateTime _parseDate(dynamic dateField) {
    if (dateField == null) return DateTime.now();

    try {
      if (dateField is String && dateField.isNotEmpty) {
        return DateTime.parse(dateField);
      }
      return DateTime.now();
    } catch (e) {
      debugPrint(
          'Error parsing date: $dateField, using DateTime.now(). Error: $e');
      return DateTime.now();
    }
  }

  /// Metodo toJson para serializar a JSON.
  /// Prioriza el nuevo formato (cards) si está disponible.
  @override
  Map<String, dynamic> toJson() {
    if (cards.isNotEmpty) {
      // Nuevo formato
      return {
        'id': id,
        'type': 'discovery',
        'date': date.toIso8601String().split('T').first,
        'title': reflexion,
        'subtitle': subtitle,
        'language': language,
        'version': version,
        'estimated_reading_minutes': estimatedReadingMinutes,
        'key_verse': keyVerse?.toJson(),
        'cards': cards.map((c) => c.toJson()).toList(),
        'tags': tags,
        'metadata': metadata,
      };
    } else {
      // Formato antiguo para backward compatibility
      return {
        'id': id,
        'tipo': 'discovery',
        'fecha': date.toIso8601String().split('T').first,
        'titulo': reflexion,
        'versiculo_clave': versiculoClave,
        'secciones': secciones?.map((s) => s.toJson()).toList() ?? [],
        'preguntas_discovery': preguntasDiscovery,
        'oracion': oracion,
        'version': version,
        'language': language,
        'tags': tags,
      };
    }
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
    String? subtitle,
    int? estimatedReadingMinutes,
    KeyVerse? keyVerse,
    List<DiscoveryCard>? cards,
    Map<String, dynamic>? metadata,
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
      subtitle: subtitle ?? this.subtitle,
      estimatedReadingMinutes:
          estimatedReadingMinutes ?? this.estimatedReadingMinutes,
      keyVerse: keyVerse ?? this.keyVerse,
      cards: cards ?? this.cards,
      metadata: metadata ?? this.metadata,
      secciones: secciones ?? this.secciones,
      preguntasDiscovery: preguntasDiscovery ?? this.preguntasDiscovery,
      versiculoClave: versiculoClave ?? this.versiculoClave,
    );
  }

  /// Cuenta el total de secciones o tarjetas.
  int get totalSections =>
      cards.isNotEmpty ? cards.length : (secciones?.length ?? 0);

  /// Cuenta las preguntas de reflexión.
  int get totalQuestions {
    if (cards.isNotEmpty) {
      // Contar preguntas en tarjetas de tipo discovery_activation
      return cards
          .where((c) => c.type == 'discovery_activation')
          .expand((c) => c.discoveryQuestions ?? [])
          .length;
    }
    return preguntasDiscovery?.length ?? 0;
  }
}
