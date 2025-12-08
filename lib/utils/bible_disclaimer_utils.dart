// Utilidad para extraer el disclaimer de la base de datos bíblica
import 'package:sqflite/sqflite.dart';

/// Obtiene el disclaimer (description y detailed_info) de la base de datos SQLite de la Biblia.
/// Retorna un mapa con las claves 'description' y 'detailed_info'.
/// Si no se encuentra, retorna valores vacíos.
Future<Map<String, String>> getBibleDisclaimer(Database db) async {
  try {
    final result = await db.rawQuery(
      'SELECT description, detailed_info FROM metadata LIMIT 1',
    );
    if (result.isNotEmpty) {
      final row = result.first;
      return {
        'description': row['description']?.toString() ?? '',
        'detailed_info': row['detailed_info']?.toString() ?? '',
      };
    }
  } catch (e) {
    // Si hay error, retorna valores vacíos
    return {'description': '', 'detailed_info': ''};
  }
  return {'description': '', 'detailed_info': ''};
}
