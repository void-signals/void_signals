import 'flags.dart';
import 'nodes.dart';
import 'system.dart';

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
class Signal<T> {
  final SignalNode<T> _node;

  /// Creates a new signal with the given initial value.
  Signal(T initialValue) : _node = SignalNode<T>(value: initialValue);

  /// Gets the current value of the signal.
  ///
  /// This also tracks the signal as a dependency if called within
  /// an effect or computed context.
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  @pragma('wasm:prefer-inline')
  T get value => getSignal(_node);

  /// Sets the value of the signal.
  ///
  /// If the new value is different from the current value, all dependent
  /// effects and computed values will be notified.
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  @pragma('wasm:prefer-inline')
  set value(T newValue) => setSignal(_node, newValue);

  /// Gets the current value.
  ///
  /// This is the callable form, equivalent to accessing [value].
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  @pragma('wasm:prefer-inline')
  T call() => value;

  /// Updates the signal value.
  ///
  /// Use this method when you need to set a value that might be null,
  /// since the [call] method only reads the value.
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  @pragma('wasm:prefer-inline')
  void update(T newValue) => value = newValue;

  /// Reads the current value without tracking as a dependency.
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  @pragma('wasm:prefer-inline')
  T peek() => _node.currentValue;

  /// Reads the current value without tracking, but ensures any pending
  /// updates have been applied first.
  ///
  /// This is useful when you need the latest value but don't want to
  /// create a dependency.
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  @pragma('wasm:prefer-inline')
  T syncPeek() {
    // If there's a pending update, apply it
    if (_node.flags.isDirty) {
      _node.currentValue = _node.pendingValue;
      _node.flags = ReactiveFlags.mutable;
    }
    return _node.currentValue;
  }

  /// Returns whether this signal has any subscribers.
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  @pragma('wasm:prefer-inline')
  bool get hasSubscribers => _node.hasSubscribers;

  @override
  String toString() => 'Signal($value)';
}

/// A computed value that automatically updates when its dependencies change.
///
/// Computed values are derived from other signals and computed values.
/// They are lazily evaluated and cached until one of their dependencies changes.
///
/// Example:
/// ```dart
/// final firstName = signal('John');
/// final lastName = signal('Doe');
/// final fullName = computed((prev) => '${firstName()} ${lastName()}');
/// print(fullName()); // 'John Doe'
/// firstName('Jane');
/// print(fullName()); // 'Jane Doe'
/// ```
class Computed<T> {
  final ComputedNode<T> _node;

  /// Creates a new computed value with the given getter function.
  ///
  /// The getter receives the previous computed value as an argument,
  /// which can be useful for optimizations or maintaining state.
  Computed(T Function(T? previousValue) getter)
      : _node = ComputedNode<T>(getter: getter);

  /// Gets the current computed value.
  ///
  /// The value is lazily computed and cached. It will only be recomputed
  /// when one of its dependencies changes.
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  @pragma('wasm:prefer-inline')
  T get value => getComputed(_node);

  /// Gets the current computed value.
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  @pragma('wasm:prefer-inline')
  T call() => value;

  /// Reads the cached value without tracking or recomputing.
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  @pragma('wasm:prefer-inline')
  T? peek() => _node.value;

  /// Returns whether this computed has any subscribers.
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  @pragma('wasm:prefer-inline')
  bool get hasSubscribers => _node.hasSubscribers;

  @override
  String toString() => 'Computed($value)';
}

/// An effect that runs when its dependencies change.
///
/// Effects are used to perform side effects in response to reactive changes.
/// They are automatically re-run whenever any of the signals or computed
/// values they access are updated.
///
/// Example:
/// ```dart
/// final count = signal(0);
/// final eff = effect(() {
///   print('Count is: ${count()}');
/// });
/// count(1); // Prints: 'Count is: 1'
/// eff.stop(); // Stop listening to changes
/// ```
class Effect {
  final EffectNode _node;

  Effect._(this._node);

  /// Stops the effect from running.
  ///
  /// After calling stop(), the effect will no longer react to changes
  /// in its dependencies.
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
/// dispose of them all at once. This is useful for cleanup when
/// a component or feature is destroyed.
///
/// Example:
/// ```dart
/// final scope = effectScope(() {
///   effect(() { /* effect 1 */ });
///   effect(() { /* effect 2 */ });
/// });
/// scope.stop(); // Stops all effects created in the scope
/// ```
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
///
/// Example:
/// ```dart
/// final count = signal(0);
/// ```
@pragma('vm:prefer-inline')
@pragma('dart2js:tryInline')
@pragma('wasm:prefer-inline')
Signal<T> signal<T>(T value) => Signal<T>(value);

/// Creates a new computed value with the given getter function.
///
/// The getter function receives the previous computed value as an argument.
///
/// Example:
/// ```dart
/// final doubled = computed((prev) => count() * 2);
/// ```
@pragma('vm:prefer-inline')
@pragma('dart2js:tryInline')
@pragma('wasm:prefer-inline')
Computed<T> computed<T>(T Function(T? previousValue) getter) =>
    Computed<T>(getter);

/// Creates a new computed value with a simple getter function.
///
/// This is a convenience method for computed values that don't need
/// access to the previous value.
///
/// Example:
/// ```dart
/// final doubled = computedFrom(() => count() * 2);
/// ```
@pragma('vm:prefer-inline')
@pragma('dart2js:tryInline')
@pragma('wasm:prefer-inline')
Computed<T> computedFrom<T>(T Function() getter) =>
    Computed<T>((_) => getter());

/// Creates a new effect that runs the given function.
///
/// The effect will run immediately and then again whenever any of
/// its dependencies change.
///
/// Example:
/// ```dart
/// final eff = effect(() {
///   print('Count: ${count()}');
/// });
/// ```
@pragma('vm:prefer-inline')
@pragma('dart2js:tryInline')
@pragma('wasm:prefer-inline')
Effect effect(void Function() fn) => Effect._(createEffect(fn));

/// Creates a new effect scope.
///
/// All effects created within the scope's function will be tracked
/// and can be disposed together.
///
/// Example:
/// ```dart
/// final scope = effectScope(() {
///   effect(() { /* ... */ });
/// });
/// scope.stop();
/// ```
@pragma('vm:prefer-inline')
@pragma('dart2js:tryInline')
@pragma('wasm:prefer-inline')
EffectScope effectScope(void Function() fn) =>
    EffectScope._(createEffectScope(fn));

/// Triggers all subscribers of the tracked dependencies.
///
/// This is useful for manually triggering updates to dependencies.
///
/// Example:
/// ```dart
/// trigger(() {
///   count(); // Track this signal
/// });
/// ```
@pragma('vm:prefer-inline')
@pragma('dart2js:tryInline')
@pragma('wasm:prefer-inline')
void trigger(void Function() fn) => triggerFn(fn);

/// Batches multiple signal updates into a single flush.
///
/// This is useful for performance optimization when updating
/// multiple signals at once.
///
/// Example:
/// ```dart
/// batch(() {
///   signal1(newValue1);
///   signal2(newValue2);
/// }); // Effects run once after all updates
/// ```
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
///
/// This is useful when you want to read a signal's value without
/// creating a dependency.
///
/// Example:
/// ```dart
/// effect(() {
///   // This will create a dependency on count
///   print(count());
///
///   // This will not create a dependency
///   untrack(() => otherSignal());
/// });
/// ```
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
