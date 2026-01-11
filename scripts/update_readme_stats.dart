#!/usr/bin/env dart
/// Auto-generates README.md statistics from actual codebase
/// 
/// Usage:
///   dart scripts/update_readme_stats.dart
/// 
/// This script:
/// - Counts Dart files in lib/ and test/
/// - Runs flutter test to get test count
/// - Parses coverage data
/// - Counts supported languages
/// - Updates README.md with actual values
///
/// Run this before committing changes to keep README stats accurate.

import 'dart:io';

void main() async {
  print('📊 Generating README statistics from codebase...\n');
  
  try {
    // Gather statistics
    final libFiles = await countDartFiles('lib');
    final testFiles = await countDartFiles('test');
    final languages = await countLanguages();
    
    print('✅ Statistics gathered:');
    print('   📁 lib/: $libFiles Dart files');
    print('   🧪 test/: $testFiles test files');
    print('   🌍 Languages: $languages');
    
    // Note: Test count and coverage require running tests
    // which can be slow, so they're optional
    print('\n⚠️  Test count and coverage require running tests.');
    print('   Run with --full for complete stats (slower).');
    
    final fullStats = Platform.environment['FULL_STATS'] == 'true';
    
    Map<String, dynamic> stats = {
      'lib_files': libFiles,
      'test_files': testFiles,
      'languages': languages,
    };
    
    if (fullStats) {
      print('\n🧪 Running tests to get coverage...');
      final testResults = await runTests();
      final coverage = await getCoverage();
      
      stats.addAll({
        'total_tests': testResults['total'],
        'passing_tests': testResults['passing'],
        'coverage_percent': coverage['percent'],
        'coverage_covered': coverage['covered'],
        'coverage_total': coverage['total'],
      });
      
      print('   ✅ Tests: ${testResults['total']} (${testResults['passing']} passing)');
      print('   ✅ Coverage: ${coverage['percent']}% (${coverage['covered']}/${coverage['total']} lines)');
    }
    
    // Update README.md
    await updateReadme(stats);
    
    print('\n✅ README.md updated successfully!');
    print('   Review changes with: git diff README.md');
    
  } catch (e, stackTrace) {
    print('❌ Error: $e');
    print('Stack trace: $stackTrace');
    exit(1);
  }
}

/// Count .dart files in a directory recursively
Future<int> countDartFiles(String path) async {
  final dir = Directory(path);
  if (!await dir.exists()) {
    print('⚠️  Warning: Directory $path does not exist');
    return 0;
  }
  
  var count = 0;
  await for (final entity in dir.list(recursive: true)) {
    if (entity is File && entity.path.endsWith('.dart')) {
      count++;
    }
  }
  return count;
}

/// Run flutter test and parse test count
Future<Map<String, int>> runTests() async {
  final result = await Process.run('flutter', ['test', '--no-pub']);
  
  if (result.exitCode != 0) {
    print('⚠️  Warning: Tests failed, cannot determine test count');
    // Return null values to indicate unavailable data
    return {'total': 0, 'passing': 0};
  }
  
  final output = result.stdout.toString();
  
  // Parse test output for count - handle various formats:
  // - "All tests passed! X tests"
  // - "All X tests passed!"
  // - "X tests passed"
  final passedRegex = RegExp(r'(?:All\s+)?(\d+)\s+tests?\s+passed', caseSensitive: false);
  final match = passedRegex.firstMatch(output);
  
  if (match != null) {
    final total = int.parse(match.group(1)!);
    return {'total': total, 'passing': total};
  }
  
  print('⚠️  Warning: Could not parse test count from output');
  return {'total': 0, 'passing': 0};
}

/// Run tests with coverage and parse lcov.info
Future<Map<String, dynamic>> getCoverage() async {
  // Run tests with coverage
  final result = await Process.run(
    'flutter',
    ['test', '--coverage', '--no-pub'],
  );
  
  if (result.exitCode != 0) {
    print('⚠️  Warning: Coverage generation failed');
    return {'percent': '0.00', 'covered': 0, 'total': 0};
  }
  
  // Parse lcov.info
  final lcovFile = File('coverage/lcov.info');
  if (!await lcovFile.exists()) {
    print('⚠️  Warning: coverage/lcov.info not found');
    return {'percent': '0.00', 'covered': 0, 'total': 0};
  }
  
  final content = await lcovFile.readAsString();
  
  // Sum all LF (lines found) and LH (lines hit)
  var totalLines = 0;
  var coveredLines = 0;
  
  for (final line in content.split('\n')) {
    if (line.startsWith('LF:')) {
      totalLines += int.parse(line.substring(3));
    } else if (line.startsWith('LH:')) {
      coveredLines += int.parse(line.substring(3));
    }
  }
  
  final percent = totalLines > 0 
    ? (coveredLines / totalLines * 100).toStringAsFixed(2)
    : '0.00';
  
  return {
    'percent': percent,
    'covered': coveredLines,
    'total': totalLines,
  };
}

/// Count supported languages in i18n directory
Future<int> countLanguages() async {
  final i18nDir = Directory('i18n');
  if (!await i18nDir.exists()) {
    print('⚠️  Warning: i18n directory not found');
    return 0; // Return 0 to indicate unavailable data
  }
  
  var count = 0;
  await for (final entity in i18nDir.list()) {
    // Count .json files (each represents a language)
    if (entity is File && entity.path.endsWith('.json')) {
      count++;
    }
  }
  return count;
}

/// Update README.md with new statistics
Future<void> updateReadme(Map<String, dynamic> stats) async {
  final readmeFile = File('README.md');
  if (!await readmeFile.exists()) {
    throw Exception('README.md not found');
  }
  
  var content = await readmeFile.readAsString();
  
  // Update source files count (English section)
  content = content.replaceAllMapped(
    RegExp(r'\| Source Files \(lib/\) \| (\d+) Dart files \|'),
    (match) => '| Source Files (lib/) | ${stats['lib_files']} Dart files |',
  );
  
  // Update source files count (Spanish section)
  content = content.replaceAllMapped(
    RegExp(r'\| Archivos Fuente \(lib/\) \| (\d+) archivos Dart \|'),
    (match) => '| Archivos Fuente (lib/) | ${stats['lib_files']} archivos Dart |',
  );
  
  // Update test files count (English section)
  content = content.replaceAllMapped(
    RegExp(r'\| Test Files \| (\d+) test files \|'),
    (match) => '| Test Files | ${stats['test_files']} test files |',
  );
  
  // Update test files count (Spanish section)
  content = content.replaceAllMapped(
    RegExp(r'\| Archivos de Test \| (\d+) archivos \|'),
    (match) => '| Archivos de Test | ${stats['test_files']} archivos |',
  );
  
  // Update supported languages count (English section)
  content = content.replaceAllMapped(
    RegExp(r'\| Supported Languages \| (\d+) \('),
    (match) => '| Supported Languages | ${stats['languages']} (',
  );
  
  // Update supported languages count (Spanish section)
  content = content.replaceAllMapped(
    RegExp(r'\| Idiomas Soportados \| (\d+) \('),
    (match) => '| Idiomas Soportados | ${stats['languages']} (',
  );
  
  // Update test count if available
  if (stats.containsKey('total_tests') && stats['total_tests'] > 0) {
    // English section - handle both comma and non-comma formats
    content = content.replaceAllMapped(
      RegExp(r'\| Total Tests \| ([\d,]+) tests'),
      (match) => '| Total Tests | ${_formatNumber(stats['total_tests'])} tests',
    );
    
    // Spanish section - handle both comma and non-comma formats
    content = content.replaceAllMapped(
      RegExp(r'\| Total de Tests \| ([\d.,]+) tests'),
      (match) => '| Total de Tests | ${_formatNumber(stats['total_tests'])} tests',
    );
    
    // Update badge
    content = content.replaceAllMapped(
      RegExp(r'!\[Tests\]\(https://img\.shields\.io/badge/Tests-(\d+,?\d*)-'),
      (match) => '![Tests](https://img.shields.io/badge/Tests-${_formatNumber(stats['total_tests'])}-',
    );
  }
  
  // Update coverage if available
  if (stats.containsKey('coverage_percent') && 
      stats['coverage_percent'] != '0.00' &&
      stats['coverage_total'] > 0) {
    // English section - handle both comma and non-comma number formats
    content = content.replaceAllMapped(
      RegExp(r'\| Test Coverage \| ([\d.]+)% \(([\d,]+)/([\d,]+) lines\) \|'),
      (match) => '| Test Coverage | ${stats['coverage_percent']}% (${_formatNumber(stats['coverage_covered'])}/${_formatNumber(stats['coverage_total'])} lines) |',
    );
    
    // Spanish section - handle both comma and period number formats
    content = content.replaceAllMapped(
      RegExp(r'\| Cobertura de Tests \| ([\d.]+)% \(([\d.,]+)/([\d.,]+) líneas\) \|'),
      (match) => '| Cobertura de Tests | ${stats['coverage_percent']}% (${_formatNumber(stats['coverage_covered'])}/${_formatNumber(stats['coverage_total'])} líneas) |',
    );
    
    // Update badge
    final coveragePercent = double.parse(stats['coverage_percent'].toString());
    final color = coveragePercent >= 60 ? 'green' : 
                  coveragePercent >= 40 ? 'yellow' : 'red';
    
    content = content.replaceAllMapped(
      RegExp(r'!\[Coverage\]\(https://img\.shields\.io/badge/Coverage-([\d.]+)%25-\w+\.svg\)'),
      (match) => '![Coverage](https://img.shields.io/badge/Coverage-${stats['coverage_percent']}%25-$color.svg)',
    );
  }
  
  // Write updated content
  await readmeFile.writeAsString(content);
}

/// Format number with thousands separator
String _formatNumber(int number) {
  return number.toString().replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
    (match) => '${match.group(1)},',
  );
}
