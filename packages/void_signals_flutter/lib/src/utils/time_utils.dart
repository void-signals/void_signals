import 'dart:async';

import 'package:void_signals/void_signals.dart' as signals;
import 'package:void_signals/void_signals.dart' show Signal, untrack;

/// Result of a debounced/throttled/delayed signal operation.
///
/// Contains a signal with the timed value and a dispose function to clean up resources.
class TimedSignal<T> {
  /// The signal that holds the timed value.
  final Signal<T> _signal;

  /// Disposes the internal effect and timer resources.
  final void Function() dispose;

  const TimedSignal._({required Signal<T> signal, required this.dispose})
      : _signal = signal;

  /// Gets the current value of the timed signal.
  ///
  /// This also tracks the signal as a dependency if called within
  /// an effect or computed context.
  T get value => _signal.value;

  /// Convenience method to get the current value (callable syntax).
  T call() => _signal.value;

  /// Gets the underlying signal.
  ///
  /// Use this when you need to pass the signal to a builder widget.
  Signal<T> get signal => _signal;
}

/// Creates a debounced signal that only updates after a delay.
///
/// The signal will wait for the specified duration after the last update
/// before actually changing the value.
///
/// **Important:** Call [TimedSignal.dispose] when no longer needed to prevent
/// memory leaks.
///
/// Example:
/// ```dart
/// final searchQuery = signal('');
/// final debouncedResult = debounced(searchQuery, Duration(milliseconds: 300));
///
/// // Use the debounced value
/// effect(() {
///   print('Search: ${debouncedResult.value}');
/// });
///
/// // In a widget
/// Watch(builder: (ctx, _) => Text(debouncedResult.value));
///
/// // Don't forget to dispose when done
/// debouncedResult.dispose();
/// ```
TimedSignal<T> debounced<T>(Signal<T> source, Duration duration) {
  // Use untrack to ensure effect creation is isolated from any outer reactive context.
  // This prevents issues when debounced() is called inside another effect (e.g., from late final initialization).
  return untrack(() {
    final debouncedSignal = signals.signal<T>(source.value);
    Timer? timer;

    final eff = signals.effect(() {
      final value = source.value;
      timer?.cancel();
      timer = Timer(duration, () {
        debouncedSignal.value = value;
      });
    });

    return TimedSignal._(
      signal: debouncedSignal,
      dispose: () {
        timer?.cancel();
        eff.stop();
      },
    );
  });
}

/// Creates a throttled signal that only updates at most once per duration.
///
/// The first update is always applied immediately. Subsequent updates within
/// the duration window are ignored, and the last value is applied after the
/// duration passes.
///
/// **Important:** Call [TimedSignal.dispose] when no longer needed to prevent
/// memory leaks.
///
/// Example:
/// ```dart
/// final scrollPosition = signal(0.0);
/// final throttledResult = throttled(scrollPosition, Duration(milliseconds: 100));
///
/// // Updates at most every 100ms, even with rapid scroll events
/// // Don't forget to dispose when done
/// throttledResult.dispose();
/// ```
TimedSignal<T> throttled<T>(Signal<T> source, Duration duration) {
  // Use untrack to ensure effect creation is isolated from any outer reactive context.
  return untrack(() {
    final throttledSignal = signals.signal<T>(source.value);
    Timer? pendingTimer;
    T? pendingValue;
    bool hasPendingValue = false;
    DateTime? lastUpdate;
    T? lastSourceValue = source.value;

    final eff = signals.effect(() {
      final value = source.value;

      // Skip if value hasn't actually changed
      if (lastSourceValue == value) {
        return;
      }
      lastSourceValue = value;

      final now = DateTime.now();

      if (lastUpdate == null || now.difference(lastUpdate!) >= duration) {
        // Enough time has passed, update immediately
        lastUpdate = now;
        throttledSignal.value = value;
        hasPendingValue = false;
        pendingTimer?.cancel();
        pendingTimer = null;
      } else {
        // Within throttle window, schedule trailing update
        pendingValue = value;
        hasPendingValue = true;
        pendingTimer?.cancel();
        pendingTimer = Timer(duration - now.difference(lastUpdate!), () {
          if (hasPendingValue) {
            lastUpdate = DateTime.now();
            throttledSignal.value = pendingValue as T;
            hasPendingValue = false;
          }
        });
      }
    });

    return TimedSignal._(
      signal: throttledSignal,
      dispose: () {
        pendingTimer?.cancel();
        eff.stop();
      },
    );
  });
}

/// Creates a signal that delays updates by a fixed duration.
///
/// Unlike debounce, this always delays every update.
///
/// **Important:** Call [TimedSignal.dispose] when no longer needed to prevent
/// memory leaks.
TimedSignal<T> delayed<T>(Signal<T> source, Duration duration) {
  // Use untrack to ensure effect creation is isolated from any outer reactive context.
  return untrack(() {
    final delayedSignal = signals.signal<T>(source.value);
    Timer? timer;

    final eff = signals.effect(() {
      final value = source.value;
      timer?.cancel();
      timer = Timer(duration, () {
        delayedSignal.value = value;
      });
    });

    return TimedSignal._(
      signal: delayedSignal,
      dispose: () {
        timer?.cancel();
        eff.stop();
      },
    );
  });
}
