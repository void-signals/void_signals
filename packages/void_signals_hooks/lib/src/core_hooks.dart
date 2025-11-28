import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:void_signals_flutter/void_signals_flutter.dart';

// =============================================================================
// Core Hooks
//
// These hooks integrate void_signals with flutter_hooks for a hook-based
// reactive state management experience.
// =============================================================================

/// Creates and memoizes a [Signal].
///
/// The signal remains the same throughout the widget's lifecycle, similar
/// to how `useState` works in React hooks.
///
/// Example:
/// ```dart
/// class CounterWidget extends HookWidget {
///   @override
///   Widget build(BuildContext context) {
///     final count = useSignal(0);
///     final countValue = useWatch(count);
///
///     return Column(
///       children: [
///         Text('Count: $countValue'),
///         ElevatedButton(
///           onPressed: () => count.value++,
///           child: const Text('Increment'),
///         ),
///       ],
///     );
///   }
/// }
/// ```
Signal<T> useSignal<T>(T initialValue) {
  return use(_SignalHook(initialValue));
}

/// Creates and memoizes a [Computed] value.
///
/// The computed value is derived from other signals and automatically
/// updates when its dependencies change.
///
/// Example:
/// ```dart
/// class PriceWidget extends HookWidget {
///   @override
///   Widget build(BuildContext context) {
///     final price = useSignal(100.0);
///     final quantity = useSignal(2);
///     final total = useComputed((prev) => price.value * quantity.value);
///
///     return Text('Total: \$${useWatch(total).toStringAsFixed(2)}');
///   }
/// }
/// ```
Computed<T> useComputed<T>(T Function(T? prev) computation) {
  return use(_ComputedHook<T>(computation));
}

/// Creates a simple computed value without needing the previous value.
///
/// This is a convenience wrapper around [useComputed] for cases where
/// you don't need access to the previous computed value.
///
/// Example:
/// ```dart
/// final firstName = useSignal('John');
/// final lastName = useSignal('Doe');
/// final fullName = useComputedSimple(() => '${firstName.value} ${lastName.value}');
/// ```
Computed<T> useComputedSimple<T>(T Function() computation) {
  return use(_ComputedHook<T>((prev) => computation()));
}

/// Creates an effect that re-runs when dependencies change.
///
/// The effect runs immediately on first build and then whenever any
/// signals accessed within it change. Optionally, provide [keys] to
/// recreate the effect when those keys change.
///
/// Example:
/// ```dart
/// class LoggingWidget extends HookWidget {
///   @override
///   Widget build(BuildContext context) {
///     final count = useSignal(0);
///
///     // This effect runs whenever count changes
///     useSignalEffect(() {
///       print('Count changed to: ${count.value}');
///     });
///
///     return ElevatedButton(
///       onPressed: () => count.value++,
///       child: const Text('Increment'),
///     );
///   }
/// }
/// ```
void useSignalEffect(void Function() fn, [List<Object?>? keys]) {
  use(_EffectHook(fn, keys));
}

/// Watches a signal and triggers rebuild when it changes.
///
/// This is the primary way to reactively read a signal's value in a
/// HookWidget. The widget will automatically rebuild when the signal
/// value changes.
///
/// Example:
/// ```dart
/// class CounterDisplay extends HookWidget {
///   final Signal<int> count;
///   const CounterDisplay({required this.count});
///
///   @override
///   Widget build(BuildContext context) {
///     final value = useWatch(count);
///     return Text('Count: $value');
///   }
/// }
/// ```
T useWatch<T>(Signal<T> signal) {
  return use(_WatchHook<T>(signal));
}

/// Watches a computed value and triggers rebuild when it changes.
///
/// Similar to [useWatch], but for [Computed] values. The widget rebuilds
/// when the computed value changes.
///
/// Example:
/// ```dart
/// class TotalDisplay extends HookWidget {
///   final Computed<double> total;
///   const TotalDisplay({required this.total});
///
///   @override
///   Widget build(BuildContext context) {
///     final value = useWatchComputed(total);
///     return Text('Total: \$${value.toStringAsFixed(2)}');
///   }
/// }
/// ```
T useWatchComputed<T>(Computed<T> computed) {
  return use(_WatchComputedHook<T>(computed));
}

/// Creates an effect scope that groups multiple effects together.
///
/// The scope is automatically stopped when the widget is disposed.
/// Useful for creating multiple related effects that should be
/// managed as a unit.
///
/// Example:
/// ```dart
/// class ScopedEffectsWidget extends HookWidget {
///   @override
///   Widget build(BuildContext context) {
///     final scope = useEffectScope(() {
///       // All effects created here are part of this scope
///     });
///
///     return const Text('Scoped effects active');
///   }
/// }
/// ```
EffectScope useEffectScope([void Function()? setup]) {
  return use(_EffectScopeHook(setup));
}

/// Creates a signal and automatically watches it, returning a (value, setValue) tuple.
///
/// This provides a React-like useState experience where you get both the
/// current value and a setter function.
///
/// Example:
/// ```dart
/// class ToggleWidget extends HookWidget {
///   @override
///   Widget build(BuildContext context) {
///     final (isOn, setIsOn) = useReactive(false);
///
///     return Switch(
///       value: isOn,
///       onChanged: setIsOn,
///     );
///   }
/// }
/// ```
(T, void Function(T)) useReactive<T>(T initialValue) {
  final sig = useSignal(initialValue);
  final value = useWatch(sig);
  return (value, (T v) => sig.value = v);
}

/// Selects part of a signal's value, only rebuilding when the selected value changes.
///
/// This is useful for performance optimization when you only need a
/// derived value from a complex signal.
///
/// Example:
/// ```dart
/// class UserNameDisplay extends HookWidget {
///   final Signal<User> user;
///   const UserNameDisplay({required this.user});
///
///   @override
///   Widget build(BuildContext context) {
///     // Only rebuilds when user.name changes, not when age or other fields change
///     final name = useSelect(user, (u) => u.name);
///     return Text('Hello, $name!');
///   }
/// }
/// ```
R useSelect<T, R>(Signal<T> signal, R Function(T value) selector) {
  return use(_SelectHook<T, R>(signal, selector));
}

/// Selects part of a computed value, only rebuilding when the selected value changes.
///
/// Example:
/// ```dart
/// final users = computed((_) => fetchUsers());
/// final count = useSelectComputed(users, (list) => list.length);
/// ```
R useSelectComputed<T, R>(Computed<T> computed, R Function(T value) selector) {
  return use(_SelectComputedHook<T, R>(computed, selector));
}

/// Batch updates multiple signals, memoized by the provided keys.
///
/// This is useful for performing multiple signal updates that should
/// only trigger a single re-render.
///
/// Example:
/// ```dart
/// class FormWidget extends HookWidget {
///   @override
///   Widget build(BuildContext context) {
///     final firstName = useSignal('');
///     final lastName = useSignal('');
///
///     useBatch(() {
///       firstName.value = 'John';
///       lastName.value = 'Doe';
///     }, []);
///
///     return const Text('Form initialized');
///   }
/// }
/// ```
T useBatch<T>(T Function() fn, [List<Object?>? keys]) {
  return useMemoized(() => batch(fn), keys ?? const []);
}

/// Executes a function without tracking dependencies.
///
/// This is useful when you want to read a signal's value without
/// creating a reactive dependency.
///
/// Example:
/// ```dart
/// class AnalyticsWidget extends HookWidget {
///   @override
///   Widget build(BuildContext context) {
///     final count = useSignal(0);
///
///     useSignalEffect(() {
///       // Read count reactively (creates dependency)
///       print('Count: ${count.value}');
///
///       // Read another value without creating dependency
///       final timestamp = useUntrack(() => DateTime.now());
///       print('Logged at: $timestamp');
///     });
///
///     return const Text('Analytics active');
///   }
/// }
/// ```
T useUntrack<T>(T Function() fn) {
  return untrack(fn);
}

/// Creates a signal from a Stream.
///
/// The signal will update whenever the stream emits a new value.
/// The stream subscription is automatically cleaned up when the
/// widget is disposed.
///
/// Example:
/// ```dart
/// class StreamWidget extends HookWidget {
///   @override
///   Widget build(BuildContext context) {
///     final messagesStream = useStream();
///     final messages = useSignalFromStream(
///       messagesStream,
///       initialValue: <Message>[],
///     );
///
///     return ListView.builder(
///       itemCount: useWatch(messages).length,
///       itemBuilder: (context, index) => MessageTile(messages.value[index]),
///     );
///   }
/// }
/// ```
Signal<T> useSignalFromStream<T>(Stream<T> stream, {required T initialValue}) {
  return use(_StreamSignalHook<T>(stream, initialValue));
}

/// Creates a signal from a Future.
///
/// The signal starts with the initial value and updates when the
/// future completes.
///
/// Example:
/// ```dart
/// class UserWidget extends HookWidget {
///   @override
///   Widget build(BuildContext context) {
///     final userFuture = useMemoized(() => fetchUser());
///     final user = useSignalFromFuture(
///       userFuture,
///       initialValue: null,
///     );
///
///     final userData = useWatch(user);
///     if (userData == null) {
///       return const CircularProgressIndicator();
///     }
///     return Text('Hello, ${userData.name}!');
///   }
/// }
/// ```
Signal<T> useSignalFromFuture<T>(Future<T> future, {required T initialValue}) {
  return use(_FutureSignalHook<T>(future, initialValue));
}

// =============================================================================
// Hook Implementations
// =============================================================================

class _SignalHook<T> extends Hook<Signal<T>> {
  const _SignalHook(this.initialValue);
  final T initialValue;

  @override
  _SignalHookState<T> createState() => _SignalHookState<T>();
}

class _SignalHookState<T> extends HookState<Signal<T>, _SignalHook<T>> {
  late Signal<T> _signal;

  @override
  void initHook() {
    _signal = signal(hook.initialValue);
    _trackForDevTools();
  }

  void _trackForDevTools() {
    if (kDebugMode) {
      VoidSignalsDebugService.tracker.trackSignal(
        _signal,
        label: 'useSignal<$T>',
      );
    }
  }

  @override
  Signal<T> build(BuildContext context) => _signal;

  @override
  String get debugLabel => 'useSignal<$T>';
}

class _ComputedHook<T> extends Hook<Computed<T>> {
  const _ComputedHook(this.computation);
  final T Function(T? prev) computation;

  @override
  _ComputedHookState<T> createState() => _ComputedHookState<T>();
}

class _ComputedHookState<T> extends HookState<Computed<T>, _ComputedHook<T>> {
  late Computed<T> _computed;

  @override
  void initHook() {
    _computed = computed<T>(hook.computation);
    _trackForDevTools();
  }

  void _trackForDevTools() {
    if (kDebugMode) {
      VoidSignalsDebugService.tracker.trackComputed(
        _computed,
        label: 'useComputed<$T>',
      );
    }
  }

  @override
  Computed<T> build(BuildContext context) => _computed;

  @override
  String get debugLabel => 'useComputed<$T>';
}

class _EffectHook extends Hook<void> {
  const _EffectHook(this.fn, this.keys);
  final void Function() fn;
  final List<Object?>? keys;

  @override
  _EffectHookState createState() => _EffectHookState();
}

class _EffectHookState extends HookState<void, _EffectHook> {
  Effect? _effect;

  @override
  void initHook() {
    _effect = effect(hook.fn);
    _trackForDevTools();
  }

  void _trackForDevTools() {
    if (kDebugMode && _effect != null) {
      VoidSignalsDebugService.tracker.trackEffect(
        _effect!,
        label: 'useSignalEffect',
      );
    }
  }

  @override
  void didUpdateHook(_EffectHook oldHook) {
    if (hook.keys != null && oldHook.keys != null) {
      if (!_listEquals(hook.keys!, oldHook.keys!)) {
        _effect?.stop();
        _effect = effect(hook.fn);
        _trackForDevTools();
      }
    }
  }

  @override
  void build(BuildContext context) {}

  @override
  void dispose() {
    _effect?.stop();
    _effect = null;
  }

  @override
  String get debugLabel => 'useSignalEffect';
}

class _WatchHook<T> extends Hook<T> {
  const _WatchHook(this.signal);
  final Signal<T> signal;

  @override
  _WatchHookState<T> createState() => _WatchHookState<T>();
}

class _WatchHookState<T> extends HookState<T, _WatchHook<T>> {
  Effect? _effect;
  late T _value;

  @override
  void initHook() {
    _value = hook.signal.value;
    _subscribe();
    _trackForDevTools();
  }

  void _trackForDevTools() {
    if (kDebugMode) {
      VoidSignalsDebugService.tracker.trackSignal(
        hook.signal,
        label: 'useWatch<$T>',
      );
    }
  }

  void _subscribe() {
    _effect = effect(() {
      final newValue = hook.signal.value;
      if (_value != newValue) {
        _value = newValue;
        setState(() {});
      }
    });
  }

  @override
  void didUpdateHook(_WatchHook<T> oldHook) {
    if (!identical(oldHook.signal, hook.signal)) {
      _effect?.stop();
      _value = hook.signal.value;
      _subscribe();
    }
  }

  @override
  T build(BuildContext context) => _value;

  @override
  void dispose() {
    _effect?.stop();
    _effect = null;
  }

  @override
  String get debugLabel => 'useWatch<$T>';
}

class _WatchComputedHook<T> extends Hook<T> {
  const _WatchComputedHook(this.computed);
  final Computed<T> computed;

  @override
  _WatchComputedHookState<T> createState() => _WatchComputedHookState<T>();
}

class _WatchComputedHookState<T> extends HookState<T, _WatchComputedHook<T>> {
  Effect? _effect;
  late T _value;

  @override
  void initHook() {
    _value = hook.computed.value;
    _subscribe();
    _trackForDevTools();
  }

  void _trackForDevTools() {
    if (kDebugMode) {
      VoidSignalsDebugService.tracker.trackComputed(
        hook.computed,
        label: 'useWatchComputed<$T>',
      );
    }
  }

  void _subscribe() {
    _effect = effect(() {
      final newValue = hook.computed.value;
      if (_value != newValue) {
        _value = newValue;
        setState(() {});
      }
    });
  }

  @override
  void didUpdateHook(_WatchComputedHook<T> oldHook) {
    if (!identical(oldHook.computed, hook.computed)) {
      _effect?.stop();
      _value = hook.computed.value;
      _subscribe();
    }
  }

  @override
  T build(BuildContext context) => _value;

  @override
  void dispose() {
    _effect?.stop();
    _effect = null;
  }

  @override
  String get debugLabel => 'useWatchComputed<$T>';
}

class _EffectScopeHook extends Hook<EffectScope> {
  const _EffectScopeHook(this.setup);
  final void Function()? setup;

  @override
  _EffectScopeHookState createState() => _EffectScopeHookState();
}

class _EffectScopeHookState extends HookState<EffectScope, _EffectScopeHook> {
  late EffectScope _scope;

  @override
  void initHook() {
    _scope = effectScope(() {});
    hook.setup?.call();
  }

  @override
  EffectScope build(BuildContext context) => _scope;

  @override
  void dispose() => _scope.stop();

  @override
  String get debugLabel => 'useEffectScope';
}

class _SelectHook<T, R> extends Hook<R> {
  const _SelectHook(this.signal, this.selector);
  final Signal<T> signal;
  final R Function(T value) selector;

  @override
  _SelectHookState<T, R> createState() => _SelectHookState<T, R>();
}

class _SelectHookState<T, R> extends HookState<R, _SelectHook<T, R>> {
  Effect? _effect;
  late R _selectedValue;

  @override
  void initHook() {
    _selectedValue = hook.selector(hook.signal.value);
    _subscribe();
  }

  void _subscribe() {
    _effect = effect(() {
      final newSelected = hook.selector(hook.signal.value);
      if (_selectedValue != newSelected) {
        _selectedValue = newSelected;
        setState(() {});
      }
    });
  }

  @override
  void didUpdateHook(_SelectHook<T, R> oldHook) {
    if (!identical(oldHook.signal, hook.signal) ||
        !identical(oldHook.selector, hook.selector)) {
      _effect?.stop();
      _selectedValue = hook.selector(hook.signal.value);
      _subscribe();
    }
  }

  @override
  R build(BuildContext context) => _selectedValue;

  @override
  void dispose() {
    _effect?.stop();
    _effect = null;
  }

  @override
  String get debugLabel => 'useSelect<$T, $R>';
}

class _SelectComputedHook<T, R> extends Hook<R> {
  const _SelectComputedHook(this.computed, this.selector);
  final Computed<T> computed;
  final R Function(T value) selector;

  @override
  _SelectComputedHookState<T, R> createState() =>
      _SelectComputedHookState<T, R>();
}

class _SelectComputedHookState<T, R>
    extends HookState<R, _SelectComputedHook<T, R>> {
  Effect? _effect;
  late R _selectedValue;

  @override
  void initHook() {
    _selectedValue = hook.selector(hook.computed.value);
    _subscribe();
  }

  void _subscribe() {
    _effect = effect(() {
      final newSelected = hook.selector(hook.computed.value);
      if (_selectedValue != newSelected) {
        _selectedValue = newSelected;
        setState(() {});
      }
    });
  }

  @override
  void didUpdateHook(_SelectComputedHook<T, R> oldHook) {
    if (!identical(oldHook.computed, hook.computed) ||
        !identical(oldHook.selector, hook.selector)) {
      _effect?.stop();
      _selectedValue = hook.selector(hook.computed.value);
      _subscribe();
    }
  }

  @override
  R build(BuildContext context) => _selectedValue;

  @override
  void dispose() {
    _effect?.stop();
    _effect = null;
  }

  @override
  String get debugLabel => 'useSelectComputed<$T, $R>';
}

class _StreamSignalHook<T> extends Hook<Signal<T>> {
  const _StreamSignalHook(this.stream, this.initialValue);
  final Stream<T> stream;
  final T initialValue;

  @override
  _StreamSignalHookState<T> createState() => _StreamSignalHookState<T>();
}

class _StreamSignalHookState<T>
    extends HookState<Signal<T>, _StreamSignalHook<T>> {
  late Signal<T> _signal;
  StreamSubscription<T>? _subscription;

  @override
  void initHook() {
    _signal = signal(hook.initialValue);
    _subscription = hook.stream.listen((value) => _signal.value = value);
    _trackForDevTools();
  }

  void _trackForDevTools() {
    if (kDebugMode) {
      VoidSignalsDebugService.tracker.trackSignal(
        _signal,
        label: 'useSignalFromStream<$T>',
      );
    }
  }

  @override
  void didUpdateHook(_StreamSignalHook<T> oldHook) {
    if (!identical(oldHook.stream, hook.stream)) {
      _subscription?.cancel();
      _subscription = hook.stream.listen((value) => _signal.value = value);
    }
  }

  @override
  Signal<T> build(BuildContext context) => _signal;

  @override
  void dispose() {
    _subscription?.cancel();
    _subscription = null;
  }

  @override
  String get debugLabel => 'useSignalFromStream<$T>';
}

class _FutureSignalHook<T> extends Hook<Signal<T>> {
  const _FutureSignalHook(this.future, this.initialValue);
  final Future<T> future;
  final T initialValue;

  @override
  _FutureSignalHookState<T> createState() => _FutureSignalHookState<T>();
}

class _FutureSignalHookState<T>
    extends HookState<Signal<T>, _FutureSignalHook<T>> {
  late Signal<T> _signal;

  @override
  void initHook() {
    _signal = signal(hook.initialValue);
    hook.future.then((value) => _signal.value = value);
    _trackForDevTools();
  }

  void _trackForDevTools() {
    if (kDebugMode) {
      VoidSignalsDebugService.tracker.trackSignal(
        _signal,
        label: 'useSignalFromFuture<$T>',
      );
    }
  }

  @override
  void didUpdateHook(_FutureSignalHook<T> oldHook) {
    if (!identical(oldHook.future, hook.future)) {
      hook.future.then((value) => _signal.value = value);
    }
  }

  @override
  Signal<T> build(BuildContext context) => _signal;

  @override
  String get debugLabel => 'useSignalFromFuture<$T>';
}

// =============================================================================
// Utility Functions
// =============================================================================

bool _listEquals<T>(List<T> a, List<T> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
