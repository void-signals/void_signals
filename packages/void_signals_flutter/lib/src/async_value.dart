import 'dart:async';

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:void_signals/void_signals.dart';

// Re-export AsyncValue types from void_signals for convenience
// These are already exported via void_signals.dart, but we keep
// them here for backwards compatibility with direct imports
export 'package:void_signals/void_signals.dart'
    show
        AsyncValue,
        AsyncLoading,
        AsyncLoadingWithPrevious,
        AsyncData,
        AsyncError,
        AsyncErrorWithPrevious,
        AsyncComputed,
        asyncComputed,
        StreamComputed,
        streamComputed,
        combineAsync;

/// Creates an async signal from a [Future].
///
/// The signal will be in loading state initially, then transition to
/// data or error state when the future completes.
///
/// Example:
/// ```dart
/// final userSignal = asyncSignal(fetchUser());
/// ```
Signal<AsyncValue<T>> asyncSignal<T>(Future<T> future) {
  final sig = signal<AsyncValue<T>>(AsyncLoading<T>());

  future.then(
    (value) {
      sig.value = AsyncData(value);
    },
  ).catchError((Object error, StackTrace stackTrace) {
    sig.value = AsyncError(error, stackTrace);
  });

  return sig;
}

/// Creates an async signal from a [Stream].
///
/// The signal will be in loading state initially, then update with
/// data or error as the stream emits values.
///
/// Example:
/// ```dart
/// final messagesSignal = asyncSignalFromStream(messagesStream);
/// ```
Signal<AsyncValue<T>> asyncSignalFromStream<T>(
  Stream<T> stream, {
  T? initialValue,
}) {
  final AsyncValue<T> initial =
      initialValue != null ? AsyncData<T>(initialValue) : AsyncLoading<T>();
  final sig = signal<AsyncValue<T>>(initial);

  stream.listen(
    (value) => sig.value = AsyncData(value),
    onError: (Object error, StackTrace stackTrace) =>
        sig.value = AsyncError(error, stackTrace),
  );

  return sig;
}

/// Extension methods for [AsyncValue] in Flutter widgets.
extension AsyncValueWidgetExtension<T> on AsyncValue<T> {
  /// Builds a widget based on the async value state.
  ///
  /// Example:
  /// ```dart
  /// asyncValue.widget(
  ///   loading: () => CircularProgressIndicator(),
  ///   data: (value) => Text('$value'),
  ///   error: (e, s) => Text('Error: $e'),
  /// )
  /// ```
  Widget widget({
    required Widget Function() loading,
    required Widget Function(T value) data,
    required Widget Function(Object error, StackTrace stackTrace) error,
  }) {
    return when(loading: loading, data: data, error: error);
  }

  /// Builds a widget with default loading and error widgets.
  ///
  /// Example:
  /// ```dart
  /// asyncValue.whenData((value) => Text('$value'))
  /// ```
  Widget whenData(
    Widget Function(T value) data, {
    Widget Function()? loading,
    Widget Function(Object error, StackTrace stackTrace)? error,
  }) {
    return when(
      loading: loading ?? () => const SizedBox.shrink(),
      data: data,
      error: error ?? (e, s) => const SizedBox.shrink(),
    );
  }
}

/// A widget that builds based on an [AsyncValue] signal.
///
/// Example:
/// ```dart
/// final userSignal = asyncSignal(fetchUser());
///
/// AsyncSignalBuilder<User>(
///   signal: userSignal,
///   loading: (context) => CircularProgressIndicator(),
///   data: (context, user) => Text(user.name),
///   error: (context, error, stackTrace) => Text('Error: $error'),
/// )
/// ```
class AsyncSignalBuilder<T> extends StatefulWidget {
  /// The async value signal to watch.
  final Signal<AsyncValue<T>> signal;

  /// Builder for the loading state.
  final Widget Function(BuildContext context) loading;

  /// Builder for the data state.
  final Widget Function(BuildContext context, T value) data;

  /// Builder for the error state.
  final Widget Function(
      BuildContext context, Object error, StackTrace stackTrace) error;

  const AsyncSignalBuilder({
    super.key,
    required this.signal,
    required this.loading,
    required this.data,
    required this.error,
  });

  @override
  State<AsyncSignalBuilder<T>> createState() => _AsyncSignalBuilderState<T>();
}

class _AsyncSignalBuilderState<T> extends State<AsyncSignalBuilder<T>> {
  Effect? _effect;
  late AsyncValue<T> _lastValue;

  @override
  void initState() {
    super.initState();
    _lastValue = widget.signal.value;
    _subscribeToSignal();
  }

  void _subscribeToSignal() {
    _effect = effect(() {
      final newValue = widget.signal.value;
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
  void didUpdateWidget(AsyncSignalBuilder<T> oldWidget) {
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
    return _lastValue.when(
      loading: () => widget.loading(context),
      data: (value) => widget.data(context, value),
      error: (error, stackTrace) => widget.error(context, error, stackTrace),
    );
  }
}
