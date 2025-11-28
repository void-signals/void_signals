// ignore_for_file: unused_local_variable, unused_element, unused_field
// ignore_for_file: prefer_const_constructors, prefer_const_declarations
// ignore_for_file: avoid_print, unnecessary_lambdas
// ignore_for_file: dead_code, unreachable_from_main

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:void_signals_flutter/void_signals_flutter.dart';
import 'package:void_signals_hooks/void_signals_hooks.dart';

/// Demo page to test all 38 lint rules and DevTools integration.
///
/// This page intentionally includes various patterns that should trigger
/// lint rules, so you can see them in action.
///
/// ## Lint Rules Categories:
///
/// ### Signal Creation & Management (6 rules)
/// 1. avoid_signal_in_build
/// 2. avoid_signal_creation_in_builder
/// 3. prefer_final_signal
/// 4. prefer_signal_with_label
/// 5. prefer_signal_over_value_notifier
/// 6. prefer_signal_scope_for_di
///
/// ### Reactive Patterns (6 rules)
/// 7. prefer_watch_over_effect_in_widget
/// 8. watch_without_signal_access
/// 9. prefer_computed_over_derived_signal
/// 10. prefer_batch_for_multiple_updates
/// 11. prefer_peek_in_non_reactive
/// 12. prefer_watch_over_effect_for_ui
///
/// ### Effect & Scope Management (5 rules)
/// 13. avoid_nested_effect_scope
/// 14. missing_effect_cleanup
/// 15. missing_scope_dispose
/// 16. avoid_effect_for_ui
/// 17. avoid_effect_in_build
///
/// ### Async & State (7 rules)
/// 18. avoid_signal_access_in_async
/// 19. avoid_async_in_computed
/// 20. avoid_mutating_signal_collection
/// 21. avoid_circular_computed
/// 22. avoid_signal_access_after_await
/// 23. prefer_async_computed_for_tracked
/// 24. async_computed_dependency_tracking
///
/// ### Flutter Integration (3 rules)
/// 25. caution_signal_in_init_state
/// 26. avoid_set_state_with_signals
/// 27. unnecessary_untrack
///
/// ### Hooks Rules (11 rules)
/// 28. hooks_outside_hook_widget
/// 29. conditional_hook_call
/// 30. hook_in_callback
/// 31. use_signal_without_watch
/// 32. use_effect_without_dependency
/// 33. prefer_use_computed_over_effect
/// 34. use_debounced_zero_duration
/// 35. prefer_use_signal_with_label
/// 36. use_select_pure_selector
/// 37. unnecessary_use_batch
/// 38. unnecessary_use_untrack
class LintDemoPage extends StatelessWidget {
  const LintDemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lint Rules Demo (38 Rules)')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          _LintRulesOverview(),
          SizedBox(height: 24),
          _SignalCreationRulesDemo(),
          SizedBox(height: 24),
          _ReactivePatternsRulesDemo(),
          SizedBox(height: 24),
          _EffectScopeRulesDemo(),
          SizedBox(height: 24),
          _AsyncStateRulesDemo(),
          SizedBox(height: 24),
          _FlutterIntegrationRulesDemo(),
          SizedBox(height: 24),
          _HooksRulesDemo(),
        ],
      ),
    );
  }
}

/// Overview of all lint rules
class _LintRulesOverview extends StatelessWidget {
  const _LintRulesOverview();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '📋 Lint Rules Overview',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            const Text(
              'This page demonstrates all 38 lint rules in void_signals_lint.\n'
              'Each section contains intentional violations (commented out) that you can uncomment to test.',
            ),
            const SizedBox(height: 8),
            _buildCategoryChip('Signal Creation & Management', 6),
            _buildCategoryChip('Reactive Patterns', 6),
            _buildCategoryChip('Effect & Scope Management', 5),
            _buildCategoryChip('Async & State', 7),
            _buildCategoryChip('Flutter Integration', 3),
            _buildCategoryChip('Hooks Rules', 11),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String name, int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Chip(
        label: Text('$name ($count rules)'),
        backgroundColor: Colors.blue.shade50,
      ),
    );
  }
}

// =============================================================================
// SECTION 1: Signal Creation & Management (6 rules)
// =============================================================================

class _SignalCreationRulesDemo extends StatefulWidget {
  const _SignalCreationRulesDemo();

  @override
  State<_SignalCreationRulesDemo> createState() =>
      _SignalCreationRulesDemoState();
}

class _SignalCreationRulesDemoState extends State<_SignalCreationRulesDemo> {
  // ✅ GOOD: Final signal declaration
  late final Signal<int> _counter = signal(0);

  // ❌ BAD: prefer_final_signal - Non-final signal
  // Uncomment to test:
  // late Signal<int> _mutableSignal = signal(0);

  // ❌ BAD: prefer_signal_with_label - Signal without label
  // Uncomment to test:
  // late final Signal<int> _noLabel = signal(0);

  @override
  Widget build(BuildContext context) {
    // ❌ BAD: avoid_signal_in_build - Creating signal in build
    // Uncomment to test:
    // final badSignal = signal(0);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '1️⃣ Signal Creation & Management (6 rules)',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            _buildRuleItem(
              'avoid_signal_in_build',
              'Prevents creating signals in build()',
              '// final badSignal = signal(0);',
            ),
            _buildRuleItem(
              'avoid_signal_creation_in_builder',
              'Prevents signal creation in SignalBuilder',
              '// SignalBuilder(signal: signal(0), ...)',
            ),
            _buildRuleItem(
              'prefer_final_signal',
              'Signals should be final',
              '// late Signal<int> _mutable = signal(0);',
            ),
            _buildRuleItem(
              'prefer_signal_with_label',
              'Suggests adding debug labels',
              '// signal(0) → signal(0, label: "name")',
            ),
            _buildRuleItem(
              'prefer_signal_over_value_notifier',
              'Suggests Signal over ValueNotifier',
              '// ValueNotifier<int>(0) → signal(0)',
            ),
            _buildRuleItem(
              'prefer_signal_scope_for_di',
              'Suggests SignalScope for DI patterns',
              '// Provider<Signal<T>> → SignalScope',
            ),

            // ❌ BAD: avoid_signal_creation_in_builder - Signal in builder
            // Uncomment to test:
            // SignalBuilder(
            //   signal: signal(0), // ERROR: Don't create signal here
            //   builder: (context, value, _) => Text('$value'),
            // ),

            // ❌ BAD: prefer_signal_over_value_notifier
            // Uncomment to test:
            // final notifier = ValueNotifier<int>(0);
          ],
        ),
      ),
    );
  }

  Widget _buildRuleItem(String rule, String description, String example) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            rule,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontWeight: FontWeight.bold,
              color: Colors.deepOrange,
            ),
          ),
          Text(description, style: const TextStyle(fontSize: 12)),
          Text(
            example,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 10,
              color: Colors.grey.shade600,
            ),
          ),
          const Divider(),
        ],
      ),
    );
  }
}

// =============================================================================
// SECTION 2: Reactive Patterns (5 rules)
// =============================================================================

class _ReactivePatternsRulesDemo extends StatefulWidget {
  const _ReactivePatternsRulesDemo();

  @override
  State<_ReactivePatternsRulesDemo> createState() =>
      _ReactivePatternsRulesDemoState();
}

class _ReactivePatternsRulesDemoState
    extends State<_ReactivePatternsRulesDemo> {
  late final Signal<int> _a = signal(1);
  late final Signal<int> _b = signal(2);
  late final Signal<int> _c = signal(3);

  // ✅ GOOD: Computed for derived state
  late final Computed<int> _sum = computed((prev) => _a.value + _b.value);

  // ❌ BAD: prefer_computed_over_derived_signal - Using effect to derive state
  // Uncomment to test:
  // late final Signal<int> _derivedBad = signal(0);
  // void _setupBadDerived() {
  //   effect(() {
  //     _derivedBad.value = _a.value + _b.value; // Should use computed
  //   });
  // }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '2️⃣ Reactive Patterns (6 rules)',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            _buildRuleItem(
              'prefer_watch_over_effect_in_widget',
              'Suggests Watch widget over effects in widgets',
              '// effect(() { setState... }) → Watch(...)',
            ),
            _buildRuleItem(
              'watch_without_signal_access',
              'Warns when Watch doesn\'t access signals',
              '// Watch(builder: (_) => Text("static"))',
            ),
            _buildRuleItem(
              'prefer_computed_over_derived_signal',
              'Suggests computed for derived state',
              '// effect(() { derived.value = a.value + b.value })',
            ),
            _buildRuleItem(
              'prefer_batch_for_multiple_updates',
              'Suggests batch for multiple updates',
              '// a.value = 1; b.value = 2; → batch(() { ... })',
            ),
            _buildRuleItem(
              'prefer_peek_in_non_reactive',
              'Suggests peek() in non-reactive contexts',
              '// onPressed: () { print(signal.value) } → .peek()',
            ),
            _buildRuleItem(
              'prefer_watch_over_effect_for_ui',
              'Suggests Watch widget for UI updates',
              '// effect for UI → Watch/SignalBuilder',
            ),

            // ❌ BAD: prefer_batch_for_multiple_updates
            // Uncomment to test:
            // ElevatedButton(
            //   onPressed: () {
            //     _a.value = 10;
            //     _b.value = 20;
            //     _c.value = 30; // Should use batch()
            //   },
            //   child: Text('Bad Multiple Updates'),
            // ),

            // ❌ BAD: watch_without_signal_access
            // Uncomment to test:
            // Watch(
            //   builder: (_) => Text('No signal accessed'),
            // ),
          ],
        ),
      ),
    );
  }

  Widget _buildRuleItem(String rule, String description, String example) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            rule,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
          Text(description, style: const TextStyle(fontSize: 12)),
          Text(
            example,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 10,
              color: Colors.grey.shade600,
            ),
          ),
          const Divider(),
        ],
      ),
    );
  }
}

// =============================================================================
// SECTION 3: Effect & Scope Management (5 rules)
// =============================================================================

class _EffectScopeRulesDemo extends StatefulWidget {
  const _EffectScopeRulesDemo();

  @override
  State<_EffectScopeRulesDemo> createState() => _EffectScopeRulesDemoState();
}

class _EffectScopeRulesDemoState extends State<_EffectScopeRulesDemo> {
  late final Signal<int> _counter = signal(0);

  // ✅ GOOD: Proper scope management
  late final EffectScope _scope;

  @override
  void initState() {
    super.initState();
    _scope = effectScope(() {
      effect(() {
        debugPrint('Counter: ${_counter.value}');
      });
    });
  }

  @override
  void dispose() {
    _scope.stop(); // ✅ GOOD: Stop scope on dispose
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ❌ BAD: avoid_effect_in_build - Effect in build
    // Uncomment to test:
    // effect(() {
    //   print('This effect is in build!');
    // });

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '3️⃣ Effect & Scope Management (5 rules)',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            _buildRuleItem(
              'avoid_nested_effect_scope',
              'Prevents nested effect scopes',
              '// effectScope(() { effectScope(() {...}) })',
            ),
            _buildRuleItem(
              'missing_effect_cleanup',
              'Ensures effects return cleanup',
              '// effect(() { subscribe() }) → return unsubscribe',
            ),
            _buildRuleItem(
              'missing_scope_dispose',
              'Ensures EffectScopes are disposed',
              '// dispose() must call scope.stop()',
            ),
            _buildRuleItem(
              'avoid_effect_for_ui',
              'Warns against effects for UI updates',
              '// effect(() { setState(...) }) → Watch',
            ),
            _buildRuleItem(
              'avoid_effect_in_build',
              'Prevents effect() in build()',
              '// build() { effect(...) } // ERROR',
            ),

            // ❌ BAD: avoid_nested_effect_scope
            // Uncomment to test:
            // void _badNestedScope() {
            //   effectScope(() {
            //     effectScope(() { // ERROR: Nested scope
            //       effect(() {});
            //     });
            //   });
            // }

            // ❌ BAD: missing_effect_cleanup
            // Uncomment to test:
            // void _badNoCleanup() {
            //   effect(() {
            //     final subscription = stream.listen((_) {});
            //     // Missing: return () => subscription.cancel();
            //   });
            // }
          ],
        ),
      ),
    );
  }

  Widget _buildRuleItem(String rule, String description, String example) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            rule,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontWeight: FontWeight.bold,
              color: Colors.purple,
            ),
          ),
          Text(description, style: const TextStyle(fontSize: 12)),
          Text(
            example,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 10,
              color: Colors.grey.shade600,
            ),
          ),
          const Divider(),
        ],
      ),
    );
  }
}

// =============================================================================
// SECTION 4: Async & State (7 rules) - Including NEW rules
// =============================================================================

class _AsyncStateRulesDemo extends StatefulWidget {
  const _AsyncStateRulesDemo();

  @override
  State<_AsyncStateRulesDemo> createState() => _AsyncStateRulesDemoState();
}

class _AsyncStateRulesDemoState extends State<_AsyncStateRulesDemo> {
  late final Signal<int> _userId = signal(1);
  late final Signal<List<int>> _items = signal([1, 2, 3]);

  // ✅ GOOD: Use asyncComputed for async operations with tracked dependencies
  late final AsyncComputed<String> _userData = asyncComputed(() async {
    final id = _userId.value; // ✅ Signal read BEFORE await
    await Future.delayed(const Duration(milliseconds: 100));
    return 'User $id data';
  });

  // ❌ BAD: avoid_async_in_computed - Async in regular computed
  // Uncomment to test:
  // late final Computed<Future<String>> _badAsync = computed((prev) async {
  //   await Future.delayed(Duration.zero);
  //   return 'Bad';
  // });

  // ❌ BAD: avoid_circular_computed - Circular dependency
  // Uncomment to test:
  // late final Computed<int> _circA = computed((prev) => _circB.value + 1);
  // late final Computed<int> _circB = computed((prev) => _circA.value + 1);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '4️⃣ Async & State (7 rules) ⭐ NEW',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            _buildRuleItem(
              'avoid_signal_access_in_async',
              'Warns about stale values after await',
              '// async () { await x; signal.value } // stale!',
              Colors.red,
            ),
            _buildRuleItem(
              'avoid_async_in_computed',
              'Prevents async in regular computed',
              '// computed((p) async { ... }) → asyncComputed',
              Colors.red,
            ),
            _buildRuleItem(
              'avoid_mutating_signal_collection',
              'Prevents direct collection mutation',
              '// items.value.add(x) → items.value = [..., x]',
              Colors.red,
            ),
            _buildRuleItem(
              'avoid_circular_computed',
              'Detects circular dependencies',
              '// a = computed(() => b.value); b = computed(() => a.value)',
              Colors.red,
            ),
            _buildRuleItem(
              'avoid_signal_access_after_await',
              'Warns about signal access after await',
              '// await x; final v = signal.value; // stale',
              Colors.red,
            ),
            _buildRuleItem(
              'prefer_async_computed_for_tracked ⭐',
              'Suggests asyncComputed when signals are read',
              '// asyncSignal() { signal.value } → asyncComputed',
              Colors.orange,
            ),
            _buildRuleItem(
              'async_computed_dependency_tracking ⭐',
              'Warns about signal reads after await in asyncComputed',
              '// asyncComputed { await x; signal.value } // not tracked!',
              Colors.orange,
            ),

            const SizedBox(height: 8),
            const Text(
              '⭐ = New rules for async support',
              style: TextStyle(fontStyle: FontStyle.italic, fontSize: 12),
            ),

            // ❌ BAD: avoid_mutating_signal_collection
            // Uncomment to test:
            // ElevatedButton(
            //   onPressed: () {
            //     _items.value.add(4); // ERROR: Direct mutation
            //   },
            //   child: Text('Bad Mutation'),
            // ),

            // ❌ BAD: prefer_async_computed_for_tracked
            // Uncomment to test:
            // final badAsyncSignal = asyncSignal(() async {
            //   final id = _userId.value; // Should use asyncComputed
            //   return await fetchData(id);
            // });

            // ❌ BAD: async_computed_dependency_tracking
            // Uncomment to test:
            // asyncComputed((prev) async {
            //   await Future.delayed(Duration.zero);
            //   return _userId.value; // ERROR: Read after await not tracked!
            // });
          ],
        ),
      ),
    );
  }

  Widget _buildRuleItem(
    String rule,
    String description,
    String example,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            rule,
            style: TextStyle(
              fontFamily: 'monospace',
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(description, style: const TextStyle(fontSize: 12)),
          Text(
            example,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 10,
              color: Colors.grey.shade600,
            ),
          ),
          const Divider(),
        ],
      ),
    );
  }
}

// =============================================================================
// SECTION 5: Flutter Integration (4 rules)
// =============================================================================

class _FlutterIntegrationRulesDemo extends StatefulWidget {
  const _FlutterIntegrationRulesDemo();

  @override
  State<_FlutterIntegrationRulesDemo> createState() =>
      _FlutterIntegrationRulesDemoState();
}

class _FlutterIntegrationRulesDemoState
    extends State<_FlutterIntegrationRulesDemo> {
  late final Signal<int> _counter = signal(0);

  @override
  void initState() {
    super.initState();
    // ❌ BAD: caution_signal_in_init_state - Reading signal in initState
    // Uncomment to test:
    // print('Counter value: ${_counter.value}');
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '5️⃣ Flutter Integration (3 rules)',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            _buildRuleItem(
              'caution_signal_in_init_state',
              'Cautions about signal access in initState',
              '// initState() { signal.value } // widget not mounted',
            ),
            _buildRuleItem(
              'avoid_set_state_with_signals',
              'Warns against unnecessary setState',
              '// effect(() { setState(() {}) }) → Watch',
            ),
            _buildRuleItem(
              'unnecessary_untrack',
              'Flags unnecessary untrack calls',
              '// untrack(() { nonReactiveCode }) // unnecessary',
            ),

            // ❌ BAD: avoid_set_state_with_signals
            // Uncomment to test:
            // effect(() {
            //   final value = _counter.value;
            //   setState(() {}); // ERROR: Use Watch instead
            // });

            // ❌ BAD: unnecessary_untrack
            // Uncomment to test:
            // untrack(() {
            //   print('No reactive code here'); // Unnecessary untrack
            // });
          ],
        ),
      ),
    );
  }

  Widget _buildRuleItem(String rule, String description, String example) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            rule,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
          Text(description, style: const TextStyle(fontSize: 12)),
          Text(
            example,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 10,
              color: Colors.grey.shade600,
            ),
          ),
          const Divider(),
        ],
      ),
    );
  }
}

// =============================================================================
// SECTION 6: Hooks Rules (11 rules)
// =============================================================================

class _HooksRulesDemo extends HookWidget {
  const _HooksRulesDemo();

  @override
  Widget build(BuildContext context) {
    // ✅ GOOD: Hooks at top level of build
    final counter = useSignal(0);
    final doubled = useComputed((prev) => counter.value * 2);
    final counterValue = useWatch(counter);

    // ✅ GOOD: useSignalEffect with signal access
    useSignalEffect(() {
      debugPrint('Hook counter: ${counter.value}');
    });

    // ❌ BAD: use_debounced_zero_duration
    // Uncomment to test:
    // useDebounced(Duration.zero, () => print('bad'));

    // ❌ BAD: conditional_hook_call
    // Uncomment to test:
    // if (counterValue > 5) {
    //   final badConditional = useSignal(0); // ERROR
    // }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '6️⃣ Hooks Rules (11 rules)',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            _buildRuleItem(
              'hooks_outside_hook_widget',
              'Ensures hooks are in HookWidget.build()',
              '// StatelessWidget: useSignal() // ERROR',
              Colors.red,
            ),
            _buildRuleItem(
              'conditional_hook_call',
              'Prevents hooks in conditionals/loops',
              '// if (x) { useSignal() } // ERROR',
              Colors.red,
            ),
            _buildRuleItem(
              'hook_in_callback',
              'Prevents hooks inside callbacks',
              '// onPressed: () { useSignal() } // ERROR',
              Colors.red,
            ),
            _buildRuleItem(
              'use_signal_without_watch',
              'Warns when useSignal is not watched',
              '// final s = useSignal(); // never useWatch(s)',
              Colors.orange,
            ),
            _buildRuleItem(
              'use_effect_without_dependency',
              'Warns when effect has no deps',
              '// useSignalEffect(() { print("static") })',
              Colors.yellow.shade800,
            ),
            _buildRuleItem(
              'prefer_use_computed_over_effect',
              'Suggests useComputed for derived values',
              '// useSignalEffect(() { d.value = a + b })',
              Colors.yellow.shade800,
            ),
            _buildRuleItem(
              'use_debounced_zero_duration',
              'Warns against zero duration debounce',
              '// useDebounced(Duration.zero, fn)',
              Colors.orange,
            ),
            _buildRuleItem(
              'prefer_use_signal_with_label',
              'Suggests debug labels for hooks',
              '// useSignal(0) → useSignal(0, label: "x")',
              Colors.yellow.shade800,
            ),
            _buildRuleItem(
              'use_select_pure_selector',
              'Ensures useSelect selector is pure',
              '// useSelect(signal, (v) { signal.value = x })',
              Colors.orange,
            ),
            _buildRuleItem(
              'unnecessary_use_batch',
              'Flags unnecessary useBatch',
              '// useBatch(() { singleUpdate }) // unnecessary',
              Colors.yellow.shade800,
            ),
            _buildRuleItem(
              'unnecessary_use_untrack',
              'Flags unnecessary useUntrack',
              '// useUntrack(() { noReactive }) // unnecessary',
              Colors.yellow.shade800,
            ),

            const SizedBox(height: 12),
            Text('Counter: $counterValue, Doubled: ${doubled.value}'),
            ElevatedButton(
              onPressed: () => counter.value++,
              child: const Text('Increment'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRuleItem(
    String rule,
    String description,
    String example,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            rule,
            style: TextStyle(
              fontFamily: 'monospace',
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(description, style: const TextStyle(fontSize: 12)),
          Text(
            example,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 10,
              color: Colors.grey.shade600,
            ),
          ),
          const Divider(),
        ],
      ),
    );
  }
}

// =============================================================================
// TEST CLASSES - Uncomment to test specific lint rules
// =============================================================================

// ❌ Test: hooks_outside_hook_widget
// class BadHooksInStateless extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     final count = useSignal(0); // ERROR: Not in HookWidget
//     return Text('$count');
//   }
// }

// ❌ Test: hook_in_callback
// class BadHookInCallback extends HookWidget {
//   @override
//   Widget build(BuildContext context) {
//     return ElevatedButton(
//       onPressed: () {
//         final count = useSignal(0); // ERROR: Hook in callback
//       },
//       child: const Text('Bad'),
//     );
//   }
// }

// ❌ Test: missing_scope_dispose
// class BadMissingScopeDispose extends StatefulWidget {
//   @override
//   State<BadMissingScopeDispose> createState() => _BadMissingScopeDisposeState();
// }
// class _BadMissingScopeDisposeState extends State<BadMissingScopeDispose> {
//   late final EffectScope _scope;
//
//   @override
//   void initState() {
//     super.initState();
//     _scope = effectScope(() { effect(() {}); });
//   }
//
//   @override
//   void dispose() {
//     // ERROR: Missing _scope.stop()
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) => Container();
// }

// ❌ Test: avoid_signal_access_in_async
// void badAsyncSignalAccess() async {
//   final mySignal = signal(0);
//   await Future.delayed(Duration(seconds: 1));
//   print(mySignal.value); // ERROR: Stale value after await
// }

// ❌ Test: avoid_async_in_computed
// Computed<Future<int>> badAsyncComputed() {
//   return computed((prev) async {
//     await Future.delayed(Duration.zero);
//     return 42; // ERROR: Use asyncComputed instead
//   });
// }

// ❌ Test: prefer_async_computed_for_tracked
// AsyncSignal<String> badAsyncSignalWithTracking() {
//   final userId = signal(1);
//   return asyncSignal(() async {
//     final id = userId.value; // ERROR: Use asyncComputed for tracking
//     return 'User $id';
//   });
// }

// ❌ Test: async_computed_dependency_tracking
// AsyncComputed<String> badAsyncComputedTracking() {
//   final userId = signal(1);
//   return asyncComputed((prev) async {
//     await Future.delayed(Duration.zero);
//     return 'User ${userId.value}'; // ERROR: Read after await not tracked
//   });
// }
