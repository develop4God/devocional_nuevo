// lib/models/testimony_model.dart

import 'package:flutter/material.dart';

/// Modelo de datos para un testimonio personal.
///
/// Contiene el ID, texto del testimonio y fecha de creación.
class Testimony {
  final String id;
  final String text;
  final DateTime createdDate;

  Testimony({
    required this.id,
    required this.text,
    required this.createdDate,
  });

  /// Constructor factory para crear una instancia de [Testimony] desde un JSON.
  factory Testimony.fromJson(Map<String, dynamic> json) {
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

    return Testimony(
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

  /// Crea una copia del testimonio con los campos especificados actualizados.
  Testimony copyWith({String? id, String? text, DateTime? createdDate}) {
    return Testimony(
      id: id ?? this.id,
      text: text ?? this.text,
      createdDate: createdDate ?? this.createdDate,
    );
  }

  /// Calcula los días transcurridos desde la creación del testimonio.
  int get daysOld {
    final now = DateTime.now();
    final difference = now.difference(createdDate);
    return difference.inDays;
  }
}
