import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:void_signals/void_signals.dart';

import 'devtools/debug_service.dart';

// =============================================================================
// Reactive Widget Builders
//
// The batch() function from void_signals handles coalescing of synchronous
// signal updates. Flutter's natural frame lifecycle handles UI updates.
// =============================================================================

/// A widget that rebuilds when a [Signal] changes.
///
/// This widget subscribes to a signal and rebuilds whenever the signal's
/// value changes. The builder function receives the current value of the signal.
///
/// Example:
/// ```dart
/// final count = signal(0);
///
/// SignalBuilder<int>(
///   signal: count,
///   builder: (context, value, child) {
///     return Text('Count: $value');
///   },
/// )
/// ```
class SignalBuilder<T> extends StatefulWidget {
  /// The signal to subscribe to.
  final Signal<T> signal;

  /// Builder function that receives the current signal value.
  final Widget Function(BuildContext context, T value, Widget? child) builder;

  /// Optional child widget that doesn't depend on the signal value.
  ///
  /// This child will not be rebuilt when the signal changes, which can
  /// improve performance for complex child widgets.
  final Widget? child;

  const SignalBuilder({
    super.key,
    required this.signal,
    required this.builder,
    this.child,
  });

  @override
  State<SignalBuilder<T>> createState() => _SignalBuilderState<T>();
}

class _SignalBuilderState<T> extends State<SignalBuilder<T>> {
  Effect? _effect;
  late T _lastValue;

  @override
  void initState() {
    super.initState();
    _lastValue = widget.signal.value;
    _subscribeToSignal();
    _trackForDevTools();
  }

  void _trackForDevTools() {
    if (kDebugMode) {
      VoidSignalsDebugService.tracker.trackSignal(
        widget.signal,
        label: 'SignalBuilder<$T>',
      );
    }
  }

  void _subscribeToSignal() {
    _effect = effect(() {
      // Access the signal to track it
      final newValue = widget.signal.value;
      // Only trigger rebuild if value actually changed
      if (_lastValue != newValue) {
        _lastValue = newValue;
        _safeSetState();
      }
    });
  }

  void _safeSetState() {
    if (!mounted) return;
    // Check if we're in a safe phase to call setState
    final phase = SchedulerBinding.instance.schedulerPhase;
    if (phase == SchedulerPhase.persistentCallbacks ||
        phase == SchedulerPhase.midFrameMicrotasks) {
      // We're in build phase, schedule for next frame
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() {});
      });
    } else {
      // Safe to call setState directly
      setState(() {});
    }
  }

  @override
  void didUpdateWidget(SignalBuilder<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.signal, widget.signal)) {
      _effect?.stop();
      _lastValue = widget.signal.value;
      _subscribeToSignal();
    }
  }

  @override
  void dispose() {
    _effect?.stop();
    _effect = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, widget.signal.value, widget.child);
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<Signal<T>>('signal', widget.signal));
    properties.add(DiagnosticsProperty<T>('value', _lastValue));
  }
}

/// A widget that rebuilds when multiple [Signal]s change.
///
/// This widget subscribes to multiple signals and rebuilds whenever any
/// of them change.
///
/// Example:
/// ```dart
/// final firstName = signal('John');
/// final lastName = signal('Doe');
///
/// MultiSignalBuilder(
///   signals: [firstName, lastName],
///   builder: (context, child) {
///     return Text('${firstName()} ${lastName()}');
///   },
/// )
/// ```
class MultiSignalBuilder extends StatefulWidget {
  /// The list of signals to subscribe to.
  final List<Signal> signals;

  /// Builder function that receives the context and optional child.
  final Widget Function(BuildContext context, Widget? child) builder;

  /// Optional child widget that doesn't depend on signal values.
  final Widget? child;

  const MultiSignalBuilder({
    super.key,
    required this.signals,
    required this.builder,
    this.child,
  });

  @override
  State<MultiSignalBuilder> createState() => _MultiSignalBuilderState();
}

class _MultiSignalBuilderState extends State<MultiSignalBuilder> {
  Effect? _effect;
  late List<dynamic> _lastValues;

  @override
  void initState() {
    super.initState();
    _lastValues = widget.signals.map((s) => s.value).toList();
    _subscribeToSignals();
    _trackForDevTools();
  }

  void _trackForDevTools() {
    if (kDebugMode) {
      for (int i = 0; i < widget.signals.length; i++) {
        VoidSignalsDebugService.tracker.trackSignal(
          widget.signals[i],
          label: 'MultiSignalBuilder[${i}]',
        );
      }
    }
  }

  void _subscribeToSignals() {
    _effect = effect(() {
      // Access all signals to track them
      bool hasChanged = false;
      for (int i = 0; i < widget.signals.length; i++) {
        final newValue = widget.signals[i].value;
        if (i < _lastValues.length && _lastValues[i] != newValue) {
          hasChanged = true;
        }
      }
      if (hasChanged) {
        _lastValues = widget.signals.map((s) => s.value).toList();
        _safeSetState();
      }
    });
  }

  void _safeSetState() {
    if (!mounted) return;
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
  void didUpdateWidget(MultiSignalBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!listEquals(oldWidget.signals, widget.signals)) {
      _effect?.stop();
      _lastValues = widget.signals.map((s) => s.value).toList();
      _subscribeToSignals();
    }
  }

  @override
  void dispose() {
    _effect?.stop();
    _effect = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, widget.child);
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(IterableProperty<Signal>('signals', widget.signals));
  }
}

/// A widget that rebuilds when a [Computed] changes.
///
/// This widget subscribes to a computed value and rebuilds whenever
/// the computed's value changes.
///
/// Example:
/// ```dart
/// final count = signal(0);
/// final doubled = computed((prev) => count() * 2);
///
/// ComputedBuilder<int>(
///   computed: doubled,
///   builder: (context, value, child) {
///     return Text('Doubled: $value');
///   },
/// )
/// ```
class ComputedBuilder<T> extends StatefulWidget {
  /// The computed to subscribe to.
  final Computed<T> computed;

  /// Builder function that receives the current computed value.
  final Widget Function(BuildContext context, T value, Widget? child) builder;

  /// Optional child widget that doesn't depend on the computed value.
  final Widget? child;

  const ComputedBuilder({
    super.key,
    required this.computed,
    required this.builder,
    this.child,
  });

  @override
  State<ComputedBuilder<T>> createState() => _ComputedBuilderState<T>();
}

class _ComputedBuilderState<T> extends State<ComputedBuilder<T>> {
  Effect? _effect;
  late T _lastValue;

  @override
  void initState() {
    super.initState();
    _lastValue = widget.computed.value;
    _subscribeToComputed();
    _trackForDevTools();
  }

  void _trackForDevTools() {
    if (kDebugMode) {
      VoidSignalsDebugService.tracker.trackComputed(
        widget.computed,
        label: 'ComputedBuilder<$T>',
      );
    }
  }

  void _subscribeToComputed() {
    _effect = effect(() {
      // Access the computed to track it
      final newValue = widget.computed.value;
      // Only trigger rebuild if value actually changed
      if (_lastValue != newValue) {
        _lastValue = newValue;
        _safeSetState();
      }
    });
  }

  void _safeSetState() {
    if (!mounted) return;
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
  void didUpdateWidget(ComputedBuilder<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.computed, widget.computed)) {
      _effect?.stop();
      _lastValue = widget.computed.value;
      _subscribeToComputed();
    }
  }

  @override
  void dispose() {
    _effect?.stop();
    _effect = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, widget.computed.value, widget.child);
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
        .add(DiagnosticsProperty<Computed<T>>('computed', widget.computed));
    properties.add(DiagnosticsProperty<T>('value', _lastValue));
  }
}

/// A widget that subscribes to reactive dependencies and rebuilds automatically.
///
/// This is the recommended way to use signals in Flutter. Unlike [SignalBuilder]
/// or [ComputedBuilder], this widget doesn't require you to specify which signals
/// to watch. It automatically tracks all reactive dependencies accessed during
/// the build.
///
/// This is the simplest and most flexible reactive widget - just access any
/// signals in the builder and the widget will automatically rebuild when
/// they change.
///
/// ## How it works
///
/// Watch uses a clever technique to track dependencies:
/// 1. On first build, it runs your builder inside an effect to track all accessed signals
/// 2. When any tracked signal changes, it schedules a rebuild (using microtask batching)
/// 3. Multiple rapid signal changes are coalesced into a single rebuild
///
/// ## Example
///
/// ```dart
/// final count = signal(0);
/// final multiplier = signal(2);
///
/// // Automatically tracks both count and multiplier
/// Watch(
///   builder: (context) => Text('Result: ${count.value * multiplier.value}'),
/// )
/// ```
///
/// ## With child optimization
///
/// ```dart
/// Watch(
///   child: const Icon(Icons.favorite),  // Not rebuilt
///   builder: (context, child) => Row(
///     children: [child!, Text('${count.value}')],
///   ),
/// )
/// ```
class Watch extends StatefulWidget {
  /// Builder function that can access any signals or computed values.
  ///
  /// The [child] parameter is the widget passed to [Watch.child], which
  /// can be used for optimization - it won't be rebuilt when signals change.
  final Widget Function(BuildContext context, Widget? child) builder;

  /// Optional child widget that doesn't depend on signal values.
  ///
  /// This child will not be rebuilt when signals change, which can
  /// improve performance for complex child widgets.
  final Widget? child;

  /// Creates a Watch widget.
  ///
  /// The [builder] function is called whenever any signal accessed within
  /// it changes.
  const Watch({
    super.key,
    required this.builder,
    this.child,
  });

  @override
  State<Watch> createState() => _WatchState();
}

class _WatchState extends State<Watch> {
  Effect? _effect;
  Widget? _cachedResult;

  @override
  void initState() {
    super.initState();
  }

  void _setupEffect() {
    _effect?.stop();

    // Create an effect that tracks dependencies
    bool isInitialRun = true;

    _effect = effect(() {
      // Run the builder to track dependencies and get result
      final result = widget.builder(context, widget.child);

      if (isInitialRun) {
        // First run - just cache the result
        _cachedResult = result;
        isInitialRun = false;
      } else {
        // Subsequent runs - cache new result and trigger setState
        _cachedResult = result;
        _safeSetState();
      }
    });
  }

  void _safeSetState() {
    if (!mounted) return;

    final phase = SchedulerBinding.instance.schedulerPhase;
    if (phase == SchedulerPhase.persistentCallbacks ||
        phase == SchedulerPhase.midFrameMicrotasks) {
      // In build phase, schedule for next frame
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() {});
      });
    } else {
      // Safe to call setState directly
      setState(() {});
    }
  }

  @override
  void didUpdateWidget(Watch oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.builder, widget.builder)) {
      _effect?.stop();
      _effect = null;
      _cachedResult = null;
    }
  }

  @override
  void dispose() {
    _effect?.stop();
    _effect = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Setup effect on first build or after builder changes
    if (_effect == null) {
      _setupEffect();
    }
    // Return the cached result from effect
    return _cachedResult!;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
  }
}

/// A widget that watches a specific value and rebuilds when it changes.
///
/// Unlike [Watch], this widget requires you to provide a getter function
/// that returns the value to watch. This is useful when you want more
/// explicit control over what triggers rebuilds.
///
/// ## Example
///
/// ```dart
/// final count = signal(0);
///
/// WatchValue<int>(
///   getter: () => count.value,
///   builder: (context, value) => Text('Count: $value'),
/// )
/// ```
class WatchValue<T> extends StatefulWidget {
  /// The getter function that accesses reactive values.
  final T Function() getter;

  /// Builder function that receives the current value.
  final Widget Function(BuildContext context, T value) builder;

  const WatchValue({
    super.key,
    required this.getter,
    required this.builder,
  });

  @override
  State<WatchValue<T>> createState() => _WatchValueState<T>();
}

class _WatchValueState<T> extends State<WatchValue<T>> {
  Effect? _effect;
  late T _value;

  @override
  void initState() {
    super.initState();
    _value = widget.getter();
    _setupEffect();
  }

  void _setupEffect() {
    _effect = effect(() {
      final newValue = widget.getter();
      if (_value != newValue) {
        _value = newValue;
        _safeSetState();
      }
    });
  }

  void _safeSetState() {
    if (!mounted) return;
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
  void didUpdateWidget(WatchValue<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.getter, widget.getter)) {
      _effect?.stop();
      _value = widget.getter();
      _setupEffect();
    }
  }

  @override
  void dispose() {
    _effect?.stop();
    _effect = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, _value);
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<T>('value', _value));
  }
}

/// A widget that selects a part of a signal's value and only rebuilds
/// when the selected value changes.
///
/// This is useful for performance optimization when you only need a
/// derived value from a signal.
///
/// Example:
/// ```dart
/// final user = signal(User(name: 'John', age: 30));
///
/// SignalSelector<User, String>(
///   signal: user,
///   selector: (user) => user.name,
///   builder: (context, name, child) {
///     return Text(name);
///   },
/// )
/// ```
class SignalSelector<T, R> extends StatefulWidget {
  /// The signal to select from.
  final Signal<T> signal;

  /// Function that selects a value from the signal's value.
  final R Function(T value) selector;

  /// Builder function that receives the selected value.
  final Widget Function(BuildContext context, R value, Widget? child) builder;

  /// Optional child widget that doesn't depend on the selected value.
  final Widget? child;

  const SignalSelector({
    super.key,
    required this.signal,
    required this.selector,
    required this.builder,
    this.child,
  });

  @override
  State<SignalSelector<T, R>> createState() => _SignalSelectorState<T, R>();
}

class _SignalSelectorState<T, R> extends State<SignalSelector<T, R>> {
  Effect? _effect;
  late R _selectedValue;

  @override
  void initState() {
    super.initState();
    _selectedValue = widget.selector(widget.signal.value);
    _subscribeToSignal();
    _trackForDevTools();
  }

  void _trackForDevTools() {
    if (kDebugMode) {
      VoidSignalsDebugService.tracker.trackSignal(
        widget.signal,
        label: 'SignalSelector<$T, $R>',
      );
    }
  }

  void _subscribeToSignal() {
    _effect = effect(() {
      final newSelected = widget.selector(widget.signal.value);
      if (_selectedValue != newSelected) {
        _selectedValue = newSelected;
        _safeSetState();
      }
    });
  }

  void _safeSetState() {
    if (!mounted) return;
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
  void didUpdateWidget(SignalSelector<T, R> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.signal, widget.signal) ||
        !identical(oldWidget.selector, widget.selector)) {
      _effect?.stop();
      _selectedValue = widget.selector(widget.signal.value);
      _subscribeToSignal();
    }
  }

  @override
  void dispose() {
    _effect?.stop();
    _effect = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, _selectedValue, widget.child);
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<Signal<T>>('signal', widget.signal));
    properties.add(DiagnosticsProperty<R>('selectedValue', _selectedValue));
  }
}

/// A widget that selects a part of a computed's value and only rebuilds
/// when the selected value changes.
///
/// Example:
/// ```dart
/// final users = computed((_) => fetchUsers());
///
/// ComputedSelector<List<User>, int>(
///   computed: users,
///   selector: (users) => users.length,
///   builder: (context, count, child) {
///     return Text('$count users');
///   },
/// )
/// ```
class ComputedSelector<T, R> extends StatefulWidget {
  /// The computed to select from.
  final Computed<T> computed;

  /// Function that selects a value from the computed's value.
  final R Function(T value) selector;

  /// Builder function that receives the selected value.
  final Widget Function(BuildContext context, R value, Widget? child) builder;

  /// Optional child widget that doesn't depend on the selected value.
  final Widget? child;

  const ComputedSelector({
    super.key,
    required this.computed,
    required this.selector,
    required this.builder,
    this.child,
  });

  @override
  State<ComputedSelector<T, R>> createState() => _ComputedSelectorState<T, R>();
}

class _ComputedSelectorState<T, R> extends State<ComputedSelector<T, R>> {
  Effect? _effect;
  late R _selectedValue;

  @override
  void initState() {
    super.initState();
    _selectedValue = widget.selector(widget.computed.value);
    _subscribeToComputed();
    _trackForDevTools();
  }

  void _trackForDevTools() {
    if (kDebugMode) {
      VoidSignalsDebugService.tracker.trackComputed(
        widget.computed,
        label: 'ComputedSelector<$T, $R>',
      );
    }
  }

  void _subscribeToComputed() {
    _effect = effect(() {
      final newSelected = widget.selector(widget.computed.value);
      if (_selectedValue != newSelected) {
        _selectedValue = newSelected;
        _safeSetState();
      }
    });
  }

  void _safeSetState() {
    if (!mounted) return;
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
  void didUpdateWidget(ComputedSelector<T, R> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.computed, widget.computed) ||
        !identical(oldWidget.selector, widget.selector)) {
      _effect?.stop();
      _selectedValue = widget.selector(widget.computed.value);
      _subscribeToComputed();
    }
  }

  @override
  void dispose() {
    _effect?.stop();
    _effect = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, _selectedValue, widget.child);
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
        .add(DiagnosticsProperty<Computed<T>>('computed', widget.computed));
    properties.add(DiagnosticsProperty<R>('selectedValue', _selectedValue));
  }
}
