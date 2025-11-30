import 'package:reactivity_benchmark/reactive_framework.dart';
import 'package:reactivity_benchmark/run_framework_bench.dart';
import 'package:reactivity_benchmark/utils/create_computed.dart';
import 'package:reactivity_benchmark/utils/create_signal.dart';
import 'package:state_beacon_core/state_beacon_core.dart';

final class StateBeaconFramework extends ReactiveFramework {
  const StateBeaconFramework()
    : super('[state_beacon](https://pub.dev/packages/state_beacon)');

  @override
  @pragma('vm:prefer-inline')
  Computed<T> computed<T>(T Function() fn) {
    final c = Beacon.derived(fn);
    return createComputed(() => c.value);
  }

  @override
  @pragma('vm:prefer-inline')
  void effect(void Function() fn) {
    Beacon.effect(fn);
    // Flush the scheduler to run effects synchronously
    BeaconScheduler.flush();
  }

  @override
  @pragma('vm:prefer-inline')
  Signal<T> signal<T>(T value) {
    final s = Beacon.writable(value);
    return createSignal(() => s.value, (v) {
      s.value = v;
      // Flush after write to ensure effects run
      BeaconScheduler.flush();
    });
  }

  @override
  @pragma('vm:prefer-inline')
  void withBatch<T>(T Function() fn) {
    fn();
    BeaconScheduler.flush();
  }

  @override
  @pragma('vm:prefer-inline')
  T withBuild<T>(T Function() fn) => fn();
}

void main() {
  runFrameworkBench(const StateBeaconFramework());
}
