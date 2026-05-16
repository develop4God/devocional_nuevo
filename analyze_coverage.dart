import 'dart:io';

void main() async {
  final file = File('coverage/lcov.info');
  if (!await file.exists()) {
    stdout.writeln('lcov.info not found');
    return;
  }

  final lines = await file.readAsLines();
  final fileCoverage = <String, FileStats>{};
  String? currentFile;

  for (final line in lines) {
    if (line.startsWith('SF:')) {
      currentFile = line.substring(3);
      fileCoverage[currentFile] = FileStats();
    } else if (line.startsWith('DA:')) {
      final parts = line.substring(3).split(',');
      final executionCount = int.parse(parts[1]);
      if (executionCount > 0) {
        fileCoverage[currentFile!]!.coveredLines++;
      }
      fileCoverage[currentFile!]!.totalLines++;
    }
  }

  final statsList = fileCoverage.entries.map((e) {
    final uncovered = e.value.totalLines - e.value.coveredLines;
    final percentage = e.value.totalLines > 0
        ? (e.value.coveredLines / e.value.totalLines) * 100
        : 100.0;
    return {
      'file': e.key,
      'uncovered': uncovered,
      'percentage': percentage,
      'total': e.value.totalLines,
    };
  }).toList();

  // Filter for files in lib/ and sort by number of uncovered lines descending
  final topUncovered =
      statsList.where((s) => s['file'].toString().startsWith('lib/')).toList()
        ..sort(
          (a, b) => (b['uncovered'] as int).compareTo(a['uncovered'] as int),
        );

  stdout.writeln('Top 5 files with most uncovered lines:');
  for (var i = 0; i < 5 && i < topUncovered.length; i++) {
    final s = topUncovered[i];
    final percentage = (s['percentage'] as double);
    stdout.writeln(
      '${s['file']}: ${s['uncovered']} uncovered lines (${percentage.toStringAsFixed(1)}% coverage, ${s['total']} total lines)',
    );
  }
}

class FileStats {
  int totalLines = 0;
  int coveredLines = 0;
}
