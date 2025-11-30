import 'kairo/utils.dart';
import 'utils/bench_repeat.dart';
import 'reactive_framework.dart';
import 'kairo/avoidable.dart';
import 'kairo/broad.dart';
import 'kairo/deep.dart';
import 'kairo/diamond.dart';
import 'kairo/mux.dart';
import 'kairo/repeated.dart';
import 'kairo/triangle.dart';
import 'kairo/unstable.dart';

final cases = [
  (avoidablePropagation, 'avoidablePropagation'),
  (broadPropagation, 'broadPropagation'),
  (deepPropagation, 'deepPropagation'),
  (diamond, 'diamond'),
  (mux, 'mux'),
  (repeatedObservers, 'repeatedObservers'),
  (triangle, 'triangle'),
  (unstable, 'unstable'),
];

typedef BenchResult = ({String test, int time, KairoState state});

Future<List<BenchResult>> kairoBench(
  ReactiveFramework framework, {
  int testRepeats = 10,
}) async {
  final results = <BenchResult>[];

  for (final (testCase, name) in cases) {
    try {
      final iter = framework.withBuild(() {
        final iter = testCase(framework);
        return iter;
      });

      // warm up
      KairoState state = iter();

      final timingResult = await fastestTest(testRepeats, () {
        for (int i = 0; i < 1000; i++) {
          final itemState = iter();
          if (state == KairoState.success) {
            state = itemState;
          }
        }
        return null;
      });

      results.add((
        test: '$name (${state.name})',
        time: timingResult.timing.time,
        state: state,
      ));
    } catch (e) {
      results.add((test: '$name (fail)', time: 0, state: KairoState.fail));
    }
  }

  return results;
}
