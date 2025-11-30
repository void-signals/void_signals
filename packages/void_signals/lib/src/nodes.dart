import 'flags.dart';

/// A link connecting a dependency to a subscriber in the reactive graph.
///
/// Links form a doubly-linked list structure that enables efficient dependency
/// tracking and propagation in the reactive system. The compact memory layout
/// groups related fields together to improve cache locality.
///
/// Each link maintains pointers for both:
/// - The dependency chain (in the subscriber's dependency list)
/// - The subscriber chain (in the dependency's subscriber list)
///
/// Example:
/// ```dart
/// // Links are created internally when signals are accessed in effects
/// final count = signal(0);
/// effect(() {
///   print(count.value); // Creates a link from count to this effect
/// });
/// ```
@pragma('vm:isolate-unsendable')
@pragma('vm:entry-point')
final class Link {
  @pragma('vm:prefer-inline')
  Link(this.dep, this.sub, this.version);

  /// The dependency node being subscribed to.
  final ReactiveNode dep;

  /// The subscriber node that depends on [dep].
  final ReactiveNode sub;

  /// Version number used to detect stale links.
  int version;

  /// Next link in the subscriber's dependency list.
  Link? nextDep;

  /// Previous link in the subscriber's dependency list.
  Link? prevDep;

  /// Next link in the dependency's subscriber list.
  Link? nextSub;

  /// Previous link in the dependency's subscriber list.
  Link? prevSub;
}

/// A stack node for non-recursive graph traversal.
///
/// Used internally by the reactive system to traverse dependency graphs
/// without recursion, avoiding stack overflow for deeply nested dependencies.
///
/// Example:
/// ```dart
/// // Internal usage for graph traversal
/// var stack = Stack(initialValue);
/// while (stack != null) {
///   final value = stack.value;
///   stack = stack.prev;
///   // Process value...
/// }
/// ```
@pragma('vm:isolate-unsendable')
final class Stack<T> {
  Stack(this.value, [this.prev]);

  /// The value stored in this stack node.
  T value;

  /// Reference to the previous stack node, or null if this is the bottom.
  Stack<T>? prev;
}

/// Base class for all reactive nodes in the signal graph.
///
/// [ReactiveNode] provides the fundamental structure for dependency tracking
/// and subscriber management. It uses a flat structure to avoid unnecessary
/// virtual method call overhead.
///
/// The node maintains:
/// - [flags]: State flags for tracking dirty/pending/watching status
/// - [deps]/[depsTail]: Linked list of dependencies
/// - [subs]/[subsTail]: Linked list of subscribers
///
/// Example:
/// ```dart
/// // All reactive primitives extend ReactiveNode
/// final sig = signal(0);      // SignalNode extends ReactiveNode
/// final comp = computed((_) => sig.value * 2); // ComputedNode extends ReactiveNode
/// ```
@pragma('vm:isolate-unsendable')
@pragma('vm:entry-point')
abstract class ReactiveNode {
  ReactiveNode(this.flags);

  /// State flags for this node.
  ReactiveFlags flags;

  /// Head of the dependency linked list.
  Link? deps;

  /// Tail of the dependency linked list.
  Link? depsTail;

  /// Head of the subscriber linked list.
  Link? subs;

  /// Tail of the subscriber linked list.
  Link? subsTail;

  /// Next effect in the effect queue.
  ///
  /// Only used by [EffectNode], but placed in base class to avoid type checks.
  ReactiveNode? nextEffect;
}

/// A signal node that holds a mutable value.
///
/// [SignalNode] is the underlying node for [Signal] values. It stores both
/// the current value and a pending value to support batched updates.
///
/// Example:
/// ```dart
/// final node = SignalNode(42);
/// print(node.currentValue); // 42
/// node.pendingValue = 100;
/// node.applyPending(); // Returns true if value changed
/// print(node.currentValue); // 100
/// ```
@pragma('vm:isolate-unsendable')
@pragma('vm:entry-point')
base class SignalNode<T> extends ReactiveNode {
  @pragma('vm:prefer-inline')
  SignalNode(T value)
      : currentValue = value,
        pendingValue = value,
        super(ReactiveFlags.mutable);

  /// The current committed value of the signal.
  T currentValue;

  /// The pending value waiting to be applied.
  T pendingValue;

  /// Applies the pending value and returns whether the value changed.
  ///
  /// Returns `true` if [pendingValue] differs from [currentValue],
  /// `false` otherwise. After calling, [currentValue] equals [pendingValue].
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  @pragma('wasm:prefer-inline')
  bool applyPending() {
    flags = ReactiveFlags.mutable;
    final old = currentValue;
    return !identical(old, currentValue = pendingValue);
  }
}

/// A computed node that derives its value from other reactive sources.
///
/// [ComputedNode] lazily evaluates its getter function and caches the result.
/// The cached value is invalidated when any dependency changes.
///
/// Example:
/// ```dart
/// final countNode = SignalNode(5);
/// final doubledNode = ComputedNode((prev) => countNode.currentValue * 2);
/// print(doubledNode.cachedValue); // null (not yet computed)
/// doubledNode.recompute();
/// print(doubledNode.cachedValue); // 10
/// ```
@pragma('vm:isolate-unsendable')
@pragma('vm:entry-point')
base class ComputedNode<T> extends ReactiveNode {
  @pragma('vm:prefer-inline')
  ComputedNode(this.getter) : super(ReactiveFlags.none);

  /// The getter function that computes the value.
  ///
  /// Receives the previous cached value (or null if never computed).
  final T Function(T?) getter;

  /// Internal cached value. Use [cachedValue] to access.
  T? _cachedValue;

  /// Gets the cached value without triggering recomputation.
  ///
  /// Returns `null` if the computed has never been evaluated.
  T? get cachedValue => _cachedValue;

  /// Sets the cached value. Used internally by the reactive system.
  set cachedValue(T? value) => _cachedValue = value;

  /// Recomputes the value and returns whether it changed.
  ///
  /// Calls [getter] with the previous cached value and stores the result.
  /// Returns `true` if the new value differs from the old value.
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  @pragma('wasm:prefer-inline')
  bool recompute() {
    final old = _cachedValue;
    return !identical(old, _cachedValue = getter(old));
  }
}

/// An effect node that reacts to dependency changes.
///
/// [EffectNode] wraps a side-effect function that runs automatically
/// when any of its tracked dependencies change.
///
/// Example:
/// ```dart
/// final node = EffectNode(() {
///   print('Effect triggered!');
/// });
/// // The effect function is stored in node.fn
/// node.fn(); // Manually invoke: prints "Effect triggered!"
/// ```
@pragma('vm:isolate-unsendable')
@pragma('vm:entry-point')
final class EffectNode extends ReactiveNode {
  @pragma('vm:prefer-inline')
  EffectNode(this.fn)
      : super(6 as ReactiveFlags /* watching | recursedCheck */);

  /// The side-effect function to execute when dependencies change.
  final void Function() fn;
}

/// A scope node that manages a group of effects.
///
/// [ScopeNode] allows grouping multiple effects together for collective
/// lifecycle management. When the scope is stopped, all effects within
/// it are also stopped.
///
/// Example:
/// ```dart
/// final scope = ScopeNode();
/// // Effects created within this scope will be tracked
/// // When scope is stopped, all tracked effects are cleaned up
/// ```
@pragma('vm:isolate-unsendable')
@pragma('vm:entry-point')
final class ScopeNode extends ReactiveNode {
  @pragma('vm:prefer-inline')
  ScopeNode() : super(ReactiveFlags.none);
}
