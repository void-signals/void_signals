import 'package:solidart/solidart.dart' as solidart;
import 'package:reactivity_benchmark/reactive_framework.dart';
import 'package:reactivity_benchmark/run_framework_bench.dart';
import 'package:reactivity_benchmark/utils/create_computed.dart';
import 'package:reactivity_benchmark/utils/create_signal.dart';

final class SolidartFramework extends ReactiveFramework {
  const SolidartFramework()
    : super('[solidart](https://github.com/nank1ro/solidart)');

  @override
  @pragma('vm:prefer-inline')
  Computed<T> computed<T>(T Function() fn) {
    final c = solidart.Computed(fn);
    return createComputed(() => c.value);
  }

  @override
  @pragma('vm:prefer-inline')
  void effect(void Function() fn) {
    solidart.Effect(fn);
  }

  @override
  @pragma('vm:prefer-inline')
  Signal<T> signal<T>(T value) {
    final s = solidart.Signal(value);
    return createSignal(() => s.value, (v) => s.value = v);
  }

  @override
  @pragma('vm:prefer-inline')
  void withBatch<T>(T Function() fn) {
    solidart.batch(fn);
  }

  @override
  @pragma('vm:prefer-inline')
  T withBuild<T>(T Function() fn) => fn();
}

void main() {
  runFrameworkBench(const SolidartFramework());
}
