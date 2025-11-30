import 'package:void_signals/src/nodes.dart';
import 'package:void_signals/src/system.dart';

import 'flags.dart';

/// A reactive signal that holds a value and notifies subscribers when changed.
///
/// Signals are the foundation of the reactive system. When a signal's value
/// changes, all effects and computed values that depend on it are automatically
/// updated.
///
/// Example:
/// ```dart
/// final count = signal(0);
/// print(count()); // 0
/// count(1);       // Sets value to 1
/// print(count()); // 1
/// ```
final class Signal<T> extends SignalNode<T> {
  /// Creates a new signal with the given initial value.
  Signal(T initialValue) : super(initialValue);

  /// Gets the current value of the signal.
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  @pragma('wasm:prefer-inline')
  T get value => getSignal(this);

  /// Sets the value of the signal.
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  @pragma('wasm:prefer-inline')
  set value(T newValue) => setSignal(this, newValue);

  /// Gets the current value.
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  @pragma('wasm:prefer-inline')
  T call() => value;

  /// Updates the signal value.
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  @pragma('wasm:prefer-inline')
  void update(T newValue) => value = newValue;

  /// Reads the current value without tracking as a dependency.
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  @pragma('wasm:prefer-inline')
  T peek() => currentValue;

  /// Reads the current value without tracking, but ensures any pending
  /// updates have been applied first.
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  @pragma('wasm:prefer-inline')
  T syncPeek() {
    // If there's a pending update, apply it (16 = dirty)
    if ((flags as int) & 16 != 0) {
      currentValue = pendingValue;
      flags = 1 as ReactiveFlags; // mutable
    }
    return currentValue;
  }

  /// Returns whether this signal has any subscribers.
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  @pragma('wasm:prefer-inline')
  bool get hasSubscribers => subs != null;

  @override
  String toString() => 'Signal($currentValue)';
}

/// A computed value that automatically updates when its dependencies change.
///
/// Computed values are derived from other signals and computed values.
/// They are lazily evaluated and cached until one of their dependencies changes.
///
/// Use [value] to get the computed value (triggers computation if needed).
/// Use [peek] to read the cached value without triggering recomputation.
final class Computed<T> extends ComputedNode<T> {
  /// Creates a new computed value with the given getter function.
  Computed(T Function(T? previousValue) getter) : super(getter);

  /// Gets the current computed value.
  ///
  /// This triggers dependency tracking and recomputation if necessary.
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  @pragma('wasm:prefer-inline')
  T get value => getComputed(this);

  /// Gets the current computed value.
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  @pragma('wasm:prefer-inline')
  T call() => value;

  /// Reads the cached value without tracking or recomputing.
  ///
  /// Returns `null` if the computed has never been evaluated.
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  @pragma('wasm:prefer-inline')
  T? peek() => cachedValue;

  /// Returns whether this computed has any subscribers.
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  @pragma('wasm:prefer-inline')
  bool get hasSubscribers => subs != null;

  @override
  String toString() => 'Computed($value)';
}

/// An effect that runs when its dependencies change.
///
/// Effects are used to perform side effects in response to reactive changes.
/// They are automatically re-run whenever any of the signals or computed
/// values they access are updated.
class Effect {
  final EffectNode _node;

  Effect._(this._node);

  /// Stops the effect from running.
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  @pragma('wasm:prefer-inline')
  void stop() => stopEffect(_node);

  @override
  String toString() => 'Effect';
}

/// A scope that manages a group of effects.
///
/// Effect scopes allow you to group multiple effects together and
/// dispose of them all at once.
class EffectScope {
  final ScopeNode _node;

  EffectScope._(this._node);

  /// Stops all effects in this scope.
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  @pragma('wasm:prefer-inline')
  void stop() => stopEffectScope(_node);

  @override
  String toString() => 'EffectScope';
}

// =============================================================================
// Public API Functions
// =============================================================================

/// Creates a new reactive signal with the given initial value.
@pragma('vm:prefer-inline')
@pragma('dart2js:tryInline')
@pragma('wasm:prefer-inline')
Signal<T> signal<T>(T value) => Signal<T>(value);

/// Creates a new computed value with the given getter function.
@pragma('vm:prefer-inline')
@pragma('dart2js:tryInline')
@pragma('wasm:prefer-inline')
Computed<T> computed<T>(T Function(T? previousValue) getter) =>
    Computed<T>(getter);

/// Creates a new computed value with a simple getter function.
@pragma('vm:prefer-inline')
@pragma('dart2js:tryInline')
@pragma('wasm:prefer-inline')
Computed<T> computedFrom<T>(T Function() getter) =>
    Computed<T>((_) => getter());

/// Creates a new effect that runs the given function.
@pragma('vm:prefer-inline')
@pragma('dart2js:tryInline')
@pragma('wasm:prefer-inline')
Effect effect(void Function() fn) => Effect._(createEffect(fn));

/// Creates a new effect scope.
@pragma('vm:prefer-inline')
@pragma('dart2js:tryInline')
@pragma('wasm:prefer-inline')
EffectScope effectScope(void Function() fn) =>
    EffectScope._(createEffectScope(fn));

/// Triggers all subscribers of the tracked dependencies.
@pragma('vm:prefer-inline')
@pragma('dart2js:tryInline')
@pragma('wasm:prefer-inline')
void trigger(void Function() fn) => triggerFn(fn);

/// Batches multiple signal updates into a single flush.
@pragma('vm:prefer-inline')
@pragma('dart2js:tryInline')
@pragma('wasm:prefer-inline')
T batch<T>(T Function() fn) {
  startBatch();
  try {
    return fn();
  } finally {
    endBatch();
  }
}

/// Runs a function without tracking dependencies.
@pragma('vm:prefer-inline')
@pragma('dart2js:tryInline')
@pragma('wasm:prefer-inline')
T untrack<T>(T Function() fn) {
  final prevSub = setActiveSub(null);
  try {
    return fn();
  } finally {
    setActiveSub(prevSub);
  }
}

/// Returns whether the given function is a signal.
@pragma('vm:prefer-inline')
@pragma('dart2js:tryInline')
@pragma('wasm:prefer-inline')
bool isSignal(dynamic value) => value is Signal;

/// Returns whether the given function is a computed.
@pragma('vm:prefer-inline')
@pragma('dart2js:tryInline')
@pragma('wasm:prefer-inline')
bool isComputed(dynamic value) => value is Computed;

/// Returns whether the given function is an effect.
@pragma('vm:prefer-inline')
@pragma('dart2js:tryInline')
@pragma('wasm:prefer-inline')
bool isEffect(dynamic value) => value is Effect;

/// Returns whether the given function is an effect scope.
@pragma('vm:prefer-inline')
@pragma('dart2js:tryInline')
@pragma('wasm:prefer-inline')
bool isEffectScope(dynamic value) => value is EffectScope;
