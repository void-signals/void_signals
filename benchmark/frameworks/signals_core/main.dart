import 'package:signals_core/signals_core.dart' as signals;
import 'package:reactivity_benchmark/reactive_framework.dart';
import 'package:reactivity_benchmark/run_framework_bench.dart';
import 'package:reactivity_benchmark/utils/create_computed.dart';
import 'package:reactivity_benchmark/utils/create_signal.dart';

final class SignalsCoreFramework extends ReactiveFramework {
  const SignalsCoreFramework()
    : super('[signals_core](https://github.com/rodydavis/signals.dart)');

  @override
  @pragma('vm:prefer-inline')
  Computed<T> computed<T>(T Function() fn) {
    final c = signals.computed(fn);
    return createComputed(() => c.value);
  }

  @override
  @pragma('vm:prefer-inline')
  void effect(void Function() fn) {
    signals.effect(fn);
  }

  @override
  @pragma('vm:prefer-inline')
  Signal<T> signal<T>(T value) {
    final s = signals.signal(value);
    return createSignal(() => s.value, (v) => s.value = v);
  }

  @override
  @pragma('vm:prefer-inline')
  void withBatch<T>(T Function() fn) {
    signals.batch(fn);
  }

  @override
  @pragma('vm:prefer-inline')
  T withBuild<T>(T Function() fn) => fn();
}

void main() {
  signals.SignalsObserver.instance = null;
  runFrameworkBench(const SignalsCoreFramework());
}
