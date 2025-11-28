import 'flags.dart';

/// A link connecting a dependency to a subscriber in the reactive graph.
///
/// [Link] is the fundamental building block of the reactive dependency graph.
/// It connects a dependency node (what is being watched) to a subscriber node
/// (what is watching). Links form a bidirectional doubly-linked list structure
/// for efficient traversal and cleanup.
///
/// Uses class fields instead of Map/List for better performance.
/// Field order is optimized for cache locality - hot fields first.
///
/// Example:
/// ```dart
/// // Links are created automatically when you access a signal in a reactive context
/// final count = signal(0);
/// effect(() {
///   // This creates a link between 'count' (dependency) and the effect (subscriber)
///   print(count.value);
/// });
/// ```
@pragma('vm:isolate-unsendable')
final class Link {
  /// Creates a new link between a dependency and subscriber.
  Link({
    required this.dep,
    required this.sub,
    required this.version,
    this.prevDep,
    this.nextDep,
    this.prevSub,
    this.nextSub,
  });

  // Hot fields - accessed frequently together
  final ReactiveNode dep;
  final ReactiveNode sub;
  int version;

  // Traversal fields
  Link? nextDep;
  Link? prevDep;
  Link? nextSub;
  Link? prevSub;
}

/// Stack node for non-recursive graph traversal.
///
/// [Stack] is an immutable linked list used internally for iterative
/// (non-recursive) traversal of the reactive graph. This avoids stack
/// overflow issues with deeply nested dependency chains.
///
/// Example:
/// ```dart
/// // Internal usage pattern:
/// Stack<Link>? stack;
/// // Push a value
/// stack = Stack(value: link, prev: stack);
/// // Pop a value
/// final top = stack!.value;
/// stack = stack!.prev;
/// ```
@pragma('vm:isolate-unsendable')
final class Stack<T> {
  /// Creates a new stack node with the given value and optional previous node.
  const Stack({required this.value, this.prev});

  /// The value stored in this stack node.
  final T value;

  /// The previous node in the stack, or null if this is the bottom.
  final Stack<T>? prev;
}

/// Base class for all reactive nodes in the graph.
///
/// [ReactiveNode] is the abstract base for all nodes in the reactive system:
/// - [SignalNode]: Holds a mutable value
/// - [ComputedNode]: Derives a value from other nodes
/// - [EffectNode]: Executes side effects when dependencies change
/// - [ScopeNode]: Groups effects for batch disposal
///
/// Uses sealed class for pattern matching optimization and exhaustive
/// switch expressions.
///
/// Example:
/// ```dart
/// // Pattern matching on node types
/// void processNode(ReactiveNode node) {
///   switch (node) {
///     case SignalNode():
///       print('Signal with value: ${node.currentValue}');
///     case ComputedNode():
///       print('Computed value: ${node.value}');
///     case EffectNode():
///       print('Effect node');
///     case ScopeNode():
///       print('Scope node');
///   }
/// }
/// ```
@pragma('vm:isolate-unsendable')
sealed class ReactiveNode {
  /// Creates a reactive node with the given initial flags.
  ReactiveNode({required this.flags});

  // Dependencies (what this node depends on)
  Link? deps;
  Link? depsTail;

  // Subscribers (what depends on this node)
  Link? subs;
  Link? subsTail;

  // Reactive flags
  ReactiveFlags flags;

  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  @pragma('wasm:prefer-inline')
  bool get hasDependencies => deps != null;

  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  @pragma('wasm:prefer-inline')
  bool get hasSubscribers => subs != null;
}

/// Signal node - holds a mutable value.
///
/// [SignalNode] is the internal representation of a [Signal]. It stores:
/// - [currentValue]: The value that subscribers see
/// - [pendingValue]: The new value waiting to be applied
///
/// The two-value design enables batched updates where multiple signals
/// can be changed before notifying subscribers.
///
/// Example:
/// ```dart
/// // SignalNode is created internally by signal()
/// final count = signal(0);  // Creates SignalNode<int>
///
/// // Access internals (for debugging/testing only)
/// final node = (count as dynamic)._node as SignalNode<int>;
/// print(node.currentValue);  // 0
/// ```
@pragma('vm:isolate-unsendable')
final class SignalNode<T> extends ReactiveNode {
  /// Creates a signal node with the given initial value.
  SignalNode({required T value})
      : currentValue = value,
        pendingValue = value,
        super(flags: ReactiveFlags.mutable);

  /// The current value visible to subscribers.
  T currentValue;

  /// The pending value waiting to be applied during the next flush.
  T pendingValue;
}

/// Computed node - derives value from other signals.
///
/// [ComputedNode] is the internal representation of a [Computed] value.
/// It lazily computes its value from other signals and caches the result
/// until dependencies change.
///
/// Features:
/// - Lazy evaluation: only computed when accessed
/// - Cached: returns same value until dependencies change
/// - Previous value access: getter receives previous value for optimizations
///
/// Example:
/// ```dart
/// final count = signal(0);
/// // Creates ComputedNode internally
/// final doubled = computed((prev) {
///   print('Previous: $prev'); // null on first run
///   return count.value * 2;
/// });
///
/// print(doubled.value); // Computes: 0
/// print(doubled.value); // Cached: 0 (no recomputation)
/// count.value = 5;
/// print(doubled.value); // Recomputes: 10
/// ```
@pragma('vm:isolate-unsendable')
final class ComputedNode<T> extends ReactiveNode {
  /// Creates a computed node with the given getter function.
  ComputedNode({required T Function(T? previousValue) getter})
      : _getter = getter,
        super(flags: ReactiveFlags.none);

  /// The cached computed value, or null if not yet computed.
  T? value;

  /// The getter function that computes the value.
  final T Function(T? previousValue) _getter;

  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  @pragma('wasm:prefer-inline')
  T compute(T? prev) => _getter(prev);
}

/// Effect node - side effect that runs when dependencies change.
///
/// [EffectNode] is the internal representation of an [Effect]. It automatically
/// tracks dependencies accessed during execution and re-runs when any of those
/// dependencies change.
///
/// Effects are ideal for:
/// - Logging and debugging
/// - Synchronizing with external systems
/// - Triggering side effects like API calls
/// - Updating non-reactive state
///
/// Example:
/// ```dart
/// final user = signal<User?>(null);
///
/// // Creates EffectNode internally
/// final eff = effect(() {
///   final u = user.value;
///   if (u != null) {
///     // Side effect: update analytics
///     analytics.setUserId(u.id);
///   }
/// });
///
/// // Later: stop listening
/// eff.stop();
/// ```
@pragma('vm:isolate-unsendable')
final class EffectNode extends ReactiveNode {
  /// Creates an effect node with the given effect function.
  EffectNode({required this.fn})
      : super(flags: ReactiveFlags.watching | ReactiveFlags.recursedCheck);

  /// The function to execute when dependencies change.
  final void Function() fn;
}

/// Scope node - manages a group of effects.
///
/// [ScopeNode] is the internal representation of an [EffectScope]. It groups
/// related effects together so they can be disposed as a unit. This is
/// particularly useful for cleanup when a component or feature is destroyed.
///
/// Example:
/// ```dart
/// // Creates ScopeNode internally
/// final scope = effectScope(() {
///   effect(() => print('Effect 1: ${count.value}'));
///   effect(() => print('Effect 2: ${name.value}'));
/// });
///
/// // Later: stop all effects in the scope at once
/// scope.stop();
/// ```
@pragma('vm:isolate-unsendable')
final class ScopeNode extends ReactiveNode {
  /// Creates a new scope node for managing a group of effects.
  ScopeNode() : super(flags: ReactiveFlags.none);
}
