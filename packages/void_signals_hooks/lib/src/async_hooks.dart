import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:void_signals/void_signals.dart';

import 'core_hooks.dart';

// =============================================================================
// Async Hooks
//
// These hooks provide convenient patterns for handling asynchronous operations
// with signals in Flutter hooks.
// =============================================================================

/// The state of an async operation.
enum AsyncStatus {
  /// The operation has not started yet.
  idle,

  /// The operation is currently loading.
  loading,

  /// The operation completed successfully.
  success,

  /// The operation failed with an error.
  error,
}

/// The result of an async operation.
class UseAsyncState<T> {
  /// The current status of the operation.
  final AsyncStatus status;

  /// The data from the operation, if successful.
  final T? data;

  /// The error from the operation, if failed.
  final Object? error;

  /// The stack trace from the error, if available.
  final StackTrace? stackTrace;

  const UseAsyncState._({
    required this.status,
    this.data,
    this.error,
    this.stackTrace,
  });

  /// Creates an idle state.
  const UseAsyncState.idle() : this._(status: AsyncStatus.idle);

  /// Creates a loading state.
  const UseAsyncState.loading() : this._(status: AsyncStatus.loading);

  /// Creates a success state with data.
  const UseAsyncState.success(T data)
      : this._(status: AsyncStatus.success, data: data);

  /// Creates an error state.
  const UseAsyncState.error(Object error, [StackTrace? stackTrace])
      : this._(status: AsyncStatus.error, error: error, stackTrace: stackTrace);

  /// Whether the operation is idle.
  bool get isIdle => status == AsyncStatus.idle;

  /// Whether the operation is loading.
  bool get isLoading => status == AsyncStatus.loading;

  /// Whether the operation completed successfully.
  bool get isSuccess => status == AsyncStatus.success;

  /// Whether the operation failed.
  bool get isError => status == AsyncStatus.error;

  /// Whether the operation has completed (success or error).
  bool get isComplete => isSuccess || isError;

  /// Returns the data if available, otherwise the provided default.
  T dataOr(T defaultValue) => data ?? defaultValue;

  /// Maps the data to a new type.
  UseAsyncState<R> map<R>(R Function(T data) mapper) {
    if (isSuccess && data != null) {
      return UseAsyncState.success(mapper(data as T));
    }
    return UseAsyncState._(
      status: status,
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// Returns the appropriate widget based on the state.
  Widget when({
    required Widget Function() idle,
    required Widget Function() loading,
    required Widget Function(T data) success,
    required Widget Function(Object error, StackTrace? stackTrace) error,
  }) {
    return switch (status) {
      AsyncStatus.idle => idle(),
      AsyncStatus.loading => loading(),
      AsyncStatus.success => success(data as T),
      AsyncStatus.error => error(this.error!, stackTrace),
    };
  }

  /// Returns the appropriate widget based on the state with fallback.
  Widget maybeWhen({
    Widget Function()? idle,
    Widget Function()? loading,
    Widget Function(T data)? success,
    Widget Function(Object error, StackTrace? stackTrace)? error,
    required Widget Function() orElse,
  }) {
    return switch (status) {
      AsyncStatus.idle => idle?.call() ?? orElse(),
      AsyncStatus.loading => loading?.call() ?? orElse(),
      AsyncStatus.success => success?.call(data as T) ?? orElse(),
      AsyncStatus.error => error?.call(this.error!, stackTrace) ?? orElse(),
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UseAsyncState<T> &&
        other.status == status &&
        other.data == data &&
        other.error == error;
  }

  @override
  int get hashCode => Object.hash(status, data, error);

  @override
  String toString() {
    return switch (status) {
      AsyncStatus.idle => 'UseAsyncState.idle()',
      AsyncStatus.loading => 'UseAsyncState.loading()',
      AsyncStatus.success => 'UseAsyncState.success($data)',
      AsyncStatus.error => 'UseAsyncState.error($error)',
    };
  }
}

/// Controller for async operations.
///
/// Provides state management and control methods for async operations.
class UseAsyncController<T> {
  final UseAsyncState<T> Function() _getState;
  final Future<void> Function(Future<T> Function()) _execute;
  final void Function() _reset;

  UseAsyncController._(this._getState, this._execute, this._reset);

  /// The current state of the async operation.
  UseAsyncState<T> get state => _getState();

  /// Executes the async operation.
  Future<void> execute(Future<T> Function() operation) => _execute(operation);

  /// Resets the state to idle.
  void reset() => _reset();
}

/// Creates a hook for managing async operations.
///
/// Returns a [UseAsyncController] that provides:
/// - `state`: The current [UseAsyncState]
/// - `execute`: A method to execute the async operation
/// - `reset`: A method to reset the state to idle
///
/// Example:
/// ```dart
/// class UserWidget extends HookWidget {
///   @override
///   Widget build(BuildContext context) {
///     final async = useAsync<User>();
///     final state = useWatch(async.stateSignal);
///
///     return state.when(
///       idle: () => ElevatedButton(
///         onPressed: () => async.execute(() => api.fetchUser(userId)),
///         child: const Text('Load User'),
///       ),
///       loading: () => const CircularProgressIndicator(),
///       success: (user) => Text('Hello, ${user.name}!'),
///       error: (e, _) => Column(
///         children: [
///           Text('Error: $e'),
///           ElevatedButton(onPressed: async.reset, child: const Text('Retry')),
///         ],
///       ),
///     );
///   }
/// }
/// ```
UseAsyncController<T> useAsync<T>() {
  return use(_AsyncHook<T>());
}

/// Creates a hook that automatically executes an async operation.
///
/// The operation runs immediately and can be re-executed by changing keys.
///
/// Example:
/// ```dart
/// class UserProfileWidget extends HookWidget {
///   final String userId;
///   const UserProfileWidget({required this.userId});
///
///   @override
///   Widget build(BuildContext context) {
///     final state = useAsyncData(
///       () => api.fetchUser(userId),
///       keys: [userId],
///     );
///
///     return state.when(
///       idle: () => const SizedBox(), // Should never happen
///       loading: () => const CircularProgressIndicator(),
///       success: (user) => Text('Hello, ${user.name}!'),
///       error: (e, _) => Text('Error: $e'),
///     );
///   }
/// }
/// ```
UseAsyncState<T> useAsyncData<T>(
  Future<T> Function() operation, {
  List<Object?>? keys,
}) {
  return use(_AsyncDataHook<T>(operation, keys));
}

/// Creates a hook that tracks the latest value of a signal without subscribing.
///
/// This is useful when you need to access the current value in callbacks
/// without creating a reactive dependency.
///
/// Example:
/// ```dart
/// class FormWidget extends HookWidget {
///   @override
///   Widget build(BuildContext context) {
///     final count = useSignal(0);
///     final latestCount = useLatest(count);
///
///     return ElevatedButton(
///       onPressed: () {
///         // Access latest value without reactive dependency
///         print('Count was: ${latestCount.current}');
///       },
///       child: const Text('Log Count'),
///     );
///   }
/// }
/// ```
ValueRef<T> useLatest<T>(Signal<T> signal) {
  return use(_LatestHook<T>(signal));
}

/// A reference to the latest value.
class ValueRef<T> {
  final Signal<T> _signal;

  ValueRef._(this._signal);

  /// Gets the current value.
  T get current => _signal.value;
}

/// Creates a listener that runs on signal changes without triggering rebuild.
///
/// This is useful for side effects like logging, analytics, or navigation.
///
/// Example:
/// ```dart
/// class NavigationWidget extends HookWidget {
///   @override
///   Widget build(BuildContext context) {
///     final route = useSignal('/home');
///
///     useListener(route, (value) {
///       Navigator.pushNamed(context, value);
///     });
///
///     return const SizedBox();
///   }
/// }
/// ```
void useListener<T>(
  Signal<T> signal,
  void Function(T value) listener, {
  bool fireImmediately = false,
}) {
  use(_ListenerHook<T>(signal, listener, fireImmediately));
}

// =============================================================================
// Common State Hooks
// =============================================================================

/// Creates a toggle hook for boolean state.
///
/// Returns a tuple of:
/// - `value`: The current boolean value
/// - `toggle`: A function to toggle the value
/// - `setTrue`: A function to set the value to true
/// - `setFalse`: A function to set the value to false
///
/// Example:
/// ```dart
/// class ToggleWidget extends HookWidget {
///   @override
///   Widget build(BuildContext context) {
///     final (isOn, toggle, setOn, setOff) = useToggle(false);
///
///     return Column(
///       children: [
///         Switch(value: isOn, onChanged: (_) => toggle()),
///         TextButton(onPressed: setOn, child: const Text('Turn On')),
///         TextButton(onPressed: setOff, child: const Text('Turn Off')),
///       ],
///     );
///   }
/// }
/// ```
(bool, void Function(), void Function(), void Function()) useToggle([
  bool initialValue = false,
]) {
  final sig = useSignal(initialValue);
  final value = useWatch(sig);

  return (
    value,
    () => sig.value = !sig.value,
    () => sig.value = true,
    () => sig.value = false,
  );
}

/// Creates a counter hook with increment, decrement, and reset functions.
///
/// Returns a tuple of:
/// - `count`: The current count value
/// - `increment`: A function to increment by 1 (or custom step)
/// - `decrement`: A function to decrement by 1 (or custom step)
/// - `reset`: A function to reset to initial value
/// - `set`: A function to set a specific value
///
/// Example:
/// ```dart
/// class CounterWidget extends HookWidget {
///   @override
///   Widget build(BuildContext context) {
///     final (count, inc, dec, reset, set) = useCounter(0);
///
///     return Column(
///       children: [
///         Text('Count: $count'),
///         Row(
///           children: [
///             IconButton(onPressed: dec, icon: const Icon(Icons.remove)),
///             IconButton(onPressed: inc, icon: const Icon(Icons.add)),
///           ],
///         ),
///         TextButton(onPressed: reset, child: const Text('Reset')),
///         TextButton(onPressed: () => set(100), child: const Text('Set to 100')),
///       ],
///     );
///   }
/// }
/// ```
(
  int,
  void Function([int step]),
  void Function([int step]),
  void Function(),
  void Function(int),
) useCounter([int initialValue = 0]) {
  final sig = useSignal(initialValue);
  final value = useWatch(sig);
  final initial = useMemoized(() => initialValue);

  return (
    value,
    ([int step = 1]) => sig.value += step,
    ([int step = 1]) => sig.value -= step,
    () => sig.value = initial,
    (int v) => sig.value = v,
  );
}

/// Creates an interval that runs a callback periodically.
///
/// The interval is automatically canceled when the widget is disposed.
/// Pass `null` as the callback to pause the interval.
///
/// Example:
/// ```dart
/// class TimerWidget extends HookWidget {
///   @override
///   Widget build(BuildContext context) {
///     final (seconds, _, _, _, _) = useCounter(0);
///     final isRunning = useSignal(true);
///     final running = useWatch(isRunning);
///
///     useInterval(
///       running ? () => seconds++ : null,
///       const Duration(seconds: 1),
///     );
///
///     return Column(
///       children: [
///         Text('Seconds: $seconds'),
///         ElevatedButton(
///           onPressed: () => isRunning.value = !isRunning.value,
///           child: Text(running ? 'Pause' : 'Resume'),
///         ),
///       ],
///     );
///   }
/// }
/// ```
void useInterval(void Function()? callback, Duration duration) {
  use(_IntervalHook(callback, duration));
}

/// Creates a timeout that runs a callback after a delay.
///
/// The timeout is automatically canceled when the widget is disposed.
/// Returns a function to cancel the timeout manually.
///
/// Example:
/// ```dart
/// class NotificationWidget extends HookWidget {
///   @override
///   Widget build(BuildContext context) {
///     final visible = useSignal(true);
///     final showing = useWatch(visible);
///
///     final cancel = useTimeout(
///       showing ? () => visible.value = false : null,
///       const Duration(seconds: 5),
///     );
///
///     if (!showing) return const SizedBox();
///
///     return Row(
///       children: [
///         const Text('Notification'),
///         IconButton(onPressed: cancel, icon: const Icon(Icons.close)),
///       ],
///     );
///   }
/// }
/// ```
void Function() useTimeout(void Function()? callback, Duration duration) {
  return use(_TimeoutHook(callback, duration));
}

// =============================================================================
// Hook Implementations
// =============================================================================

class _AsyncHook<T> extends Hook<UseAsyncController<T>> {
  const _AsyncHook();

  @override
  _AsyncHookState<T> createState() => _AsyncHookState<T>();
}

class _AsyncHookState<T>
    extends HookState<UseAsyncController<T>, _AsyncHook<T>> {
  late Signal<UseAsyncState<T>> _state;
  late UseAsyncController<T> _controller;
  int _operationId = 0;

  @override
  void initHook() {
    _state = signal(const UseAsyncState.idle());
    _controller = UseAsyncController._(() => _state.value, _execute, _reset);
  }

  Future<void> _execute(Future<T> Function() operation) async {
    final currentId = ++_operationId;
    _state.value = const UseAsyncState.loading();

    try {
      final result = await operation();
      if (currentId == _operationId) {
        _state.value = UseAsyncState.success(result);
      }
    } catch (e, st) {
      if (currentId == _operationId) {
        _state.value = UseAsyncState.error(e, st);
      }
    }
  }

  void _reset() {
    _operationId++;
    _state.value = const UseAsyncState.idle();
  }

  @override
  UseAsyncController<T> build(BuildContext context) => _controller;

  @override
  String get debugLabel => 'useAsync<$T>';
}

class _AsyncDataHook<T> extends Hook<UseAsyncState<T>> {
  const _AsyncDataHook(this.operation, this.keys);
  final Future<T> Function() operation;
  final List<Object?>? keys;

  @override
  _AsyncDataHookState<T> createState() => _AsyncDataHookState<T>();
}

class _AsyncDataHookState<T>
    extends HookState<UseAsyncState<T>, _AsyncDataHook<T>> {
  late Signal<UseAsyncState<T>> _state;
  Effect? _effect;
  int _operationId = 0;

  @override
  void initHook() {
    _state = signal(const UseAsyncState.loading());
    _subscribe();
    _execute();
  }

  void _subscribe() {
    _effect = effect(() {
      // Read the state to create dependency
      _state.value;
      // Schedule rebuild
      setState(() {});
    });
  }

  @override
  void didUpdateHook(_AsyncDataHook<T> oldHook) {
    if (hook.keys != null &&
        oldHook.keys != null &&
        !listEquals(hook.keys, oldHook.keys)) {
      _execute();
    }
  }

  Future<void> _execute() async {
    final currentId = ++_operationId;
    _state.value = const UseAsyncState.loading();

    try {
      final result = await hook.operation();
      if (currentId == _operationId) {
        _state.value = UseAsyncState.success(result);
      }
    } catch (e, st) {
      if (currentId == _operationId) {
        _state.value = UseAsyncState.error(e, st);
      }
    }
  }

  @override
  UseAsyncState<T> build(BuildContext context) => _state.value;

  @override
  void dispose() {
    _effect?.stop();
    _effect = null;
  }

  @override
  String get debugLabel => 'useAsyncData<$T>';
}

class _LatestHook<T> extends Hook<ValueRef<T>> {
  const _LatestHook(this.signal);
  final Signal<T> signal;

  @override
  _LatestHookState<T> createState() => _LatestHookState<T>();
}

class _LatestHookState<T> extends HookState<ValueRef<T>, _LatestHook<T>> {
  late ValueRef<T> _ref;

  @override
  void initHook() {
    _ref = ValueRef._(hook.signal);
  }

  @override
  void didUpdateHook(_LatestHook<T> oldHook) {
    if (!identical(oldHook.signal, hook.signal)) {
      _ref = ValueRef._(hook.signal);
    }
  }

  @override
  ValueRef<T> build(BuildContext context) => _ref;

  @override
  String get debugLabel => 'useLatest<$T>';
}

class _ListenerHook<T> extends Hook<void> {
  const _ListenerHook(this.signal, this.listener, this.fireImmediately);
  final Signal<T> signal;
  final void Function(T value) listener;
  final bool fireImmediately;

  @override
  _ListenerHookState<T> createState() => _ListenerHookState<T>();
}

class _ListenerHookState<T> extends HookState<void, _ListenerHook<T>> {
  Effect? _effect;
  bool _isFirst = true;

  @override
  void initHook() {
    _subscribe();
  }

  void _subscribe() {
    _isFirst = true;
    _effect = effect(() {
      final value = hook.signal.value;
      if (_isFirst) {
        _isFirst = false;
        if (hook.fireImmediately) {
          hook.listener(value);
        }
      } else {
        hook.listener(value);
      }
    });
  }

  @override
  void didUpdateHook(_ListenerHook<T> oldHook) {
    if (!identical(oldHook.signal, hook.signal) ||
        !identical(oldHook.listener, hook.listener)) {
      _effect?.stop();
      _subscribe();
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
  String get debugLabel => 'useListener<$T>';
}

class _IntervalHook extends Hook<void> {
  const _IntervalHook(this.callback, this.duration);
  final void Function()? callback;
  final Duration duration;

  @override
  _IntervalHookState createState() => _IntervalHookState();
}

class _IntervalHookState extends HookState<void, _IntervalHook> {
  Timer? _timer;

  @override
  void initHook() {
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    if (hook.callback != null) {
      _timer = Timer.periodic(hook.duration, (_) => hook.callback!());
    }
  }

  @override
  void didUpdateHook(_IntervalHook oldHook) {
    if (!identical(oldHook.callback, hook.callback) ||
        oldHook.duration != hook.duration) {
      _startTimer();
    }
  }

  @override
  void build(BuildContext context) {}

  @override
  void dispose() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  String get debugLabel => 'useInterval';
}

class _TimeoutHook extends Hook<void Function()> {
  const _TimeoutHook(this.callback, this.duration);
  final void Function()? callback;
  final Duration duration;

  @override
  _TimeoutHookState createState() => _TimeoutHookState();
}

class _TimeoutHookState extends HookState<void Function(), _TimeoutHook> {
  Timer? _timer;

  @override
  void initHook() {
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    if (hook.callback != null) {
      _timer = Timer(hook.duration, () => hook.callback!());
    }
  }

  void _cancel() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void didUpdateHook(_TimeoutHook oldHook) {
    if (!identical(oldHook.callback, hook.callback) ||
        oldHook.duration != hook.duration) {
      _startTimer();
    }
  }

  @override
  void Function() build(BuildContext context) => _cancel;

  @override
  void dispose() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  String get debugLabel => 'useTimeout';
}
