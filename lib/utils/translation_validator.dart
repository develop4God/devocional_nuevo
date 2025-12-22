import 'dart:convert';
import 'dart:developer';
import 'dart:io';

/// Utilidad para validar y completar traducciones entre el archivo de referencia en.json y cualquier archivo de idioma
/// Uso: dart run lib/utils/translation_validator.dart [lang]
void main(List<String> args) async {
  final referencePath = 'i18n/en.json'; // Usar inglés como template
  final lang = args.isNotEmpty ? args[0] : 'ja';
  final targetPath = 'i18n/$lang.json';

  final referenceFile = File(referencePath);
  final targetFile = File(targetPath);

  if (!referenceFile.existsSync() || !targetFile.existsSync()) {
    log('❌ No se encontró el archivo de referencia o el de traducción ($lang).');
    return;
  }

  final referenceJson = json.decode(await referenceFile.readAsString());
  final targetJson = json.decode(await targetFile.readAsString());

  final missingKeys = <String>[];
  final incompleteKeys = <String>[];
  int pendingCount = 0;

  /// Inserta claves faltantes en el JSON destino, usando el valor 'PENDING' por defecto
  void insertMissingKeys(dynamic reference, dynamic target) {
    if (reference is Map) {
      reference.forEach((key, value) {
        if (target is Map) {
          if (!target.containsKey(key)) {
            if (value is Map) {
              target[key] = {};
              insertMissingKeys(value, target[key]);
            } else {
              target[key] = 'PENDING';
              pendingCount++;
            }
          } else {
            insertMissingKeys(value, target[key]);
          }
        }
      });
    }
  }

  void compareKeys(dynamic reference, dynamic target, String prefix) {
    if (reference is Map) {
      reference.forEach((key, value) {
        final fullKey = prefix.isEmpty ? key : '$prefix.$key';
        if (target is Map && target.containsKey(key)) {
          compareKeys(value, target[key], fullKey);
        } else {
          missingKeys.add(fullKey);
        }
      });
    } else if (reference is String) {
      if (target is! String || target.trim().isEmpty) {
        incompleteKeys.add(prefix);
      }
    }
  }

  compareKeys(referenceJson, targetJson, '');
  insertMissingKeys(referenceJson, targetJson);

  log('==== REPORTE DE VALIDACIÓN Y COMPLETADO DE TRADUCCIÓN ($lang) ====');
  if (missingKeys.isEmpty && incompleteKeys.isEmpty) {
    log('✅ Todas las claves están presentes y completas.');
  } else {
    if (missingKeys.isNotEmpty) {
      log('❌ Claves faltantes en $lang.json:');
      for (final k in missingKeys) {
        log('  - $k');
      }
    }
    if (incompleteKeys.isNotEmpty) {
      log('⚠️ Claves incompletas o vacías en $lang.json:');
      for (final k in incompleteKeys) {
        log('  - $k');
      }
    }
  }

  // Guarda el archivo destino actualizado con las claves faltantes
  await targetFile
      .writeAsString(JsonEncoder.withIndent('  ').convert(targetJson));
  if (pendingCount > 0) {
    log('✅ Archivo $lang.json actualizado: se agregaron $pendingCount claves nuevas marcadas como "PENDING".');
  } else {
    log('ℹ️ No se agregaron claves nuevas. El archivo $lang.json ya estaba completo.');
  }
}
