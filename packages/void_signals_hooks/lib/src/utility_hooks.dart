import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:void_signals/void_signals.dart';

// =============================================================================
// Debounce and Throttle Hooks
// =============================================================================

/// Creates a debounced signal that only updates after a delay.
///
/// The returned computed will only update after the source signal has
/// stopped changing for the specified duration. This is useful for
/// reducing the frequency of expensive operations like API calls.
///
/// Example:
/// ```dart
/// class SearchWidget extends HookWidget {
///   @override
///   Widget build(BuildContext context) {
///     final searchText = useSignal('');
///     final debouncedSearch = useDebounced(searchText, Duration(milliseconds: 300));
///
///     // This effect only runs after typing stops for 300ms
///     useSignalEffect(() {
///       final query = debouncedSearch.value;
///       if (query.isNotEmpty) {
///         performSearch(query);
///       }
///     });
///
///     return TextField(
///       onChanged: (v) => searchText.value = v,
///       decoration: const InputDecoration(hintText: 'Search...'),
///     );
///   }
/// }
/// ```
Computed<T> useDebounced<T>(Signal<T> source, Duration duration) {
  return use(_DebouncedHook<T>(source, duration));
}

/// Creates a throttled signal that updates at most once per duration.
///
/// Unlike debouncing, throttling ensures the signal updates at regular
/// intervals during rapid changes. The first update is always applied
/// immediately.
///
/// Example:
/// ```dart
/// class ScrollTrackerWidget extends HookWidget {
///   @override
///   Widget build(BuildContext context) {
///     final scrollPosition = useSignal(0.0);
///     final throttledPosition = useThrottled(scrollPosition, Duration(milliseconds: 100));
///
///     // This effect runs at most every 100ms, even with rapid scrolling
///     useSignalEffect(() {
///       analytics.trackScrollPosition(throttledPosition.value);
///     });
///
///     return NotificationListener<ScrollNotification>(
///       onNotification: (notification) {
///         scrollPosition.value = notification.metrics.pixels;
///         return true;
///       },
///       child: ListView.builder(
///         itemCount: 100,
///         itemBuilder: (context, index) => ListTile(title: Text('Item $index')),
///       ),
///     );
///   }
/// }
/// ```
Computed<T> useThrottled<T>(Signal<T> source, Duration duration) {
  return use(_ThrottledHook<T>(source, duration));
}

// =============================================================================
// Combinator Hooks
// =============================================================================

/// Combines two signals into a computed value.
///
/// The computed updates whenever either of the source signals changes.
/// This is useful for deriving values from multiple reactive sources.
///
/// Example:
/// ```dart
/// class FullNameWidget extends HookWidget {
///   @override
///   Widget build(BuildContext context) {
///     final firstName = useSignal('John');
///     final lastName = useSignal('Doe');
///     final fullName = useCombine2(firstName, lastName, (f, l) => '$f $l');
///
///     return Text(useWatchComputed(fullName));
///   }
/// }
/// ```
Computed<R> useCombine2<T1, T2, R>(
  Signal<T1> s1,
  Signal<T2> s2,
  R Function(T1, T2) combiner,
) {
  return use(_Combine2Hook(s1, s2, combiner));
}

/// Combines three signals into a computed value.
///
/// The computed updates whenever any of the source signals changes.
///
/// Example:
/// ```dart
/// class ColorWidget extends HookWidget {
///   @override
///   Widget build(BuildContext context) {
///     final r = useSignal(255);
///     final g = useSignal(128);
///     final b = useSignal(0);
///     final color = useCombine3(r, g, b, (r, g, b) => Color.fromRGBO(r, g, b, 1.0));
///
///     return Container(
///       color: useWatchComputed(color),
///       child: const Text('Color Preview'),
///     );
///   }
/// }
/// ```
Computed<R> useCombine3<T1, T2, T3, R>(
  Signal<T1> s1,
  Signal<T2> s2,
  Signal<T3> s3,
  R Function(T1, T2, T3) combiner,
) {
  return use(_Combine3Hook(s1, s2, s3, combiner));
}

/// Returns the current and previous value of a signal.
///
/// Returns a tuple of `(current, previous)` where:
/// - `current`: A computed that always has the current signal value
/// - `previous`: A computed that has the previous value (null on first access)
///
/// This is useful for animations, comparisons, or detecting changes.
///
/// Example:
/// ```dart
/// class AnimatedCounterWidget extends HookWidget {
///   @override
///   Widget build(BuildContext context) {
///     final count = useSignal(0);
///     final (current, previous) = usePrevious(count);
///
///     final currentValue = useWatchComputed(current);
///     final previousValue = useWatchComputed(previous);
///
///     return Column(
///       children: [
///         Text('Current: $currentValue'),
///         Text('Previous: ${previousValue ?? 'N/A'}'),
///         if (previousValue != null)
///           Text('Change: ${currentValue - previousValue}'),
///         ElevatedButton(
///           onPressed: () => count.value++,
///           child: const Text('Increment'),
///         ),
///       ],
///     );
///   }
/// }
/// ```
(Computed<T>, Computed<T?>) usePrevious<T>(Signal<T> source) {
  return use(_PreviousHook<T>(source));
}

// =============================================================================
// Hook Implementations
// =============================================================================

class _DebouncedHook<T> extends Hook<Computed<T>> {
  const _DebouncedHook(this.source, this.duration);
  final Signal<T> source;
  final Duration duration;

  @override
  _DebouncedHookState<T> createState() => _DebouncedHookState<T>();
}

class _DebouncedHookState<T> extends HookState<Computed<T>, _DebouncedHook<T>> {
  late Signal<T> _debouncedSignal;
  late Computed<T> _computed;
  Timer? _timer;
  Effect? _effect;

  @override
  void initHook() {
    _debouncedSignal = signal<T>(hook.source.value);
    _computed = computed((_) => _debouncedSignal.value);
    _effect = effect(() {
      final value = hook.source.value;
      _timer?.cancel();
      _timer = Timer(hook.duration, () {
        _debouncedSignal.value = value;
      });
    });
  }

  @override
  void didUpdateHook(_DebouncedHook<T> oldHook) {
    if (!identical(oldHook.source, hook.source) ||
        oldHook.duration != hook.duration) {
      _effect?.stop();
      _timer?.cancel();
      _debouncedSignal = signal<T>(hook.source.value);
      _computed = computed((_) => _debouncedSignal.value);
      _effect = effect(() {
        final value = hook.source.value;
        _timer?.cancel();
        _timer = Timer(hook.duration, () {
          _debouncedSignal.value = value;
        });
      });
    }
  }

  @override
  Computed<T> build(BuildContext context) => _computed;

  @override
  void dispose() {
    _timer?.cancel();
    _effect?.stop();
  }

  @override
  String get debugLabel => 'useDebounced<$T>';
}

class _ThrottledHook<T> extends Hook<Computed<T>> {
  const _ThrottledHook(this.source, this.duration);
  final Signal<T> source;
  final Duration duration;

  @override
  _ThrottledHookState<T> createState() => _ThrottledHookState<T>();
}

class _ThrottledHookState<T> extends HookState<Computed<T>, _ThrottledHook<T>> {
  late Signal<T> _throttledSignal;
  late Computed<T> _computed;
  Effect? _effect;
  DateTime? _lastUpdate;

  @override
  void initHook() {
    _throttledSignal = signal<T>(hook.source.value);
    _computed = computed((_) => _throttledSignal.value);
    _effect = effect(() {
      final value = hook.source.value;
      final now = DateTime.now();
      if (_lastUpdate == null ||
          now.difference(_lastUpdate!) >= hook.duration) {
        _lastUpdate = now;
        _throttledSignal.value = value;
      }
    });
  }

  @override
  void didUpdateHook(_ThrottledHook<T> oldHook) {
    if (!identical(oldHook.source, hook.source) ||
        oldHook.duration != hook.duration) {
      _effect?.stop();
      _lastUpdate = null;
      _throttledSignal = signal<T>(hook.source.value);
      _computed = computed((_) => _throttledSignal.value);
      _effect = effect(() {
        final value = hook.source.value;
        final now = DateTime.now();
        if (_lastUpdate == null ||
            now.difference(_lastUpdate!) >= hook.duration) {
          _lastUpdate = now;
          _throttledSignal.value = value;
        }
      });
    }
  }

  @override
  Computed<T> build(BuildContext context) => _computed;

  @override
  void dispose() => _effect?.stop();

  @override
  String get debugLabel => 'useThrottled<$T>';
}

class _Combine2Hook<T1, T2, R> extends Hook<Computed<R>> {
  const _Combine2Hook(this.s1, this.s2, this.combiner);
  final Signal<T1> s1;
  final Signal<T2> s2;
  final R Function(T1, T2) combiner;

  @override
  _Combine2HookState<T1, T2, R> createState() =>
      _Combine2HookState<T1, T2, R>();
}

class _Combine2HookState<T1, T2, R>
    extends HookState<Computed<R>, _Combine2Hook<T1, T2, R>> {
  late Computed<R> _computed;

  @override
  void initHook() {
    _computed = computed((_) => hook.combiner(hook.s1.value, hook.s2.value));
  }

  @override
  void didUpdateHook(_Combine2Hook<T1, T2, R> oldHook) {
    if (!identical(oldHook.s1, hook.s1) ||
        !identical(oldHook.s2, hook.s2) ||
        !identical(oldHook.combiner, hook.combiner)) {
      _computed = computed((_) => hook.combiner(hook.s1.value, hook.s2.value));
    }
  }

  @override
  Computed<R> build(BuildContext context) => _computed;

  @override
  String get debugLabel => 'useCombine2<$T1, $T2, $R>';
}

class _Combine3Hook<T1, T2, T3, R> extends Hook<Computed<R>> {
  const _Combine3Hook(this.s1, this.s2, this.s3, this.combiner);
  final Signal<T1> s1;
  final Signal<T2> s2;
  final Signal<T3> s3;
  final R Function(T1, T2, T3) combiner;

  @override
  _Combine3HookState<T1, T2, T3, R> createState() =>
      _Combine3HookState<T1, T2, T3, R>();
}

class _Combine3HookState<T1, T2, T3, R>
    extends HookState<Computed<R>, _Combine3Hook<T1, T2, T3, R>> {
  late Computed<R> _computed;

  @override
  void initHook() {
    _computed = computed(
      (_) => hook.combiner(hook.s1.value, hook.s2.value, hook.s3.value),
    );
  }

  @override
  void didUpdateHook(_Combine3Hook<T1, T2, T3, R> oldHook) {
    if (!identical(oldHook.s1, hook.s1) ||
        !identical(oldHook.s2, hook.s2) ||
        !identical(oldHook.s3, hook.s3) ||
        !identical(oldHook.combiner, hook.combiner)) {
      _computed = computed(
        (_) => hook.combiner(hook.s1.value, hook.s2.value, hook.s3.value),
      );
    }
  }

  @override
  Computed<R> build(BuildContext context) => _computed;

  @override
  String get debugLabel => 'useCombine3<$T1, $T2, $T3, $R>';
}

class _PreviousHook<T> extends Hook<(Computed<T>, Computed<T?>)> {
  const _PreviousHook(this.source);
  final Signal<T> source;

  @override
  _PreviousHookState<T> createState() => _PreviousHookState<T>();
}

class _PreviousHookState<T>
    extends HookState<(Computed<T>, Computed<T?>), _PreviousHook<T>> {
  late Signal<T?> _previousSignal;
  late Computed<T> _currentComputed;
  late Computed<T?> _previousComputed;
  T? _previous;
  Effect? _effect;

  @override
  void initHook() {
    _previousSignal = signal<T?>(null);
    _currentComputed = computed((_) => hook.source.value);
    _previousComputed = computed((_) => _previousSignal.value);
    _effect = effect(() {
      final current = hook.source.value;
      _previousSignal.value = _previous;
      _previous = current;
    });
  }

  @override
  void didUpdateHook(_PreviousHook<T> oldHook) {
    if (!identical(oldHook.source, hook.source)) {
      _effect?.stop();
      _previous = null;
      _previousSignal = signal<T?>(null);
      _currentComputed = computed((_) => hook.source.value);
      _previousComputed = computed((_) => _previousSignal.value);
      _effect = effect(() {
        final current = hook.source.value;
        _previousSignal.value = _previous;
        _previous = current;
      });
    }
  }

  @override
  (Computed<T>, Computed<T?>) build(BuildContext context) =>
      (_currentComputed, _previousComputed);

  @override
  void dispose() => _effect?.stop();

  @override
  String get debugLabel => 'usePrevious<$T>';
}
