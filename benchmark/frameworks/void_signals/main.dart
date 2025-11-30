import 'package:void_signals/void_signals.dart' as vs;
import 'package:reactivity_benchmark/reactive_framework.dart';
import 'package:reactivity_benchmark/run_framework_bench.dart';
import 'package:reactivity_benchmark/utils/create_computed.dart';
import 'package:reactivity_benchmark/utils/create_signal.dart';

final class VoidSignalsFramework extends ReactiveFramework {
  const VoidSignalsFramework()
    : super('[void_signals](https://github.com/iota9star/void_signals)');

  @override
  @pragma('vm:prefer-inline')
  Computed<T> computed<T>(T Function() fn) {
    final c = vs.computed<T>((_) => fn());
    return createComputed(c.call);
  }

  @override
  @pragma('vm:prefer-inline')
  void effect(void Function() fn) {
    vs.effect(fn);
  }

  @override
  @pragma('vm:prefer-inline')
  Signal<T> signal<T>(T value) {
    final s = vs.signal(value);
    return createSignal(s.call, (v) => s.value = v);
  }

  @override
  @pragma('vm:prefer-inline')
  void withBatch<T>(T Function() fn) {
    vs.startBatch();
    fn();
    vs.endBatch();
  }

  @override
  @pragma('vm:prefer-inline')
  T withBuild<T>(T Function() fn) => fn();
}

void main() {
  runFrameworkBench(const VoidSignalsFramework());
}
