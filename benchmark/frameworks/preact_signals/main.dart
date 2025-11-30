import 'package:preact_signals/preact_signals.dart' as preact;
import 'package:reactivity_benchmark/reactive_framework.dart';
import 'package:reactivity_benchmark/run_framework_bench.dart';
import 'package:reactivity_benchmark/utils/create_computed.dart';
import 'package:reactivity_benchmark/utils/create_signal.dart';

final class PreactSignalsFramework extends ReactiveFramework {
  const PreactSignalsFramework()
    : super('[preact_signals](https://pub.dev/packages/preact_signals)');

  @override
  @pragma('vm:prefer-inline')
  Computed<T> computed<T>(T Function() fn) {
    final c = preact.computed(() => fn());
    return createComputed(() => c.value);
  }

  @override
  @pragma('vm:prefer-inline')
  void effect(void Function() fn) {
    preact.effect(fn);
  }

  @override
  @pragma('vm:prefer-inline')
  Signal<T> signal<T>(T value) {
    final s = preact.signal(value);
    return createSignal(() => s.value, (v) => s.value = v);
  }

  @override
  @pragma('vm:prefer-inline')
  void withBatch<T>(T Function() fn) {
    preact.batch(fn);
  }

  @override
  @pragma('vm:prefer-inline')
  T withBuild<T>(T Function() fn) => fn();
}

void main() {
  runFrameworkBench(const PreactSignalsFramework());
}
