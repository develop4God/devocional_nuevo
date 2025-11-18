import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

/// Utilidad para validar traducciones entre el archivo de referencia en.json y cualquier archivo de idioma
/// Uso: dart run lib/utils/translation_validator.dart [lang]
void main(List<String> args) async {
  final referencePath = 'i18n/en.json';
  final lang = args.isNotEmpty ? args[0] : 'ja';
  final targetPath = 'i18n/$lang.json';

  final referenceFile = File(referencePath);
  final targetFile = File(targetPath);

  if (!referenceFile.existsSync() || !targetFile.existsSync()) {
    debugPrint(
        '❌ No se encontró el archivo de referencia o el de traducción ($lang).');
    return;
  }

  final referenceJson = json.decode(await referenceFile.readAsString());
  final targetJson = json.decode(await targetFile.readAsString());

  final missingKeys = <String>[];
  final incompleteKeys = <String>[];

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

  debugPrint('==== REPORTE DE VALIDACIÓN DE TRADUCCIÓN ($lang) ====');
  if (missingKeys.isEmpty && incompleteKeys.isEmpty) {
    debugPrint('✅ Todas las claves están presentes y completas.');
  } else {
    if (missingKeys.isNotEmpty) {
      debugPrint('❌ Claves faltantes en $lang.json:');
      for (final k in missingKeys) {
        debugPrint('  - $k');
      }
    }
    if (incompleteKeys.isNotEmpty) {
      debugPrint('⚠️ Claves incompletas o vacías en $lang.json:');
      for (final k in incompleteKeys) {
        debugPrint('  - $k');
      }
    }
  }
}
