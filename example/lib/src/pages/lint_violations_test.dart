// This file intentionally contains lint violations to test all 38 lint rules.
// Run `dart run custom_lint` to verify each rule triggers correctly.

// ignore_for_file: unused_local_variable, unused_element, unused_field
// ignore_for_file: prefer_const_constructors, prefer_const_declarations
// ignore_for_file: avoid_print, unused_import

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:void_signals_flutter/void_signals_flutter.dart';
import 'package:void_signals_hooks/void_signals_hooks.dart';

// =============================================================================
// 1. avoid_signal_in_build - Creating signal in build()
// =============================================================================
class TestAvoidSignalInBuild extends StatelessWidget {
  const TestAvoidSignalInBuild({super.key});

  @override
  Widget build(BuildContext context) {
    // ❌ VIOLATION: avoid_signal_in_build
    final badSignal = signal(0);
    return Text('$badSignal');
  }
}

// =============================================================================
// 2. avoid_signal_creation_in_builder - Signal in SignalBuilder
// =============================================================================
class TestAvoidSignalCreationInBuilder extends StatelessWidget {
  const TestAvoidSignalCreationInBuilder({super.key});

  @override
  Widget build(BuildContext context) {
    // ❌ VIOLATION: avoid_signal_creation_in_builder
    return SignalBuilder(
      signal: signal(0),
      builder: (context, value, _) => Text('$value'),
    );
  }
}

// =============================================================================
// 3. prefer_final_signal - Non-final signal
// =============================================================================
// ❌ VIOLATION: prefer_final_signal - non-final, non-late signal
Signal<int> _mutableTopLevelSignal = signal(0);

class TestPreferFinalSignal extends StatefulWidget {
  const TestPreferFinalSignal({super.key});

  @override
  State<TestPreferFinalSignal> createState() => _TestPreferFinalSignalState();
}

class _TestPreferFinalSignalState extends State<TestPreferFinalSignal> {
  @override
  Widget build(BuildContext context) => Container();
}

void testPreferFinalSignalInFunction() {
  // ❌ VIOLATION: prefer_final_signal - var instead of final
  var mutableSignal = signal(0);
  print(mutableSignal);
}

// =============================================================================
// 4. prefer_signal_with_label - Signal without label (INFO level, may not show)
// =============================================================================
// Note: This is INFO level and may be filtered out

// =============================================================================
// 5. prefer_signal_over_value_notifier - Using ValueNotifier
// =============================================================================
class TestPreferSignalOverValueNotifier extends StatefulWidget {
  const TestPreferSignalOverValueNotifier({super.key});

  @override
  State<TestPreferSignalOverValueNotifier> createState() =>
      _TestPreferSignalOverValueNotifierState();
}

class _TestPreferSignalOverValueNotifierState
    extends State<TestPreferSignalOverValueNotifier> {
  // ❌ VIOLATION: prefer_signal_over_value_notifier
  final notifier = ValueNotifier<int>(0);

  @override
  Widget build(BuildContext context) => Container();
}

// =============================================================================
// 6. prefer_signal_scope_for_di - Using Provider for Signal (hard to trigger)
// =============================================================================
// Note: This requires specific Provider patterns

// =============================================================================
// 7. prefer_watch_over_effect_in_widget - Effect in widget for setState
// =============================================================================
class TestPreferWatchOverEffectInWidget extends StatefulWidget {
  const TestPreferWatchOverEffectInWidget({super.key});

  @override
  State<TestPreferWatchOverEffectInWidget> createState() =>
      _TestPreferWatchOverEffectInWidgetState();
}

class _TestPreferWatchOverEffectInWidgetState
    extends State<TestPreferWatchOverEffectInWidget> {
  final _counter = signal(0);

  @override
  void initState() {
    super.initState();
    // ❌ VIOLATION: prefer_watch_over_effect_in_widget
    effect(() {
      _counter.value;
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) => Container();
}

// =============================================================================
// 8. watch_without_signal_access - Watch without signal access
// =============================================================================
class TestWatchWithoutSignalAccess extends StatelessWidget {
  const TestWatchWithoutSignalAccess({super.key});

  @override
  Widget build(BuildContext context) {
    // ❌ VIOLATION: watch_without_signal_access
    return Watch(builder: (_) => Text('No signal accessed here'));
  }
}

// =============================================================================
// 9. prefer_computed_over_derived_signal - Effect to derive state
// =============================================================================
class TestPreferComputedOverDerivedSignal extends StatefulWidget {
  const TestPreferComputedOverDerivedSignal({super.key});

  @override
  State<TestPreferComputedOverDerivedSignal> createState() =>
      _TestPreferComputedOverDerivedSignalState();
}

class _TestPreferComputedOverDerivedSignalState
    extends State<TestPreferComputedOverDerivedSignal> {
  final _a = signal(1);
  final _derived = signal(0);

  @override
  void initState() {
    super.initState();
    // ❌ VIOLATION: prefer_computed_over_derived_signal
    effect(() {
      _derived.value = _a.value * 2;
    });
  }

  @override
  Widget build(BuildContext context) => Container();
}

// =============================================================================
// 10. prefer_batch_for_multiple_updates - Multiple signal updates
// =============================================================================
class TestPreferBatchForMultipleUpdates extends StatefulWidget {
  const TestPreferBatchForMultipleUpdates({super.key});

  @override
  State<TestPreferBatchForMultipleUpdates> createState() =>
      _TestPreferBatchForMultipleUpdatesState();
}

class _TestPreferBatchForMultipleUpdatesState
    extends State<TestPreferBatchForMultipleUpdates> {
  final _a = signal(0);
  final _b = signal(0);
  final _c = signal(0);

  void _badUpdate() {
    // ❌ VIOLATION: prefer_batch_for_multiple_updates
    _a.value = 1;
    _b.value = 2;
    _c.value = 3;
  }

  @override
  Widget build(BuildContext context) => Container();
}

// =============================================================================
// 11. prefer_peek_in_non_reactive - Using .value in callback (INFO level)
// =============================================================================
// Note: This is INFO level and may be filtered out

// =============================================================================
// 12. avoid_nested_effect_scope - Nested effect scopes
// =============================================================================
class TestAvoidNestedEffectScope extends StatefulWidget {
  const TestAvoidNestedEffectScope({super.key});

  @override
  State<TestAvoidNestedEffectScope> createState() =>
      _TestAvoidNestedEffectScopeState();
}

class _TestAvoidNestedEffectScopeState
    extends State<TestAvoidNestedEffectScope> {
  @override
  void initState() {
    super.initState();
    // ❌ VIOLATION: avoid_nested_effect_scope
    effectScope(() {
      effectScope(() {
        effect(() {});
      });
    });
  }

  @override
  Widget build(BuildContext context) => Container();
}

// =============================================================================
// 13. missing_effect_cleanup - Effect without cleanup
// =============================================================================
class TestMissingEffectCleanup extends StatefulWidget {
  const TestMissingEffectCleanup({super.key});

  @override
  State<TestMissingEffectCleanup> createState() =>
      _TestMissingEffectCleanupState();
}

class _TestMissingEffectCleanupState extends State<TestMissingEffectCleanup> {
  @override
  void initState() {
    super.initState();
    // ❌ VIOLATION: missing_effect_cleanup
    effect(() {
      print('No cleanup returned');
    });
  }

  @override
  Widget build(BuildContext context) => Container();
}

// =============================================================================
// 14. missing_scope_dispose - EffectScope not disposed
// =============================================================================
class TestMissingScopeDispose extends StatefulWidget {
  const TestMissingScopeDispose({super.key});

  @override
  State<TestMissingScopeDispose> createState() =>
      _TestMissingScopeDisposeState();
}

class _TestMissingScopeDisposeState extends State<TestMissingScopeDispose> {
  // ❌ VIOLATION: missing_scope_dispose - scope created but not stopped in dispose
  late final _scope = effectScope(() {
    effect(() {});
  });

  @override
  void dispose() {
    // Missing _scope.stop()
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Container();
}

// =============================================================================
// 15. avoid_effect_for_ui - Effect for UI updates
// =============================================================================
// Similar to prefer_watch_over_effect_in_widget

// =============================================================================
// 16. avoid_effect_in_build - Effect in build()
// =============================================================================
class TestAvoidEffectInBuild extends StatelessWidget {
  const TestAvoidEffectInBuild({super.key});

  @override
  Widget build(BuildContext context) {
    // ❌ VIOLATION: avoid_effect_in_build
    effect(() {
      print('Effect in build!');
    });
    return Container();
  }
}

// =============================================================================
// 17. avoid_signal_access_in_async - Signal after await
// =============================================================================
Future<void> testAvoidSignalAccessInAsync() async {
  final mySignal = signal(0);
  await Future.delayed(Duration.zero);
  // ❌ VIOLATION: avoid_signal_access_in_async
  print(mySignal.value);
}

// =============================================================================
// 18. avoid_async_in_computed - Async in computed
// =============================================================================
final testAvoidAsyncInComputed = computed((prev) async {
  // ❌ VIOLATION: avoid_async_in_computed
  await Future.delayed(Duration.zero);
  return 42;
});

// =============================================================================
// 19. avoid_mutating_signal_collection - Direct collection mutation
// =============================================================================
void testAvoidMutatingSignalCollection() {
  final items = signal(<int>[1, 2, 3]);
  // ❌ VIOLATION: avoid_mutating_signal_collection
  items.value.add(4);
}

// =============================================================================
// 20. avoid_circular_computed - Circular dependency
// =============================================================================
// ❌ VIOLATION: avoid_circular_computed - circular dependencies
final _circularA = computed((prev) => _circularB.value + 1);
final _circularB = computed((prev) => _circularA.value + 1);

// =============================================================================
// 21. avoid_signal_access_after_await - Signal after await
// =============================================================================
class TestAvoidSignalAccessAfterAwait extends StatefulWidget {
  const TestAvoidSignalAccessAfterAwait({super.key});

  @override
  State<TestAvoidSignalAccessAfterAwait> createState() =>
      _TestAvoidSignalAccessAfterAwaitState();
}

class _TestAvoidSignalAccessAfterAwaitState
    extends State<TestAvoidSignalAccessAfterAwait> {
  final _mySignal = signal(0);

  Future<void> _badAsyncMethod() async {
    await Future.delayed(Duration.zero);
    // ❌ VIOLATION: avoid_signal_access_after_await
    print(_mySignal.value);
  }

  @override
  Widget build(BuildContext context) => Container();
}

// =============================================================================
// 22. prefer_async_computed_for_tracked - asyncSignal with signal read
// =============================================================================
final _trackingUserId = signal(1);
// ❌ VIOLATION: prefer_async_computed_for_tracked
final testPreferAsyncComputedForTracked = asyncSignal(() async {
  final id = _trackingUserId.value;
  await Future.delayed(Duration.zero);
  return 'User $id';
});

// =============================================================================
// 23. async_computed_dependency_tracking - Signal read after await in asyncComputed
// =============================================================================
final userId = signal(1);
final testAsyncComputedDependencyTracking = asyncComputed(() async {
  await Future.delayed(Duration.zero);
  // ❌ VIOLATION: async_computed_dependency_tracking
  return 'User ${userId.value}';
});

// =============================================================================
// 24. caution_signal_in_init_state - Signal access in initState
// =============================================================================
class TestCautionSignalInInitState extends StatefulWidget {
  const TestCautionSignalInInitState({super.key});

  @override
  State<TestCautionSignalInInitState> createState() =>
      _TestCautionSignalInInitStateState();
}

class _TestCautionSignalInInitStateState
    extends State<TestCautionSignalInInitState> {
  final _counter = signal(0);

  @override
  void initState() {
    super.initState();
    // ❌ VIOLATION: caution_signal_in_init_state
    print('Counter: ${_counter.value}');
  }

  @override
  Widget build(BuildContext context) => Container();
}

// =============================================================================
// 25. avoid_set_state_with_signals - setState with signal update
// =============================================================================
class TestAvoidSetStateWithSignals extends StatefulWidget {
  const TestAvoidSetStateWithSignals({super.key});

  @override
  State<TestAvoidSetStateWithSignals> createState() =>
      _TestAvoidSetStateWithSignalsState();
}

class _TestAvoidSetStateWithSignalsState
    extends State<TestAvoidSetStateWithSignals> {
  final _counter = signal(0);

  void _badIncrement() {
    // ❌ VIOLATION: avoid_set_state_with_signals
    setState(() {
      _counter.value++;
    });
  }

  @override
  Widget build(BuildContext context) => Container();
}

// =============================================================================
// 26. unnecessary_untrack - Unnecessary untrack
// =============================================================================
void testUnnecessaryUntrack() {
  // ❌ VIOLATION: unnecessary_untrack
  untrack(() {
    print('No reactive code here');
  });
}

// =============================================================================
// 27. prefer_watch_over_effect_for_ui - Effect for UI
// =============================================================================
// Similar to prefer_watch_over_effect_in_widget

// =============================================================================
// 28. hooks_outside_hook_widget - Hooks in non-HookWidget
// =============================================================================
class TestHooksOutsideHookWidget extends StatelessWidget {
  const TestHooksOutsideHookWidget({super.key});

  @override
  Widget build(BuildContext context) {
    // ❌ VIOLATION: hooks_outside_hook_widget
    final count = useSignal(0);
    return Text('$count');
  }
}

// =============================================================================
// 29. conditional_hook_call - Hook in conditional
// =============================================================================
class TestConditionalHookCall extends HookWidget {
  final bool showCounter;
  const TestConditionalHookCall({super.key, this.showCounter = true});

  @override
  Widget build(BuildContext context) {
    if (showCounter) {
      // ❌ VIOLATION: conditional_hook_call
      final count = useSignal(0);
      return Text('$count');
    }
    return const Text('No counter');
  }
}

// =============================================================================
// 30. hook_in_callback - Hook in callback
// =============================================================================
class TestHookInCallback extends HookWidget {
  const TestHookInCallback({super.key});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        // ❌ VIOLATION: hook_in_callback
        final count = useSignal(0);
        print(count);
      },
      child: const Text('Bad'),
    );
  }
}

// =============================================================================
// 31. use_signal_without_watch - useSignal without useWatch
// =============================================================================
class TestUseSignalWithoutWatch extends HookWidget {
  const TestUseSignalWithoutWatch({super.key});

  @override
  Widget build(BuildContext context) {
    // ❌ VIOLATION: use_signal_without_watch
    final counter = useSignal(0);
    // Never watched!
    return const Text('No watch');
  }
}

// =============================================================================
// 32. use_effect_without_dependency - useSignalEffect with no signal access
// =============================================================================
class TestUseEffectWithoutDependency extends HookWidget {
  const TestUseEffectWithoutDependency({super.key});

  @override
  Widget build(BuildContext context) {
    // ❌ VIOLATION: use_effect_without_dependency
    useSignalEffect(() {
      print('No signal accessed');
    });
    return const Text('Test');
  }
}

// =============================================================================
// 33. prefer_use_computed_over_effect - useSignalEffect to derive state
// =============================================================================
class TestPreferUseComputedOverEffect extends HookWidget {
  const TestPreferUseComputedOverEffect({super.key});

  @override
  Widget build(BuildContext context) {
    final a = useSignal(1);
    final derived = useSignal(0);

    // ❌ VIOLATION: prefer_use_computed_over_effect
    useSignalEffect(() {
      derived.value = a.value * 2;
    });

    return Text('${derived.value}');
  }
}

// =============================================================================
// 34. use_debounced_zero_duration - useDebounced with Duration.zero
// =============================================================================
class TestUseDebouncedZeroDuration extends HookWidget {
  const TestUseDebouncedZeroDuration({super.key});

  @override
  Widget build(BuildContext context) {
    final mySignal = useSignal(0);
    // ❌ VIOLATION: use_debounced_zero_duration
    final debounced = useDebounced(mySignal, Duration.zero);
    return Text('$debounced');
  }
}

// =============================================================================
// 35. prefer_use_signal_with_label - useSignal without label (INFO level)
// =============================================================================
// Note: This is INFO level and may be filtered out

// =============================================================================
// 36. use_select_pure_selector - useSelect with impure selector
// =============================================================================
class TestUseSelectPureSelector extends HookWidget {
  const TestUseSelectPureSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final counter = useSignal(0);
    // ❌ VIOLATION: use_select_pure_selector (if selector mutates)
    final selected = useSelect(counter, (v) {
      counter.value = v + 1; // Impure!
      return v;
    });
    return Text('$selected');
  }
}

// =============================================================================
// 37. unnecessary_use_batch - useBatch with single update
// =============================================================================
class TestUnnecessaryUseBatch extends HookWidget {
  const TestUnnecessaryUseBatch({super.key});

  @override
  Widget build(BuildContext context) {
    final counter = useSignal(0);
    // ❌ VIOLATION: unnecessary_use_batch
    useBatch(() {
      counter.value = 1; // Single update, batch unnecessary
    });
    return const Text('Test');
  }
}

// =============================================================================
// 38. unnecessary_use_untrack - useUntrack with no reactive code
// =============================================================================
class TestUnnecessaryUseUntrack extends HookWidget {
  const TestUnnecessaryUseUntrack({super.key});

  @override
  Widget build(BuildContext context) {
    // ❌ VIOLATION: unnecessary_use_untrack
    useUntrack(() {
      print('No reactive code');
    });
    return const Text('Test');
  }
}
