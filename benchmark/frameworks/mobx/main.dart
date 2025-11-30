import 'package:mobx/mobx.dart' as mobx;
import 'package:reactivity_benchmark/reactive_framework.dart';
import 'package:reactivity_benchmark/run_framework_bench.dart';
import 'package:reactivity_benchmark/utils/create_computed.dart';
import 'package:reactivity_benchmark/utils/create_signal.dart';

final class MobXFramework extends ReactiveFramework {
  const MobXFramework() : super('[mobx](https://github.com/mobxjs/mobx.dart)');

  @override
  @pragma('vm:prefer-inline')
  Computed<T> computed<T>(T Function() fn) {
    final c = mobx.Computed(() => fn());
    return createComputed(() => c.value);
  }

  @override
  @pragma('vm:prefer-inline')
  void effect(void Function() fn) {
    mobx.autorun((_) => fn());
  }

  @override
  @pragma('vm:prefer-inline')
  Signal<T> signal<T>(T value) {
    final s = mobx.Observable(value);
    return createSignal(() => s.value, (v) => s.value = v);
  }

  @override
  @pragma('vm:prefer-inline')
  void withBatch<T>(T Function() fn) {
    mobx.runInAction(fn);
  }

  @override
  @pragma('vm:prefer-inline')
  T withBuild<T>(T Function() fn) => fn();
}

void main() {
  runFrameworkBench(const MobXFramework());
}
