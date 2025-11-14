// lib/models/thanksgiving_model.dart

import 'package:flutter/material.dart';

/// Modelo de datos para un agradecimiento personal.
///
/// Contiene el ID, texto del agradecimiento y fecha de creación.
class Thanksgiving {
  final String id;
  final String text;
  final DateTime createdDate;

  Thanksgiving({
    required this.id,
    required this.text,
    required this.createdDate,
  });

  /// Constructor factory para crear una instancia de [Thanksgiving] desde un JSON.
  factory Thanksgiving.fromJson(Map<String, dynamic> json) {
    DateTime parsedCreatedDate;
    final String? createdDateString = json['createdDate'] as String?;
    if (createdDateString != null && createdDateString.isNotEmpty) {
      try {
        parsedCreatedDate = DateTime.parse(createdDateString);
      } catch (e) {
        debugPrint(
          'Error parsing created date: $createdDateString, using DateTime.now(). Error: $e',
        );
        parsedCreatedDate = DateTime.now();
      }
    } else {
      parsedCreatedDate = DateTime.now();
    }

    return Thanksgiving(
      id: json['id'] as String? ?? UniqueKey().hashCode.toString(),
      text: json['text'] as String? ?? '',
      createdDate: parsedCreatedDate,
    );
  }

  /// Metodo toJson para serializar a JSON.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'createdDate': createdDate.toIso8601String(),
    };
  }

  /// Crea una copia del agradecimiento con los campos especificados actualizados.
  Thanksgiving copyWith({
    String? id,
    String? text,
    DateTime? createdDate,
  }) {
    return Thanksgiving(
      id: id ?? this.id,
      text: text ?? this.text,
      createdDate: createdDate ?? this.createdDate,
    );
  }

  /// Calcula los días transcurridos desde la creación del agradecimiento.
  int get daysOld {
    final now = DateTime.now();
    final difference = now.difference(createdDate);
    return difference.inDays;
  }
}
