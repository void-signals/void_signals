/// Test configuration and result types.
library;

import 'utils/perf_tests.dart';

/// Configuration for a test case.
class TestConfig {
  const TestConfig({
    required this.name,
    required this.width,
    required this.staticFraction,
    required this.nSources,
    required this.totalLayers,
    required this.readFraction,
    required this.iterations,
    required this.expected,
  });

  final String name;
  final int width;
  final double staticFraction;
  final int nSources;
  final int totalLayers;
  final double readFraction;
  final int iterations;
  final TestResult expected;
}
