/// Main benchmark runner that mirrors dart-reactivity-benchmark.
library;

import 'dart:convert';
import 'dart:io';

import 'kairo/utils.dart';
import 'reactive_framework.dart';
import 'kairo_bench.dart';
import 's_bench.dart';
import 'cellx_bench.dart';
import 'mol_bench.dart';
import 'dynamic_bench.dart';

/// Result of a single benchmark run.
class BenchResult {
  BenchResult({
    required this.framework,
    required this.test,
    required this.time,
    this.passed = true,
    this.notes = '',
  });

  final String framework;
  final String test;
  final int time;
  final bool passed;
  final String notes;

  Map<String, dynamic> toJson() => {
    'framework': framework,
    'test': test,
    'time': time,
    'passed': passed,
    'notes': notes,
  };
}

/// Run all benchmarks for a framework.
class BenchmarkRunner {
  BenchmarkRunner(this.frameworks);

  final List<ReactiveFramework> frameworks;
  final List<BenchResult> results = [];

  /// Run all benchmarks for all frameworks.
  Future<void> runAll({bool verbose = true, int testRepeats = 10}) async {
    for (final framework in frameworks) {
      final name = _extractName(framework.name);
      if (verbose) {
        print('\n${'=' * 60}');
        print('Benchmarking: ${framework.name}');
        print('=' * 60);
      }

      // Run Kairo benchmarks
      if (verbose) print('\n  [Kairo Benchmarks]');
      final kairoResults = await kairoBench(
        framework,
        testRepeats: testRepeats,
      );
      for (final r in kairoResults) {
        results.add(
          BenchResult(
            framework: name,
            test: r.test,
            time: r.time,
            passed: r.state == KairoState.success,
          ),
        );
        if (verbose) print('    ${r.test}: ${r.time}μs');
      }

      // Run S-bench
      if (verbose) print('\n  [S-Bench - Signal Operations]');
      final sbenchResults = sbench(framework);
      for (final r in sbenchResults) {
        results.add(
          BenchResult(
            framework: name,
            test: r.test,
            time: r.time,
            passed: r.passed,
          ),
        );
        if (verbose) print('    ${r.test}: ${r.time}μs');
      }

      // Run CellX benchmark
      if (verbose) print('\n  [CellX Benchmarks]');
      final cellxResults = cellxBench(framework);
      for (final r in cellxResults) {
        results.add(
          BenchResult(
            framework: name,
            test: r.test,
            time: r.time,
            passed: r.passed,
          ),
        );
        if (verbose) print('    ${r.test}: ${r.time}μs');
      }

      // Run Mol benchmark
      if (verbose) print('\n  [Mol Benchmark]');
      final molResult = await molBench(framework, testRepeats: testRepeats);
      results.add(
        BenchResult(
          framework: name,
          test: molResult.test,
          time: molResult.time,
          passed: molResult.passed,
        ),
      );
      if (verbose) print('    ${molResult.test}: ${molResult.time}μs');

      // Run Dynamic benchmarks
      if (verbose) print('\n  [Dynamic Graph Benchmarks]');
      final dynamicResults = await dynamicBench(
        framework,
        testRepeats: testRepeats,
      );
      for (final r in dynamicResults) {
        results.add(
          BenchResult(
            framework: name,
            test: r.test,
            time: r.time,
            passed: r.passed,
          ),
        );
        if (verbose) print('    ${r.test}: ${r.time}μs');
      }
    }
  }

  /// Generate markdown report.
  String generateMarkdownReport() {
    final buffer = StringBuffer();

    buffer.writeln('# Reactivity Benchmark Report');
    buffer.writeln();
    buffer.writeln('Generated: ${DateTime.now().toIso8601String()}');
    buffer.writeln();

    final testNames = results.map((r) => r.test).toSet().toList()..sort();
    final frameworkNames = frameworks.map((f) => _extractName(f.name)).toList();

    buffer.writeln('## Results');
    buffer.writeln();
    buffer.write('| Test |');
    for (final name in frameworkNames) {
      buffer.write(' $name |');
    }
    buffer.writeln();

    buffer.write('|------|');
    for (final _ in frameworkNames) {
      buffer.write('--------|');
    }
    buffer.writeln();

    for (final test in testNames) {
      buffer.write('| $test |');

      final testResults = results
          .where((r) => r.test == test && r.passed)
          .toList();
      final bestTime = testResults.isEmpty
          ? double.infinity
          : testResults.map((r) => r.time).reduce((a, b) => a < b ? a : b);

      for (final framework in frameworkNames) {
        final result = results.firstWhere(
          (r) => r.test == test && r.framework == framework,
          orElse: () => BenchResult(framework: framework, test: test, time: 0),
        );

        if (!result.passed) {
          buffer.write(' ❌ |');
        } else if (result.time == bestTime) {
          buffer.write(' **${_formatTime(result.time)}** 🏆 |');
        } else {
          buffer.write(' ${_formatTime(result.time)} |');
        }
      }
      buffer.writeln();
    }

    // Add summary section
    buffer.writeln();
    buffer.writeln('## Summary');
    buffer.writeln();

    final stats = _calculateStats();
    final sorted = stats.entries.toList()
      ..sort((a, b) => b.value.wins - a.value.wins);

    buffer.writeln('| Rank | Framework | Wins | Pass Rate |');
    buffer.writeln('|------|-----------|------|-----------|');

    for (var i = 0; i < sorted.length; i++) {
      final entry = sorted[i];
      final medal = switch (i) {
        0 => '🥇',
        1 => '🥈',
        2 => '🥉',
        _ => '${i + 1}',
      };
      final passRate = (entry.value.passed / entry.value.total * 100)
          .toStringAsFixed(0);
      buffer.writeln(
        '| $medal | ${entry.key} | ${entry.value.wins} | $passRate% |',
      );
    }

    return buffer.toString();
  }

  /// Generate JSON report.
  String generateJsonReport() {
    final report = {
      'timestamp': DateTime.now().toIso8601String(),
      'frameworks': frameworks.map((f) => f.name).toList(),
      'results': results.map((r) => r.toJson()).toList(),
      'summary': _calculateStats().map(
        (k, v) =>
            MapEntry(k, {'wins': v.wins, 'passed': v.passed, 'total': v.total}),
      ),
    };

    return const JsonEncoder.withIndent('  ').convert(report);
  }

  Map<String, ({int wins, int total, int passed})> _calculateStats() {
    final frameworkStats = <String, ({int wins, int total, int passed})>{};

    for (final framework in frameworks.map((f) => _extractName(f.name))) {
      final frameworkResults = results
          .where((r) => r.framework == framework)
          .toList();
      int wins = 0;

      final testNames = results.map((r) => r.test).toSet();
      for (final test in testNames) {
        final testResults = results
            .where((r) => r.test == test && r.passed)
            .toList();
        if (testResults.isEmpty) continue;

        final best = testResults.reduce((a, b) => a.time < b.time ? a : b);
        if (best.framework == framework) wins++;
      }

      frameworkStats[framework] = (
        wins: wins,
        total: frameworkResults.length,
        passed: frameworkResults.where((r) => r.passed).length,
      );
    }

    return frameworkStats;
  }

  /// Save reports to files.
  Future<void> saveReports(String directory) async {
    final dir = Directory(directory);
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }

    await File(
      '$directory/BENCHMARK_REPORT.md',
    ).writeAsString(generateMarkdownReport());
    await File(
      '$directory/benchmark_results.json',
    ).writeAsString(generateJsonReport());
  }

  static String _extractName(String name) {
    final match = RegExp(r'\[([^\]]+)\]').firstMatch(name);
    return match?.group(1) ?? name;
  }

  static String _formatTime(int microseconds) {
    if (microseconds < 1000) {
      return '${microseconds}μs';
    } else if (microseconds < 1000000) {
      return '${(microseconds / 1000).toStringAsFixed(2)}ms';
    } else {
      return '${(microseconds / 1000000).toStringAsFixed(2)}s';
    }
  }

  /// Print ranking summary.
  void printRanking() {
    final stats = _calculateStats();
    final sorted = stats.entries.toList()
      ..sort((a, b) => b.value.wins - a.value.wins);

    print('\nRanking:');
    for (var i = 0; i < sorted.length; i++) {
      final entry = sorted[i];
      final medal = switch (i) {
        0 => '🥇',
        1 => '🥈',
        2 => '🥉',
        _ => '  ${i + 1}.',
      };
      final passRate = (entry.value.passed / entry.value.total * 100)
          .toStringAsFixed(0);
      print('$medal ${entry.key}: ${entry.value.wins} wins, $passRate% pass');
    }
  }
}

/// Run benchmark for a single framework and print markdown report.
Future<void> runFrameworkBench(
  ReactiveFramework framework, {
  int testRepeats = 10,
}) async {
  final runner = BenchmarkRunner([framework]);
  await runner.runAll(verbose: false, testRepeats: testRepeats);
  print(runner.generateMarkdownReport());
}
