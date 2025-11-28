import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:void_signals/void_signals.dart';

import 'devtools/debug_service.dart';

// =============================================================================
// Consumer Widget Pattern (Alternative API)
//
// This pattern provides a Riverpod-style API for developers familiar with that
// approach. The Watch widget is the recommended default for most use cases.
//
// Consumer pattern (Riverpod-style):
//   Consumer(builder: (context, ref, _) => Text('${ref.watch(count)}'))
//
// Watch pattern (recommended):
//   Watch(builder: (context, _) => Text('${count.value}'))
//
// Choose Consumer if you:
// 1. Are migrating from Riverpod and prefer the ref pattern
// 2. Want explicit watch/read distinction
// 3. Need ref.select for fine-grained updates
//
// Choose Watch if you:
// 1. Prefer simpler, more direct signal access
// 2. Want automatic dependency tracking via .value
// 3. Prefer less boilerplate
// =============================================================================

/// A ref object that provides access to signals within Consumer widgets.
///
/// This provides a Riverpod-style API for signal access. For simpler usage,
/// consider using [Watch] widget which automatically tracks dependencies.
///
/// API comparison:
/// - `ref.watch(signal)` → `signal.value` (inside Watch builder)
/// - `ref.read(signal)` → `signal.peek()`
/// - `ref.listen(signal, listener)` → `effect(() { signal.value; listener(); })`
/// - `ref.select(signal, selector)` → Use [SignalSelector] widget

///
/// Similar to Riverpod's WidgetRef, this provides methods to watch, read,
/// and listen to signals in a declarative way.
///
/// Example:
/// ```dart
/// class MyWidget extends ConsumerWidget {
///   @override
///   Widget build(BuildContext context, SignalRef ref) {
///     final count = ref.watch(countSignal);
///     return Text('Count: $count');
///   }
/// }
/// ```
abstract class SignalRef {
  /// The [BuildContext] of the widget associated with this ref.
  BuildContext get context;

  /// Whether the widget is still mounted.
  ///
  /// This should be checked before performing async operations:
  /// ```dart
  /// await someAsyncOp();
  /// if (!ref.mounted) return;
  /// // Safe to update UI
  /// ```
  bool get mounted;

  /// Watches a signal and rebuilds the widget when it changes.
  ///
  /// This creates a dependency on the signal. Whenever the signal's
  /// value changes, the widget will rebuild.
  ///
  /// Example:
  /// ```dart
  /// final count = ref.watch(countSignal);
  /// ```
  T watch<T>(Signal<T> signal);

  /// Watches a computed value and rebuilds when it changes.
  T watchComputed<T>(Computed<T> computed);

  /// Reads a signal's current value without creating a dependency.
  ///
  /// The widget will NOT rebuild when this signal changes.
  /// Use this for event handlers where you only need the current value.
  ///
  /// Example:
  /// ```dart
  /// onPressed: () {
  ///   final count = ref.read(countSignal);
  ///   print('Current count: $count');
  /// }
  /// ```
  T read<T>(Signal<T> signal);

  /// Reads a computed's current value without creating a dependency.
  T readComputed<T>(Computed<T> computed);

  /// Listens to a signal and calls [listener] when it changes.
  ///
  /// Unlike [watch], this does not cause a rebuild. Use this for
  /// side effects like showing dialogs or navigation.
  ///
  /// The listener is automatically cleaned up when the widget is disposed.
  ///
  /// Example:
  /// ```dart
  /// ref.listen(errorSignal, (prev, error) {
  ///   if (error != null) {
  ///     ScaffoldMessenger.of(context).showSnackBar(...);
  ///   }
  /// });
  /// ```
  void listen<T>(
    Signal<T> signal,
    void Function(T? previous, T current) listener, {
    bool fireImmediately = false,
  });

  /// Selects a part of a signal's value and only rebuilds when
  /// the selected part changes.
  ///
  /// This is useful for performance optimization when you only
  /// need a derived value.
  ///
  /// Example:
  /// ```dart
  /// // Only rebuild when user.name changes, not when other fields change
  /// final name = ref.select(userSignal, (user) => user.name);
  /// ```
  R select<T, R>(Signal<T> signal, R Function(T value) selector);

  /// Invalidates a signal, causing it to refresh.
  ///
  /// This is useful for "refresh" functionality.
  void invalidate<T>(Signal<T> signal);
}

/// A widget that can watch signals.
///
/// For simpler usage, consider using [Watch] widget which automatically
/// tracks dependencies without requiring a ref object.
///
/// ```dart
/// // Consumer pattern (Riverpod-style):
/// class CounterWidget extends ConsumerWidget {
///   Widget build(BuildContext context, SignalRef ref) {
///     final count = ref.watch(countSignal);
///     return Text('Count: $count');
///   }
/// }
///
/// // Watch pattern (alternative):
/// Watch(builder: (context, _) => Text('Count: ${countSignal.value}'))
/// ```
abstract class ConsumerWidget extends ConsumerStatefulWidget {
  /// Creates a consumer widget.
  const ConsumerWidget({super.key});

  /// Describes the part of the user interface represented by this widget.
  Widget build(BuildContext context, SignalRef ref);

  @override
  ConsumerState<ConsumerWidget> createState() => _ConsumerWidgetState();
}

class _ConsumerWidgetState extends ConsumerState<ConsumerWidget> {
  @override
  Widget build(BuildContext context) => widget.build(context, ref);
}

/// A stateful widget that can watch signals.
///
/// Use this when you need both signal watching and stateful lifecycle methods.
/// For simpler cases, consider using [Watch] with a regular [StatefulWidget].
///
/// Example:
/// ```dart
/// class MyWidget extends ConsumerStatefulWidget {
///   @override
///   ConsumerState<MyWidget> createState() => _MyWidgetState();
/// }
///
/// class _MyWidgetState extends ConsumerState<MyWidget> {
///   @override
///   void initState() {
///     super.initState();
///     // Setup code
///   }
///
///   @override
///   Widget build(BuildContext context) {
///     final count = ref.watch(countSignal);
///     return Text('Count: $count');
///   }
/// }
/// ```
abstract class ConsumerStatefulWidget extends StatefulWidget {
  /// Creates a consumer stateful widget.
  const ConsumerStatefulWidget({super.key});

  @override
  ConsumerState createState();

  @override
  ConsumerStatefulElement createElement() => ConsumerStatefulElement(this);
}

/// The [State] for a [ConsumerStatefulWidget].
///
/// It has all the lifecycle of a normal [State], with the addition
/// of a [ref] property for accessing signals.
abstract class ConsumerState<T extends ConsumerStatefulWidget>
    extends State<T> {
  /// Access signals through this ref.
  late final SignalRef ref = context as SignalRef;
}

/// The [Element] for a [ConsumerStatefulWidget].
class ConsumerStatefulElement extends StatefulElement implements SignalRef {
  /// Creates a consumer stateful element.
  ConsumerStatefulElement(ConsumerStatefulWidget super.widget);

  final Map<int, _SignalSubscription> _subscriptions = {};
  Map<int, _SignalSubscription>? _oldSubscriptions;
  final List<Effect> _listenEffects = [];
  bool? _isActive;

  @override
  BuildContext get context => this;

  @override
  bool get mounted => super.mounted;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Handle container changes if needed in the future
  }

  @override
  Widget build() {
    // Handle TickerMode for pause/resume
    final isActive = TickerMode.of(this);
    if (isActive != _isActive) {
      _isActive = isActive;
      for (final sub in _subscriptions.values) {
        if (isActive) {
          sub.resume();
        } else {
          sub.pause();
        }
      }
    }

    try {
      _oldSubscriptions = _subscriptions;
      // Don't clear _subscriptions, we'll reuse matching ones
      return super.build();
    } finally {
      // Close subscriptions that weren't reused
      if (_oldSubscriptions != null) {
        for (final entry in _oldSubscriptions!.entries) {
          if (!_subscriptions.containsKey(entry.key)) {
            entry.value.close();
          }
        }
        _oldSubscriptions = null;
      }
    }
  }

  @override
  T watch<T>(Signal<T> signal) {
    _assertMounted();
    final identity = identityHashCode(signal);

    // Check if we already have a subscription
    final existing = _oldSubscriptions?.remove(identity);
    if (existing != null) {
      // Reuse existing subscription
      _subscriptions[identity] = existing;
    } else if (!_subscriptions.containsKey(identity)) {
      // Create new subscription
      final sub = _SignalSubscriptionImpl<T>(
        signal: signal,
        onUpdate: () {
          if (mounted) _safeMarkNeedsBuild();
        },
      );
      _subscriptions[identity] = sub;
      _applyTickerMode(sub);

      // Track for DevTools
      if (kDebugMode) {
        VoidSignalsDebugService.tracker.trackSignal(
          signal,
          label: 'ConsumerWidget.watch<$T>',
        );
      }
    }

    return signal.value;
  }

  @override
  T watchComputed<T>(Computed<T> computed) {
    _assertMounted();
    final identity = identityHashCode(computed);

    // Check if we already have a subscription
    final existing = _oldSubscriptions?.remove(identity);
    if (existing != null) {
      _subscriptions[identity] = existing;
    } else if (!_subscriptions.containsKey(identity)) {
      final sub = _ComputedSubscription<T>(
        computed: computed,
        onUpdate: () {
          if (mounted) _safeMarkNeedsBuild();
        },
      );
      _subscriptions[identity] = sub;
      _applyTickerMode(sub);

      if (kDebugMode) {
        VoidSignalsDebugService.tracker.trackComputed(
          computed,
          label: 'ConsumerWidget.watchComputed<$T>',
        );
      }
    }

    return computed.value;
  }

  void _applyTickerMode(_SignalSubscription sub) {
    if (_isActive == false) sub.pause();
  }

  @override
  T read<T>(Signal<T> signal) {
    _assertMounted();
    return signal.peek();
  }

  @override
  T readComputed<T>(Computed<T> computed) {
    _assertMounted();
    return computed.peek() as T;
  }

  @override
  void listen<T>(
    Signal<T> signal,
    void Function(T? previous, T current) listener, {
    bool fireImmediately = false,
  }) {
    _assertMounted();

    T? lastValue = signal.peek();
    final eff = effect(() {
      final newValue = signal.value;
      if (fireImmediately || lastValue != newValue) {
        final prev = lastValue;
        lastValue = newValue;
        listener(prev, newValue);
      }
    });

    _listenEffects.add(eff);
  }

  @override
  R select<T, R>(Signal<T> signal, R Function(T value) selector) {
    _assertMounted();
    final identity = Object.hash(identityHashCode(signal), selector);

    final existing = _oldSubscriptions?.remove(identity);
    if (existing != null) {
      _subscriptions[identity] = existing;
      return (existing as _SelectSubscription<T, R>).selectedValue;
    }

    if (!_subscriptions.containsKey(identity)) {
      final sub = _SelectSubscription<T, R>(
        signal: signal,
        selector: selector,
        onUpdate: () {
          if (mounted) _safeMarkNeedsBuild();
        },
      );
      _subscriptions[identity] = sub;
      _applyTickerMode(sub);
    }

    return (_subscriptions[identity] as _SelectSubscription<T, R>)
        .selectedValue;
  }

  @override
  void invalidate<T>(Signal<T> signal) {
    // Signals don't have built-in invalidation, but we can trigger a rebuild
    // by accessing the value
    signal.value = signal.peek();
  }

  void _assertMounted() {
    if (!mounted) {
      throw StateError(
        'Cannot use "ref" after the widget is disposed.\n'
        'Make sure to check "ref.mounted" before using ref in async callbacks.',
      );
    }
  }

  void _safeMarkNeedsBuild() {
    final phase = SchedulerBinding.instance.schedulerPhase;
    if (phase == SchedulerPhase.persistentCallbacks ||
        phase == SchedulerPhase.midFrameMicrotasks) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted) markNeedsBuild();
      });
    } else {
      markNeedsBuild();
    }
  }

  @override
  void unmount() {
    super.unmount();

    // Close all subscriptions
    for (final sub in _subscriptions.values) {
      sub.close();
    }
    _subscriptions.clear();

    // Stop all listen effects
    for (final eff in _listenEffects) {
      eff.stop();
    }
    _listenEffects.clear();
  }
}

// =============================================================================
// Internal Subscription Classes
// =============================================================================

abstract class _SignalSubscription<T> {
  void pause();
  void resume();
  void close();
}

class _SignalSubscriptionImpl<T> implements _SignalSubscription<T> {
  final Signal<T> signal;
  final void Function() onUpdate;
  Effect? _effect;
  T? _lastValue;
  int _pauseCount = 0;
  bool _hasMissedUpdate = false;
  bool _closed = false;

  _SignalSubscriptionImpl({
    required this.signal,
    required this.onUpdate,
  }) {
    _lastValue = signal.peek();
    _subscribe();
  }

  void _subscribe() {
    _effect = effect(() {
      final newValue = signal.value;
      if (!_closed && _lastValue != newValue) {
        _lastValue = newValue;
        if (_pauseCount > 0) {
          _hasMissedUpdate = true;
        } else {
          onUpdate();
        }
      }
    });
  }

  @override
  void pause() {
    _pauseCount++;
  }

  @override
  void resume() {
    if (_pauseCount > 0) {
      _pauseCount--;
      if (_pauseCount == 0 && _hasMissedUpdate) {
        _hasMissedUpdate = false;
        onUpdate();
      }
    }
  }

  @override
  void close() {
    if (_closed) return;
    _closed = true;
    _effect?.stop();
    _effect = null;
  }
}

class _ComputedSubscription<T> implements _SignalSubscription<T> {
  final Computed<T> computed;
  final void Function() onUpdate;
  Effect? _effect;
  T? _lastValue;
  int _pauseCount = 0;
  bool _hasMissedUpdate = false;
  bool _closed = false;

  _ComputedSubscription({
    required this.computed,
    required this.onUpdate,
  }) {
    _lastValue = computed.peek();
    _subscribe();
  }

  void _subscribe() {
    _effect = effect(() {
      final newValue = computed.value;
      if (!_closed && _lastValue != newValue) {
        _lastValue = newValue;
        if (_pauseCount > 0) {
          _hasMissedUpdate = true;
        } else {
          onUpdate();
        }
      }
    });
  }

  @override
  void pause() {
    _pauseCount++;
  }

  @override
  void resume() {
    if (_pauseCount > 0) {
      _pauseCount--;
      if (_pauseCount == 0 && _hasMissedUpdate) {
        _hasMissedUpdate = false;
        onUpdate();
      }
    }
  }

  @override
  void close() {
    if (_closed) return;
    _closed = true;
    _effect?.stop();
    _effect = null;
  }
}

class _SelectSubscription<T, R> implements _SignalSubscription<R> {
  final Signal<T> signal;
  final R Function(T value) selector;
  final void Function() onUpdate;
  Effect? _effect;
  late R selectedValue;
  int _pauseCount = 0;
  bool _hasMissedUpdate = false;
  bool _closed = false;

  _SelectSubscription({
    required this.signal,
    required this.selector,
    required this.onUpdate,
  }) {
    selectedValue = selector(signal.peek());
    _subscribe();
  }

  void _subscribe() {
    _effect = effect(() {
      final newSelected = selector(signal.value);
      if (!_closed && selectedValue != newSelected) {
        selectedValue = newSelected;
        if (_pauseCount > 0) {
          _hasMissedUpdate = true;
        } else {
          onUpdate();
        }
      }
    });
  }

  @override
  void pause() {
    _pauseCount++;
  }

  @override
  void resume() {
    if (_pauseCount > 0) {
      _pauseCount--;
      if (_pauseCount == 0 && _hasMissedUpdate) {
        _hasMissedUpdate = false;
        onUpdate();
      }
    }
  }

  @override
  void close() {
    if (_closed) return;
    _closed = true;
    _effect?.stop();
    _effect = null;
  }
}

// =============================================================================
// Consumer Widget (Inline Builder)
// =============================================================================

/// A widget builder that can watch signals.
///
/// This provides a Riverpod-style API. For simpler usage, consider using
/// [Watch] widget which automatically tracks dependencies.
///
/// ```dart
/// // Consumer pattern (Riverpod-style):
/// Consumer(
///   builder: (context, ref, child) {
///     final count = ref.watch(countSignal);
///     return Text('Count: $count');
///   },
/// )
///
/// // Watch pattern (alternative):
/// Watch(builder: (context, _) => Text('Count: ${countSignal.value}'))
/// ```
class Consumer extends ConsumerWidget {
  /// The builder function.
  final Widget Function(BuildContext context, SignalRef ref, Widget? child)
      builder;

  /// An optional child widget that won't rebuild when signals change.
  final Widget? child;

  /// Creates a consumer widget with a builder.
  const Consumer({
    super.key,
    required this.builder,
    this.child,
  });

  @override
  Widget build(BuildContext context, SignalRef ref) {
    return builder(context, ref, child);
  }
}
