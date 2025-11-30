import 'config.dart';
import 'framework_type.dart';
import 'reactive_framework.dart';
import 'utils/bench_repeat.dart';
import 'utils/dep_graph.dart';
import 'utils/perf_tests.dart';

typedef DynamicResult = ({String test, int time, bool passed});

Future<List<DynamicResult>> dynamicBench(
  ReactiveFramework framework, {
  int testRepeats = 10,
}) async {
  final results = <DynamicResult>[];

  for (final config in perfTests) {
    try {
      final TestConfig(:iterations, :readFraction, :name, :expected) = config;
      final counter = Counter();

      int runOnce() {
        try {
          final graph = makeGraph(framework, config, counter);
          return runGraph(graph, iterations, readFraction, framework);
        } catch (e) {
          return -1;
        }
      }

      // warm up
      runOnce();

      final timingResult = await fastestTest(testRepeats, () {
        counter.count = 0;
        final sum = runOnce();
        return TestResult(sum: sum, count: counter.count);
      });

      final result = timingResult.result;
      final sumOk = result.sum == expected.sum;
      final countOk = result.count == expected.count;
      final testName =
          '${config.width}x${config.totalLayers} - ${config.nSources} sources${config.staticFraction < 1 ? " - dynamic" : ""} ($name, sum: ${sumOk ? "pass" : "fail"}, count: ${countOk ? "pass" : "fail"})';

      results.add((
        test: testName,
        time: timingResult.timing.time,
        passed: sumOk && countOk,
      ));
    } catch (e) {
      results.add((test: '${config.name} (fail)', time: 0, passed: false));
    }
  }

  return results;
}
