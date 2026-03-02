import 'dart:convert';
import 'dart:io';

/// Supported languages (en.json is the single source of truth)
const supportedLanguages = ['es', 'en', 'pt', 'fr', 'ja', 'zh', 'hi'];

/// Bidirectional translation validator.
/// - Detects keys MISSING in the target (compared to en.json) → adds as "PENDING"
/// - Detects keys EXTRA in the target (not present in en.json) → removes them
/// - Reports per-section key counts vs reference
/// - Rebuilds each file in reference key order
///
/// Usage: dart run lib/utils/translation_validator.dart [lang]
void main(List<String> args) async {
  stdout.writeln('Starting bidirectional language validation...\n');

  final languages = args.isNotEmpty
      ? args
      : supportedLanguages.where((l) => l != 'en').toList();

  final processed = <String>[];
  final notFound = <String>[];

  final referenceFile = File('i18n/en.json');
  if (!referenceFile.existsSync()) {
    stdout.writeln('❌ Reference file i18n/en.json not found. Aborting.');
    exit(1);
  }
  final referenceJson =
      json.decode(await referenceFile.readAsString()) as Map<String, dynamic>;

  final refSectionCounts = <String, int>{};
  for (final sec in referenceJson.keys) {
    refSectionCounts[sec] = _countLeaves(referenceJson[sec]);
  }
  final refTotal = refSectionCounts.values.fold(0, (a, b) => a + b);

  stdout.writeln('=== REFERENCE: en.json — $refTotal total keys ===');
  for (final e in refSectionCounts.entries) {
    stdout.writeln('  ${e.key}: ${e.value} keys');
  }
  stdout.writeln('');

  for (final lang in languages) {
    final targetPath = 'i18n/$lang.json';
    final targetFile = File(targetPath);

    if (!targetFile.existsSync()) {
      stdout.writeln('❌ File not found: $targetPath');
      notFound.add(lang);
      continue;
    }
    processed.add(lang);

    final targetJson =
        json.decode(await targetFile.readAsString()) as Map<String, dynamic>;

    final missingKeys = <String>[];
    final extraKeys = <String>[];

    _findMissing(referenceJson, targetJson, '', missingKeys);
    _findExtra(referenceJson, targetJson, '', extraKeys);

    _insertMissing(referenceJson, targetJson);
    _removeExtra(referenceJson, targetJson);

    final reorderedTarget = _reorder(referenceJson, targetJson);

    final tgtSectionCounts = <String, int>{};
    for (final sec in reorderedTarget.keys) {
      tgtSectionCounts[sec] = _countLeaves(reorderedTarget[sec]);
    }
    final tgtTotal = tgtSectionCounts.values.fold(0, (a, b) => a + b);

    await targetFile.writeAsString(
      const JsonEncoder.withIndent('  ').convert(reorderedTarget),
    );

    stdout.writeln('==== VALIDATION REPORT ($lang) ====');
    stdout.writeln('  Reference (en): $refTotal keys');
    stdout.writeln('  Target ($lang):  $tgtTotal keys');

    if (missingKeys.isEmpty && extraKeys.isEmpty) {
      stdout.writeln('  ✅ Perfect match — no changes needed.');
    } else {
      if (missingKeys.isNotEmpty) {
        stdout.writeln(
            '  ❌ ${missingKeys.length} missing keys → added as PENDING:');
        for (final k in missingKeys) {
          stdout.writeln('    + $k');
        }
      }
      if (extraKeys.isNotEmpty) {
        stdout.writeln('  🗑️  ${extraKeys.length} extra keys → removed:');
        final shown = extraKeys.take(30).toList();
        for (final k in shown) {
          stdout.writeln('    - $k');
        }
        if (extraKeys.length > 30) {
          stdout.writeln('    ... and ${extraKeys.length - 30} more.');
        }
      }
    }

    stdout.writeln('  --- Per-section counts ($lang vs en) ---');
    var sectionOk = true;
    for (final sec in refSectionCounts.keys) {
      final refCnt = refSectionCounts[sec] ?? 0;
      final tgtCnt = tgtSectionCounts[sec] ?? 0;
      final ok = refCnt == tgtCnt;
      if (!ok) sectionOk = false;
      stdout.writeln('    ${ok ? '✅' : '❌'} $sec: $tgtCnt / $refCnt');
    }
    if (sectionOk) stdout.writeln('  ✅ All sections match reference counts.');
    stdout.writeln('');
  }

  stdout.writeln('--- FINAL SUMMARY ---');
  stdout.writeln('Languages processed: ${processed.join(', ')}');
  if (notFound.isNotEmpty) {
    stdout.writeln('Languages not found: ${notFound.join(', ')}');
  }
  stdout.writeln('en.json is the source of truth. All files are now in sync.');
}

int _countLeaves(dynamic obj) {
  if (obj is Map<String, dynamic>) {
    return obj.values.fold(0, (sum, v) => sum + _countLeaves(v));
  }
  return 1;
}

void _findMissing(
    dynamic ref, dynamic target, String prefix, List<String> out) {
  if (ref is Map<String, dynamic>) {
    for (final key in ref.keys) {
      final full = prefix.isEmpty ? key : '$prefix.$key';
      if (target is Map && !target.containsKey(key)) {
        if (ref[key] is Map) {
          _collectLeafPaths(ref[key] as Map<String, dynamic>, full, out);
        } else {
          out.add(full);
        }
      } else if (target is Map) {
        _findMissing(ref[key], target[key], full, out);
      }
    }
  }
}

void _collectLeafPaths(
    Map<String, dynamic> obj, String prefix, List<String> out) {
  for (final k in obj.keys) {
    final full = '$prefix.$k';
    if (obj[k] is Map<String, dynamic>) {
      _collectLeafPaths(obj[k] as Map<String, dynamic>, full, out);
    } else {
      out.add(full);
    }
  }
}

void _insertMissing(dynamic ref, dynamic target) {
  if (ref is Map<String, dynamic> && target is Map<String, dynamic>) {
    for (final key in ref.keys) {
      if (!target.containsKey(key)) {
        if (ref[key] is Map) {
          target[key] = <String, dynamic>{};
          _insertMissing(ref[key], target[key]);
        } else {
          target[key] = 'PENDING';
        }
      } else {
        _insertMissing(ref[key], target[key]);
      }
    }
  }
}

void _findExtra(dynamic ref, dynamic target, String prefix, List<String> out) {
  if (target is Map<String, dynamic>) {
    for (final key in target.keys) {
      final full = prefix.isEmpty ? key : '$prefix.$key';
      if (ref is Map && !ref.containsKey(key)) {
        if (target[key] is Map) {
          _collectLeafPaths(target[key] as Map<String, dynamic>, full, out);
        } else {
          out.add(full);
        }
      } else if (ref is Map && ref.containsKey(key)) {
        _findExtra(ref[key], target[key], full, out);
      }
    }
  }
}

void _removeExtra(dynamic ref, dynamic target) {
  if (target is Map<String, dynamic> && ref is Map<String, dynamic>) {
    final toRemove = target.keys.where((k) => !ref.containsKey(k)).toList();
    for (final k in toRemove) {
      target.remove(k);
    }
    for (final key in ref.keys) {
      if (target.containsKey(key)) _removeExtra(ref[key], target[key]);
    }
  }
}

Map<String, dynamic> _reorder(
    Map<String, dynamic> ref, Map<String, dynamic> target) {
  final result = <String, dynamic>{};
  for (final key in ref.keys) {
    if (target.containsKey(key)) {
      final rv = ref[key];
      final tv = target[key];
      if (rv is Map<String, dynamic> && tv is Map<String, dynamic>) {
        result[key] = _reorder(rv, tv);
      } else {
        result[key] = tv;
      }
    }
  }
  return result;
}
