// lib/models/prayer_model.dart

import 'package:flutter/material.dart';

/// Modelo de datos para una oración personal.
///
/// Contiene el ID, texto de la oración, fecha de creación, estado (activa/respondida) 
/// y fecha de respuesta.
class Prayer {
  final String id;
  final String text;
  final DateTime createdDate;
  final PrayerStatus status;
  final DateTime? answeredDate;

  Prayer({
    required this.id,
    required this.text,
    required this.createdDate,
    required this.status,
    this.answeredDate,
  });

  /// Constructor factory para crear una instancia de [Prayer] desde un JSON.
  factory Prayer.fromJson(Map<String, dynamic> json) {
    DateTime parsedCreatedDate;
    final String? createdDateString = json['createdDate'] as String?;
    if (createdDateString != null && createdDateString.isNotEmpty) {
      try {
        parsedCreatedDate = DateTime.parse(createdDateString);
      } catch (e) {
        debugPrint(
            'Error parsing created date: $createdDateString, using DateTime.now(). Error: $e');
        parsedCreatedDate = DateTime.now();
      }
    } else {
      parsedCreatedDate = DateTime.now();
    }

    DateTime? parsedAnsweredDate;
    final String? answeredDateString = json['answeredDate'] as String?;
    if (answeredDateString != null && answeredDateString.isNotEmpty) {
      try {
        parsedAnsweredDate = DateTime.parse(answeredDateString);
      } catch (e) {
        debugPrint(
            'Error parsing answered date: $answeredDateString. Error: $e');
        parsedAnsweredDate = null;
      }
    }

    return Prayer(
      id: json['id'] as String? ?? UniqueKey().hashCode.toString(),
      text: json['text'] as String? ?? '',
      createdDate: parsedCreatedDate,
      status: PrayerStatus.fromString(json['status'] as String? ?? 'active'),
      answeredDate: parsedAnsweredDate,
    );
  }

  /// Método toJson para serializar a JSON.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'createdDate': createdDate.toIso8601String(),
      'status': status.toString(),
      'answeredDate': answeredDate?.toIso8601String(),
    };
  }

  /// Crea una copia de la oración con los campos especificados actualizados.
  Prayer copyWith({
    String? id,
    String? text,
    DateTime? createdDate,
    PrayerStatus? status,
    DateTime? answeredDate,
    bool clearAnsweredDate = false,
  }) {
    return Prayer(
      id: id ?? this.id,
      text: text ?? this.text,
      createdDate: createdDate ?? this.createdDate,
      status: status ?? this.status,
      answeredDate: clearAnsweredDate ? null : (answeredDate ?? this.answeredDate),
    );
  }

  /// Calcula los días transcurridos desde la creación de la oración.
  int get daysOld {
    final now = DateTime.now();
    final difference = now.difference(createdDate);
    return difference.inDays;
  }

  /// Indica si la oración está activa.
  bool get isActive => status == PrayerStatus.active;

  /// Indica si la oración ha sido respondida.
  bool get isAnswered => status == PrayerStatus.answered;
}

/// Enumeración para los estados posibles de una oración.
enum PrayerStatus {
  active,
  answered;

  @override
  String toString() {
    switch (this) {
      case PrayerStatus.active:
        return 'active';
      case PrayerStatus.answered:
        return 'answered';
    }
  }

  /// Convierte una cadena en un [PrayerStatus].
  static PrayerStatus fromString(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return PrayerStatus.active;
      case 'answered':
        return PrayerStatus.answered;
      default:
        return PrayerStatus.active; // Default to active
    }
  }

  /// Obtiene el texto localizado para mostrar en la UI.
  String get displayName {
    switch (this) {
      case PrayerStatus.active:
        return 'Activa';
      case PrayerStatus.answered:
        return 'Respondida';
    }
  }
}