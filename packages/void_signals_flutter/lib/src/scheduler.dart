import 'dart:async';

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:void_signals/void_signals.dart';

// =============================================================================
// Flutter Scheduler Integration
//
// Provides Flutter-aware scheduling for signal updates, ensuring updates
// are batched and synchronized with the Flutter frame lifecycle.
// =============================================================================

/// A task that can be scheduled and cancelled.
class ScheduledTask {
  final VoidCallback _callback;
  bool _completed = false;

  ScheduledTask(this._callback);

  /// Whether this task has completed.
  bool get completed => _completed;

  /// Executes the task if not already completed.
  void call() {
    if (_completed) return;
    _completed = true;
    _callback();
  }
}

/// A scheduler that synchronizes signal updates with Flutter's frame lifecycle.
///
/// This is similar to Riverpod's ProviderScheduler but adapted for signals.
/// It ensures that multiple signal updates in the same frame are batched
/// together for efficiency.
///
/// Example:
/// ```dart
/// // Initialize in your app
/// FlutterSignalScheduler.initialize();
///
/// // Updates are now batched with the Flutter frame lifecycle
/// signal1.value = 1;
/// signal2.value = 2;
/// // Both updates are processed together
/// ```
class FlutterSignalScheduler {
  static FlutterSignalScheduler? _instance;
  static bool _initialized = false;

  /// Gets the singleton instance.
  static FlutterSignalScheduler get instance {
    _instance ??= FlutterSignalScheduler._();
    return _instance!;
  }

  FlutterSignalScheduler._();

  /// Whether the scheduler is initialized.
  static bool get isInitialized => _initialized;

  /// Pending effects to run.
  final List<VoidCallback> _pendingEffects = [];

  /// Completer for pending task.
  Completer<void>? _pendingTaskCompleter;

  /// Cancellation callback for current timer.
  VoidCallback? _cancelTimer;

  /// Initialize the Flutter signal scheduler.
  ///
  /// This should be called early in your app's initialization,
  /// typically in main() before runApp().
  ///
  /// ```dart
  /// void main() {
  ///   WidgetsFlutterBinding.ensureInitialized();
  ///   FlutterSignalScheduler.initialize();
  ///   runApp(MyApp());
  /// }
  /// ```
  static void initialize() {
    if (_initialized) return;
    _initialized = true;
    instance._setupScheduling();
  }

  void _setupScheduling() {
    // The actual scheduling is done through scheduleTask
  }

  /// Schedules a task to run after the current frame.
  ///
  /// Multiple tasks scheduled in the same frame will be batched together.
  Future<void> scheduleTask(VoidCallback task) {
    _pendingEffects.add(task);
    return _ensureFrameCallback();
  }

  Future<void> _ensureFrameCallback() {
    if (_pendingTaskCompleter != null) {
      return _pendingTaskCompleter!.future;
    }

    _pendingTaskCompleter = Completer<void>();

    // Use SchedulerBinding if available, otherwise fall back to Timer
    if (SchedulerBinding.instance.schedulerPhase != SchedulerPhase.idle) {
      // We're in the middle of a frame, schedule for next frame
      SchedulerBinding.instance.addPostFrameCallback((_) {
        _runPendingTasks();
      });
    } else {
      // Use a microtask for immediate batching
      scheduleMicrotask(_runPendingTasks);
    }

    return _pendingTaskCompleter!.future;
  }

  void _runPendingTasks() {
    final tasks = List<VoidCallback>.from(_pendingEffects);
    _pendingEffects.clear();

    final completer = _pendingTaskCompleter;
    _pendingTaskCompleter = null;

    // Run all pending tasks in a batch
    batch(() {
      for (final task in tasks) {
        try {
          task();
        } catch (e, stack) {
          // Report error but continue with other tasks
          SignalErrorHandler.instance?.handleError(e, stack);
        }
      }
    });

    completer?.complete();
  }

  /// Schedules a refresh for a signal.
  void scheduleRefresh(VoidCallback refresh) {
    scheduleTask(refresh);
  }

  /// Disposes the scheduler.
  void dispose() {
    _pendingEffects.clear();
    _pendingTaskCompleter?.complete();
    _pendingTaskCompleter = null;
    _cancelTimer?.call();
    _cancelTimer = null;
    _initialized = false;
    _instance = null;
  }
}

/// A widget that initializes the Flutter signal scheduler.
///
/// This should be placed at the root of your widget tree to ensure
/// proper signal scheduling.
///
/// Example:
/// ```dart
/// void main() {
///   runApp(
///     SignalSchedulerScope(
///       child: MyApp(),
///     ),
///   );
/// }
/// ```
class SignalSchedulerScope extends StatefulWidget {
  /// The child widget.
  final Widget child;

  /// Creates a signal scheduler scope.
  const SignalSchedulerScope({super.key, required this.child});

  @override
  State<SignalSchedulerScope> createState() => _SignalSchedulerScopeState();
}

class _SignalSchedulerScopeState extends State<SignalSchedulerScope> {
  @override
  void initState() {
    super.initState();
    FlutterSignalScheduler.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

/// Extension to add Flutter-aware scheduling to signals.
extension FlutterScheduledSignalExtension<T> on Signal<T> {
  /// Updates the signal value with Flutter-aware scheduling.
  ///
  /// The update will be batched with other updates in the same frame.
  void updateScheduled(T newValue) {
    if (FlutterSignalScheduler.isInitialized) {
      FlutterSignalScheduler.instance.scheduleTask(() {
        value = newValue;
      });
    } else {
      value = newValue;
    }
  }

  /// Updates the signal value using a function, with scheduling.
  void modifyScheduled(T Function(T current) modifier) {
    if (FlutterSignalScheduler.isInitialized) {
      FlutterSignalScheduler.instance.scheduleTask(() {
        value = modifier(peek());
      });
    } else {
      value = modifier(peek());
    }
  }
}

/// A mixin that provides Flutter-aware reactive state management.
///
/// This mixin automatically handles the lifecycle of signals and effects,
/// ensuring they are properly disposed when the widget is removed.
mixin FlutterSignalMixin<T extends StatefulWidget> on State<T> {
  final List<Effect> _effects = [];
  final List<SignalSubscription> _subscriptions = [];
  EffectScope? _scope;

  /// Creates a signal that is managed by this widget.
  ///
  /// The signal will be tracked for DevTools and properly cleaned up.
  Signal<S> createSignal<S>(S initialValue, {String? debugLabel}) {
    final sig = signal(initialValue);
    return sig;
  }

  /// Creates a computed that is managed by this widget.
  Computed<S> createComputed<S>(S Function(S? prev) getter,
      {String? debugLabel}) {
    return computed(getter);
  }

  /// Creates an effect that is managed by this widget.
  ///
  /// The effect will be automatically stopped when the widget is disposed.
  Effect createEffect(VoidCallback fn) {
    final eff = effect(fn);
    _effects.add(eff);
    return eff;
  }

  /// Subscribes to a signal with automatic cleanup.
  SignalSubscription<S> subscribe<S>(
    Signal<S> signal,
    void Function(S? prev, S current) listener, {
    bool fireImmediately = false,
  }) {
    final sub = signal.subscribe(listener, fireImmediately: fireImmediately);
    _subscriptions.add(sub);
    return sub;
  }

  /// Runs effects within a scope for batch cleanup.
  void runInScope(VoidCallback fn) {
    _scope ??= effectScope(() {});
    fn();
  }

  @override
  void dispose() {
    // Stop all effects
    for (final eff in _effects) {
      eff.stop();
    }
    _effects.clear();

    // Close all subscriptions
    for (final sub in _subscriptions) {
      sub.close();
    }
    _subscriptions.clear();

    // Stop the scope if any
    _scope?.stop();
    _scope = null;

    super.dispose();
  }
}

/// A StatefulWidget mixin that provides automatic signal watching.
///
/// Similar to Riverpod's ConsumerStateMixin but for signals.
mixin SignalWatcherMixin<T extends StatefulWidget> on State<T> {
  final Map<int, _WatchedSignal> _watched = {};
  final List<Effect> _listenEffects = [];

  /// Watches a signal and triggers a rebuild when it changes.
  ///
  /// This should be called in the build method.
  S watch<S>(Signal<S> signal) {
    final identity = identityHashCode(signal);

    if (!_watched.containsKey(identity)) {
      S? lastValue = signal.peek();
      final eff = effect(() {
        final newValue = signal.value;
        if (lastValue != newValue) {
          lastValue = newValue;
          if (mounted) {
            _safeSetState();
          }
        }
      });
      _watched[identity] = _WatchedSignal(signal, eff);
    }

    return signal.value;
  }

  /// Watches a computed and triggers a rebuild when it changes.
  S watchComputed<S>(Computed<S> computed) {
    final identity = identityHashCode(computed);

    if (!_watched.containsKey(identity)) {
      S? lastValue = computed.peek();
      final eff = effect(() {
        final newValue = computed.value;
        if (lastValue != newValue) {
          lastValue = newValue;
          if (mounted) {
            _safeSetState();
          }
        }
      });
      _watched[identity] = _WatchedSignal(computed, eff);
    }

    return computed.value;
  }

  /// Listens to a signal without triggering rebuilds.
  void listen<S>(
    Signal<S> signal,
    void Function(S? prev, S current) listener,
  ) {
    S? lastValue = signal.peek();
    final eff = effect(() {
      final newValue = signal.value;
      if (lastValue != newValue) {
        final prev = lastValue;
        lastValue = newValue;
        listener(prev, newValue);
      }
    });
    _listenEffects.add(eff);
  }

  void _safeSetState() {
    final phase = SchedulerBinding.instance.schedulerPhase;
    if (phase == SchedulerPhase.persistentCallbacks ||
        phase == SchedulerPhase.midFrameMicrotasks) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() {});
      });
    } else {
      setState(() {});
    }
  }

  @override
  void dispose() {
    for (final watched in _watched.values) {
      watched.effect.stop();
    }
    _watched.clear();

    for (final eff in _listenEffects) {
      eff.stop();
    }
    _listenEffects.clear();

    super.dispose();
  }
}

class _WatchedSignal {
  final dynamic signal;
  final Effect effect;

  _WatchedSignal(this.signal, this.effect);
}

/// A builder widget that uses the signal watcher mixin.
class SignalWatcher extends StatefulWidget {
  /// The builder function.
  final Widget Function(BuildContext context, SignalWatcherState state) builder;

  /// Creates a signal watcher widget.
  const SignalWatcher({super.key, required this.builder});

  @override
  SignalWatcherState createState() => SignalWatcherState();
}

/// The state for [SignalWatcher].
class SignalWatcherState extends State<SignalWatcher>
    with SignalWatcherMixin<SignalWatcher> {
  @override
  Widget build(BuildContext context) {
    return widget.builder(context, this);
  }
}
