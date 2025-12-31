import 'dart:convert';
import 'dart:io';

/// List of supported languages (now includes zh for Chinese)
const supportedLanguages = [
  'es',
  'en',
  'pt',
  'fr',
  'ja',
  'zh', // Added Chinese
];

/// Utility to validate and complete translations between the reference file in.json and any language file
/// Usage: dart run lib/utils/translation_validator.dart [lang]
void main(List<String> args) async {
  stdout.writeln('Starting language validation...');
  final languages = args.isNotEmpty ? args : supportedLanguages;
  final procesados = <String>[];
  final noEncontrados = <String>[];

  for (final lang in languages) {
    final referencePath = 'i18n/en.json'; // Usar inglés como template
    final targetPath = 'i18n/$lang.json';

    final referenceFile = File(referencePath);
    final targetFile = File(targetPath);

    if (!referenceFile.existsSync() || !targetFile.existsSync()) {
      stdout.writeln('❌ Reference or translation file not found ($lang).');
      noEncontrados.add(lang);
      continue;
    }
    procesados.add(lang);

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

    stdout.writeln(
      '==== TRANSLATION VALIDATION AND COMPLETION REPORT ($lang) ====',
    );
    if (missingKeys.isEmpty && incompleteKeys.isEmpty) {
      stdout.writeln('✅ All keys are present and complete.');
    } else {
      if (missingKeys.isNotEmpty) {
        stdout.writeln('❌ Missing keys in $lang.json:');
        for (final k in missingKeys) {
          stdout.writeln('  - $k');
        }
      }
      if (incompleteKeys.isNotEmpty) {
        stdout.writeln('⚠️ Incomplete or empty keys in $lang.json:');
        for (final k in incompleteKeys) {
          stdout.writeln('  - $k');
        }
      }
    }

    // Save the updated target file with missing keys
    await targetFile.writeAsString(
      JsonEncoder.withIndent('  ').convert(targetJson),
    );
    if (pendingCount > 0) {
      stdout.writeln(
        '✅ $lang.json updated: $pendingCount new keys added as "PENDING".',
      );
    } else {
      stdout.writeln('ℹ️ No new keys added. $lang.json was already complete.');
    }
    stdout.writeln('');
  }
  stdout.writeln('--- FINAL SUMMARY ---');
  stdout.writeln('Languages processed successfully: ${procesados.join(", ")}');
  if (noEncontrados.isNotEmpty) {
    stdout.writeln('Languages not found: ${noEncontrados.join(", ")}');
  } else {
    stdout.writeln('All language files were found and validated.');
  }
}
