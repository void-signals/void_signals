import 'package:alien_signals/alien_signals.dart' as alien;
import 'package:reactivity_benchmark/reactive_framework.dart';
import 'package:reactivity_benchmark/run_framework_bench.dart';
import 'package:reactivity_benchmark/utils/create_computed.dart';
import 'package:reactivity_benchmark/utils/create_signal.dart';

final class AlienSignalsFramework extends ReactiveFramework {
  const AlienSignalsFramework()
    : super('[alien_signals](https://github.com/medz/alien-signals-dart)');

  @override
  @pragma('vm:prefer-inline')
  Computed<T> computed<T>(T Function() fn) {
    final c = alien.computed<T>((_) => fn());
    return createComputed(c.call);
  }

  @override
  @pragma('vm:prefer-inline')
  void effect(void Function() fn) {
    alien.effect(fn);
  }

  @override
  @pragma('vm:prefer-inline')
  Signal<T> signal<T>(T value) {
    final s = alien.signal(value);
    return createSignal(() => s(), (v) => s.set(v));
  }

  @override
  @pragma('vm:prefer-inline')
  void withBatch<T>(T Function() fn) {
    alien.startBatch();
    fn();
    alien.endBatch();
  }

  @override
  @pragma('vm:prefer-inline')
  T withBuild<T>(T Function() fn) => fn();
}

void main() {
  runFrameworkBench(const AlienSignalsFramework());
}
