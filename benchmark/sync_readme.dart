import 'dart:io';

/// Syncs benchmark results from BENCHMARK_REPORT.md to README files
///
/// This script extracts the Results and Summary tables from BENCHMARK_REPORT.md
/// and inserts them between the markers in README files:
/// - benchmark/README.md: Full results and summary
/// - README.md & README_CN.md: Summary table only
void main() async {
  final reportFile = File('bench/BENCHMARK_REPORT.md');

  if (!reportFile.existsSync()) {
    print('Error: bench/BENCHMARK_REPORT.md not found');
    exit(1);
  }

  // Read report content
  final reportContent = await reportFile.readAsString();

  // Extract Results and Summary sections
  final resultsSection = _extractSection(
    reportContent,
    '## Results',
    '## Summary',
  );
  final summarySection = _extractSection(reportContent, '## Summary', null);

  if (resultsSection == null) {
    print('Error: Could not find Results section in report');
    exit(1);
  }

  // Update benchmark/README.md with full results
  await _updateBenchmarkReadme(resultsSection, summarySection);

  // Extract summary table for main README files
  final summaryTable = _extractSummaryTable(summarySection);
  if (summaryTable != null) {
    // Update root README.md
    await _updateMainReadme('../README.md', summaryTable);
    // Update root README_CN.md
    await _updateMainReadme('../README_CN.md', summaryTable);
  }
}

/// Update benchmark/README.md with full benchmark results
Future<void> _updateBenchmarkReadme(
  String resultsSection,
  String? summarySection,
) async {
  final readmeFile = File('README.md');

  if (!readmeFile.existsSync()) {
    print('Warning: benchmark/README.md not found, skipping');
    return;
  }

  // Build the new content to insert
  final buffer = StringBuffer();
  buffer.writeln('## Latest Benchmark Results');
  buffer.writeln();
  buffer.write(resultsSection.trim());
  buffer.writeln();
  if (summarySection != null) {
    buffer.writeln();
    buffer.write(summarySection.trim());
  }

  final newContent = buffer.toString();

  // Read README content
  var readmeContent = await readmeFile.readAsString();

  // Find and replace content between markers
  const startMarker = '<!-- BENCHMARK_RESULTS_START -->';
  const endMarker = '<!-- BENCHMARK_RESULTS_END -->';

  final startIndex = readmeContent.indexOf(startMarker);
  final endIndex = readmeContent.indexOf(endMarker);

  if (startIndex == -1 || endIndex == -1) {
    print('Warning: Markers not found in benchmark/README.md, skipping');
    return;
  }

  // Replace content between markers
  final before = readmeContent.substring(0, startIndex + startMarker.length);
  final after = readmeContent.substring(endIndex);

  final newReadme = '$before\n$newContent\n$after';

  // Write updated README
  await readmeFile.writeAsString(newReadme);

  print('✓ benchmark/README.md updated with latest benchmark results');
}

/// Update main README files with summary table only
Future<void> _updateMainReadme(String path, String summaryTable) async {
  final readmeFile = File(path);

  if (!readmeFile.existsSync()) {
    print('Warning: $path not found, skipping');
    return;
  }

  // Read README content
  var readmeContent = await readmeFile.readAsString();

  // Find and replace content between markers
  const startMarker = '<!-- BENCHMARK_SUMMARY_START -->';
  const endMarker = '<!-- BENCHMARK_SUMMARY_END -->';

  final startIndex = readmeContent.indexOf(startMarker);
  final endIndex = readmeContent.indexOf(endMarker);

  if (startIndex == -1 || endIndex == -1) {
    print('Warning: Summary markers not found in $path, skipping');
    return;
  }

  // Replace content between markers
  final before = readmeContent.substring(0, startIndex + startMarker.length);
  final after = readmeContent.substring(endIndex);

  final newReadme = '$before\n$summaryTable\n$after';

  // Write updated README
  await readmeFile.writeAsString(newReadme);

  print('✓ $path updated with latest benchmark summary');
}

/// Extract the summary table from the summary section
String? _extractSummaryTable(String? summarySection) {
  if (summarySection == null) return null;

  // Find the table in the summary section
  final lines = summarySection.split('\n');
  final tableLines = <String>[];
  var inTable = false;

  for (final line in lines) {
    if (line.trim().startsWith('|')) {
      inTable = true;
      tableLines.add(line);
    } else if (inTable && line.trim().isEmpty) {
      break;
    }
  }

  return tableLines.isNotEmpty ? tableLines.join('\n') : null;
}

/// Extract a section from markdown content
String? _extractSection(String content, String startHeader, String? endHeader) {
  final startIndex = content.indexOf(startHeader);
  if (startIndex == -1) return null;

  final contentStart = startIndex + startHeader.length;

  int contentEnd;
  if (endHeader != null) {
    contentEnd = content.indexOf(endHeader, contentStart);
    if (contentEnd == -1) {
      contentEnd = content.length;
    }
  } else {
    // Find next ## header or end of file
    final nextHeader = RegExp(
      r'\n## ',
    ).firstMatch(content.substring(contentStart));
    if (nextHeader != null) {
      contentEnd = contentStart + nextHeader.start;
    } else {
      contentEnd = content.length;
    }
  }

  return content.substring(contentStart, contentEnd).trim();
}
